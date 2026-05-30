import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';

/// Persists the list of player profiles and which player is currently selected,
/// using shared_preferences.
class PlayerService {
  static const String _playersKey = 'players_v1';
  static const String _currentKey = 'current_player_v1';

  /// Returns the stored player profiles, most recently used first.
  Future<List<PlayerProfile>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playersKey);
    if (raw == null || raw.isEmpty) return <PlayerProfile>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => PlayerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <PlayerProfile>[];
    }
  }

  /// The currently selected player, or `null` if none has been chosen yet.
  Future<PlayerProfile?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_currentKey);
    if (name == null || name.isEmpty) return null;
    final players = await loadPlayers();
    for (final player in players) {
      if (player.name == name) return player;
    }
    return null;
  }

  /// Adds [profile] (or updates the one with the same name, case-insensitive),
  /// moves it to the front of the list and marks it as the current player.
  Future<PlayerProfile> selectOrCreate(PlayerProfile profile) async {
    final players = await loadPlayers();
    players.removeWhere(
      (p) => p.name.toLowerCase() == profile.name.toLowerCase(),
    );
    players.insert(0, profile);
    await _savePlayers(players);
    await _setCurrent(profile.name);
    return profile;
  }

  /// Updates the language of [name] and returns the updated profile.
  Future<PlayerProfile?> setLanguage(String name, String languageCode) async {
    final players = await loadPlayers();
    PlayerProfile? updated;
    for (var i = 0; i < players.length; i++) {
      if (players[i].name == name) {
        updated = players[i].copyWith(languageCode: languageCode);
        players[i] = updated;
        break;
      }
    }
    if (updated != null) await _savePlayers(players);
    return updated;
  }

  Future<void> _setCurrent(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, name);
  }

  Future<void> _savePlayers(List<PlayerProfile> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playersKey,
      jsonEncode(players.map((p) => p.toJson()).toList()),
    );
  }
}
