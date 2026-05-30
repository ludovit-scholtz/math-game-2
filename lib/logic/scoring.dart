/// Pure scoring rules for the game. Kept free of any Flutter dependency so it
/// can be unit tested in isolation.
class Scoring {
  Scoring._();

  /// Maximum reward for a lightning-fast (under one second) correct answer.
  static const double maxPoints = 3.0;

  /// Reward for a correct answer that takes the full ten seconds.
  static const double minTimedPoints = 1.0;

  /// The point at which a fast answer stops earning the maximum reward.
  static const double fastThresholdSeconds = 1.0;

  /// After this many seconds a correct answer is no longer rewarded.
  static const double slowThresholdSeconds = 10.0;

  /// Penalty applied for a wrong answer or for taking longer than ten seconds.
  static const double wrongPenalty = -1.0;

  /// Points earned for a *correct* answer given how long the player took.
  ///
  /// * `< 1s`        -> 3 points
  /// * `1s .. 10s`   -> linearly interpolated from 3 down to 1 points
  /// * `> 10s`       -> -1 point (too slow)
  static double pointsForCorrect(double seconds) {
    if (seconds < fastThresholdSeconds) {
      return maxPoints;
    }
    if (seconds <= slowThresholdSeconds) {
      final fraction = (seconds - fastThresholdSeconds) /
          (slowThresholdSeconds - fastThresholdSeconds);
      return maxPoints - fraction * (maxPoints - minTimedPoints);
    }
    return wrongPenalty;
  }
}
