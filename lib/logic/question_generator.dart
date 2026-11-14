import 'dart:math';

import '../models/operation_type.dart';
import '../models/practice_settings.dart';
import '../models/question.dart';

/// Generates math questions for the chosen [PracticeSettings]: a number range
/// (up to 5, 10, 20, 100 or 1000), an optional rule about crossing a ten, the
/// enabled multiplication tables and a set of focused drills (doubles, making
/// ten, missing numbers, …). Division always divides evenly.
///
/// With the default settings the classic rules apply: operands and answers in
/// `0..100`, multiplication factors `2..10`, division with divisor and
/// quotient in `2..10`/`1..10`.
///
/// Each question comes with six answer cards: the correct answer plus five
/// distractors modelled on the mistakes children commonly make.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  /// Number of answer cards shown for every question.
  static const int optionCount = 6;

  /// The largest value any operand or answer may take in the classic mode.
  static const int maxValue = 100;

  /// The largest quotient of a division question.
  static const int maxDivisionValue = 10;

  /// How often a random pair is drawn before the crossing rule is relaxed.
  static const int _maxAttempts = 200;

  /// Generates one question from the allowed [operations] and [drills]; one of
  /// them is picked at random. At least one of the two must be non-empty.
  Question generate(
    Set<OperationType> operations, {
    Set<Drill> drills = const <Drill>{},
    PracticeSettings? settings,
  }) {
    assert(
      operations.isNotEmpty || drills.isNotEmpty,
      'At least one operation or drill must be selected',
    );
    final config = settings ?? PracticeSettings.defaults();
    final pools = <Object>[...operations, ...drills];
    final pick = pools[_rng.nextInt(pools.length)];
    if (pick is Drill) return _drill(pick, config);
    return _standard(pick as OperationType, config);
  }

  /// Whether `a ∘ b` carries (addition) or borrows (subtraction) in one of the
  /// lowest [columns] digit columns, e.g. `15 + 16` or `32 − 13`.
  static bool crosses(OperationType type, int a, int b, {int columns = 1}) {
    var x = a;
    var y = b;
    var carry = 0;
    for (var i = 0; i < columns; i++) {
      final da = x % 10;
      final db = y % 10;
      if (type == OperationType.addition) {
        carry = da + db + carry >= 10 ? 1 : 0;
      } else if (type == OperationType.subtraction) {
        carry = da - db - carry < 0 ? 1 : 0;
      } else {
        return false;
      }
      if (carry == 1) return true;
      x ~/= 10;
      y ~/= 10;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Standard operations
  // ---------------------------------------------------------------------------

  Question _standard(OperationType type, PracticeSettings s) {
    switch (type) {
      case OperationType.addition:
      case OperationType.subtraction:
        final pair = _addSubPair(type, s);
        return _build(type, pair.$1, pair.$2, s.range.max);
      case OperationType.multiplication:
        final table = _pickTable(s);
        final other = _rng.nextInt(9) + 2; // 2..10, product stays <= 100
        final swap = _rng.nextBool();
        return _build(
          type,
          swap ? other : table,
          swap ? table : other,
          maxValue,
        );
      case OperationType.division:
        final divisor = _pickTable(s);
        final quotient = _rng.nextInt(maxDivisionValue) + 1; // 1..10
        return _build(type, divisor * quotient, divisor, maxValue);
    }
  }

  int _pickTable(PracticeSettings s) {
    final tables = s.tables.toList()..sort();
    return tables[_rng.nextInt(tables.length)];
  }

  /// Draws operands for `+` or `−` within the range, honouring the crossing
  /// rule. Falls back to any valid pair when the rule cannot be met (e.g.
  /// "always cross a ten" within 5).
  (int, int) _addSubPair(OperationType type, PracticeSettings s) {
    final max = s.range.max;
    final columns = s.range == NumberRange.within1000 ? 2 : 1;
    var a = 0;
    var b = 0;
    for (var i = 0; i < _maxAttempts; i++) {
      a = _rng.nextInt(max + 1);
      b = type == OperationType.addition
          ? _rng.nextInt(max - a + 1) // keeps a + b <= max
          : _rng.nextInt(a + 1); // 0..a, so the result is never negative
      if (s.crossing == CrossingMode.mixed) break;
      final crossing = crosses(type, a, b, columns: columns);
      if (crossing == (s.crossing == CrossingMode.only)) break;
    }
    return (a, b);
  }

  // ---------------------------------------------------------------------------
  // Drills
  // ---------------------------------------------------------------------------

  Question _drill(Drill drill, PracticeSettings s) {
    final max = s.range.max;
    switch (drill) {
      case Drill.plusMinusOne:
        final delta = 1 + _rng.nextInt(2); // 1 or 2
        if (_rng.nextBool()) {
          final a = _rng.nextInt(max - delta + 1);
          return _build(OperationType.addition, a, delta, max);
        }
        final a = delta + _rng.nextInt(max - delta + 1);
        return _build(OperationType.subtraction, a, delta, max);
      case Drill.doubles:
        final cap = min(max ~/ 2, 50);
        final x = 1 + _rng.nextInt(cap);
        if (_rng.nextBool()) {
          return _build(OperationType.division, 2 * x, 2, max); // halves
        }
        return _build(OperationType.addition, x, x, max);
      case Drill.nearDoubles:
        final cap = min((max - 1) ~/ 2, 50);
        final x = 1 + _rng.nextInt(cap);
        return _rng.nextBool()
            ? _build(OperationType.addition, x, x + 1, max)
            : _build(OperationType.addition, x + 1, x, max);
      case Drill.pairsToTen:
        final target = min(10, max);
        final a = 1 + _rng.nextInt(target - 1);
        return _build(
          OperationType.addition,
          a,
          target - a,
          max,
          unknown: UnknownPart.operandB,
        );
      case Drill.pairsToHundred:
        // Below 100 there is no hundred to reach: practise pairs to ten.
        final target = max >= 100 ? 100 : min(10, max);
        final a = 1 + _rng.nextInt(target - 1);
        return _build(
          OperationType.addition,
          a,
          target - a,
          max,
          unknown: UnknownPart.operandB,
        );
      case Drill.bridgeTen:
        if (_rng.nextBool()) {
          final a = 2 + _rng.nextInt(8); // 2..9
          final low = _larger(2, 11 - a); // a + b must reach 11 or more
          final b = low + _rng.nextInt(9 - low + 1);
          return _build(OperationType.addition, a, b, max);
        }
        final a = 11 + _rng.nextInt(8); // 11..18
        final low = a % 10 + 1; // b must exceed the ones digit
        final b = low + _rng.nextInt(9 - low + 1);
        return _build(OperationType.subtraction, a, b, max);
      case Drill.missingNumber:
        final type = _rng.nextBool()
            ? OperationType.addition
            : OperationType.subtraction;
        final pair = _addSubPair(type, s);
        final hidden =
            _rng.nextBool() ? UnknownPart.operandA : UnknownPart.operandB;
        return _build(type, pair.$1, pair.$2, max, unknown: hidden);
    }
  }

  static int _larger(int a, int b) => a > b ? a : b;

  // ---------------------------------------------------------------------------
  // Building the question and its answer cards
  // ---------------------------------------------------------------------------

  Question _build(
    OperationType type,
    int a,
    int b,
    int rangeMax, {
    UnknownPart unknown = UnknownPart.result,
  }) {
    final probe = Question(
      operandA: a,
      operandB: b,
      type: type,
      correctAnswer: 0,
      options: const [],
      unknown: unknown,
    );
    final answer = switch (unknown) {
      UnknownPart.result => probe.result,
      UnknownPart.operandA => a,
      UnknownPart.operandB => b,
    };
    final cap = _larger(10, 2 * [rangeMax, a, b, answer].reduce(_larger));
    final options = _buildOptions(
      type,
      a,
      b,
      answer,
      unknown,
      cap,
      large: rangeMax >= 1000,
    );
    return Question(
      operandA: a,
      operandB: b,
      type: type,
      correctAnswer: answer,
      options: options,
      unknown: unknown,
    );
  }

  /// Builds the shuffled list of [optionCount] answer cards.
  List<int> _buildOptions(
    OperationType type,
    int a,
    int b,
    int answer,
    UnknownPart unknown,
    int cap, {
    required bool large,
  }) {
    final options = <int>{answer};
    final candidates = (unknown == UnknownPart.result
        ? _mistakeCandidates(type, a, b, answer, large)
        : _missingCandidates(a, b, answer, large))
      ..shuffle(_rng);

    for (final candidate in candidates) {
      if (options.length >= optionCount) break;
      if (candidate >= 0 && candidate <= cap) {
        options.add(candidate);
      }
    }

    // Guarantee a full set of distinct cards even if the mistake model did not
    // produce enough unique values (e.g. for very small answers).
    var delta = 1;
    while (options.length < optionCount) {
      if (answer + delta <= cap) options.add(answer + delta);
      if (options.length < optionCount && answer - delta >= 0) {
        options.add(answer - delta);
      }
      delta++;
    }

    final result = options.toList()..shuffle(_rng);
    return result;
  }

  /// Plausible wrong answers for a hidden operand.
  List<int> _missingCandidates(int a, int b, int answer, bool large) {
    return [
      answer + 1,
      answer - 1,
      answer + 2,
      answer - 2,
      answer + 10,
      answer - 10,
      if (large) answer + 100,
      if (large) answer - 100,
      a,
      b,
      a + b, // used the result where an operand belongs
    ];
  }

  /// Plausible wrong answers based on common student mistakes per operation.
  List<int> _mistakeCandidates(
    OperationType type,
    int a,
    int b,
    int answer,
    bool large,
  ) {
    switch (type) {
      case OperationType.addition:
        return [
          answer + 1, // miscount by one
          answer - 1,
          answer + 10, // place-value / carrying slip
          answer - 10,
          if (large) answer + 100,
          if (large) answer - 100,
          (a - b).abs(), // subtracted instead of added
        ];
      case OperationType.subtraction:
        return [
          answer + 1,
          answer - 1,
          answer + 10, // borrowing slip
          answer - 10,
          if (large) answer + 100,
          if (large) answer - 100,
          _digitwiseDifference(a, b), // took the smaller digit from the larger
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

  /// `32 − 13` done the common wrong way: `|3−1|` tens and `|2−3|` ones = 21.
  static int _digitwiseDifference(int a, int b) {
    var x = a;
    var y = b;
    var place = 1;
    var total = 0;
    while (x > 0 || y > 0) {
      total += ((x % 10) - (y % 10)).abs() * place;
      x ~/= 10;
      y ~/= 10;
      place *= 10;
    }
    return total;
  }
}
