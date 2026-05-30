import 'operation_type.dart';

/// A single math question together with the multiple-choice answer cards.
class Question {
  Question({
    required this.operandA,
    required this.operandB,
    required this.type,
    required this.correctAnswer,
    required this.options,
  });

  final int operandA;
  final int operandB;
  final OperationType type;
  final int correctAnswer;

  /// The shuffled answer cards. Always contains [correctAnswer].
  final List<int> options;

  /// The text shown to the player, e.g. `7 × 8`.
  String get prompt => '$operandA ${type.symbol} $operandB';

  /// Two questions are considered equal when they ask the same thing,
  /// regardless of how the answer cards happen to be shuffled. This is what
  /// lets the spaced-repetition logic recognise a previously missed question.
  @override
  bool operator ==(Object other) =>
      other is Question &&
      other.operandA == operandA &&
      other.operandB == operandB &&
      other.type == type;

  @override
  int get hashCode => Object.hash(operandA, operandB, type);
}
