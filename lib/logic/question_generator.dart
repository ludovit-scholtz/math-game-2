import 'dart:math';

import '../models/operation_type.dart';
import '../models/question.dart';

/// Generates math questions whose operands and answers stay within 0..100 and,
/// for division, always divide evenly with both quotient and divisor in 1..10.
/// Each question comes with six answer cards: the correct answer plus five
/// distractors modelled on the mistakes children commonly make for that
/// operation.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  /// Number of answer cards shown for every question.
  static const int optionCount = 6;

  /// The largest value any operand or answer may take.
  static const int maxValue = 100;

  Question generate(Set<OperationType> allowed) {
    assert(allowed.isNotEmpty, 'At least one operation must be selected');
    final types = allowed.toList();
    final type = types[_rng.nextInt(types.length)];

    late int a;
    late int b;
    late int answer;

    switch (type) {
      case OperationType.addition:
        a = _rng.nextInt(maxValue + 1); // 0..100
        b = _rng.nextInt(maxValue - a + 1); // keeps a + b <= 100
        answer = a + b;
        break;
      case OperationType.subtraction:
        a = _rng.nextInt(maxValue + 1); // 0..100
        b = _rng.nextInt(a + 1); // 0..a, so the result is never negative
        answer = a - b;
        break;
      case OperationType.multiplication:
        a = _rng.nextInt(9) + 2; // 2..10
        final maxB = min(10, maxValue ~/ a);
        b = _rng.nextInt(maxB - 1) + 2; // 2..maxB, product stays <= 100
        answer = a * b;
        break;
      case OperationType.division:
        b = _rng.nextInt(10) + 1; // divisor 1..10
        answer = _rng.nextInt(10) + 1; // quotient 1..10
        a = b * answer; // dividend stays <= 100 and divides evenly
        break;
    }

    final options = _buildOptions(type, a, b, answer);
    return Question(
      operandA: a,
      operandB: b,
      type: type,
      correctAnswer: answer,
      options: options,
    );
  }

  /// Builds the shuffled list of [optionCount] answer cards.
  List<int> _buildOptions(OperationType type, int a, int b, int answer) {
    final options = <int>{answer};
    final candidates = _mistakeCandidates(type, a, b, answer)..shuffle(_rng);

    for (final candidate in candidates) {
      if (options.length >= optionCount) break;
      if (candidate >= 0 && candidate <= 2 * maxValue) {
        options.add(candidate);
      }
    }

    // Guarantee a full set of distinct cards even if the mistake model did not
    // produce enough unique values (e.g. for very small answers).
    var delta = 1;
    while (options.length < optionCount) {
      if (answer + delta <= 2 * maxValue) options.add(answer + delta);
      if (options.length < optionCount && answer - delta >= 0) {
        options.add(answer - delta);
      }
      delta++;
    }

    final result = options.toList()..shuffle(_rng);
    return result;
  }

  /// Plausible wrong answers based on common student mistakes per operation.
  List<int> _mistakeCandidates(OperationType type, int a, int b, int answer) {
    switch (type) {
      case OperationType.addition:
        return [
          answer + 1, // miscount by one
          answer - 1,
          answer + 10, // place-value / carrying slip
          answer - 10,
          (a - b).abs(), // subtracted instead of added
        ];
      case OperationType.subtraction:
        return [
          answer + 1,
          answer - 1,
          answer + 10, // borrowing slip
          answer - 10,
          a + b, // added instead of subtracted
        ];
      case OperationType.multiplication:
        return [
          answer + a, // counted one group too many: a * (b + 1)
          answer - a, // one group too few: a * (b - 1)
          answer + b,
          answer - b,
          a + b, // added instead of multiplied
        ];
      case OperationType.division:
        return [
          answer + 1,
          answer - 1,
          a - b, // subtracted instead of divided
          answer + b,
          b, // confused the divisor with the answer
        ];
    }
  }
}
