import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/logic/question_generator.dart';
import 'package:math_game_2/models/operation_type.dart';

void main() {
  group('QuestionGenerator', () {
    final generator = QuestionGenerator(random: Random(42));

    test('produces exactly six distinct answer cards including the answer',
        () {
      for (var i = 0; i < 500; i++) {
        final q = generator.generate(OperationType.values.toSet());
        expect(q.options.length, QuestionGenerator.optionCount);
        expect(q.options.toSet().length, QuestionGenerator.optionCount,
            reason: 'cards must be distinct');
        expect(q.options, contains(q.correctAnswer));
      }
    });

    test('keeps operands and answers within 0..100', () {
      for (var i = 0; i < 500; i++) {
        final q = generator.generate(OperationType.values.toSet());
        expect(q.operandA, inInclusiveRange(0, 100));
        expect(q.operandB, inInclusiveRange(0, 100));
        expect(q.correctAnswer, inInclusiveRange(0, 100));
      }
    });

    test('never produces negative options', () {
      for (var i = 0; i < 500; i++) {
        final q = generator.generate(OperationType.values.toSet());
        expect(q.options.every((o) => o >= 0), isTrue);
      }
    });

    test('division divisor is always between 1 and 10', () {
      for (var i = 0; i < 500; i++) {
        final q = generator.generate({OperationType.division});
        expect(q.operandB,
            inInclusiveRange(1, QuestionGenerator.maxDivisionValue));
      }
    });

    test('division result is always between 1 and 10', () {
      for (var i = 0; i < 500; i++) {
        final q = generator.generate({OperationType.division});
        expect(q.operandA % q.operandB, 0);
        expect(q.operandA ~/ q.operandB, q.correctAnswer);
        expect(q.correctAnswer,
            inInclusiveRange(1, QuestionGenerator.maxDivisionValue));
      }
    });

    test('each operation computes the correct answer', () {
      for (var i = 0; i < 200; i++) {
        final add = generator.generate({OperationType.addition});
        expect(add.correctAnswer, add.operandA + add.operandB);

        final sub = generator.generate({OperationType.subtraction});
        expect(sub.correctAnswer, sub.operandA - sub.operandB);
        expect(sub.correctAnswer, greaterThanOrEqualTo(0));

        final mul = generator.generate({OperationType.multiplication});
        expect(mul.correctAnswer, mul.operandA * mul.operandB);
      }
    });

    test('only generates the requested operation types', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate({OperationType.addition});
        expect(q.type, OperationType.addition);
      }
    });
  });
}
