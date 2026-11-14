import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/logic/history_stats.dart';
import 'package:math_game_2/main.dart';
import 'package:math_game_2/logic/parental_gate.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/models/player_profile.dart';
import 'package:math_game_2/models/practice_settings.dart';
import 'package:math_game_2/models/score_entry.dart';
import 'package:math_game_2/screens/home_screen.dart';
import 'package:math_game_2/screens/parental_control_screen.dart';
import 'package:math_game_2/screens/parental_gate_dialog.dart';
import 'package:math_game_2/screens/parental_history_screen.dart';
import 'package:math_game_2/services/leaderboard_service.dart';
import 'package:math_game_2/services/parental_settings_service.dart';
import 'package:math_game_2/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppStrings.localizationsDelegates,
  supportedLocales: AppStrings.supportedLocales,
  home: home,
);

ScoreEntry _game(
  String name,
  int millis, {
  int correct = 8,
  int answered = 10,
  List<String> missed = const [],
  int avg = 0,
  int gems = 0,
  int streak = 0,
}) => ScoreEntry(
  name: name,
  score: correct,
  duration: ChallengeDuration.oneMinute,
  operations: const [OperationType.addition],
  correct: correct,
  answered: answered,
  dateMillis: millis,
  missed: missed,
  avgAnswerMillis: avg,
  gemsEarned: gems,
  bestStreak: streak,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_done_v1': true});
  });

  group('ParentalChallenge', () {
    test('matches an exact BigInt computation', () {
      final rng = Random(2024);
      for (var i = 0; i < 1000; i++) {
        final c = ParentalChallenge.generate(rng);
        expect(c.exponent, inInclusiveRange(5, 20));
        expect(c.factorA, inInclusiveRange(10000, 99999));
        expect(c.factorB, inInclusiveRange(10000, 99999));
        final expected =
            (BigInt.two.pow(c.exponent) +
                BigInt.from(c.factorA) * BigInt.from(c.factorB)) %
            BigInt.from(1000);
        expect(c.answer, expected.toInt());
        expect(c.answer, inInclusiveRange(0, 999));
      }
    });

    test('check accepts the answer with or without leading zeros', () {
      final c = ParentalChallenge(exponent: 5, factorA: 10000, factorB: 10000);
      // 32 + 100000000 -> 32 (mod 1000)
      expect(c.answer, 32);
      expect(c.check('32'), isTrue);
      expect(c.check('032'), isTrue);
      expect(c.check(' 32 '), isTrue);
      expect(c.check('33'), isFalse);
      expect(c.check(''), isFalse);
      expect(c.check('abc'), isFalse);
      expect(c.check('1032'), isFalse);
      expect(c.check('-32'), isFalse);
    });

    test('expression shows the problem', () {
      final c = ParentalChallenge(exponent: 7, factorA: 12345, factorB: 54321);
      expect(c.expression, '2^7 + 12345 × 54321');
    });
  });

  group('ParentalSettingsService', () {
    test('defaults, per player settings and the template', () async {
      final service = ParentalSettingsService();
      expect(await service.load('Ann'), PracticeSettings.defaults());

      final within20 = PracticeSettings.preset(PracticePreset.within20);
      await service.save(within20, 'Ann');
      expect(await service.load('Ann'), within20);
      // Editing Ann never changes what a player without settings gets.
      expect(await service.load('Bob'), PracticeSettings.defaults());

      final starting = PracticeSettings.preset(PracticePreset.starting);
      await service.save(starting); // the template (first-run setup)
      expect(await service.load('Bob'), starting);
      expect(await service.load('Ann'), within20);

      await service.save(
        PracticeSettings(range: NumberRange.within1000),
        'Bob',
      );
      expect(await service.load('Ann'), within20);
      expect(await service.load('Cy'), starting);
    });

    test('apply to all', () async {
      final service = ParentalSettingsService();
      final starting = PracticeSettings.preset(PracticePreset.starting);
      await service.saveForAll(starting, ['Ann', 'Bob']);
      expect(await service.load('Ann'), starting);
      expect(await service.load('Bob'), starting);
    });

    test('survives corrupt stored data', () async {
      SharedPreferences.setMockInitialValues({
        'practice_settings_v1': 'not json',
      });
      expect(
        await ParentalSettingsService().load('Ann'),
        PracticeSettings.defaults(),
      );
    });

    test('quick successive saves for different players all survive', () async {
      final service = ParentalSettingsService();
      await Future.wait([
        service.save(PracticeSettings(range: NumberRange.within5), 'Ann'),
        service.save(PracticeSettings(range: NumberRange.within10), 'Bob'),
        service.save(PracticeSettings(range: NumberRange.within20), 'Cy'),
        service.save(PracticeSettings(range: NumberRange.within1000)),
      ]);
      expect((await service.load('Ann')).range, NumberRange.within5);
      expect((await service.load('Bob')).range, NumberRange.within10);
      expect((await service.load('Cy')).range, NumberRange.within20);
      expect((await service.load('Dee')).range, NumberRange.within1000);
    });

    test('onboarding flag', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ParentalSettingsService();
      expect(await service.isOnboarded(), isFalse);
      await service.markOnboarded();
      expect(await service.isOnboarded(), isTrue);
    });
  });

  group('HistorySummary', () {
    test('aggregates accuracy, time, streak, gems and most missed', () {
      final summary = HistorySummary.from([
        _game(
          'A',
          1,
          correct: 8,
          answered: 10,
          avg: 2000,
          gems: 1,
          streak: 5,
          missed: ['8 + 5', '7 × 8'],
        ),
        _game(
          'A',
          2,
          correct: 2,
          answered: 10,
          avg: 4000,
          streak: 2,
          missed: ['8 + 5'],
        ),
        _game('B', 3, correct: 10, answered: 10), // no timing recorded
      ]);
      expect(summary.games, 3);
      expect(summary.practiceSeconds, 180);
      expect(summary.accuracyPercent, 67); // 20 of 30
      expect(summary.averageAnswerMillis, 3000);
      expect(summary.bestStreak, 5);
      expect(summary.gems, 1);
      expect(summary.mostMissed.first.key, '8 + 5');
      expect(summary.mostMissed.first.value, 2);
      expect(summary.mostMissed.length, 2);
    });

    test('an empty list is all zeros', () {
      final summary = HistorySummary.from([]);
      expect(summary.games, 0);
      expect(summary.accuracyPercent, 0);
      expect(summary.averageAnswerMillis, 0);
      expect(summary.mostMissed, isEmpty);
    });
  });

  group('LeaderboardService history limit', () {
    test('is kept per player', () async {
      final service = LeaderboardService();
      for (var i = 0; i < LeaderboardService.maxHistory + 5; i++) {
        await service.addScore(_game('Busy', i + 1000));
      }
      await service.addScore(_game('Quiet', 1));
      final all = await service.load();
      expect(
        all.where((e) => e.name == 'Busy').length,
        LeaderboardService.maxHistory,
      );
      expect(all.where((e) => e.name == 'Quiet').length, 1);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('first-run setup', () {
    testWidgets('is shown once on a fresh install', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Set up for your child'), findsOneWidget);
      expect(find.textContaining('Parental control'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('preset-starting')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('setup-done')));
      await tester.tap(find.byKey(const ValueKey('setup-done')));
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
      final saved = await ParentalSettingsService().load();
      expect(saved, PracticeSettings.preset(PracticePreset.starting));
      expect(await ParentalSettingsService().isOnboarded(), isTrue);

      // Not shown again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Set up for your child'), findsNothing);
    });

    testWidgets('is skipped for installations that already have players', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await PlayerService().selectOrCreate(
        PlayerProfile(name: 'Ann', languageCode: 'en'),
      );
      // A selected player needs the app shell (it owns the locale).
      await tester.pumpWidget(const MathGameApp());
      await tester.pumpAndSettle();
      expect(find.text('Set up for your child'), findsNothing);
      expect(await ParentalSettingsService().isOnboarded(), isTrue);
    });
  });

  group('home screen follows the parental settings', () {
    testWidgets('offers only enabled operations, drills and lengths', (
      tester,
    ) async {
      await ParentalSettingsService().save(
        PracticeSettings(
          operations: {OperationType.addition},
          drills: {Drill.pairsToTen},
          durations: {ChallengeDuration.twoMinutes},
        ),
      );
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Add'), findsOneWidget);
      expect(find.textContaining('Subtract'), findsNothing);
      expect(find.textContaining('Multiply'), findsNothing);
      expect(
        find.byKey(const ValueKey('home-drill-pairsToTen')),
        findsOneWidget,
      );
      expect(find.text('2 min'), findsOneWidget);
      expect(find.text('1 min'), findsNothing);
    });
  });

  group('parental gate in the menu', () {
    testWidgets('a wrong answer shows a new problem, a right one opens it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parental control'));
      await tester.pumpAndSettle();

      expect(find.text('Grown-ups only'), findsOneWidget);
      String expression() => tester
          .widget<Text>(find.byKey(const ValueKey('parental-expression')))
          .data!;
      int answerOf(String text) {
        final m = RegExp(r'2\^(\d+) \+ (\d+) × (\d+)').firstMatch(text)!;
        return ParentalChallenge(
          exponent: int.parse(m[1]!),
          factorA: int.parse(m[2]!),
          factorB: int.parse(m[3]!),
        ).answer;
      }

      final first = expression();
      final wrong = (answerOf(first) + 1) % 1000;
      await tester.enterText(
        find.byKey(const ValueKey('parental-answer')),
        '$wrong',
      );
      await tester.tap(find.byKey(const ValueKey('parental-check')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.byType(ParentalControlScreen), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('parental-answer')),
        '${answerOf(expression())}',
      );
      await tester.tap(find.byKey(const ValueKey('parental-check')));
      await tester.pumpAndSettle();
      expect(find.byType(ParentalControlScreen), findsOneWidget);
    });

    testWidgets('repeated wrong answers lock the gate for a while', (
      tester,
    ) async {
      ParentalGateLockout.reset();
      addTearDown(ParentalGateLockout.reset);
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parental control'));
      await tester.pumpAndSettle();

      for (var i = 0; i < ParentalGateLockout.maxAttempts; i++) {
        final text = tester
            .widget<Text>(find.byKey(const ValueKey('parental-expression')))
            .data!;
        final m = RegExp(r'2\^(\d+) \+ (\d+) × (\d+)').firstMatch(text)!;
        final answer = ParentalChallenge(
          exponent: int.parse(m[1]!),
          factorA: int.parse(m[2]!),
          factorB: int.parse(m[3]!),
        ).answer;
        await tester.enterText(
          find.byKey(const ValueKey('parental-answer')),
          '${(answer + 1) % 1000}',
        );
        await tester.tap(find.byKey(const ValueKey('parental-check')));
        await tester.pumpAndSettle();
      }
      // The dialog closed and the gate is locked.
      expect(find.text('Grown-ups only'), findsNothing);
      expect(ParentalGateLockout.until, isNotNull);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parental control'));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups only'), findsNothing);

      // After the lockout it opens again.
      ParentalGateLockout.until = DateTime.now().subtract(
        const Duration(seconds: 1),
      );
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parental control'));
      await tester.pumpAndSettle();
      expect(find.text('Grown-ups only'), findsOneWidget);
    });

    test('the attempt limit counts across openings of the gate', () {
      ParentalGateLockout.reset();
      addTearDown(ParentalGateLockout.reset);
      for (var i = 0; i < ParentalGateLockout.maxAttempts - 1; i++) {
        expect(ParentalGateLockout.recordFailure(), isFalse);
      }
      expect(ParentalGateLockout.recordFailure(), isTrue);
      expect(ParentalGateLockout.until, isNotNull);
      expect(ParentalGateLockout.failures, 0);
    });

    testWidgets('cancel keeps the panel closed', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parental control'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ParentalControlScreen), findsNothing);
    });
  });

  group('parental control panel', () {
    testWidgets('changes are saved per player', (tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final players = PlayerService();
      await players.selectOrCreate(
        PlayerProfile(name: 'Bob', languageCode: 'en'),
      );
      await players.selectOrCreate(
        PlayerProfile(name: 'Ann', languageCode: 'en'),
      );

      await tester.pumpWidget(
        _app(const ParentalControlScreen(initialPlayerName: 'Ann')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('range-within20')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crossing-only')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drill-doubles')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('table-10')));
      await tester.pumpAndSettle();

      final service = ParentalSettingsService();
      final ann = await service.load('Ann');
      expect(ann.range, NumberRange.within20);
      expect(ann.crossing, CrossingMode.only);
      expect(ann.drills, {Drill.doubles});
      expect(ann.tables.contains(10), isFalse);
      // Editing Ann does not change Bob, who has no own settings yet.
      expect((await service.load('Bob')).range, NumberRange.within100);
    });

    testWidgets('the last enabled option cannot be turned off', (tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await ParentalSettingsService().save(
        PracticeSettings(operations: {OperationType.addition}),
      );
      await tester.pumpWidget(_app(const ParentalControlScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('op-addition')));
      await tester.pumpAndSettle();
      expect(find.text('Keep at least one option turned on.'), findsOneWidget);
      expect((await ParentalSettingsService().load()).operations, {
        OperationType.addition,
      });
    });

    testWidgets('"always cross a ten" is disabled within 5', (tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(const ParentalControlScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('range-within5')));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('crossing-only')),
      );
      expect(chip.onSelected, isNull);
    });

    testWidgets('apply to all players', (tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final players = PlayerService();
      await players.selectOrCreate(
        PlayerProfile(name: 'Bob', languageCode: 'en'),
      );
      await players.selectOrCreate(
        PlayerProfile(name: 'Ann', languageCode: 'en'),
      );
      await ParentalSettingsService().save(
        PracticeSettings(range: NumberRange.within1000),
        'Bob',
      );

      await tester.pumpWidget(
        _app(const ParentalControlScreen(initialPlayerName: 'Ann')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('preset-starting')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('apply-to-all')));
      await tester.tap(find.byKey(const ValueKey('apply-to-all')));
      await tester.pumpAndSettle();

      final starting = PracticeSettings.preset(PracticePreset.starting);
      expect(await ParentalSettingsService().load('Bob'), starting);
      expect(await ParentalSettingsService().load('Ann'), starting);
    });
  });

  group('parental history', () {
    testWidgets('lists every game of every player with stats', (tester) async {
      tester.view.physicalSize = const Size(1080, 12000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now().millisecondsSinceEpoch;
      final old = DateTime.now()
          .subtract(const Duration(days: 60))
          .millisecondsSinceEpoch;
      final service = LeaderboardService();
      await service.addScore(
        _game('Ann', now, missed: ['8 + 5'], avg: 2500, gems: 2, streak: 6),
      );
      await service.addScore(_game('Bob', now - 1000));
      await service.addScore(_game('Ann', old));

      await tester.pumpWidget(_app(const ParentalHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('game-$now')), findsOneWidget);
      expect(find.byKey(ValueKey('game-${now - 1000}')), findsOneWidget);
      expect(find.byKey(ValueKey('game-$old')), findsOneWidget);
      expect(find.byKey(const ValueKey('history-summary')), findsOneWidget);
      expect(find.textContaining('8 + 5'), findsWidgets);

      // Filter by player.
      await tester.tap(find.byKey(const ValueKey('history-player')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('game-${now - 1000}')), findsOneWidget);
      expect(find.byKey(ValueKey('game-$now')), findsNothing);

      // Filter by period: the 60 day old game disappears.
      await tester.tap(find.byKey(const ValueKey('history-player')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All players').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-period')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 30 days').last);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('game-$old')), findsNothing);
      expect(find.byKey(ValueKey('game-$now')), findsOneWidget);
    });

    testWidgets('shows a message when nothing was played', (tester) async {
      await tester.pumpWidget(_app(const ParentalHistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-summary')), findsNothing);
    });
  });
}
