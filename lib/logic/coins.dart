import '../models/game_config.dart';

/// Pure rules for turning a finished game's score into earned coins. Kept free
/// of any Flutter dependency so it can be unit tested in isolation.
class Coins {
  Coins._();

  /// The most coins a one-minute game can reward.
  static const int maxPerGame = 20;

  static int maxForDuration(ChallengeDuration duration) {
    switch (duration) {
      case ChallengeDuration.oneMinute:
        return 20;
      case ChallengeDuration.twoMinutes:
        return 50;
      case ChallengeDuration.fiveMinutes:
        return 150;
    }
  }

  /// Coins earned for finishing a game with [score] when the best score so far
  /// for that game category is [topScore].
  ///
  /// * `score <= 0`        -> 0 coins
  /// * `score >= topScore` -> full coins (the player reached the top)
  /// * in between          -> linearly distributed from 0 up to full coins
  static int forScore(
    int score,
    int topScore, {
    ChallengeDuration duration = ChallengeDuration.oneMinute,
  }) {
    final maxCoins = maxForDuration(duration);
    if (score <= 0) return 0;
    // The first positive score in a category is itself the top score, so it
    // earns the full reward.
    if (topScore <= 0 || score >= topScore) return maxCoins;
    return (maxCoins * score / topScore).round().clamp(0, maxCoins);
  }
}
