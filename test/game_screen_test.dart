import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/screens/game_screen.dart';
import 'package:math_game_2/widgets/answer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('game screen shows six answer buttons', (tester) async {
    // Use a realistic portrait phone surface so the answer grid lays out the
    // same way it does on a device.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final config = GameConfig(
      playerName: 'Tester',
      duration: ChallengeDuration.oneMinute,
      operations: {OperationType.addition},
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: GameScreen(config: config),
      ),
    );
    await tester.pump();

    expect(find.byType(AnswerCard), findsNWidgets(6));

    // Replace the screen so its periodic timer is cancelled before the test
    // ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('game screen fits a landscape tablet without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2048, 1536);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final config = GameConfig(
      playerName: 'Tester',
      duration: ChallengeDuration.oneMinute,
      operations: {OperationType.addition},
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: GameScreen(config: config),
      ),
    );
    await tester.pump();

    expect(find.byType(AnswerCard), findsNWidgets(6));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
