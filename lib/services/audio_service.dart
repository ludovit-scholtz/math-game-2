import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays short sound effects for correct / incorrect answers and game over.
///
/// All playback failures are swallowed so that a device without working audio
/// never interrupts the game.
class AudioService {
  AudioService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();
  bool muted = false;

  Future<void> _play(String asset) async {
    if (muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('AudioService: could not play $asset ($e)');
    }
  }

  Future<void> playCorrect() => _play('sounds/correct.wav');

  Future<void> playIncorrect() => _play('sounds/incorrect.wav');

  Future<void> playGameOver() => _play('sounds/gameover.wav');

  Future<void> dispose() async {
    await _player.dispose();
  }
}
