import 'dart:math';

/// The grown-ups-only question guarding the parental control panel:
/// `(2^exponent + factorA × factorB) mod 1000`.
class ParentalChallenge {
  ParentalChallenge({
    required this.exponent,
    required this.factorA,
    required this.factorB,
  });

  static const int minExponent = 5;
  static const int maxExponent = 20;
  static const int minFactor = 10000;
  static const int maxFactor = 99999;

  factory ParentalChallenge.generate([Random? random]) {
    final rng = random ?? Random.secure();
    return ParentalChallenge(
      exponent: minExponent + rng.nextInt(maxExponent - minExponent + 1),
      factorA: minFactor + rng.nextInt(maxFactor - minFactor + 1),
      factorB: minFactor + rng.nextInt(maxFactor - minFactor + 1),
    );
  }

  final int exponent;
  final int factorA;
  final int factorB;

  /// The expression shown to the grown-up, e.g. `2^17 + 48213 × 90551`.
  String get expression => '2^$exponent + $factorA × $factorB';

  /// The expected answer, `0..999`. Reduced modulo 1000 step by step so the
  /// arithmetic stays exact on every platform (including JavaScript).
  int get answer {
    final power = (1 << exponent) % 1000;
    final product = ((factorA % 1000) * (factorB % 1000)) % 1000;
    return (power + product) % 1000;
  }

  /// Whether [input] (digits only, leading zeros allowed) is the answer.
  bool check(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || !RegExp(r'^\d{1,3}$').hasMatch(trimmed)) {
      return false;
    }
    return int.parse(trimmed) == answer;
  }
}
