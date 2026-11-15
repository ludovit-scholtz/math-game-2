// Generates the store screenshots in docs/screenshots/.
//
//   flutter test tool/screenshots/store_screenshots_test.dart
//
// The real screens are rendered headlessly (no device or emulator) with demo
// data, so the pictures can be regenerated at any time. See
// docs/SCREENSHOTS.md for the sizes, options and how to add a screen.
//
// This file is not part of the normal test run (`flutter test` only looks in
// test/); it writes files instead of asserting behaviour.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:math_game_2/l10n/app_strings.dart';
import 'package:math_game_2/main.dart';
import 'package:math_game_2/models/background_style.dart';
import 'package:math_game_2/models/game_config.dart';
import 'package:math_game_2/models/operation_type.dart';
import 'package:math_game_2/models/pet.dart';
import 'package:math_game_2/models/player_profile.dart';
import 'package:math_game_2/models/score_entry.dart';
import 'package:math_game_2/screens/game_screen.dart';
import 'package:math_game_2/screens/parental_control_screen.dart';
import 'package:math_game_2/screens/parental_history_screen.dart';
import 'package:math_game_2/screens/pet_screen.dart';
import 'package:math_game_2/screens/results_screen.dart';
import 'package:math_game_2/screens/shop_screen.dart';
import 'package:math_game_2/services/coin_service.dart';
import 'package:math_game_2/services/leaderboard_service.dart';
import 'package:math_game_2/services/player_service.dart';
import 'package:math_game_2/theme.dart';
import 'package:math_game_2/widgets/answer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'captions.dart';

/// Language of the app and the captions: `--dart-define=SCREENSHOT_LOCALE=sk`.
/// Any language of the app (`AppStrings.supportedLocales`).
const String _localeCode = String.fromEnvironment(
  'SCREENSHOT_LOCALE',
  defaultValue: 'en',
);

/// Optional comma separated device ids to render, e.g.
/// `--dart-define=SCREENSHOT_DEVICES=play-phone,ios-iphone-6.9`.
const String _deviceFilter = String.fromEnvironment('SCREENSHOT_DEVICES');

const String _emojiFamily = 'NotoColorEmoji';
const String _symbolFamily = 'NotoSansSymbols2';

/// Noto Sans CJK, which draws Japanese, Korean and Chinese text.
const String _cjkFamily = 'NotoSansCJK';

/// File name prefix of the CJK font of each language that needs one.
const Map<String, String> _cjkFiles = {
  'ja': 'NotoSansCJKjp',
  'ko': 'NotoSansCJKkr',
  'zh': 'NotoSansCJKsc',
};

/// Fonts for the characters Roboto does not have.
final List<String> _fallbackFonts = [
  if (_cjkFiles.containsKey(_localeCode)) _cjkFamily,
  _emojiFamily,
  _symbolFamily,
];
const String _player = 'Emma';

/// One store slot: the exact picture size the store wants and the size of the
/// device screen drawn inside it.
class _Device {
  const _Device(this.id, this.output, this.screen, {this.tablet = false});

  final String id;

  /// Size of the PNG in pixels.
  final Size output;

  /// Size of the app screen in logical pixels.
  final Size screen;
  final bool tablet;
}

// Sizes: see docs/SCREENSHOTS.md for where each number comes from.
const List<_Device> _devices = [
  _Device('play-phone', Size(1080, 1920), Size(412, 870)),
  _Device('play-tablet-7', Size(1080, 1920), Size(540, 864), tablet: true),
  _Device('play-tablet-10', Size(1440, 2560), Size(640, 1024), tablet: true),
  _Device('ios-iphone-6.9', Size(1320, 2868), Size(440, 956)),
  _Device('ios-iphone-6.5', Size(1284, 2778), Size(428, 926)),
  _Device('ios-ipad-13', Size(2064, 2752), Size(688, 917), tablet: true),
];

