---
description: Run flutter analyze and flutter test, then fix any failures
argument-hint: [optional test file or path, e.g. test/scoring_test.dart]
allowed-tools: Bash(flutter analyze:*), Bash(flutter test:*), Bash(flutter pub get:*), Bash(dart format:*), Bash(git status:*), Bash(git diff:*), Bash(git fetch:*)
---

Verify the working tree is healthy.

1. Run `flutter pub get` if `.dart_tool/` is missing or `pubspec.yaml` changed.
2. Run `flutter analyze`. It must print `No issues found!`.
3. Run `flutter test` (or only `$ARGUMENTS` if a test path/name was given).
4. Formatting: run `dart format <file>` only on **newly added** `.dart` files
   (`git fetch -q origin main` then
   `git diff --name-only --diff-filter=A origin/main...HEAD -- '*.dart'`, plus
   untracked ones). For existing files, match the surrounding style by hand —
   the local formatter is newer than the code's and would rewrite whole files
   (see AGENTS.md → Commands).
5. If anything fails, find the root cause and fix it — don't weaken or delete
   tests to make them pass. Re-run until green.

Report: analyzer result, test count passed/failed, and any fixes you made.
