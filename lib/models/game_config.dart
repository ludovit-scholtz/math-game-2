import 'operation_type.dart';
import 'practice_settings.dart';

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

/// Everything the player chooses on the home screen before a game starts, plus
/// the parental [settings] (number range, crossing ten, tables) in effect.
class GameConfig {
  GameConfig({
    required this.playerName,
    required this.duration,
    required this.operations,
    this.drills = const <Drill>{},
    PracticeSettings? settings,
  }) : settings = settings ?? PracticeSettings.defaults();

  final String playerName;
  final ChallengeDuration duration;
  final Set<OperationType> operations;

  /// Focused exercises (doubles, bridging through ten, …) chosen to practise.
  final Set<Drill> drills;
  final PracticeSettings settings;

  /// Identifies the difficulty of this game; empty for the classic mode.
  String get modeKey => PracticeSettings.modeKeyFor(
        operations: operations,
        drills: drills,
        settings: settings,
      );
}
