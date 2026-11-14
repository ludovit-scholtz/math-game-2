import 'game_config.dart';
import 'operation_type.dart';
import 'practice_settings.dart';

/// A single finished game. Used both for the high-score leaderboard and for the
/// per-player history of games played (which records how many faults the player
/// made, and for the parental control panel the extra statistics).
class ScoreEntry {
  ScoreEntry({
    required this.name,
    required this.score,
    required this.duration,
    required List<OperationType> operations,
    required this.correct,
    required this.answered,
    required this.dateMillis,
    List<Drill> drills = const <Drill>[],
    this.modeKey = '',
    this.gemsEarned = 0,
    this.coinsEarned = 0,
    this.bestStreak = 0,
    this.avgAnswerMillis = 0,
    List<String> missed = const <String>[],
  })  : operations = _sorted(operations),
        drills = _sortedDrills(drills),
        missed = List.unmodifiable(missed);

  final String name;
  final int score;
  final ChallengeDuration duration;

  /// The operations practised, always sorted in [OperationType] order so the
  /// game-type key is stable.
  final List<OperationType> operations;

  /// The focused drills practised, sorted in [Drill] order.
  final List<Drill> drills;

  /// Difficulty of the game (see [PracticeSettings.modeKeyFor]); empty for the
  /// classic mode, which is also what games saved before modes existed get.
  final String modeKey;

  final int correct;
  final int answered;
  final int dateMillis;
  final int gemsEarned;
  final int coinsEarned;
  final int bestStreak;

  /// Average time per answer, 0 when unknown (older games).
  final int avgAnswerMillis;

  /// Prompts answered wrongly in this game (capped, may be empty).
  final List<String> missed;

  /// Number of questions answered incorrectly.
  int get faults => (answered - correct).clamp(0, answered);

  /// Share of correct answers, 0..100.
  int get accuracyPercent =>
      answered == 0 ? 0 : (correct / answered * 100).round();

  /// The operation symbols joined together, e.g. `+−` or `+−×÷`, followed by
  /// the examples of any drills.
  String get operationSymbols => [
        operations.map((o) => o.symbol).join(),
        ...drills.map((d) => d.example),
      ].where((part) => part.isNotEmpty).join(' ');

  /// A short, language independent description of the difficulty such as
  /// `1–20 · 10✗`, or empty for the classic mode.
  String get modeLabel {
    final labels = <String>[];
    for (final part in modeKey.split('|')) {
      if (part.isEmpty || part.startsWith('d-')) continue;
      final range = NumberRangeX.fromId(part);
      if (range != null) {
        labels.add('≤${range.max}');
      } else if (part == 'x-none') {
        labels.add('10✗');
      } else if (part == 'x-only') {
        labels.add('10✓');
      } else if (part.startsWith('t-')) {
        labels.add('×${part.substring(2).replaceAll(',', '·')}');
      }
    }
    return labels.join(' ');
  }

  /// A language-independent identifier for the game type (duration, the set of
  /// operations and the difficulty). Two games share a leaderboard when their
  /// keys match. Classic games keep the key they always had.
  String get gameTypeKey {
    final base =
        '${duration.index}|${operations.map((o) => o.storageKey).join(',')}';
    return modeKey.isEmpty ? base : '$base|$modeKey';
  }

  ScoreEntry copyWith({int? coinsEarned}) => ScoreEntry(
        name: name,
        score: score,
        duration: duration,
        operations: operations,
        correct: correct,
        answered: answered,
        dateMillis: dateMillis,
        drills: drills,
        modeKey: modeKey,
        gemsEarned: gemsEarned,
        coinsEarned: coinsEarned ?? this.coinsEarned,
        bestStreak: bestStreak,
        avgAnswerMillis: avgAnswerMillis,
        missed: missed,
      );

  static List<OperationType> _sorted(List<OperationType> ops) {
    final list = ops.toList()..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  static List<Drill> _sortedDrills(List<Drill> drills) {
    final list = drills.toList()..sort((a, b) => a.index.compareTo(b.index));
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
        'drills': drills.map((d) => d.id).toList(),
        'modeKey': modeKey,
        'gemsEarned': gemsEarned,
        'coinsEarned': coinsEarned,
        'bestStreak': bestStreak,
        'avgAnswerMillis': avgAnswerMillis,
        'missed': missed,
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
    final drills = ((json['drills'] as List<dynamic>?) ?? const [])
        .map((e) => DrillX.fromId(e.toString()))
        .whereType<Drill>()
        .toList();
    final missed = ((json['missed'] as List<dynamic>?) ?? const [])
        .map((e) => e.toString())
        .toList();
    return ScoreEntry(
      name: (json['name'] ?? 'Player').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      duration: duration,
      operations: operations.isEmpty && drills.isEmpty
          ? [OperationType.addition, OperationType.subtraction]
          : operations,
      drills: drills,
      modeKey: (json['modeKey'] ?? '').toString(),
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      dateMillis: (json['dateMillis'] as num?)?.toInt() ?? 0,
      gemsEarned: (json['gemsEarned'] as num?)?.toInt() ?? 0,
      coinsEarned: (json['coinsEarned'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      avgAnswerMillis: (json['avgAnswerMillis'] as num?)?.toInt() ?? 0,
      missed: missed,
    );
  }

  static OperationType? _operationFromKey(String key) {
    for (final op in OperationType.values) {
      if (op.storageKey == key) return op;
    }
    return null;
  }
}
