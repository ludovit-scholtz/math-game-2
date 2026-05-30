import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/game_config.dart';
import '../models/score_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

/// Shows the high-score leaderboard grouped by game type (each player appears at
/// most once per game type, showing their best score). When opened right after
/// a game it also saves the new result and shows a summary of the round.
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
  List<GameTypeLeaderboard> _boards = [];
  bool _loading = true;
  int? _highlightDate;
  String? _highlightGameType;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initBoard();
  }

  Future<void> _initBoard() async {
    List<ScoreEntry> history;
    if (widget.finalScore != null && widget.finishedConfig != null) {
      final config = widget.finishedConfig!;
      final entry = ScoreEntry(
        name: config.playerName,
        score: widget.finalScore!,
        duration: config.duration,
        operations: config.operations.toList(),
        correct: widget.correctCount ?? 0,
        answered: widget.answeredCount ?? 0,
        dateMillis: DateTime.now().millisecondsSinceEpoch,
      );
      _highlightDate = entry.dateMillis;
      _highlightGameType = entry.gameTypeKey;
      history = await _service.addScore(entry);
    } else {
      history = await _service.load();
    }
    if (!mounted) return;
    setState(() {
      _boards = LeaderboardService.buildLeaderboards(history);
      _loading = false;
    });
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
                  : _boards.isEmpty
                      ? Center(child: Text(strings.noScoresYet))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final board in _boards)
                              _LeaderboardSection(
                                board: board,
                                highlightDate: _highlightDate,
                                isHighlightedType:
                                    board.gameTypeKey == _highlightGameType,
                              ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      filled: false,
                      icon: Icons.home_rounded,
                      label: strings.home,
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ),
                  if (isResult) const SizedBox(width: 12),
                  if (isResult)
                    Expanded(
                      child: _BottomButton(
                        filled: true,
                        icon: Icons.refresh_rounded,
                        label: strings.playAgain,
                        onPressed: () => Navigator.of(context).pop(),
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
    final accuracy = answered == 0 ? 0 : (correct / answered * 100).round();
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
            style: const TextStyle(
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

/// A fixed-height bottom action button whose label never wraps to a second line.
class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.filled,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool filled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
    const style = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
    );
    return SizedBox(
      height: 56,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: child,
            ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({
    required this.board,
    required this.highlightDate,
    required this.isHighlightedType,
  });

  final GameTypeLeaderboard board;
  final int? highlightDate;
  final bool isHighlightedType;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title =
        '${strings.durationLabel(board.duration)} ${board.operationSymbols}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: isHighlightedType ? AppTheme.secondary : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        for (var i = 0; i < board.entries.length; i++)
          _LeaderboardTile(
            rank: i + 1,
            entry: board.entries[i],
            highlight: board.entries[i].dateMillis == highlightDate,
          ),
        const SizedBox(height: 12),
      ],
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
    final strings = context.strings;
    return Card(
      color: highlight ? AppTheme.secondary.withOpacity(0.18) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Text(_medal, style: const TextStyle(fontSize: 22)),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${strings.faults}: ${entry.faults}'),
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
