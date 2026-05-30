import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_game_2/screens/home_screen.dart';

void main() {
  testWidgets('home screen shows the title and start button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Math Masters'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);

    // All four operations are offered.
    expect(find.textContaining('Add'), findsOneWidget);
    expect(find.textContaining('Subtract'), findsOneWidget);
    expect(find.textContaining('Multiply'), findsOneWidget);
    expect(find.textContaining('Divide'), findsOneWidget);
  });
}
