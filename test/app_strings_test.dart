import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/models/pet.dart';

void main() {
  test('pet notification copy is localized for every supported language', () {
    const playerName = 'Mia';
    final english = AppStrings(const Locale('en'));
    final englishHungry = english.petNotificationBody(
      PetMood.hungry,
      playerName,
    );

    for (final locale in AppStrings.supportedLocales) {
      final strings = AppStrings(locale);
      final hungry = strings.petNotificationBody(PetMood.hungry, playerName);
      final sad = strings.petNotificationBody(PetMood.sad, playerName);

      expect(hungry, contains(playerName));
      expect(sad, contains(playerName));
      expect(hungry, isNot(equals(sad)));
      if (locale.languageCode != 'en') {
        expect(hungry, isNot(equals(englishHungry)));
      }
    }
  });
}
