import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/models/pet.dart';
import 'package:math_game_2/models/player_profile.dart';
import 'package:math_game_2/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final selectedAt = DateTime(2026, 6, 1, 8);
  final later = selectedAt.add(const Duration(days: 1, hours: 12));

  PlayerProfile neglected() => PlayerProfile(
        name: 'Ann',
        languageCode: 'en',
        petType: PetType.cat,
        petFeedingPoints: 100,
        petEnjoymentPoints: 100,
        petFeedingUpdatedAt: selectedAt,
        petEnjoymentUpdatedAt: selectedAt,
      );

  test('withPetType keeps care exactly as it is', () {
    final before = neglected();
    final after = before.withPetType(PetType.panda);

    expect(after.petType, PetType.panda);
    expect(after.petFeedingPoints, before.petFeedingPoints);
    expect(after.petEnjoymentPoints, before.petEnjoymentPoints);
    expect(after.petFeedingUpdatedAt, before.petFeedingUpdatedAt);
    expect(after.petEnjoymentUpdatedAt, before.petEnjoymentUpdatedAt);
    expect(after.petCare(now: later).feedingPoints,
        before.petCare(now: later).feedingPoints);
    expect(after.petCare(now: later).mood, PetMood.hungry);
  });

  test('switching again and again cannot freeze the decay', () {
    var profile = neglected();
    for (var i = 0; i < 20; i++) {
      profile = profile.withPetType(
        i.isEven ? PetType.dog : PetType.rabbit,
      );
    }
    expect(profile.petCare(now: later).feedingPoints, 0);
    expect(profile.petCare(now: later).mood, PetMood.hungry);
  });

  test('setPet on a player with a pet only changes its kind', () async {
    final service = PlayerService();
    await service.selectOrCreate(neglected());

    final updated = await service.setPet('Ann', PetType.rabbit);
    expect(updated?.petType, PetType.rabbit);
    expect(updated?.petFeedingUpdatedAt, selectedAt);
    expect(updated?.petCare(now: later).mood, PetMood.hungry);

    final stored = (await service.loadPlayers()).single;
    expect(stored.petType, PetType.rabbit);
    expect(stored.petCare(now: later).mood, PetMood.hungry);
  });

  test('a player without a pet still gets a happy new one', () async {
    final service = PlayerService();
    await service.selectOrCreate(PlayerProfile(name: 'Bo', languageCode: 'en'));
    final updated = await service.setPet('Bo', PetType.dog);
    expect(updated?.petCare().feedingPoints, 100);
    expect(updated?.petCare().mood, PetMood.happy);
  });

  test('re-adding an existing name keeps the pet and its care', () async {
    final service = PlayerService();
    await service.selectOrCreate(neglected());

    // A child "creates" the same player again with a brand new happy pet.
    final selected = await service.selectOrCreate(
      PlayerProfile(name: 'ann', languageCode: 'sk').withPet(PetType.panda),
    );

    expect(selected.name, 'Ann', reason: 'coins are stored under this name');
    expect(selected.petType, PetType.cat);
    expect(selected.petFeedingUpdatedAt, selectedAt);
    expect(selected.petCare(now: later).mood, PetMood.hungry);
    expect(selected.languageCode, 'sk');

    final players = await service.loadPlayers();
    expect(players, hasLength(1));
    expect(players.single.petType, PetType.cat);
    expect((await service.loadCurrent())?.name, 'Ann');
  });

  test('re-adding a name that has no pet yet adopts the new pet', () async {
    final service = PlayerService();
    await service.selectOrCreate(PlayerProfile(name: 'Bo', languageCode: 'en'));
    final selected = await service.selectOrCreate(
      PlayerProfile(name: 'bo', languageCode: 'en').withPet(PetType.dog),
    );
    expect(selected.name, 'Bo');
    expect(selected.petType, PetType.dog);
  });
}
