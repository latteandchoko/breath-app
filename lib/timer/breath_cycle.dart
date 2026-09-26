import 'dart:async';
import '../audio/breath_generator.dart';

typedef PhaseCallback = void Function(String phase, double remaining);

class BreathCycle {
  final BreathGenerator generator;
  Timer? _timer;
  bool _isRunning = false;

  BreathCycle(this.generator);

  bool get isRunning => _isRunning;

  void start(double base, BreathSound sound, PhaseCallback onTick) {
    _isRunning = true;
    _runInhale(base, sound, onTick);
  }

  void _runInhale(double base, BreathSound sound, PhaseCallback onTick) {
    _runPhase('Вдох', base, sound, onTick, () {
      _runPause(base, sound, onTick);
    }, isInhale: true);
  }

  void _runPause(double base, BreathSound sound, PhaseCallback onTick) {
    _runPhase('Пауза', base * 2, sound, onTick, () {
      _runExhale(base, sound, onTick);
    });
  }

  void _runExhale(double base, BreathSound sound, PhaseCallback onTick) {
    _runPhase('Выдох', base * 1.5, sound, onTick, () {
      if (_isRunning) _runInhale(base, sound, onTick);
    }, isInhale: false);
  }

  void _runPhase(
    String name,
    double durationSec,
    BreathSound sound,
    PhaseCallback onTick,
    VoidCallback onDone, {
    bool isInhale = false,
  }) {
    if (!_isRunning) return;

    final totalMs = (durationSec * 1000).round();
    final startTime = DateTime.now();

    if (name == 'Вдох') {
      generator.playInhale(sound, durationSec);
    } else if (name == 'Выдох') {
      generator.playExhale(sound, durationSec);
    } else {
      generator.stop();
    }

    onTick(name, durationSec);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isRunning) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed >= totalMs) {
        t.cancel();
        onTick(name, 0);
        onDone();
      } else {
        onTick(name, (totalMs - elapsed) / 1000);
      }
    });
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    generator.stop();
  }
}

typedef VoidCallback = void Function();
