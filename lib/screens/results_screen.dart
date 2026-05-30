import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/game_config.dart';
import '../models/score_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

/// Shows the high-score leaderboard. When opened right after a game it also
/// saves the new score and shows a summary of the round.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    this.finishedConfig,
    this.finalScore,
    this.correctCount,
    this.answeredCount,
  });

  /// Non-null when arriving from a finished game.
  final GameConfig? finishedConfig;
  final int? finalScore;
  final int? correctCount;
  final int? answeredCount;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final LeaderboardService _service = LeaderboardService();
  List<ScoreEntry> _entries = [];
  bool _loading = true;
  int? _highlightDate;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initBoard();
  }

  Future<void> _initBoard() async {
    final strings = context.strings;
    if (widget.finalScore != null && widget.finishedConfig != null) {
      final entry = ScoreEntry(
        name: widget.finishedConfig!.playerName,
        score: widget.finalScore!,
        durationLabel: strings.durationLabel(widget.finishedConfig!.duration),
        dateMillis: DateTime.now().millisecondsSinceEpoch,
      );
      _highlightDate = entry.dateMillis;
      final board = await _service.addScore(entry);
      if (!mounted) return;
      setState(() {
        _entries = board;
        _loading = false;
      });
    } else {
      final board = await _service.load();
      if (!mounted) return;
      setState(() {
        _entries = board;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResult = widget.finalScore != null;
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(isResult ? strings.gameOver : strings.leaderboard),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isResult) _buildSummary(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text(strings.noScoresYet),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final highlight =
                                entry.dateMillis == _highlightDate;
                            return _LeaderboardTile(
                              rank: index + 1,
                              entry: entry,
                              highlight: highlight,
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(strings.home),
                    ),
                  ),
                  if (isResult) const SizedBox(width: 12),
                  if (isResult)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(strings.playAgain),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final strings = context.strings;
    final correct = widget.correctCount ?? 0;
    final answered = widget.answeredCount ?? 0;
    final accuracy =
        answered == 0 ? 0 : (correct / answered * 100).round();
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
      child: Column(
        children: [
          Text(
            strings.greatJob,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.scoreLabel(widget.finalScore ?? 0),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.correctAccuracyLabel(
              correct: correct,
              answered: answered,
              accuracy: accuracy,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.highlight,
  });

  final int rank;
  final ScoreEntry entry;
  final bool highlight;

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? AppTheme.secondary.withOpacity(0.18) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Text(_medal, style: const TextStyle(fontSize: 22)),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(entry.durationLabel),
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
