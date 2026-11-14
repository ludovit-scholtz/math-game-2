# 🧮 Math Master

A fun, kid-friendly math game that helps **2nd-grade** students practise the four
basic operations — addition, subtraction, multiplication and division — with
numbers **under 100 by default**; parents can choose other ranges and
school-style exercises in the **parental control** panel. Built with **Flutter**, so the same code base runs on
**Android, iOS, web and desktop**.

## How to play

1. On the home screen choose your player. Players you've used before are
   remembered, so you can switch between them without retyping a name — and each
  player keeps their own **language** and **pet**.
2. Pick a challenge length (**1, 2 or 5 minutes**) and choose which operations
   and special exercises to practise (only what a parent has enabled is offered).
   The first time the app starts, a parent is asked to set this up.
3. Answer as many questions as you can before the timer runs out by tapping one
   of the six answer cards. The game adapts to **portrait and landscape**
   orientation.
4. After the game your score is added to the **leaderboard**, which ranks the
   best score of every player **for each game type** (e.g. *1 min +−* or
   *1 min +−×÷*) and lists each player only once per game type. Beat the best
   score in a category to set a **new record** — fireworks celebrate it with
   animation and sound!
5. Open a player's **history** to review every game they've played, including how
   many faults they made.

### Coins, shop & customization

Every game also rewards **coins** — see the in-game **Guide** for the full
details:

- Each game earns coins based on its length: **0 to 20 coins** for 1 minute,
  **0 to 50 coins** for 2 minutes and **0 to 150 coins** for 5 minutes.
  Reaching the top score of a category earns the full reward, and coins are
  distributed linearly down to 0 for fewer points.
- Spend coins in the **shop** to unlock new answer-button background styles.
  There are always **20 styles** available to buy and the shop never runs dry —
  fresh styles are generated on demand. Every style has a **fixed price**
  that is identical for every player: most cost 100–1000 coins, and at least
  four budget styles for **50 coins** are always on offer.
- Use **Customize buttons** to assign any style you own to each of the **six**
  answer-button positions. Your choices are saved for your next game.

### Gems

Answer **5 questions correctly in a row** to earn a **gem** 💎; the counter then
starts again from 0. A wrong answer also resets the counter. A slow but correct
answer still counts. In the **shop** gems can be sold: every gem gives
**10 coins**.

### Practice modes & parental control

The **Parental control** panel (menu → *Parental control*) is protected by a
grown-ups-only question — `(2^a + b × c) mod 1000` with `a` in 5–20 and `b`, `c`
in 10000–99999, answered with the last three digits. It is also shown as a
**first-run setup**. Settings are stored per player (players without their own
settings use the ones from the first-run setup or "apply to all players") and a
parent can choose:

- **Number range** for + and −: up to **5, 10, 20, 100 or 1000**.
- **Crossing ten** (carrying/borrowing, e.g. `15 + 16`, `32 − 13`): never,
  sometimes or always.
- **Special exercises**: plus/minus 1 or 2, doubles and halves, near doubles,
  pairs that make 10 or 100, bridging through ten (`8 + 5`) and missing numbers
  (`7 + ? = 10`).
- **Multiplication tables** (×2 … ×10), also used as divisors.
- Which **challenge lengths** are offered, and quick presets ("Starting out",
  "Within 20", "Within 100", "Within 1000").

Games with different settings have separate leaderboards. The panel also lists
**every game of every player** with date, time, score, accuracy, answer time,
best streak, gems/coins and missed questions.

### Pets

Each player can choose a cat, dog, panda or rabbit. The pet appears on the home
screen and reacts to care: when food drops below 20 points it looks hungry, and
when fun drops below 20 points it looks sad. Food drops by **100 points per day**
and fun drops by **20 points per day**.

Changing the pet type keeps its current food and fun, so switching pets does
not refill them.

Players can spend coins to care for their pet:

- **Feed pet** costs **20 coins** and adds **30 food points**.
- **Buy a new toy** costs **100 coins** and adds **50 fun points**.

### Scoring

| Time to answer correctly | Points |
| --- | --- |
| Under 1 second | **3** |
| 1–10 seconds | **linearly from 3 down to 1** (faster = more) |
| Slower than 10 seconds | **−1** |
| Wrong answer | **−1** |

Questions you get wrong come back a few questions later (**spaced repetition**)
so you get another chance to master them.

### Designed to be educative

- Division questions always divide evenly; the divisor is one of the enabled
  tables (`2..10`) and the quotient is in `1..10` (e.g. `9 ÷ 3`, never
  `66 ÷ 3` or `66 ÷ 11`).
- The five wrong answer cards are modelled on **common mistakes** for each
  operation (off-by-one, place-value slips, adding instead of multiplying, …),
  which helps children recognise and correct their own errors.
- Sound effects reward correct answers and gently flag mistakes.

## Project layout

```
lib/
  models/      data types (Question, GameConfig, ScoreEntry, PlayerProfile, …)
  logic/       pure game logic (question generator, scoring, game controller)
  services/    audio, leaderboard/history + player persistence
  screens/     home, player selection, game, results/leaderboard and history
  widgets/     reusable UI pieces
test/          unit tests for the game logic
assets/sounds/ short WAV sound effects
assets/pets/   pet images for happy, hungry and sad states
```

The pure game logic in `lib/logic` has no Flutter dependency and is covered by
the unit tests in `test/`.

## Running locally

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter test          # run the unit tests
flutter run           # launch on a connected device, emulator or browser
```

## Building

```bash
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle (for Google Play)
flutter build web --release        # Web
flutter build windows --release    # Windows desktop (needs Visual Studio, Windows only)
```

For Windows, generate the platform folder first and (optionally) the icon:

```bash
flutter create --platforms=windows --org io.biatec --project-name math_master .
dart run flutter_launcher_icons -f flutter_launcher_icons-windows.yaml
flutter build windows --release   # -> build/windows/x64/runner/Release/math_master.exe
```

Pet reminder notifications are available on Android and iOS only; on the web and
on Windows the game works without them.

> The platform folders (`android/`, `ios/`, `web/`, …) are generated with
> `flutter create .` and are intentionally not committed; the CI pipeline
> regenerates them before building.

## CI/CD

The [`CI` workflow](.github/workflows/ci.yml) runs on every push and pull
request and:

1. runs `flutter analyze` and `flutter test`;
2. builds the release **APK** and **App Bundle** and uploads them as artifacts;
3. builds the **web** version and uploads it as an artifact;
4. builds the **Windows** desktop app (`flutter build windows`) and uploads the
   `Release` folder as an artifact.

Pushing a `vX.Y.Z` tag also runs the [`Release` workflow](.github/workflows/release.yml),
which uploads the signed App Bundle to Google Play internal testing and attaches a
**Windows zip** (`math-master-windows-x64-X.Y.Z.zip`) to the GitHub Release.

## Working with AI agents

[`AGENTS.md`](AGENTS.md) describes the architecture, conventions and game rules
for AI coding agents (`CLAUDE.md` imports it). Claude Code slash commands for
common tasks (`/check`, `/add-string`, `/add-language`, `/change-rule`, `/ship`,
`/release`) live in [`.claude/commands/`](.claude/commands/).
