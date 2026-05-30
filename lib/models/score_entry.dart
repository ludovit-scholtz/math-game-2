/// A single entry on the high-score leaderboard.
class ScoreEntry {
  ScoreEntry({
    required this.name,
    required this.score,
    required this.durationLabel,
    required this.dateMillis,
  });

  final String name;
  final int score;
  final String durationLabel;
  final int dateMillis;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'durationLabel': durationLabel,
        'dateMillis': dateMillis,
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
        name: (json['name'] ?? 'Player').toString(),
        score: (json['score'] as num?)?.toInt() ?? 0,
        durationLabel: (json['durationLabel'] ?? '').toString(),
        dateMillis: (json['dateMillis'] as num?)?.toInt() ?? 0,
      );
}
