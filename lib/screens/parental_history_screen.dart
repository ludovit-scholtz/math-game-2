import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../logic/history_stats.dart';
import '../models/score_entry.dart';
import '../services/leaderboard_service.dart';
import '../theme.dart';

/// Every game ever played on this device, for every player, with the date,
/// time and statistics a parent wants to see.
class ParentalHistoryScreen extends StatefulWidget {
  const ParentalHistoryScreen({super.key});

  @override
  State<ParentalHistoryScreen> createState() => _ParentalHistoryScreenState();
}

enum _Period { week, month, all }

class _ParentalHistoryScreenState extends State<ParentalHistoryScreen> {
  final LeaderboardService _service = LeaderboardService();

  List<ScoreEntry> _entries = [];
  bool _loading = true;
  String? _player; // null = all players
  _Period _period = _Period.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<ScoreEntry> get _visible {
    final now = DateTime.now();
    final cutoff = switch (_period) {
      _Period.week => now.subtract(const Duration(days: 7)),
      _Period.month => now.subtract(const Duration(days: 30)),
      _Period.all => null,
    };
    return _entries.where((e) {
      if (_player != null && e.name != _player) return false;
      if (cutoff != null &&
          DateTime.fromMillisecondsSinceEpoch(e.dateMillis).isBefore(cutoff)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final names = {for (final e in _entries) e.name}.toList()..sort();
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.gameHistory),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String?>(
                        key: const ValueKey('history-player'),
                        value: _player,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(strings.allPlayers),
                          ),
                          for (final name in names)
                            DropdownMenuItem<String?>(
                              value: name,
                              child: Text(name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _player = value),
                      ),
                      DropdownButton<_Period>(
                        key: const ValueKey('history-period'),
                        value: _period,
                        items: [
                          DropdownMenuItem(
                            value: _Period.week,
                            child: Text(strings.periodWeek),
                          ),
                          DropdownMenuItem(
                            value: _Period.month,
                            child: Text(strings.periodMonth),
                          ),
                          DropdownMenuItem(
                            value: _Period.all,
                            child: Text(strings.periodAll),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _period = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(strings.noHistoryYet)),
                    )
                  else ...[
                    _SummaryCard(summary: HistorySummary.from(visible)),
                    const SizedBox(height: 12),
                    for (final entry in visible) _GameRow(entry: entry),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final minutes = (summary.practiceSeconds / 60).round();
    final style = Theme.of(context).textTheme.bodyMedium;
    return Card(
      key: const ValueKey('history-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.gamesPlayed}: ${summary.games}', style: style),
            Text(
              '${strings.practiceTime}: ${strings.minutesValue(minutes)}',
              style: style,
            ),
            Text(
              '${strings.accuracy}: ${summary.accuracyPercent}%',
              style: style,
            ),
            if (summary.averageAnswerMillis > 0)
              Text(
                '${strings.averageAnswerTime}: '
                '${strings.secondsValue((summary.averageAnswerMillis / 1000).toStringAsFixed(1))}',
                style: style,
              ),
            Text('${strings.bestStreak}: ${summary.bestStreak}', style: style),
            Text('💎 ${summary.gems}   🪙 ${summary.coins}', style: style),
            if (summary.mostMissed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                strings.mostMissed,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final missed in summary.mostMissed)
                Text('${missed.key}   ×${missed.value}', style: style),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.entry});

  final ScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final localizations = MaterialLocalizations.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(entry.dateMillis);
    final when =
        '${localizations.formatShortDate(date)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final mode = [
      strings.durationLabel(entry.duration),
      entry.operationSymbols,
      entry.modeLabel,
    ].where((part) => part.isNotEmpty).join('  ');
    final details = [
      strings.scoreLabel(entry.score),
      '✓ ${entry.correct}/${entry.answered} (${entry.accuracyPercent}%)',
      if (entry.avgAnswerMillis > 0)
        strings.secondsValue((entry.avgAnswerMillis / 1000).toStringAsFixed(1)),
      if (entry.bestStreak > 0) '🔥 ${entry.bestStreak}',
      if (entry.gemsEarned > 0) '💎 ${entry.gemsEarned}',
      if (entry.coinsEarned > 0) '🪙 ${entry.coinsEarned}',
    ].join('  ·  ');
    return Card(
      child: ListTile(
        key: ValueKey('game-${entry.dateMillis}'),
        title: Text('${entry.name}  ·  $when'),
        subtitle: Text('$mode\n$details'),
        isThreeLine: true,
        onTap: entry.missed.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(strings.missedQuestions),
                  content: Text(entry.missed.join('\n')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.close),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
