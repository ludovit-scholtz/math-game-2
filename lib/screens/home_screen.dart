import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/game_config.dart';
import '../models/operation_type.dart';
import '../models/player_profile.dart';
import '../services/player_service.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'player_select_screen.dart';
import 'results_screen.dart';

/// The first screen: pick (or switch) the player, a challenge length and which
/// operations to practise, then start playing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlayerService _playerService = PlayerService();

  PlayerProfile? _player;
  bool _loadingPlayer = true;

  ChallengeDuration _duration = ChallengeDuration.oneMinute;
  final Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final player = await _playerService.loadCurrent();
    if (!mounted) return;
    setState(() {
      _player = player;
      _loadingPlayer = false;
    });
    if (player != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          MathGameApp.of(context).setLocale(Locale(player.languageCode));
        }
      });
    }
  }

  Future<PlayerProfile?> _choosePlayer() async {
    final selected = await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute<PlayerProfile>(
        builder: (_) => const PlayerSelectScreen(),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _player = selected);
    }
    return selected;
  }

  Future<void> _changeLanguage(String code) async {
    final player = _player;
    if (player == null) return;
    final updated = await _playerService.setLanguage(player.name, code);
    if (!mounted || updated == null) return;
    setState(() => _player = updated);
    MathGameApp.of(context).setLocale(Locale(code));
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

  Future<void> _startGame() async {
    var player = _player;
    // If no player is selected, send the user to the selection screen first.
    if (player == null) {
      player = await _choosePlayer();
      if (player == null) return;
    }
    if (!mounted) return;
    final config = GameConfig(
      playerName: player.name,
      duration: _duration,
      operations: Set<OperationType>.from(_operations),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '🧮 ${strings.appName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.homeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: strings.player,
                child: _loadingPlayer
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPlayerSection(strings),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: strings.challengeLength,
                child: Wrap(
                  spacing: 10,
                  children: ChallengeDuration.values.map((d) {
                    final selected = d == _duration;
                    return ChoiceChip(
                      label: Text(strings.durationLabel(d)),
                      selected: selected,
                      onSelected: (_) => setState(() => _duration = d),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: strings.operationsToPractise,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: OperationType.values.map((op) {
                    final selected = _operations.contains(op);
                    return FilterChip(
                      label: Text('${op.symbol}  ${strings.operationLabel(op)}'),
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
                label: Text(strings.start),
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
                label: Text(strings.leaderboard),
              ),
              if (_player != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HistoryScreen(playerName: _player!.name),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: Text(strings.history),
                ),
              ],
              const SizedBox(height: 20),
              const _ScoringHelp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection(AppStrings strings) {
    final player = _player;
    if (player == null) {
      return ElevatedButton.icon(
        onPressed: _choosePlayer,
        icon: const Icon(Icons.person_rounded),
        label: Text(strings.choosePlayer),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.person_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _choosePlayer,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(strings.changePlayer),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: strings.language,
            prefixIcon: const Icon(Icons.language_rounded),
            isDense: true,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: player.languageCode,
              onChanged: (code) {
                if (code != null) _changeLanguage(code);
              },
              items: [
                for (final locale in AppStrings.supportedLocales)
                  DropdownMenuItem<String>(
                    value: locale.languageCode,
                    child: Text(AppStrings.languageName(locale.languageCode)),
                  ),
              ],
            ),
          ),
        ),
      ],
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
    final strings = context.strings;
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
            strings.howScoringWorks,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(strings.scoreFast),
          Text(strings.scoreMedium),
          Text(strings.scoreSlow),
          Text(strings.scoreRepeat),
        ],
      ),
    );
  }
}
