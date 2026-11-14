import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/logic/game_controller.dart';
import 'package:math_game_2/logic/gems.dart';
import 'package:math_game_2/logic/question_generator.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/models/practice_settings.dart';
import 'package:math_game_2/screens/game_screen.dart';
import 'package:math_game_2/screens/results_screen.dart';
import 'package:math_game_2/screens/shop_screen.dart';
import 'package:math_game_2/services/coin_service.dart';
import 'package:math_game_2/services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameController _controller() => GameController(
  operations: {OperationType.addition},
  generator: QuestionGenerator(random: Random(9)),
);

AnswerResult _answer(GameController c, {required bool correct, double s = 2}) {
  final q = c.nextQuestion();
  final value = correct
      ? q.correctAnswer
      : q.options.firstWhere((o) => o != q.correctAnswer);
  return c.submitAnswer(q, value, s);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('gem streak', () {
    test('constants', () {
      expect(Gems.streakLength, 5);
      expect(Gems.coinValue, 10);
      expect(Gems.coinsFor(3), 30);
      expect(Gems.coinsFor(0), 0);
      expect(Gems.coinsFor(-2), 0);
    });

    test('five correct answers in a row earn one gem and reset the streak', () {
      final c = _controller();
      for (var i = 1; i <= 4; i++) {
        final r = _answer(c, correct: true);
        expect(r.gemEarned, isFalse);
        expect(c.streak, i);
      }
      final fifth = _answer(c, correct: true);
      expect(fifth.gemEarned, isTrue);
      expect(c.gemsEarned, 1);
      expect(c.streak, 0);
      expect(c.bestStreak, 5);
    });

    test('best streak is the longest run, not capped by the gem streak', () {
      final c = _controller();
      for (var i = 0; i < 12; i++) {
        _answer(c, correct: true);
      }
      expect(c.streak, 2);
      expect(c.bestStreak, 12);
      _answer(c, correct: false);
      for (var i = 0; i < 3; i++) {
        _answer(c, correct: true);
      }
      expect(c.bestStreak, 12);
    });

    test('a wrong answer resets the counter', () {
      final c = _controller();
      for (var i = 0; i < 4; i++) {
        _answer(c, correct: true);
      }
      _answer(c, correct: false);
      expect(c.streak, 0);
      for (var i = 0; i < 4; i++) {
        expect(_answer(c, correct: true).gemEarned, isFalse);
      }
      expect(c.gemsEarned, 0);
      expect(_answer(c, correct: true).gemEarned, isTrue);
      expect(c.gemsEarned, 1);
    });

    test('ten correct in a row earn two gems', () {
      final c = _controller();
      for (var i = 0; i < 10; i++) {
        _answer(c, correct: true);
      }
      expect(c.gemsEarned, 2);
    });

    test('a slow but correct answer keeps the streak alive', () {
      final c = _controller();
      for (var i = 0; i < 5; i++) {
        _answer(c, correct: true, s: 12);
      }
      expect(c.gemsEarned, 1);
    });

    test('a new game starts with no streak', () {
      final c = _controller();
      _answer(c, correct: true);
      expect(_controller().streak, 0);
    });

    test('tracks response time and missed prompts', () {
      final c = _controller();
      _answer(c, correct: true, s: 1);
      _answer(c, correct: false, s: 3);
      expect(c.averageAnswerMillis, 2000);
      expect(c.missedPrompts, hasLength(1));
    });

    test('missed prompts are distinct and capped', () {
      final c = GameController(
        operations: {OperationType.addition},
        generator: QuestionGenerator(random: Random(4)),
        reaskAfter: 1000,
      );
      for (var i = 0; i < 200; i++) {
        _answer(c, correct: false);
      }
      expect(c.missedPrompts.length, lessThanOrEqualTo(20));
      expect(c.missedPrompts.toSet().length, c.missedPrompts.length);
    });
  });

  group('selling gems', () {
    test(
      'gems persist per player and old wallets load with zero gems',
      () async {
        final service = CoinService();
        expect((await service.load('Ann')).gems, 0);
        await service.addGems('Ann', 3);
        expect((await service.load('Ann')).gems, 3);
        expect((await service.load('Bob')).gems, 0);

        expect(CoinWallet.fromJson({'coins': 4}).gems, 0);
      },
    );

    test('selling adds 10 coins per gem', () async {
      final service = CoinService();
      await service.addGems('Ann', 4);
      final wallet = await service.sellGems('Ann', 3);
      expect(wallet?.gems, 1);
      expect(wallet?.coins, 30);
    });

    test('selling more than you own or nothing fails', () async {
      final service = CoinService();
      await service.addGems('Ann', 2);
      expect(await service.sellGems('Ann', 3), isNull);
      expect(await service.sellGems('Ann', 0), isNull);
      final wallet = await service.load('Ann');
      expect(wallet.gems, 2);
      expect(wallet.coins, 0);
    });
  });

  Widget app(Widget home) => MaterialApp(
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    home: home,
  );

  testWidgets('shop sells gems for coins', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await CoinService().addGems('Ann', 3);

    await tester.pumpWidget(app(const ShopScreen(playerName: 'Ann')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gems: 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sell-one-gem')));
    await tester.pumpAndSettle();
    var wallet = await CoinService().load('Ann');
    expect(wallet.gems, 2);
    expect(wallet.coins, 10);

    await tester.tap(find.byKey(const ValueKey('sell-all-gems')));
    await tester.pumpAndSettle();
    wallet = await CoinService().load('Ann');
    expect(wallet.gems, 0);
    expect(wallet.coins, 30);

    // Nothing left to sell: the buttons are disabled.
    final button = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('sell-one-gem')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('game screen shows the gem streak', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        GameScreen(
          config: GameConfig(
            playerName: 'Tester',
            duration: ChallengeDuration.oneMinute,
            operations: {OperationType.addition},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('streak-dot-4')), findsOneWidget);
    expect(find.text('💎 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('results save earned gems, stats and the game mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final config = GameConfig(
      playerName: 'Ann',
      duration: ChallengeDuration.oneMinute,
      operations: {OperationType.addition},
      settings: PracticeSettings(range: NumberRange.within20),
    );
    await tester.pumpWidget(
      app(
        ResultsScreen(
          finishedConfig: config,
          finalScore: 12,
          correctCount: 10,
          answeredCount: 11,
          gemsEarned: 2,
          bestStreak: 7,
          avgAnswerMillis: 1800,
          missed: const ['8 + 5'],
        ),
      ),
    );
    // A new record starts endless fireworks, so settle manually.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Gems earned: 2'), findsOneWidget);
    final wallet = await CoinService().load('Ann');
    expect(wallet.gems, 2);

    final saved = (await LeaderboardService().load()).single;
    expect(saved.gemsEarned, 2);
    expect(saved.bestStreak, 7);
    expect(saved.avgAnswerMillis, 1800);
    expect(saved.missed, ['8 + 5']);
    expect(saved.modeKey, 'within20');
    expect(saved.coinsEarned, wallet.coins);
    expect(saved.coinsEarned, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
  });
}
