import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/logic/coins.dart';

void main() {
  group('Coins.forScore', () {
    test('awards no coins for zero or negative scores', () {
      expect(Coins.forScore(0, 100), 0);
      expect(Coins.forScore(-5, 100), 0);
    });

    test('awards the full 20 coins when reaching the top score', () {
      expect(Coins.forScore(100, 100), Coins.maxPerGame);
      expect(Coins.forScore(150, 100), Coins.maxPerGame);
    });

    test('the first positive score in a category earns the full reward', () {
      expect(Coins.forScore(7, 0), Coins.maxPerGame);
    });

    test('distributes linearly between zero and the top score', () {
      // Half of the top score -> half of the maximum reward.
      expect(Coins.forScore(50, 100), 10);
      // A quarter -> a quarter of the reward.
      expect(Coins.forScore(25, 100), 5);
    });

    test('never exceeds the maximum or drops below zero', () {
      for (var score = -10; score <= 200; score++) {
        final coins = Coins.forScore(score, 100);
        expect(coins, inInclusiveRange(0, Coins.maxPerGame));
      }
    });
  });
}
