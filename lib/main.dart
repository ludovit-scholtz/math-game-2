import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.loadSettings();
  await NotificationService().initialize();
  await NotificationService().scheduleForCurrentPlayer();
  final themeMode = await ThemeService.loadThemeMode();
  runApp(MathGameApp(initialThemeMode: themeMode));
}

class MathGameApp extends StatefulWidget {
  const MathGameApp({super.key, this.initialThemeMode = ThemeMode.system});

  final ThemeMode initialThemeMode;

  /// Lets descendants override the active locale at runtime (e.g. when a player
  /// with a stored language preference is selected).
  static MathGameAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MathGameAppState>()!;

  @override
  State<MathGameApp> createState() => MathGameAppState();
}

class MathGameAppState extends State<MathGameApp> {
  Locale? _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  /// Overrides the active locale. Pass `null` to fall back to the device locale.
  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    await ThemeService.saveThemeMode(mode);
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
      darkTheme: AppTheme.darkThemeData(),
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