/// One picture: a screen of the app in a certain state plus its caption.
class _Scene {
  const _Scene(this.id, this.colors, this.show);

  final String id;

  /// Backdrop gradient of the picture.
  final List<Color> colors;

  /// Pumps the screen and brings it into the state to photograph.
  final Future<void> Function(WidgetTester tester) show;
}

final List<_Scene> _scenes = [
  _Scene('home', const [Color(0xFF5B6CF0), Color(0xFF8E5BF0)], _showHome),
  _Scene('game', const [Color(0xFFFF8A3D), Color(0xFFF0497A)], _showGame),
  _Scene('results', const [Color(0xFF2BB673), Color(0xFF18B0C9)], _showResults),
  _Scene('pet', const [Color(0xFFB23CFD), Color(0xFF5B6CF0)], _showPet),
  _Scene('shop', const [Color(0xFF18B0C9), Color(0xFF5B6CF0)], _showShop),
  _Scene('parents', const [Color(0xFF3D4BB8), Color(0xFF222452)], _showParents),
  _Scene('progress', const [Color(0xFFF0497A), Color(0xFFB23CFD)], _showHistory),
];

List<String> _caption(String id) => storeCaptions[_localeCode]![id]!;

Directory get _outputRoot => Directory('docs/screenshots/$_localeCode');

void main() {
  final devices = [
    for (final device in _devices)
      if (_deviceFilter.isEmpty || _deviceFilter.split(',').contains(device.id))
        device,
  ];

  if (!storeCaptions.containsKey(_localeCode)) {
    throw ArgumentError(
      'No captions for "$_localeCode" in tool/screenshots/captions.dart.',
    );
  }

  setUpAll(_loadFonts);
  setUpAll(_muteAudio);

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'onboarding_done_v1': true});
    await _seedDemoData();
  });

  for (final device in devices) {
    for (var i = 0; i < _scenes.length; i++) {
      final scene = _scenes[i];
      final number = (i + 1).toString().padLeft(2, '0');
      testWidgets('${device.id} $number-${scene.id}', (tester) async {
        final picture = _Layout(device);
        final screen = await _photograph(
          tester,
          size: device.screen,
          pixelRatio: picture.scale,
          show: scene.show,
        );
        final image = await _photograph(
          tester,
          size: device.output,
          pixelRatio: 1,
          show: (tester) async {
            await tester.pumpWidget(
              _StorePicture(
                layout: picture,
                colors: scene.colors,
                caption: _caption(scene.id),
                screen: screen,
              ),
            );
          },
        );
        await _savePng(
          tester,
          image,
          File('${_outputRoot.path}/${device.id}/$number-${scene.id}.png'),
        );
      });
    }
  }

  testWidgets('play-feature-graphic', (tester) async {
    final image = await _photograph(
      tester,
      size: const Size(1024, 500),
      pixelRatio: 1,
      show: (tester) async {
        await tester.pumpWidget(_FeatureGraphic(caption: _caption('feature')));
        await _loadImages(tester);
      },
    );
    await _savePng(
      tester,
      image,
      File('${_outputRoot.path}/play-feature-graphic.png'),
    );
  });
}

/// There is no audio plugin in a widget test. Answer every call to it with
/// "done", so the sounds of the game and the results screen are skipped.
void _muteAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.allMessagesHandler = (channel, handler, message) async {
    if (channel.startsWith('xyz.luan/audioplayers')) {
      return const StandardMethodCodec().encodeSuccessEnvelope(null);
    }
    return handler?.call(message);
  };
}

// --- Demo data ---------------------------------------------------------------

