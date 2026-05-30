import 'operation_type.dart';

/// The length of a challenge.
enum ChallengeDuration { oneMinute, twoMinutes, fiveMinutes }

extension ChallengeDurationInfo on ChallengeDuration {
  int get seconds {
    switch (this) {
      case ChallengeDuration.oneMinute:
        return 60;
      case ChallengeDuration.twoMinutes:
        return 120;
      case ChallengeDuration.fiveMinutes:
        return 300;
    }
  }

  String get label {
    switch (this) {
      case ChallengeDuration.oneMinute:
        return '1 min';
      case ChallengeDuration.twoMinutes:
        return '2 min';
      case ChallengeDuration.fiveMinutes:
        return '5 min';
    }
  }
}

/// Everything the player chooses on the home screen before a game starts.
class GameConfig {
  GameConfig({
    required this.playerName,
    required this.duration,
    required this.operations,
  });

  final String playerName;
  final ChallengeDuration duration;
  final Set<OperationType> operations;
}
