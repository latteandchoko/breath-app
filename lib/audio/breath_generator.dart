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

    // Создаём осциллятор с нужной формой волны
    _source = await _soloud.loadWaveform(
      sound.waveform,
      false, // superWave
      1.0,   // scale
      0.0,   // detune
    );

    // Устанавливаем частоту
    _soloud.setWaveformFreq(_source!, sound.baseFreq);

    // Воспроизводим
    _handle = await _soloud.play(_source!);

    // Плавно меняем громкость:
    // Вдох — нарастание (fade in)
    // Выдох — затухание (fade out)
    if (rising) {
      _soloud.fadeVolume(_handle!, 0.0, 0.0); // мгновенно в 0
      _soloud.fadeVolume(_handle!, 0.6, durationSec * 0.8); // плавно к 0.6
    } else {
      _soloud.fadeVolume(_handle!, 0.6, 0.0); // начинаем с 0.6
      _soloud.fadeVolume(_handle!, 0.0, durationSec * 0.8); // плавно к 0
    }

    // Останавливаем через durationSec
    Future.delayed(Duration(milliseconds: (durationSec * 1000).round()), () {
      stop();
    });
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
