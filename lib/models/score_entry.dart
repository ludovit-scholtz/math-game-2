import 'game_config.dart';
import 'operation_type.dart';

/// A single finished game. Used both for the high-score leaderboard and for the
/// per-player history of games played (which records how many faults the player
/// made).
class ScoreEntry {
  ScoreEntry({
    required this.name,
    required this.score,
    required this.duration,
    required List<OperationType> operations,
    required this.correct,
    required this.answered,
    required this.dateMillis,
  }) : operations = _sorted(operations);

  final String name;
  final int score;
  final ChallengeDuration duration;

  /// The operations practised, always sorted in [OperationType] order so the
  /// game-type key is stable.
  final List<OperationType> operations;

  final int correct;
  final int answered;
  final int dateMillis;

  /// Number of questions answered incorrectly.
  int get faults => (answered - correct).clamp(0, answered);

  /// The operation symbols joined together, e.g. `+−` or `+−×÷`.
  String get operationSymbols => operations.map((o) => o.symbol).join();

  /// A language-independent identifier for the game type (duration plus the set
  /// of operations). Two games share a leaderboard when their keys match.
  String get gameTypeKey =>
      '${duration.index}|${operations.map((o) => o.storageKey).join(',')}';

  static List<OperationType> _sorted(List<OperationType> ops) {
    final list = ops.toList()..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'duration': duration.index,
        'operations': operations.map((o) => o.storageKey).toList(),
        'correct': correct,
        'answered': answered,
        'dateMillis': dateMillis,
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    final durationIndex = (json['duration'] as num?)?.toInt() ?? 0;
    final duration =
        durationIndex >= 0 && durationIndex < ChallengeDuration.values.length
            ? ChallengeDuration.values[durationIndex]
            : ChallengeDuration.oneMinute;
    final rawOps = (json['operations'] as List<dynamic>?) ?? const [];
    final operations = rawOps
        .map((e) => _operationFromKey(e.toString()))
        .whereType<OperationType>()
        .toList();
    return ScoreEntry(
      name: (json['name'] ?? 'Player').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      duration: duration,
      operations: operations.isEmpty
          ? [OperationType.addition, OperationType.subtraction]
          : operations,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      dateMillis: (json['dateMillis'] as num?)?.toInt() ?? 0,
    );
  }

  static OperationType? _operationFromKey(String key) {
    for (final op in OperationType.values) {
      if (op.storageKey == key) return op;
    }
    return null;
  }
}
