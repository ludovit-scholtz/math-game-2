import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/score_entry.dart';

/// Persists the high-score leaderboard on the device using shared_preferences.
class LeaderboardService {
  static const String _key = 'leaderboard_v1';
  static const int maxEntries = 10;

  /// Returns the stored scores, highest first.
  Future<List<ScoreEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <ScoreEntry>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return entries;
    } catch (_) {
      return <ScoreEntry>[];
    }
  }

  /// Adds [entry], keeps only the top [maxEntries] and returns the new board.
  Future<List<ScoreEntry>> addScore(ScoreEntry entry) async {
    final entries = await load()
      ..add(entry)
      ..sort((a, b) => b.score.compareTo(a.score));
    final trimmed = entries.take(maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
    return trimmed;
  }
}
