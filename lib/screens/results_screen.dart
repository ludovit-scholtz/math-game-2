import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  Future<void> _initBoard() async {
    if (widget.finalScore != null && widget.finishedConfig != null) {
      final entry = ScoreEntry(
        name: widget.finishedConfig!.playerName,
        score: widget.finalScore!,
        durationLabel: widget.finishedConfig!.duration.label,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isResult ? 'Game Over' : 'Leaderboard'),
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
                      ? const Center(
                          child: Text('No scores yet. Be the first!'),
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
                      label: const Text('Home'),
                    ),
                  ),
                  if (isResult) const SizedBox(width: 12),
                  if (isResult)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Play again'),
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
          const Text(
            '🎉 Great job!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: ${widget.finalScore}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Correct: $correct / $answered  •  Accuracy: $accuracy%',
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
