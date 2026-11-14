# AI agent instructions — Math Master (`math_game_2`)

Guidance for AI coding agents (Claude Code, GitHub Copilot, …) working in this
repository. `CLAUDE.md` imports this file, so keep it as the single source of
truth.

## What this is

A Flutter math-practice game for **2nd-grade children** ("Kids Math Practice |
Biatec" in stores, package `math_game_2`, Android id `io.biatec.math_master`).
Players answer timed +, −, ×, ÷ questions under 100, earn coins, buy button
styles and care for a pet. Everything is stored **locally on the device**
(`shared_preferences`); there is no backend and no network code.

Because the audience is young children, keep copy friendly and simple, never
add ads, tracking, analytics or network calls without explicit approval, and
keep the privacy policy (`docs/privacy-policy/*.md`) accurate if data handling
changes.

## Commands

```bash
flutter pub get
flutter analyze            # must report "No issues found!"
flutter test               # all tests must pass
flutter test test/question_generator_test.dart   # single file
flutter run -d chrome      # run locally (web) — or -d windows / a device
```

- CI (`.github/workflows/ci.yml`) runs `flutter analyze` and `flutter test`
  with Flutter **3.44.0**, then builds APK/AAB and web.
- **Formatting is not enforced by CI.** The local Dart formatter may be newer
  than the one the code was written with and would reformat many files. Do
  **not** run `dart format .` on the whole repo; format only the files you
  change (`dart format path/to/file.dart`) and keep unrelated files untouched.
- Platform folders (`android/`, `ios/`, `web/`, …) are **git-ignored** and
  generated in CI by `flutter create`. Never commit them. Run
  `flutter create --platforms=android,ios,web --org io.biatec --project-name math_master .`
  (same as CI)
  locally if you need them. Native config changes (manifest, Gradle, Info.plist)
  must be made in the Python patch steps inside the workflows, not in files.

## Architecture

```
lib/
  main.dart          app bootstrap; MathGameApp(State) owns locale + theme mode
  theme.dart         AppTheme light/dark ThemeData
  l10n/app_strings.dart   ALL user-facing text, 11 languages (see below)
  models/            plain data: Question, GameConfig/ChallengeDuration,
                     OperationType, ScoreEntry, PlayerProfile, Pet, BackgroundStyle
  logic/             pure Dart, no Flutter imports, fully unit tested
    question_generator.dart  questions + 6 answer cards (mistake-based distractors)
    scoring.dart             points per answer by response time
    game_controller.dart     a game session; spaced repetition of missed questions
    coins.dart               coins earned per game
  services/          persistence + platform: PlayerService, LeaderboardService,
                     CoinService (CoinWallet), AudioService, NotificationService,
                     ThemeService
  screens/           StatefulWidget screens; navigation via Navigator.push +
                     MaterialPageRoute (no router package, no state library)
  widgets/           AnswerCard, Fireworks, pet widgets
```

Key conventions:

- **State management** is plain `StatefulWidget` + `setState`. Screens create
  their services directly (`final _service = PlayerService();`). Don't introduce
  Provider/Riverpod/Bloc or a router unless asked.
- **Keep `lib/logic/` Flutter-free** so it stays unit-testable. Inject `Random`
  (e.g. `QuestionGenerator(random: Random(42))`) for deterministic tests.
- **Persistence** uses JSON strings in `shared_preferences` under **versioned
  keys** (`players_v1`, `history_v2`, `wallets_v1`, `theme_mode_v1`,
  `audio_muted_v1`, …). `fromJson` must tolerate missing/old fields with
  defaults. If you change a stored format incompatibly, bump the key suffix and
  migrate or default gracefully — never crash on old data.
- Players are identified by **name**. Wallets (`CoinService`) and history
  (`ScoreEntry.name`) are keyed by name.
- Enums are persisted by stable string (`OperationType.storageKey`, `PetType.id`)
  — except `ChallengeDuration`, which is stored by `index`, so **only append** new
  values to that enum.
- Leaderboards group games by `ScoreEntry.gameTypeKey` (duration + sorted
  operations).

## Game rules (keep code, README, in-app Guide and tests in sync)

- Operands and answers stay in `0..100`; subtraction is never negative;
  multiplication factors are `2..10`.
- Division always divides evenly; divisor and quotient are both in `1..10`
  (`QuestionGenerator.maxDivisionValue = 10`), so the dividend is at most 100.
- Every question has exactly `QuestionGenerator.optionCount = 6` distinct,
  non-negative answer cards.
- Scoring (`Scoring`): `<1 s` → 3 pts; `1–10 s` → linear 3→1; `>10 s` or wrong →
  −1.
- Missed questions return after `GameController.reaskAfter = 3` questions.
- Coins (`Coins.maxForDuration`): 1 min → 20, 2 min → 50, 5 min → 150, linear by
  score vs. the category's top score.
- Pets: food −100/day, fun −20/day; feed = 20 coins/+30 food, toy = 100 coins/+50
  fun; hungry/sad below 20.

When you change a rule, update in the same change: the code, its unit test,
`README.md`, the in-app Guide strings (`doc*Title`/`doc*Body` keys) in **all**
languages, and `docs/description/*.md` if the store text mentions it.

## Localization

`lib/l10n/app_strings.dart` is a hand-written map — **not** `flutter gen-l10n`/ARB.

- Supported: `cs de en es fr ja ko ru sk tr zh` (`AppStrings.supportedLocales`).
- Adding a string: add the key to **every** language map in `_localizedValues`
  (English is the fallback, but missing translations are a bug), then add a
  getter (`String get foo => _text('foo');`) or a formatter using
  `_format('foo', {'name': name})` with `{name}` placeholders.
- Plurals are handled by helpers (`coinWord`, `_usesFewSlavicForm`,
  `_usesRussianOneForm`, …) — extend them for count-dependent text.
- Use it in widgets via `context.strings.foo`. Never hard-code user-facing text.
- Per-language docs live in `docs/description/<code>.md` (store listing) and
  `docs/privacy-policy/<code>.md` (bundled as an asset; `index.md` is English).
- Use `/add-string` or `/add-language` (in `.claude/commands/`) for these tasks.

## Testing

- Tests live in `test/` (flat, `<subject>_test.dart`). Add/extend tests for every
  behaviour change; logic changes need unit tests, UI changes need widget tests.
- Widget/service tests must call `SharedPreferences.setMockInitialValues({})` in
  `setUp`.
- Widget tests wrap screens in `MaterialApp` with
  `AppStrings.localizationsDelegates` / `AppStrings.supportedLocales`; set
  `tester.view.physicalSize` for layout tests and reset in `addTearDown`.
- `GameScreen` runs a periodic timer: end such tests with
  `await tester.pumpWidget(const SizedBox());` so the timer is disposed.
- Randomised logic: loop a few hundred iterations with a seeded `Random` and
  assert invariants (ranges, distinctness, correctness).

## Git & PR workflow

- Branch from `main` (`feat/…`, `fix/…`, `chore/…`, `docs/…`); conventional
  commit messages (`feat:`, `fix:`, `docs:`, `test:`, `chore:`).
- Before committing: `flutter analyze` clean and `flutter test` green.
- Line endings are LF (enforced by `.gitattributes`); don't commit CRLF churn.
- Releases: push a `vX.Y.Z` tag → `release.yml` builds a signed AAB and uploads
  it to Google Play internal testing (see `docs/GOOGLE_PLAY_RELEASE.md`). The
  version in `pubspec.yaml` is overwritten from the tag.
- Never commit signing material (`*.jks`, `key.properties`) or secrets.
- Use `/ship` for the branch → PR → review → fix → merge loop.
