/// The four basic arithmetic operations supported by the game.
enum OperationType { addition, subtraction, multiplication, division }

extension OperationTypeInfo on OperationType {
  /// The symbol shown to the player (e.g. `+`, `−`, `×`, `÷`).
  String get symbol {
    switch (this) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '−';
      case OperationType.multiplication:
        return '×';
      case OperationType.division:
        return '÷';
    }
  }

  /// A short human readable label used on the selection screen.
  String get label {
    switch (this) {
      case OperationType.addition:
        return 'Add';
      case OperationType.subtraction:
        return 'Subtract';
      case OperationType.multiplication:
        return 'Multiply';
      case OperationType.division:
        return 'Divide';
    }
  }

  /// A stable string used when persisting the operation to storage.
  String get storageKey {
    switch (this) {
      case OperationType.addition:
        return 'addition';
      case OperationType.subtraction:
        return 'subtraction';
      case OperationType.multiplication:
        return 'multiplication';
      case OperationType.division:
        return 'division';
    }
  }
}
