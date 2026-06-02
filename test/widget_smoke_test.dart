import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows updated English title and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kids Math Practice | Biatec'), findsWidgets);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // All four operations are offered.
    expect(find.textContaining('Add'), findsOneWidget);
    expect(find.textContaining('Subtract'), findsOneWidget);
    expect(find.textContaining('Multiply'), findsOneWidget);
    expect(find.textContaining('Divide'), findsOneWidget);
  });

  testWidgets('home screen shows German translations when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Starten'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Bestenliste'), findsOneWidget);
    expect(find.textContaining('Addieren'), findsOneWidget);
  });
}