/// Fills the app with a few players, coins, bought styles and played games
/// through the same services the app uses, so the data always has the current
/// storage format.
Future<void> _seedDemoData() async {
  final players = PlayerService();
  final now = DateTime.now();
  Future<void> addPlayer(String name, PetType pet, int food, int fun) =>
      players.selectOrCreate(
        PlayerProfile(
          name: name,
          languageCode: _localeCode,
          petType: pet,
          petFeedingPoints: food,
          petEnjoymentPoints: fun,
          petCareUpdatedAt: now,
        ),
      );
  await addPlayer('Leo', PetType.dog, 70, 60);
  await addPlayer('Mia', PetType.panda, 90, 80);
  // Added last, so this is the selected player.
  await addPlayer(_player, PetType.cat, 88, 74);

  final coins = CoinService();
  await coins.addReward(_player, coins: 1500, gems: 7);
  // Buy a few styles and put them on the answer buttons.
  final styles = BackgroundCatalog.availableFor(const <String>{});
  for (var i = 0; i < 4; i++) {
    final bought = await coins.purchase(_player, styles[i]);
    if (bought != null) await coins.assign(_player, i * 2 % 6, styles[i].id);
  }

  // A deterministic history of games over the last days.
  final random = math.Random(7);
  final history = LeaderboardService();
  const names = [_player, 'Leo', 'Mia'];
  const operationSets = [
    [OperationType.addition, OperationType.subtraction],
    [OperationType.multiplication],
    [OperationType.addition],
    OperationType.values,
    [OperationType.multiplication, OperationType.division],
  ];
  for (var i = 17; i >= 0; i--) {
    final answered = 14 + random.nextInt(22);
    final faults = random.nextInt(4);
    await history.addScore(
      ScoreEntry(
        name: names[i % names.length],
        score: answered * 2 - faults * 3 + random.nextInt(6),
        duration: ChallengeDuration.values[i % 2],
        operations: operationSets[i % operationSets.length],
        correct: answered - faults,
        answered: answered,
        dateMillis: now
            .subtract(Duration(hours: 7 * i + 1, minutes: 13 * i))
            .millisecondsSinceEpoch,
        gemsEarned: (answered - faults) ~/ 6,
        coinsEarned: 8 + random.nextInt(40),
        bestStreak: 5 + random.nextInt(12),
        avgAnswerMillis: 1500 + random.nextInt(1800),
        missed: [
          for (var m = 0; m < faults; m++)
            '${6 + random.nextInt(4)} × ${6 + random.nextInt(4)}',
        ],
      ),
    );
  }
}

// --- Scenes ------------------------------------------------------------------

/// The app shell used for every screen except the home screen.
Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale(_localeCode),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      theme: AppTheme.themeData(),
      home: home,
    );

Future<void> _showHome(WidgetTester tester) async {
  await tester.pumpWidget(
    const MathGameApp(initialThemeMode: ThemeMode.light),
  );
  await tester.pumpAndSettle();
  await _loadImages(tester);
}

GameConfig _gameConfig() => GameConfig(
      playerName: _player,
      duration: ChallengeDuration.twoMinutes,
      operations: OperationType.values.toSet(),
    );

Future<void> _showGame(WidgetTester tester) async {
  await tester.pumpWidget(_app(GameScreen(config: _gameConfig())));
  await tester.pump();
  // Answer a few questions correctly, then stop while the last answer is
  // still marked as correct.
  for (var i = 0; i < 4; i++) {
    await tester.tap(_correctAnswerCard(tester));
    await tester.pump(const Duration(milliseconds: 1000));
  }
  await tester.tap(_correctAnswerCard(tester));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Reads the question (e.g. `7 × 8`) from the screen and finds the card with
/// its answer.
Finder _correctAnswerCard(WidgetTester tester) {
  final prompt = RegExp(r'^(\d+) ([+−×÷]) (\d+)$');
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final match = prompt.firstMatch(text.data ?? '');
    if (match == null) continue;
    final a = int.parse(match.group(1)!);
    final b = int.parse(match.group(3)!);
    final answer = switch (match.group(2)!) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      _ => a ~/ b,
    };
    return find.byWidgetPredicate(
      (widget) => widget is AnswerCard && widget.value == answer,
    );
  }
  throw StateError('No question found on the game screen.');
}

