import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/logic/scoring.dart';

void main() {
  group('Scoring.pointsForCorrect', () {
    test('awards 3 points for answers under one second', () {
      expect(Scoring.pointsForCorrect(0.0), 3.0);
      expect(Scoring.pointsForCorrect(0.5), 3.0);
      expect(Scoring.pointsForCorrect(0.999), 3.0);
    });

    test('awards 3 points exactly at one second', () {
      expect(Scoring.pointsForCorrect(1.0), closeTo(3.0, 1e-9));
    });

    test('awards 1 point exactly at ten seconds', () {
      expect(Scoring.pointsForCorrect(10.0), closeTo(1.0, 1e-9));
    });

    test('interpolates linearly between one and ten seconds', () {
      // Midpoint of 1..10 is 5.5 -> midpoint of 3..1 is 2.
      expect(Scoring.pointsForCorrect(5.5), closeTo(2.0, 1e-9));
      // Sooner answers earn strictly more than later ones.
      expect(
        Scoring.pointsForCorrect(3.0),
        greaterThan(Scoring.pointsForCorrect(7.0)),
      );
    });

    test('penalises answers slower than ten seconds', () {
      expect(Scoring.pointsForCorrect(10.001), -1.0);
      expect(Scoring.pointsForCorrect(30.0), -1.0);
    });
  });
}
