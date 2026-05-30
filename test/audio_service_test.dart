import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('audio settings default to unmuted with full volume', () async {
    final settings = await AudioService.loadSettings();

    expect(settings.muted, isFalse);
    expect(settings.volume, 1.0);
  });

  test('audio settings are persisted and clamped', () async {
    await AudioService.saveSettings(muted: true, volume: 1.5);
    final settings = await AudioService.loadSettings();

    expect(settings.muted, isTrue);
    expect(settings.volume, 1.0);
  });
}
