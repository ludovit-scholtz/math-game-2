// Smoke test that the app boots and shows the home screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_game_2/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and shows the home screen', (tester) async {
    await tester.pumpWidget(const MathGameApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Math Master'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
  });
}
