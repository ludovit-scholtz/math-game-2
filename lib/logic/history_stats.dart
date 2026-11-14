import '../models/game_config.dart';
import '../models/score_entry.dart';

/// Aggregated statistics over a list of finished games, shown to parents.
class HistorySummary {
  HistorySummary._({
    required this.games,
    required this.practiceSeconds,
    required this.accuracyPercent,
    required this.averageAnswerMillis,
    required this.bestStreak,
    required this.gems,
    required this.coins,
    required this.mostMissed,
  });

  /// Number of most-missed prompts reported.
  static const int mostMissedCount = 5;

  final int games;

  /// Total time spent playing, from the challenge lengths.
  final int practiceSeconds;

  /// Share of correct answers over all games, 0..100.
  final int accuracyPercent;

  /// Average answer time over the games that recorded it, 0 when unknown.
  final int averageAnswerMillis;
  final int bestStreak;
  final int gems;
  final int coins;

  /// The prompts missed most often (most first), with how many games missed
  /// them.
  final List<MapEntry<String, int>> mostMissed;

  factory HistorySummary.from(List<ScoreEntry> entries) {
    var seconds = 0;
    var correct = 0;
    var answered = 0;
    var timedAnswers = 0;
    var timedMillis = 0;
    var bestStreak = 0;
    var gems = 0;
    var coins = 0;
    final missedCounts = <String, int>{};
    for (final entry in entries) {
      seconds += entry.duration.seconds;
      correct += entry.correct;
      answered += entry.answered;
      if (entry.avgAnswerMillis > 0 && entry.answered > 0) {
        timedAnswers += entry.answered;
        timedMillis += entry.avgAnswerMillis * entry.answered;
      }
      if (entry.bestStreak > bestStreak) bestStreak = entry.bestStreak;
      gems += entry.gemsEarned;
      coins += entry.coinsEarned;
      for (final prompt in entry.missed) {
        missedCounts[prompt] = (missedCounts[prompt] ?? 0) + 1;
      }
    }
    final ranked = missedCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return HistorySummary._(
      games: entries.length,
      practiceSeconds: seconds,
      accuracyPercent: answered == 0 ? 0 : (correct / answered * 100).round(),
      averageAnswerMillis: timedAnswers == 0
          ? 0
          : (timedMillis / timedAnswers).round(),
      bestStreak: bestStreak,
      gems: gems,
      coins: coins,
      mostMissed: ranked.take(mostMissedCount).toList(),
    );
  }
}
