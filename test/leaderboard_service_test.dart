import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/models/score_entry.dart';
import 'package:math_game_2/services/leaderboard_service.dart';

ScoreEntry _entry({
  required String name,
  required int score,
  ChallengeDuration duration = ChallengeDuration.oneMinute,
  List<OperationType> operations = const [
    OperationType.addition,
    OperationType.subtraction,
  ],
  int correct = 0,
  int answered = 0,
  int dateMillis = 0,
}) {
  return ScoreEntry(
    name: name,
    score: score,
    duration: duration,
    operations: operations,
    correct: correct,
    answered: answered,
    dateMillis: dateMillis,
  );
}

void main() {
  group('ScoreEntry', () {
    test('faults is answered minus correct', () {
      final entry = _entry(name: 'A', score: 1, correct: 7, answered: 10);
      expect(entry.faults, 3);
    });

    test('operations are sorted and produce a stable game-type key', () {
      final a = _entry(
        name: 'A',
        score: 1,
        operations: const [OperationType.subtraction, OperationType.addition],
      );
      final b = _entry(
        name: 'B',
        score: 2,
        operations: const [OperationType.addition, OperationType.subtraction],
      );
      expect(a.gameTypeKey, b.gameTypeKey);
      expect(a.operationSymbols, '+−');
    });

    test('round-trips through json', () {
      final entry = _entry(
        name: 'A',
        score: 42,
        duration: ChallengeDuration.fiveMinutes,
        operations: const [
          OperationType.multiplication,
          OperationType.division,
        ],
        correct: 8,
        answered: 9,
        dateMillis: 123,
      );
      final restored = ScoreEntry.fromJson(entry.toJson());
      expect(restored.name, entry.name);
      expect(restored.score, entry.score);
      expect(restored.duration, entry.duration);
      expect(restored.operations, entry.operations);
      expect(restored.faults, entry.faults);
      expect(restored.gameTypeKey, entry.gameTypeKey);
    });
  });

  group('LeaderboardService.buildLeaderboards', () {
    test('keeps only each player\'s best score per game type', () {
      final boards = LeaderboardService.buildLeaderboards([
        _entry(name: 'Ann', score: 5, dateMillis: 1),
        _entry(name: 'Ann', score: 9, dateMillis: 2),
        _entry(name: 'Bob', score: 7, dateMillis: 3),
      ]);

      expect(boards, hasLength(1));
      final entries = boards.single.entries;
      // Ann appears once with her best score and ranks above Bob.
      expect(entries.map((e) => e.name), ['Ann', 'Bob']);
      expect(entries.first.score, 9);
    });

    test('separates different game types', () {
      final boards = LeaderboardService.buildLeaderboards([
        _entry(name: 'Ann', score: 5, duration: ChallengeDuration.oneMinute),
        _entry(
          name: 'Ann',
          score: 8,
          duration: ChallengeDuration.twoMinutes,
        ),
        _entry(
          name: 'Ann',
          score: 3,
          operations: const [
            OperationType.addition,
            OperationType.subtraction,
            OperationType.multiplication,
            OperationType.division,
          ],
        ),
      ]);

      expect(boards, hasLength(3));
      // Sorted by duration first.
      expect(boards.first.duration, ChallengeDuration.oneMinute);
    });
  });
}
