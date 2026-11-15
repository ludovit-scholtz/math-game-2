---
description: Add a new supported language end-to-end
argument-hint: <ISO 639-1 code, e.g. pl>
---

Add support for language `$ARGUMENTS`.

1. `lib/l10n/app_strings.dart`:
   - Add `Locale('$ARGUMENTS')` to `supportedLocales` (keep alphabetical order).
   - Add a full `'$ARGUMENTS': { ... }` map to `_localizedValues` with **every**
     key the `'en'` map has (diff the key sets — none may be missing).
   - Add the language to `languageName` and `languageIcon`.
   - Add a case to `_coinBalancePrefix` and handle plurals in `coinWord`
     (check the language's CLDR plural rules; add a helper if needed).
   - Check every other `switch (_languageCode)` in the file.
2. Create `docs/description/$ARGUMENTS.md` (copy structure of `index.md`) and
   `docs/privacy-policy/$ARGUMENTS.md` (translate `index.md` faithfully; keep the
   effective date).
3. Confirm `flutter_localizations` supports the locale (Material/Cupertino
   delegates are already registered).
4. Update the language list in `README.md` / `AGENTS.md` if they enumerate
   languages.
   Store screenshots: add the language's eight captions to
   `tool/screenshots/captions.dart`, add it to the `locale` matrix of the
   `store-screenshots` job in `.github/workflows/ci.yml`, and if the language
   uses a script that Roboto cannot draw (like Japanese, Korean or Chinese) add
   a font in `tool/screenshots/subset_fonts.py` (see `docs/SCREENSHOTS.md`).
5. Tests: the existing loops over `AppStrings.supportedLocales` must pass; add a
   widget test rendering the home screen in the new locale (see
   `test/widget_smoke_test.dart` German example).
6. Run `/check`.
