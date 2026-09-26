import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/breath_generator.dart';
import '../timer/breath_cycle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _baseController = TextEditingController(text: '2');
  final _generator = BreathGenerator();
  late final _cycle = BreathCycle(_generator);

  BreathSound _selectedSound = breathSounds[0];
  String _phase = '';
  double _remaining = 0;
  bool _isRunning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generator.init();
  }

  @override
  void dispose() {
    _cycle.stop();
    _generator.dispose();
    _baseController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isRunning) {
      _cycle.stop();
      setState(() {
        _isRunning = false;
        _phase = '';
        _remaining = 0;
      });
      return;
    }

    final parsed = double.tryParse(_baseController.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Введите число больше 0');
      return;
    }

    setState(() {
      _error = null;
      _isRunning = true;
    });

    _cycle.start(parsed, _selectedSound, (phase, remaining) {
      if (mounted) setState(() { _phase = phase; _remaining = remaining; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дыхание 1-2-1.5')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _baseController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Базовая длительность (сек)',
                helperText: 'Вдох ×1, пауза ×2, выдох ×1.5',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<BreathSound>(
              value: _selectedSound,
              decoration: const InputDecoration(
                labelText: 'Звук',
                border: OutlineInputBorder(),
              ),
              items: breathSounds
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: _isRunning
                  ? null
                  : (v) {
                      if (v != null) setState(() => _selectedSound = v);
                    },
            ),
            const SizedBox(height: 48),

            if (_isRunning) ...[
              Text(
                _phase,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${_remaining.toStringAsFixed(1)} сек',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
            ],

            const Spacer(),

            FilledButton(
              onPressed: _toggle,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: _isRunning ? Colors.red : null,
              ),
              child: Text(
                _isRunning ? 'СТОП' : 'СТАРТ',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
