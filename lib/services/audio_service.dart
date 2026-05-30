import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettings {
  const AudioSettings({required this.muted, required this.volume});

  final bool muted;
  final double volume;
}

/// Plays short sound effects for correct / incorrect answers and game over.
///
/// All playback failures are swallowed so that a device without working audio
/// never interrupts the game.
class AudioService {
  AudioService() {
    _player.setReleaseMode(ReleaseMode.stop);
    _applyVolume();
    loadSettings().then((_) => _applyVolume());
  }

  static const String _mutedKey = 'audio_muted_v1';
  static const String _volumeKey = 'audio_volume_v1';

  final AudioPlayer _player = AudioPlayer();
  static bool _muted = false;
  static double _volume = 1.0;

  static AudioSettings get currentSettings =>
      AudioSettings(muted: _muted, volume: _volume);

  static Future<AudioSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_mutedKey) ?? false;
    _volume = _clampVolume(prefs.getDouble(_volumeKey) ?? 1.0);
    return currentSettings;
  }

  static Future<AudioSettings> saveSettings({
    required bool muted,
    required double volume,
  }) async {
    _muted = muted;
    _volume = _clampVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _muted);
    await prefs.setDouble(_volumeKey, _volume);
    return currentSettings;
  }

  static double _clampVolume(double value) => value.clamp(0.0, 1.0).toDouble();

  Future<void> _applyVolume([double multiplier = 1.0]) async {
    try {
      await _player.setVolume(
        _muted ? 0.0 : _clampVolume(_volume * multiplier),
      );
    } catch (e) {
      debugPrint('AudioService: could not set volume ($e)');
    }
  }

  Future<void> _play(String asset, {double volumeMultiplier = 1.0}) async {
    if (_muted || _volume <= 0) return;
    try {
      await _applyVolume(volumeMultiplier);
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('AudioService: could not play $asset ($e)');
    }
  }

  Future<void> playCorrect() => _play('sounds/correct.wav');

  Future<void> playIncorrect() => _play('sounds/incorrect.wav');

  Future<void> playGameOver() => _play('sounds/gameover.wav');

  Future<void> playFireworks() => _play(
        'sounds/fireworks.wav',
        volumeMultiplier: 0.8,
      );

  Future<void> dispose() async {
    await _player.dispose();
  }
}
