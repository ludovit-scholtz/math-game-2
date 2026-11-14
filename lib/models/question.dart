import 'operation_type.dart';

/// Which part of `a ∘ b = result` the player has to find.
enum UnknownPart { result, operandA, operandB }

/// A single math question together with the multiple-choice answer cards.
class Question {
  Question({
    required this.operandA,
    required this.operandB,
    required this.type,
    required this.correctAnswer,
    required this.options,
    this.unknown = UnknownPart.result,
  });

  /// The real operands, even when one of them is hidden from the player.
  final int operandA;
  final int operandB;
  final OperationType type;

  /// The value the player has to find (the result, or the hidden operand).
  final int correctAnswer;
  final UnknownPart unknown;

  /// The shuffled answer cards. Always contains [correctAnswer].
  final List<int> options;

  /// The full result of `operandA ∘ operandB`.
  int get result {
    switch (type) {
      case OperationType.addition:
        return operandA + operandB;
      case OperationType.subtraction:
        return operandA - operandB;
      case OperationType.multiplication:
        return operandA * operandB;
      case OperationType.division:
        return operandB == 0 ? 0 : operandA ~/ operandB;
    }
  }

  /// The text shown to the player, e.g. `7 × 8` or `7 + ? = 10`.
  String get prompt {
    switch (unknown) {
      case UnknownPart.result:
        return '$operandA ${type.symbol} $operandB';
      case UnknownPart.operandA:
        return '? ${type.symbol} $operandB = $result';
      case UnknownPart.operandB:
        return '$operandA ${type.symbol} ? = $result';
    }
  }

  /// Two questions are considered equal when they ask the same thing,
  /// regardless of how the answer cards happen to be shuffled. This is what
  /// lets the spaced-repetition logic recognise a previously missed question.
  @override
  bool operator ==(Object other) =>
      other is Question &&
      other.operandA == operandA &&
      other.operandB == operandB &&
      other.type == type &&
      other.unknown == unknown;

  @override
  int get hashCode => Object.hash(operandA, operandB, type, unknown);
}