Future<void> _showResults(WidgetTester tester) async {
  await tester.pumpWidget(
    _app(
      ResultsScreen(
        finishedConfig: _gameConfig(),
        finalScore: 96,
        correctCount: 34,
        answeredCount: 35,
        gemsEarned: 6,
        bestStreak: 21,
        avgAnswerMillis: 1900,
        missed: const ['7 × 8'],
      ),
    ),
  );
  // A new record starts endless fireworks, so this never settles: let them
  // run for a moment instead.
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _showPet(WidgetTester tester) async {
  await tester.pumpWidget(_app(const PetScreen(playerName: _player)));
  await tester.pumpAndSettle();
  await _loadImages(tester);
}

Future<void> _showShop(WidgetTester tester) async {
  await tester.pumpWidget(_app(const ShopScreen(playerName: _player)));
  await tester.pumpAndSettle();
}

Future<void> _showParents(WidgetTester tester) async {
  await tester.pumpWidget(
    _app(const ParentalControlScreen(initialPlayerName: _player)),
  );
  await tester.pumpAndSettle();
}

Future<void> _showHistory(WidgetTester tester) async {
  await tester.pumpWidget(_app(const ParentalHistoryScreen()));
  await tester.pumpAndSettle();
}

// --- Rendering ---------------------------------------------------------------

/// Where the device screen sits inside the store picture.
class _Layout {
  _Layout(this.device) {
    final out = device.output;
    captionHeight = out.height * 0.19;
    bezel = out.width * (device.tablet ? 0.016 : 0.014);
    final maxWidth = out.width * 0.86 - 2 * bezel;
    final maxHeight = out.height * 0.955 - captionHeight - 2 * bezel;
    scale = math.min(
      maxWidth / device.screen.width,
      maxHeight / device.screen.height,
    );
  }

  final _Device device;
  late final double captionHeight;
  late final double bezel;

  /// Output pixels per logical pixel of the app screen.
  late final double scale;

  Size get screenSize => device.screen * scale;
  double get cornerRadius => device.output.width * (device.tablet ? 0.03 : 0.055);
}

/// Shows a widget on a surface of [size] logical pixels and returns a picture
/// of it with [pixelRatio] pixels per logical pixel.
Future<ui.Image> _photograph(
  WidgetTester tester, {
  required Size size,
  required double pixelRatio,
  required Future<void> Function(WidgetTester tester) show,
}) async {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The layout and fonts of an Android device, whatever runs the generator.
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  try {
    await show(tester);
    _useDeviceFonts(tester);
    await tester.pump();
    // The root of the render tree is a repaint boundary, so it can be turned
    // into an image without wrapping the app.
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    // The root layer is measured in physical pixels.
    final image = await tester.runAsync(
      () => layer.toImage(Offset.zero & (size * pixelRatio)),
    );
    // Dispose the screen, including the timer of a running game, and let
    // short delays that were already started (answer feedback) run out.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    return image!;
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// A device picks its system font for text without a font family and finds a
/// font for emoji on its own. A widget test does neither: such text is drawn
/// with a placeholder font (boxes). So give every paragraph on screen the
/// fonts a device would use; the next frame lays the text out again.
void _useDeviceFonts(WidgetTester tester) {
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>().toList()) {
    final text = paragraph.text;
    if (text is! TextSpan) continue;
    final style = text.style ?? const TextStyle();
    paragraph.text = TextSpan(
      text: text.text,
      children: text.children,
      recognizer: text.recognizer,
      semanticsLabel: text.semanticsLabel,
      locale: text.locale,
      style: style.copyWith(
        fontFamily: style.fontFamily ?? 'Roboto',
        fontFamilyFallback: [...?style.fontFamilyFallback, ..._fallbackFonts],
      ),
    );
  }
}

/// Asset images decode asynchronously, which a widget test does not wait for.
Future<void> _loadImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}

/// Writes [image] as a PNG without an alpha channel (both stores reject
/// screenshots with transparency).
Future<void> _savePng(WidgetTester tester, ui.Image image, File file) async {
  await tester.runAsync(() async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgb = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: data!.buffer,
      numChannels: 4,
    ).convert(numChannels: 3);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(rgb, level: 9));
  });
  // ignore: avoid_print
  print('${file.path}  ${image.width}x${image.height}');
}

