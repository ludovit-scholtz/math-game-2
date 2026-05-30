import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.loadSettings();
  runApp(const MathGameApp());
}

class MathGameApp extends StatefulWidget {
  const MathGameApp({super.key});

  /// Lets descendants override the active locale at runtime (e.g. when a player
  /// with a stored language preference is selected).
  static MathGameAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MathGameAppState>()!;

  @override
  State<MathGameApp> createState() => MathGameAppState();
}

class MathGameAppState extends State<MathGameApp> {
  Locale? _locale;

  /// Overrides the active locale. Pass `null` to fall back to the device locale.
  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.strings.appName,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      theme: AppTheme.themeData(),
      home: const HomeScreen(),
    );
  }
}
