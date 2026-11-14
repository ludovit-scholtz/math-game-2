---
description: Change a game rule and keep code, tests and docs in sync
argument-hint: <rule change, e.g. "division divisor 2..10">
---

Change this game rule: $ARGUMENTS

Rules live in `lib/logic/` (pure Dart) and `lib/models/`. See the "Game rules"
section of AGENTS.md for the current values.

1. Locate the rule (question_generator / scoring / game_controller / coins /
   player_profile pet decay) and change it. Prefer named constants over magic
   numbers; keep comments accurate (comments stating ranges must match the
   code exactly — check off-by-one in `nextInt(n)` bounds).
2. Update/add unit tests in `test/` asserting the new invariant, using a seeded
   `Random` and a few hundred iterations for randomised logic. Test the
   boundaries (min and max are both reachable, nothing outside the range).
3. Update every place that describes the rule:
   - `AGENTS.md` → "Game rules"
   - `README.md`
   - in-app Guide strings (`doc*Body`, `score*` keys) for **every locale** in `AppStrings.supportedLocales` in
     `lib/l10n/app_strings.dart`
   - `docs/description/*.md` if store text mentions it
4. Run `/check`.
