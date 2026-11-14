import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';
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

  /// Adds [profile], moves it to the front of the list and marks it as the
  /// current player.
  ///
  /// When a player with the same name (case-insensitive) already exists, that
  /// player is **kept** - name, pet and pet care included - and only takes the
  /// new language. Re-adding a name must never reset a pet or orphan the
  /// player's coins, which are stored under the original spelling. The
  /// profile that ended up selected is returned.
  Future<PlayerProfile> selectOrCreate(PlayerProfile profile) async {
    final players = await loadPlayers();
    PlayerProfile? existing;
    for (final player in players) {
      if (player.name.toLowerCase() == profile.name.toLowerCase()) {
        existing = player;
        break;
      }
    }
    var selected = profile;
    if (existing != null) {
      players.remove(existing);
      selected = existing.hasPet
          ? existing.copyWith(languageCode: profile.languageCode)
          : profile.copyWith(name: existing.name);
    }
    players.insert(0, selected);
    await _savePlayers(players);
    await _setCurrent(selected.name);
    return selected;
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

  /// Gives [name] a pet. A player who has no pet yet gets a fresh, happy one;
  /// a player who already has one only changes its kind and keeps its care
  /// levels, so switching pets cannot be used to dodge feeding and toys.
  Future<PlayerProfile?> setPet(String name, PetType petType) async {
    return _updatePlayer(
      name,
      (player) => player.hasPet
          ? player.withPetType(petType)
          : player.withPet(petType),
    );
  }

  /// Feeds the player's pet and returns the updated profile.
  Future<PlayerProfile?> feedPet(String name) async {
    return _updatePlayer(
      name,
      (player) => player.withUpdatedPetCare(feedingDelta: 30),
    );
  }

  /// Buys the player's pet a new toy and returns the updated profile.
  Future<PlayerProfile?> buyPetToy(String name) async {
    return _updatePlayer(
      name,
      (player) => player.withUpdatedPetCare(enjoymentDelta: 50),
    );
  }

  Future<PlayerProfile?> _updatePlayer(
    String name,
    PlayerProfile Function(PlayerProfile player) update,
  ) async {
    final players = await loadPlayers();
    PlayerProfile? updated;
    for (var i = 0; i < players.length; i++) {
      if (players[i].name == name) {
        updated = update(players[i]);
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
