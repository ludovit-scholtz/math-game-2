import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/models/player_profile.dart';
import 'package:math_game_2/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('selectOrCreate stores the player and marks it current', () async {
    final service = PlayerService();
    await service.selectOrCreate(
      PlayerProfile(name: 'Ann', languageCode: 'sk'),
    );

    final players = await service.loadPlayers();
    expect(players.map((p) => p.name), ['Ann']);

    final current = await service.loadCurrent();
    expect(current?.name, 'Ann');
    expect(current?.languageCode, 'sk');
  });

  test('selecting an existing name does not duplicate it', () async {
    final service = PlayerService();
    await service.selectOrCreate(
      PlayerProfile(name: 'Ann', languageCode: 'en'),
    );
    await service.selectOrCreate(
      PlayerProfile(name: 'Bob', languageCode: 'de'),
    );
    await service.selectOrCreate(
      PlayerProfile(name: 'Ann', languageCode: 'en'),
    );

    final players = await service.loadPlayers();
    expect(players.map((p) => p.name), ['Ann', 'Bob']);
    // The reselected player moves to the front.
    expect(players.first.name, 'Ann');
  });

  test('setLanguage updates a stored player', () async {
    final service = PlayerService();
    await service.selectOrCreate(
      PlayerProfile(name: 'Ann', languageCode: 'en'),
    );

    final updated = await service.setLanguage('Ann', 'cs');
    expect(updated?.languageCode, 'cs');

    final players = await service.loadPlayers();
    expect(players.single.languageCode, 'cs');
  });
}
