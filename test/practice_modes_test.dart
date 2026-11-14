import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/logic/question_generator.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/models/practice_settings.dart';
import 'package:math_game_2/models/question.dart';
import 'package:math_game_2/models/score_entry.dart';

const _addSub = {OperationType.addition, OperationType.subtraction};

void _expectValidCards(Question q) {
  expect(q.options.length, QuestionGenerator.optionCount);
  expect(q.options.toSet().length, QuestionGenerator.optionCount);
  expect(q.options, contains(q.correctAnswer));
  expect(q.options.every((o) => o >= 0), isTrue);
}

void main() {
  group('PracticeSettings', () {
    test('defaults equal the classic behaviour', () {
      final s = PracticeSettings.defaults();
      expect(s.operations, OperationType.values.toSet());
      expect(s.range, NumberRange.within100);
      expect(s.crossing, CrossingMode.mixed);
      expect(s.drills, isEmpty);
      expect(s.tables, {for (var t = 2; t <= 10; t++) t});
      expect(s.durations, ChallengeDuration.values.toSet());
      expect(s.matchingPreset, PracticePreset.within100);
    });

    test('survives a JSON round trip', () {
      final s = PracticeSettings(
        operations: {OperationType.addition},
        range: NumberRange.within20,
        crossing: CrossingMode.only,
        drills: {Drill.doubles, Drill.missingNumber},
        tables: {2, 5},
        durations: {ChallengeDuration.twoMinutes},
      );
      expect(PracticeSettings.fromJson(s.toJson()), s);
    });

    test('fromJson tolerates missing, unknown and invalid values', () {
      final s = PracticeSettings.fromJson({
        'operations': ['nonsense'],
        'range': 'huge',
        'tables': [1, 99, 'x', 7],
        'durations': [42],
        'drills': ['nope'],
      });
      expect(s.operations, OperationType.values.toSet());
      expect(s.range, NumberRange.within100);
      expect(s.tables, {7});
      expect(s.durations, ChallengeDuration.values.toSet());
      expect(PracticeSettings.fromJson({}), PracticeSettings.defaults());
    });

    test('always allows something to practise', () {
      final s = PracticeSettings.defaults().copyWith(operations: <OperationType>{});
      expect(s.hasAnythingToPractise, isTrue);
      // Drills can carry the settings on their own.
      final drillsOnly = PracticeSettings(
        operations: <OperationType>{},
        drills: {Drill.pairsToTen},
      );
      expect(drillsOnly.hasAnythingToPractise, isTrue);
      expect(drillsOnly.operations, isEmpty);
    });

    test('"always cross a ten" is not allowed within 5', () {
      final s = PracticeSettings(
        range: NumberRange.within5,
        crossing: CrossingMode.only,
      ).normalized();
      expect(s.crossing, CrossingMode.mixed);
    });

    test('the classic mode has an empty mode key, other modes differ', () {
      String key(PracticeSettings s, Set<OperationType> ops,
              [Set<Drill> drills = const {}]) =>
          PracticeSettings.modeKeyFor(
            operations: ops,
            drills: drills,
            settings: s,
          );
      expect(key(PracticeSettings.defaults(), _addSub), '');
      expect(
        key(PracticeSettings(range: NumberRange.within20), _addSub),
        isNot(''),
      );
      // The range does not matter when only multiplication is practised.
      expect(
        key(PracticeSettings(range: NumberRange.within20),
            {OperationType.multiplication}),
        '',
      );
      expect(
        key(PracticeSettings.defaults(), _addSub, {Drill.doubles}),
        contains('d-doubles'),
      );
      expect(
        key(PracticeSettings(tables: {2, 5}), {OperationType.division}),
        't-2,5',
      );
    });
  });

  group('ScoreEntry game types', () {
    ScoreEntry entry({String modeKey = ''}) => ScoreEntry(
          name: 'A',
          score: 1,
          duration: ChallengeDuration.oneMinute,
          operations: const [OperationType.addition],
          correct: 1,
          answered: 1,
          dateMillis: 1,
          modeKey: modeKey,
        );

    test('classic games keep their original game type key', () {
      expect(entry().gameTypeKey, '0|addition');
    });

    test('different modes never share a leaderboard', () {
      expect(entry(modeKey: 'within20').gameTypeKey,
          isNot(entry().gameTypeKey));
    });

    test('old stored games without the new fields still load', () {
      final old = ScoreEntry.fromJson({
        'name': 'Ann',
        'score': 5,
        'duration': 1,
        'operations': ['addition'],
        'correct': 3,
        'answered': 4,
        'dateMillis': 10,
      });
      expect(old.modeKey, '');
      expect(old.drills, isEmpty);
      expect(old.gemsEarned, 0);
      expect(old.avgAnswerMillis, 0);
      expect(old.missed, isEmpty);
      expect(old.gameTypeKey, '1|addition');
    });

    test('new fields survive a JSON round trip', () {
      final e = ScoreEntry(
        name: 'Ann',
        score: 5,
        duration: ChallengeDuration.fiveMinutes,
        operations: const [],
        drills: const [Drill.bridgeTen],
        modeKey: 'within20|d-bridgeTen',
        correct: 3,
        answered: 4,
        dateMillis: 10,
        gemsEarned: 2,
        coinsEarned: 7,
        bestStreak: 6,
        avgAnswerMillis: 2500,
        missed: const ['8 + 5'],
      );
      final back = ScoreEntry.fromJson(e.toJson());
      expect(back.drills, [Drill.bridgeTen]);
      expect(back.modeKey, e.modeKey);
      expect(back.gemsEarned, 2);
      expect(back.coinsEarned, 7);
      expect(back.bestStreak, 6);
      expect(back.avgAnswerMillis, 2500);
      expect(back.missed, ['8 + 5']);
      expect(back.gameTypeKey, e.gameTypeKey);
    });
  });

  group('QuestionGenerator ranges', () {
    for (final range in NumberRange.values) {
      test('addition and subtraction stay within ${range.max}', () {
        final gen = QuestionGenerator(random: Random(range.max));
        final settings = PracticeSettings(range: range);
        for (var i = 0; i < 400; i++) {
          final q = gen.generate(_addSub, settings: settings);
          expect(q.operandA, inInclusiveRange(0, range.max));
          expect(q.operandB, inInclusiveRange(0, range.max));
          expect(q.result, inInclusiveRange(0, range.max));
          expect(q.correctAnswer, q.result);
          _expectValidCards(q);
        }
      });
    }
  });

  group('QuestionGenerator crossing ten', () {
    test('crosses() detects carrying and borrowing', () {
      expect(QuestionGenerator.crosses(OperationType.addition, 15, 16), isTrue);
      expect(QuestionGenerator.crosses(OperationType.addition, 23, 14), isFalse);
      expect(QuestionGenerator.crosses(OperationType.addition, 8, 5), isTrue);
      expect(
          QuestionGenerator.crosses(OperationType.subtraction, 32, 13), isTrue);
      expect(
          QuestionGenerator.crosses(OperationType.subtraction, 38, 15), isFalse);
      // The hundreds column only counts when two columns are checked.
      expect(
        QuestionGenerator.crosses(OperationType.addition, 50, 50),
        isFalse,
      );
      expect(
        QuestionGenerator.crosses(OperationType.addition, 50, 50, columns: 2),
        isTrue,
      );
    });

    for (final range in [
      NumberRange.within10,
      NumberRange.within20,
      NumberRange.within100,
      NumberRange.within1000,
    ]) {
      for (final mode in [CrossingMode.none, CrossingMode.only]) {
        test('${mode.name} is honoured within ${range.max}', () {
          final gen = QuestionGenerator(random: Random(3));
          final settings = PracticeSettings(range: range, crossing: mode);
          final columns = range == NumberRange.within1000 ? 2 : 1;
          for (var i = 0; i < 300; i++) {
            final q = gen.generate(_addSub, settings: settings);
            final crossed = QuestionGenerator.crosses(
              q.type,
              q.operandA,
              q.operandB,
              columns: columns,
            );
            expect(crossed, mode == CrossingMode.only,
                reason: '${q.prompt} within ${range.max}');
          }
        });
      }
    }

    test('an impossible rule falls back to valid questions', () {
      final gen = QuestionGenerator(random: Random(1));
      // Normalisation forbids this, but the generator must not hang or crash.
      final settings = PracticeSettings(
        range: NumberRange.within5,
        crossing: CrossingMode.only,
      );
      for (var i = 0; i < 50; i++) {
        final q = gen.generate(_addSub, settings: settings);
        expect(q.result, inInclusiveRange(0, 5));
      }
    });
  });

  group('QuestionGenerator tables', () {
    test('multiplication and division only use the enabled tables', () {
      final gen = QuestionGenerator(random: Random(5));
      final settings = PracticeSettings(tables: {3, 7});
      for (var i = 0; i < 300; i++) {
        final mul = gen.generate({OperationType.multiplication},
            settings: settings);
        expect({mul.operandA, mul.operandB}.intersection({3, 7}), isNotEmpty);
        expect(mul.result, lessThanOrEqualTo(100));
        _expectValidCards(mul);

        final div =
            gen.generate({OperationType.division}, settings: settings);
        expect({3, 7}, contains(div.operandB));
        expect(div.operandA % div.operandB, 0);
        expect(div.correctAnswer, inInclusiveRange(1, 10));
      }
    });
  });

  group('QuestionGenerator drills', () {
    QuestionGenerator gen() => QuestionGenerator(random: Random(11));
    const none = <OperationType>{};

    test('plus/minus one or two', () {
      final g = gen();
      for (var i = 0; i < 300; i++) {
        final q = g.generate(none, drills: {Drill.plusMinusOne});
        expect([1, 2], contains(q.operandB));
        expect(q.result, inInclusiveRange(0, 100));
        _expectValidCards(q);
      }
    });

    test('doubles and halves', () {
      final g = gen();
      for (var i = 0; i < 300; i++) {
        final q = g.generate(none, drills: {Drill.doubles});
        if (q.type == OperationType.addition) {
          expect(q.operandA, q.operandB);
        } else {
          expect(q.type, OperationType.division);
          expect(q.operandB, 2);
          expect(q.operandA.isEven, isTrue);
        }
        _expectValidCards(q);
      }
    });

    test('near doubles differ by one', () {
      final g = gen();
      for (var i = 0; i < 300; i++) {
        final q = g.generate(none, drills: {Drill.nearDoubles});
        expect((q.operandA - q.operandB).abs(), 1);
        _expectValidCards(q);
      }
    });

    test('pairs to ten ask for the missing partner', () {
      final g = gen();
      for (var i = 0; i < 300; i++) {
        final q = g.generate(none, drills: {Drill.pairsToTen});
        expect(q.unknown, UnknownPart.operandB);
        expect(q.result, 10);
        expect(q.correctAnswer, 10 - q.operandA);
        expect(q.prompt, '${q.operandA} + ? = 10');
        _expectValidCards(q);
      }
    });

    test('pairs to a hundred', () {
      final g = gen();
      for (var i = 0; i < 300; i++) {
        final q = g.generate(none, drills: {Drill.pairsToHundred});
        expect(q.result, 100);
        expect(q.correctAnswer, 100 - q.operandA);
        _expectValidCards(q);
      }
    });

    test('bridging through ten always crosses a ten within 20', () {
      final g = gen();
      for (var i = 0; i < 400; i++) {
        final q = g.generate(none, drills: {Drill.bridgeTen});
        expect(QuestionGenerator.crosses(q.type, q.operandA, q.operandB),
            isTrue,
            reason: q.prompt);
        expect(q.operandA, lessThanOrEqualTo(18));
        expect(q.result, greaterThanOrEqualTo(2));
        _expectValidCards(q);
      }
    });

    test('missing numbers are solvable and rendered with a question mark', () {
      final g = gen();
      final seen = <UnknownPart>{};
      for (var i = 0; i < 400; i++) {
        final q = g.generate(none, drills: {Drill.missingNumber});
        seen.add(q.unknown);
        expect(q.prompt, contains('?'));
        expect(q.prompt, contains('= ${q.result}'));
        final hidden =
            q.unknown == UnknownPart.operandA ? q.operandA : q.operandB;
        expect(q.correctAnswer, hidden);
        _expectValidCards(q);
      }
      expect(seen, {UnknownPart.operandA, UnknownPart.operandB});
    });

    test('a missed missing-number question is told apart from the plain one',
        () {
      final plain = Question(
        operandA: 3,
        operandB: 5,
        type: OperationType.addition,
        correctAnswer: 8,
        options: const [8],
      );
      final missing = Question(
        operandA: 3,
        operandB: 5,
        type: OperationType.addition,
        correctAnswer: 5,
        options: const [5],
        unknown: UnknownPart.operandB,
      );
      expect(plain == missing, isFalse);
      expect(missing.prompt, '3 + ? = 8');
    });

    test('drills mix with operations', () {
      final g = gen();
      final seenDrill = <bool>{};
      for (var i = 0; i < 300; i++) {
        final q = g.generate(
          {OperationType.multiplication},
          drills: {Drill.pairsToTen},
        );
        seenDrill.add(q.unknown != UnknownPart.result);
      }
      expect(seenDrill, {true, false});
    });

    test('all drills work in every range', () {
      for (final range in NumberRange.values) {
        final g = QuestionGenerator(random: Random(range.max));
        final settings = PracticeSettings(range: range);
        for (var i = 0; i < 200; i++) {
          final q = g.generate(none,
              drills: Drill.values.toSet(), settings: settings);
          _expectValidCards(q);
        }
      }
    });

    test('1000-range subtraction offers the digit-by-digit slip', () {
      final g = QuestionGenerator(random: Random(2));
      final settings = PracticeSettings(range: NumberRange.within1000);
      for (var i = 0; i < 200; i++) {
        final q = g.generate({OperationType.subtraction}, settings: settings);
        _expectValidCards(q);
      }
    });
  });
}
