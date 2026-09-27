import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';

class BreathSound {
  final String name;
  final WaveForm waveform;
  final double baseFreq;

  const BreathSound({
    required this.name,
    required this.waveform,
    required this.baseFreq,
  });
}

const List<BreathSound> breathSounds = [
  BreathSound(name: 'Мягкий ветер', waveform: WaveForm.sin, baseFreq: 180),
  BreathSound(name: 'Глубокий океан', waveform: WaveForm.fSaw, baseFreq: 90),
  BreathSound(name: 'Ночной лес', waveform: WaveForm.triangle, baseFreq: 220),
  BreathSound(name: 'Тёплый туман', waveform: WaveForm.sin, baseFreq: 140),
  BreathSound(name: 'Шёпот', waveform: WaveForm.fSquare, baseFreq: 320),
  BreathSound(name: 'Горный ручей', waveform: WaveForm.saw, baseFreq: 260),
  BreathSound(name: 'Далёкий прибой', waveform: WaveForm.fSaw, baseFreq: 70),
  BreathSound(name: 'Утренний бриз', waveform: WaveForm.sin, baseFreq: 200),
  BreathSound(name: 'Пещера', waveform: WaveForm.triangle, baseFreq: 60),
  BreathSound(name: 'Дождь', waveform: WaveForm.square, baseFreq: 380),
];

class BreathGenerator {
  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _source;
  SoundHandle? _handle;
  bool _inited = false;
  Timer? _stopTimer;

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

    // loadWaveform возвращает Future<AudioSource>, нужно await [citation:1]
    _source = await _soloud.loadWaveform(
      sound.waveform,
      false, // superWave
      1.0,   // scale
      0.0,   // detune
    );

    // setWaveformFreq принимает AudioSource (не handle) [citation:2]
    _soloud.setWaveformFreq(_source!, sound.baseFreq);

    // play возвращает Future<SoundHandle> в 4.x
    _handle = await _soloud.play(_source!);

    // fadeVolume принимает handle, конечную громкость и Duration [citation:3]
    final fadeTime = Duration(milliseconds: (durationSec * 800).round());

    if (rising) {
      _soloud.fadeVolume(_handle!, 0.6, fadeTime); // нарастание
    } else {
      _soloud.fadeVolume(_handle!, 0.6, Duration.zero); // сразу на 0.6
      _soloud.fadeVolume(_handle!, 0.0, fadeTime);      // затухание
    }

    // Останавливаем через durationSec
    _stopTimer?.cancel();
    _stopTimer = Timer(
      Duration(milliseconds: (durationSec * 1000).round()),
      () => stop(),
    );
  }

  Future<void> stop() async {
    _stopTimer?.cancel();
    _stopTimer = null;

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
