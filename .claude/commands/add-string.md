---
description: Add a localized UI string to all supported languages
argument-hint: <key> <English text>
---

Add a new user-facing string: `$ARGUMENTS`

1. Read `lib/l10n/app_strings.dart`. Note the language maps (one per `AppStrings.supportedLocales` entry) in
   `_localizedValues` (currently `en sk cs ru de zh es ko tr fr ja` — confirm the order
   in the file) and `AppStrings.supportedLocales`.
2. Add the key next to related keys in **every** language map with a natural,
   child-friendly translation (the audience is ~7-year-olds). Keep placeholders
   like `{name}` identical across languages. Keep emoji consistent.
3. Add the accessor near similar ones:
   - plain: `String get myKey => _text('myKey');`
   - with values: `String myKey(String name) => _format('myKey', {'name': name});`
   - count-dependent: reuse/extend the plural helpers (`coinWord`,
     `_usesFewSlavicForm`, `_usesRussianOneForm`, `_usesRussianFewForm`).
4. Use it from widgets with `context.strings.myKey`.
5. Add or extend a test in `test/app_strings_test.dart` asserting the key is
   non-empty for every locale in `AppStrings.supportedLocales` (and that
   placeholders get substituted, if any).
6. Run `/check`.
