import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_config.dart';
import '../models/score_entry.dart';

/// The best result of every player for a single game type.
class GameTypeLeaderboard {
  GameTypeLeaderboard({
    required this.gameTypeKey,
    required this.duration,
    required this.operationSymbols,
    required this.entries,
  });

  final String gameTypeKey;
  final ChallengeDuration duration;
  final String operationSymbols;

  /// One entry per player (their best score), highest first.
  final List<ScoreEntry> entries;
}

/// Persists every finished game on the device using shared_preferences. The
/// stored history powers both the leaderboard (best score per player per game
/// type) and the per-player history screen.
class LeaderboardService {
  static const String _key = 'history_v2';

  /// Maximum number of games kept in storage.
  static const int maxHistory = 500;

  /// Returns all stored games, most recent first.
  Future<List<ScoreEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <ScoreEntry>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
      return entries;
    } catch (_) {
      return <ScoreEntry>[];
    }
  }

  /// Stores [entry] and returns the full, updated history (most recent first).
  Future<List<ScoreEntry>> addScore(ScoreEntry entry) async {
    final entries = await load()..insert(0, entry);
    final trimmed = entries.take(maxHistory).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
    return trimmed;
  }

  /// Groups [entries] into one leaderboard per game type, keeping only each
  /// player's best score within a game type so a player appears at most once
  /// per game type.
  static List<GameTypeLeaderboard> buildLeaderboards(
    List<ScoreEntry> entries,
  ) {
    final byType = <String, List<ScoreEntry>>{};
    for (final entry in entries) {
      byType.putIfAbsent(entry.gameTypeKey, () => <ScoreEntry>[]).add(entry);
    }

    final boards = <GameTypeLeaderboard>[];
    for (final group in byType.values) {
      final best = <String, ScoreEntry>{};
      for (final entry in group) {
        final current = best[entry.name];
        if (current == null || entry.score > current.score) {
          best[entry.name] = entry;
        }
      }
      final ranked = best.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      final first = group.first;
      boards.add(
        GameTypeLeaderboard(
          gameTypeKey: first.gameTypeKey,
          duration: first.duration,
          operationSymbols: first.operationSymbols,
          entries: ranked,
        ),
      );
    }

    boards.sort((a, b) {
      final byDuration = a.duration.index.compareTo(b.duration.index);
      if (byDuration != 0) return byDuration;
      return a.operationSymbols.compareTo(b.operationSymbols);
    });
    return boards;
  }
}
