import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/logic/game_controller.dart';
import 'package:math_game_2/logic/question_generator.dart';
import 'package:math_game_2/models/operation_type.dart';

void main() {
  group('GameController', () {
    test('a fast correct answer adds three points', () {
      final controller = GameController(
        operations: {OperationType.addition},
        generator: QuestionGenerator(random: Random(1)),
      );
      final q = controller.nextQuestion();
      final result = controller.submitAnswer(q, q.correctAnswer, 0.5);
      expect(result.correct, isTrue);
      expect(result.pointsAwarded, 3.0);
      expect(controller.score, 3.0);
      expect(controller.correctCount, 1);
    });

    test('a wrong answer subtracts a point', () {
      final controller = GameController(
        operations: {OperationType.addition},
        generator: QuestionGenerator(random: Random(2)),
      );
      final q = controller.nextQuestion();
      final wrong = q.options.firstWhere((o) => o != q.correctAnswer);
      final result = controller.submitAnswer(q, wrong, 2.0);
      expect(result.correct, isFalse);
      expect(result.pointsAwarded, -1.0);
      expect(controller.score, -1.0);
      expect(controller.correctCount, 0);
      expect(controller.answeredCount, 1);
    });

    test('a missed question is re-asked after the configured cooldown', () {
      final controller = GameController(
        operations: {OperationType.addition},
        generator: QuestionGenerator(random: Random(3)),
        reaskAfter: 3,
      );
      final missed = controller.nextQuestion();
      final wrong = missed.options.firstWhere((o) => o != missed.correctAnswer);
      controller.submitAnswer(missed, wrong, 2.0);

      // The next two questions are fresh, the third brings the missed one back.
      controller.nextQuestion();
      controller.nextQuestion();
      final returned = controller.nextQuestion();
      expect(returned, equals(missed));
    });
  });
}