/// Widget tests only know a placeholder font, so load the fonts a device
/// would use: Roboto and the Material icons from the Flutter SDK, plus the
/// emoji font kept next to this file.
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      // .../bin/cache/artifacts/engine/<platform>/flutter_tester
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent
          .parent.path;
  // The SDK names these files differently from platform to platform
  // (Roboto-Regular.ttf, roboto-regular.ttf), so look them up ignoring case.
  final sdkFontDir = Directory(
    '$flutterRoot/bin/cache/artifacts/material_fonts',
  );
  if (!sdkFontDir.existsSync()) {
    throw StateError('Flutter SDK fonts not found: ${sdkFontDir.path}');
  }
  final sdkFonts = {
    for (final file in sdkFontDir.listSync().whereType<File>())
      file.uri.pathSegments.last.toLowerCase(): file.path,
  };
  String sdkFont(String name) =>
      sdkFonts[name] ?? '${sdkFontDir.path}/$name';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('Font not found: $path');
      }
      loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    for (final weight in const [
      'thin',
      'light',
      'regular',
      'medium',
      'bold',
      'black',
    ])
      sdkFont('roboto-$weight.ttf'),
  ]);
  await load('MaterialIcons', [sdkFont('materialicons-regular.otf')]);
  final cjk = _cjkFiles[_localeCode];
  if (cjk != null) {
    await load(_cjkFamily, [
      'tool/screenshots/fonts/$cjk-Regular-subset.otf',
      'tool/screenshots/fonts/$cjk-Bold-subset.otf',
    ]);
  }
  await load(_emojiFamily, [
    'tool/screenshots/fonts/NotoColorEmoji-subset.ttf',
  ]);
  await load(_symbolFamily, [
    'tool/screenshots/fonts/NotoSansSymbols2-subset.ttf',
  ]);
}

final TextStyle _captionStyle = TextStyle(
  fontFamily: 'Roboto',
  fontFamilyFallback: _fallbackFonts,
  color: Colors.white,
  decoration: TextDecoration.none,
  height: 1.15,
);

/// The finished store picture: caption on a colourful backdrop and the app
/// screen in a simple device frame.
class _StorePicture extends StatelessWidget {
  const _StorePicture({
    required this.layout,
    required this.colors,
    required this.caption,
    required this.screen,
  });

  final _Layout layout;
  final List<Color> colors;
  final List<String> caption;
  final ui.Image screen;

  @override
  Widget build(BuildContext context) {
    final width = layout.device.output.width;
    final radius = layout.cornerRadius;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: layout.captionHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        caption[0],
                        maxLines: 1,
                        style: _captionStyle.copyWith(
                          fontSize: width * 0.078,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: width * 0.018),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        caption[1],
                        maxLines: 1,
                        style: _captionStyle.copyWith(
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(layout.bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF14172B),
                borderRadius: BorderRadius.circular(radius + layout.bezel),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: width * 0.05,
                    offset: Offset(0, width * 0.02),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: RawImage(
                  image: screen,
                  width: layout.screenSize.width,
                  height: layout.screenSize.height,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 1024 x 500 banner Google Play shows at the top of the store listing.
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({required this.caption});

  final List<String> caption;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B6CF0), Color(0xFFB23CFD)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/math_master_icon.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        caption[0],
                        maxLines: 1,
                        style: _captionStyle.copyWith(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        caption[1],
                        maxLines: 1,
                        style: _captionStyle.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '+   −   ×   ÷',
                      style: _captionStyle.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFD54A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
