import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_settings.dart';

/// Persists what parents allow each child to practise, and whether the
/// first-run setup has been completed. Stored locally in shared_preferences
/// like everything else.
///
/// Settings are kept per player (by name). A player without their own settings
/// uses the **template**: the settings chosen in the first-run setup or applied
/// with "apply to all players". Editing one player never changes another.
class ParentalSettingsService {
  static const String _settingsKey = 'practice_settings_v1';
  static const String _onboardingKey = 'onboarding_done_v1';

  /// The stored settings: `{'template': {...}, 'players': {name: {...}}}`.
  Future<Map<String, dynamic>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _saveRaw(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(data));
  }

  static PracticeSettings? _parse(Object? value) {
    if (value is! Map) return null;
    try {
      return PracticeSettings.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  /// The settings applying to [playerName]; with no name (or no saved
  /// settings yet) the template, or the classic defaults.
  Future<PracticeSettings> load([String? playerName]) async {
    final data = await _loadRaw();
    final players = data['players'];
    if (playerName != null && players is Map) {
      final own = _parse(players[playerName]);
      if (own != null) return own;
    }
    return _parse(data['template']) ?? PracticeSettings.defaults();
  }

  /// Saves [settings] for [playerName]. With no name they become the
  /// template that players without their own settings use. Saving for one
  /// player never changes what other players get.
  Future<void> save(PracticeSettings settings, [String? playerName]) async {
    final data = await _loadRaw();
    if (playerName == null) {
      data['template'] = settings.toJson();
    } else {
      final players = data['players'] is Map
          ? Map<String, dynamic>.from(data['players'] as Map)
          : <String, dynamic>{};
      players[playerName] = settings.toJson();
      data['players'] = players;
    }
    await _saveRaw(data);
  }

  /// Saves [settings] for every one of [playerNames] and as the template.
  Future<void> saveForAll(
    PracticeSettings settings,
    Iterable<String> playerNames,
  ) async {
    final data = await _loadRaw();
    final players = data['players'] is Map
        ? Map<String, dynamic>.from(data['players'] as Map)
        : <String, dynamic>{};
    for (final name in playerNames) {
      players[name] = settings.toJson();
    }
    data['players'] = players;
    data['template'] = settings.toJson();
    await _saveRaw(data);
  }

  /// Whether the first-run setup was completed (or skipped for an existing
  /// installation).
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
