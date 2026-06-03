import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/models/pet.dart';
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

  test('app name is localized', () {
    expect(
      AppStrings(const Locale('cs')).appName,
      'Matematika pro děti | Biatec',
    );
    expect(
      AppStrings(const Locale('sk')).appName,
      'Matematika pre deti | Biatec',
    );
    expect(AppStrings(const Locale('de')).appName, 'Mathe für Kinder | Biatec');
  });

  test('setPet gives a player a fresh pet with full care', () async {
    final service = PlayerService();
    await service.selectOrCreate(
      PlayerProfile(name: 'Ann', languageCode: 'en'),
    );

    final updated = await service.setPet('Ann', PetType.panda);
    expect(updated?.petType, PetType.panda);
    expect(updated?.petCare().feedingPoints, 100);
    expect(updated?.petCare().enjoymentPoints, 100);
  });

  test('pet care drops by elapsed days and reacts to care actions', () async {
    final twoDaysAgo = DateTime(2026, 6, 1);
    final now = DateTime(2026, 6, 3);
    final profile = PlayerProfile(
      name: 'Ann',
      languageCode: 'en',
      petType: PetType.cat,
      petFeedingPoints: 100,
      petEnjoymentPoints: 100,
      petCareUpdatedAt: twoDaysAgo,
    );

    final care = profile.petCare(now: now);
    expect(care.feedingPoints, 0);
    expect(care.enjoymentPoints, 60);
    expect(care.mood, PetMood.hungry);

    final fed = profile.withUpdatedPetCare(feedingDelta: 30, now: now);
    expect(fed.petCare(now: now).feedingPoints, 30);
    expect(fed.petCare(now: now).enjoymentPoints, 60);
  });

  test('pet food drops one point every 14.4 minutes', () {
    final selectedAt = DateTime(2026, 6, 3, 8);
    final profile = PlayerProfile(
      name: 'Ann',
      languageCode: 'en',
      petType: PetType.cat,
      petFeedingPoints: 100,
      petEnjoymentPoints: 100,
      petFeedingUpdatedAt: selectedAt,
      petEnjoymentUpdatedAt: selectedAt,
    );

    expect(
      profile
          .petCare(now: selectedAt.add(const Duration(minutes: 14)))
          .feedingPoints,
      100,
    );
    expect(
      profile
          .petCare(
            now: selectedAt.add(const Duration(minutes: 14, seconds: 24)),
          )
          .feedingPoints,
      99,
    );
    expect(
      profile
          .petCare(now: selectedAt.add(const Duration(hours: 12)))
          .feedingPoints,
      50,
    );
    final dayCare = profile.petCare(
      now: selectedAt.add(const Duration(hours: 24)),
    );
    expect(dayCare.feedingPoints, 0);
    expect(dayCare.mood, PetMood.hungry);
  });

  test('feeding and toys keep separate decay timestamps', () {
    final selectedAt = DateTime(2026, 6, 3, 8);
    final halfDayLater = selectedAt.add(const Duration(hours: 12));
    final profile = PlayerProfile(
      name: 'Ann',
      languageCode: 'en',
      petType: PetType.rabbit,
      petFeedingPoints: 100,
      petEnjoymentPoints: 100,
      petFeedingUpdatedAt: selectedAt,
      petEnjoymentUpdatedAt: selectedAt,
    );

    final fed = profile.withUpdatedPetCare(
      feedingDelta: 30,
      now: halfDayLater,
    );

    expect(fed.petCare(now: halfDayLater).feedingPoints, 80);
    expect(fed.petCare(now: halfDayLater).enjoymentPoints, 90);
    expect(fed.petFeedingUpdatedAt, halfDayLater);
    expect(fed.petEnjoymentUpdatedAt, selectedAt);
  });
}
