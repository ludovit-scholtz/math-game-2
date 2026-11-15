# Fonts for the screenshot generator

Used only by `tool/screenshots/store_screenshots_test.dart`; they are not part
of the app.

| File | Source | Licence |
| --- | --- | --- |
| `NotoColorEmoji-subset.ttf` | [Noto Color Emoji](https://github.com/googlefonts/noto-emoji) | SIL Open Font License 1.1 |
| `NotoSansSymbols2-subset.ttf` | [Noto Sans Symbols 2](https://github.com/notofonts/symbols) | SIL Open Font License 1.1 |
| `NotoSansCJK{jp,kr,sc}-{Regular,Bold}-subset.otf` | [Noto Sans CJK](https://github.com/notofonts/noto-cjk) | SIL Open Font License 1.1 |

These files are subsets that only contain the characters the app and the
screenshot captions show (the CJK fonts: those of their own language). They
are built by `python tool/screenshots/subset_fonts.py`. The licence text is at
<https://openfontlicense.org/open-font-license-official-text/>.
