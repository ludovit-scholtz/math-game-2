import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/score_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

/// Shows the games a single player has played, including the statistics for
/// each game such as the number of faults.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LeaderboardService _service = LeaderboardService();
  List<ScoreEntry> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _service.load();
    final games = all
        .where((e) => e.name == widget.playerName)
        .toList()
      ..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
    if (!mounted) return;
    setState(() {
      _games = games;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playerName),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _games.isEmpty
                ? Center(child: Text(strings.noHistoryYet))
                : Column(
                    children: [
                      _StatsHeader(games: _games),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _games.length,
                          itemBuilder: (context, index) =>
                              _GameTile(entry: _games[index]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.games});

  final List<ScoreEntry> games;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final bestScore =
        games.map((e) => e.score).fold<int>(games.first.score, (a, b) => b > a ? b : a);
    final totalFaults = games.fold<int>(0, (sum, e) => sum + e.faults);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatBox(label: strings.gamesPlayed, value: '${games.length}'),
          _StatBox(label: strings.bestScore, value: '$bestScore'),
          _StatBox(label: strings.faults, value: '$totalFaults'),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.entry});

  final ScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final accuracy = entry.answered == 0
        ? 0
        : (entry.correct / entry.answered * 100).round();
    final gameType =
        '${strings.durationLabel(entry.duration)} ${entry.operationSymbols}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            entry.operationSymbols,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          gameType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${strings.faults}: ${entry.faults}  •  '
          '${strings.correctAccuracyLabel(correct: entry.correct, answered: entry.answered, accuracy: accuracy)}',
        ),
        trailing: Text(
          '${entry.score}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
