# 🧮 Math Master

A fun, kid-friendly math game that helps **2nd-grade** students practise the four
basic operations — addition, subtraction, multiplication and division — with all
numbers kept **under 100**. Built with **Flutter**, so the same code base runs on
**Android, iOS, web and desktop**.

## How to play

1. On the home screen choose your player. Players you've used before are
   remembered, so you can switch between them without retyping a name — and each
  player keeps their own **language** and **pet**.
2. Pick a challenge length (**1, 2 or 5 minutes**) and choose which operations to
   practise.
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
  fresh styles are generated on demand. Every style has a **fixed price
  (100–1000 coins)** that is identical for every player.
- Use **Customize buttons** to assign any style you own to each of the **six**
  answer-button positions. Your choices are saved for your next game.

### Pets

Each player can choose a cat, dog, panda or rabbit. The pet appears on the home
screen and reacts to care: when food drops below 20 points it looks hungry, and
when fun drops below 20 points it looks sad. Food drops by **100 points per day**
and fun drops by **20 points per day**.

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

- Division questions always divide evenly (e.g. `99 ÷ 3`, never `98 ÷ 3`).
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
```

> The platform folders (`android/`, `ios/`, `web/`, …) are generated with
> `flutter create .` and are intentionally not committed; the CI pipeline
> regenerates them before building.

## CI/CD

The [`CI` workflow](.github/workflows/ci.yml) runs on every push and pull
request and:

1. checks formatting, runs `flutter analyze` and `flutter test`;
2. builds the release **APK** and **App Bundle** and uploads them as artifacts;
3. builds the **web** version and uploads it as an artifact.
