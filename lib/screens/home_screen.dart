import 'package:flutter/material.dart';

import '../models/game_config.dart';
import '../models/operation_type.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'results_screen.dart';

/// The first screen: pick a name, a challenge length and which operations to
/// practise, then start playing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Player');

  ChallengeDuration _duration = ChallengeDuration.oneMinute;
  final Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleOperation(OperationType type) {
    setState(() {
      if (_operations.contains(type)) {
        if (_operations.length > 1) _operations.remove(type);
      } else {
        _operations.add(type);
      }
    });
  }

  void _startGame() {
    final name = _nameController.text.trim().isEmpty
        ? 'Player'
        : _nameController.text.trim();
    final config = GameConfig(
      playerName: name,
      duration: _duration,
      operations: Set<OperationType>.from(_operations),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '🧮 Math Masters',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Practise +, −, × and ÷ under 100 and beat your best score!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Your name',
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your name',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Challenge length',
                child: Wrap(
                  spacing: 10,
                  children: ChallengeDuration.values.map((d) {
                    final selected = d == _duration;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _duration = d),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Operations to practise',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: OperationType.values.map((op) {
                    final selected = _operations.contains(op);
                    return FilterChip(
                      label: Text('${op.symbol}  ${op.label}'),
                      selected: selected,
                      onSelected: (_) => _toggleOperation(op),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ResultsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Leaderboard'),
              ),
              const SizedBox(height: 20),
              const _ScoringHelp(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoringHelp extends StatelessWidget {
  const _ScoringHelp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How scoring works',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('⚡ Answer in under 1 second: 3 points'),
          const Text('⏱️ Between 1 and 10 seconds: faster = more points'),
          const Text('🐢 Slower than 10 seconds or wrong: −1 point'),
          const Text('🔁 Missed questions come back so you can master them'),
        ],
      ),
    );
  }
}
