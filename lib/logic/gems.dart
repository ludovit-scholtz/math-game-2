/// Pure rules for gems: a gem is earned for every [streakLength] correct
/// answers in a row and can be sold in the shop for [coinValue] coins.
class Gems {
  Gems._();

  /// Correct answers in a row needed to earn one gem.
  static const int streakLength = 5;

  /// Coins a player receives for selling one gem.
  static const int coinValue = 10;

  static int coinsFor(int gems) => gems <= 0 ? 0 : gems * coinValue;
}
