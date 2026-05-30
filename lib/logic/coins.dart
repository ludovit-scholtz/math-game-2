/// Pure rules for turning a finished game's score into earned coins. Kept free
/// of any Flutter dependency so it can be unit tested in isolation.
class Coins {
  Coins._();

  /// The most coins a single game can reward (awarded when the player reaches
  /// the top score for that game category).
  static const int maxPerGame = 20;

  /// Coins earned for finishing a game with [score] when the best score so far
  /// for that game category is [topScore].
  ///
  /// * `score <= 0`        -> 0 coins
  /// * `score >= topScore` -> [maxPerGame] coins (the player reached the top)
  /// * in between          -> linearly distributed from 0 up to [maxPerGame]
  static int forScore(int score, int topScore) {
    if (score <= 0) return 0;
    // The first positive score in a category is itself the top score, so it
    // earns the full reward.
    if (topScore <= 0 || score >= topScore) return maxPerGame;
    return (maxPerGame * score / topScore).round().clamp(0, maxPerGame);
  }
}
