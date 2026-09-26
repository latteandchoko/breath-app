import 'dart:async';
import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';

class BreathSound {
  final String name;
  final double baseFreq;
  final bool isNoise;
  final double noiseCutoff;

  const BreathSound({
    required this.name,
    required this.baseFreq,
    this.isNoise = true,
    this.noiseCutoff = 0.5,
  });
}

const List<BreathSound> breathSounds = [
  BreathSound(name: 'Мягкий ветер', baseFreq: 180, noiseCutoff: 0.4),
  BreathSound(name: 'Глубокий океан', baseFreq: 90, noiseCutoff: 0.2),
  BreathSound(name: 'Ночной лес', baseFreq: 220, noiseCutoff: 0.5),
  BreathSound(name: 'Тёплый туман', baseFreq: 140, noiseCutoff: 0.3),
  BreathSound(name: 'Шёпот', baseFreq: 320, noiseCutoff: 0.7),
  BreathSound(name: 'Горный ручей', baseFreq: 260, noiseCutoff: 0.6),
  BreathSound(name: 'Далёкий прибой', baseFreq: 70, noiseCutoff: 0.15),
  BreathSound(name: 'Утренний бриз', baseFreq: 200, noiseCutoff: 0.45),
  BreathSound(name: 'Пещера', baseFreq: 60, noiseCutoff: 0.1),
  BreathSound(name: 'Дождь', baseFreq: 380, noiseCutoff: 0.8),
];

class BreathGenerator {
  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _source;
  SoundHandle? _handle;
  bool _inited = false;
  final Random _random = Random();

  Future<void> init() async {
    if (_inited) return;
    await _soloud.init();
    _inited = true;
  }

  Future<void> playInhale(BreathSound sound, double durationSec) async {
    await _play(sound, durationSec, rising: true);
  }

  Future<void> playExhale(BreathSound sound, double durationSec) async {
    await _play(sound, durationSec, rising: false);
  }

  Future<void> _play(BreathSound sound, double durationSec, {required bool rising}) async {
    await stop();
    if (!_inited) await init();

    // Создаём буфер с шумом вручную и загружаем как PCM
    final sampleRate = 22050;
    final totalSamples = (durationSec * sampleRate).round();
    final buffer = Float32List(totalSamples);

    double lp = 0.0;
    final cutoff = sound.noiseCutoff.clamp(0.02, 0.95);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      // Огибающая: вдох — нарастание, выдох — затухание
      final env = rising
          ? sin(t * pi / 2)
          : sin((1 - t) * pi / 2);

      // Белый шум + однополюсный фильтр низких частот
      final white = _random.nextDouble() * 2 - 1;
      lp = lp + cutoff * (white - lp);

      // Лёгкая модуляция для «живости»
      final mod = 0.85 + 0.15 * sin(2 * pi * sound.baseFreq / 40 * t);

      buffer[i] = (lp * env * mod * 0.6).clamp(-1.0, 1.0);
    }

    _source = await _soloud.loadMem(
      'breath_${sound.name}_${rising ? "in" : "out"}_${DateTime.now().microsecondsSinceEpoch}',
      _floatToBytes(buffer),
    );

    _handle = _soloud.play(_source!);
  }

  Uint8List _floatToBytes(Float32List floats) {
    final bytes = Uint8List(floats.length * 4);
    final view = ByteData.view(bytes.buffer);
    for (int i = 0; i < floats.length; i++) {
      view.setFloat32(i * 4, floats[i], Endian.little);
    }
    return bytes;
  }

  Future<void> stop() async {
    if (_handle != null) {
      await _soloud.stop(_handle!);
      _handle = null;
    }
    if (_source != null) {
      await _soloud.disposeSource(_source!);
      _source = null;
    }
  }

  Future<void> dispose() async {
    await stop();
    if (_inited) {
      _soloud.deinit();
      _inited = false;
    }
  }
}
