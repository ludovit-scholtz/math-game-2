#!/usr/bin/env python3
"""Builds the small emoji and symbol fonts the screenshot generator uses.

Widget tests have no system fonts, so the emoji and symbols the app shows
(coins, gems, medals, check marks, ...) need font files. This script downloads
Noto Color Emoji and Noto Sans Symbols 2 (both SIL Open Font License) and keeps
only the characters that appear in `lib/`, which turns 10 MB of fonts into a
few hundred kB that can live in the repository.

Japanese, Korean and Chinese text also needs a font. For these languages the
script downloads Noto Sans CJK (SIL Open Font License) and keeps only the
characters of that language's texts (app strings and screenshot captions).

Run it again when the app starts using a new emoji or symbol, or when texts
of these languages change:

    pip install fonttools
    python tool/screenshots/subset_fonts.py
"""
import re
import sys
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "tool" / "screenshots" / "fonts"

# (download, cached name, output). A character goes into the first font that
# has it: colour emoji first, then plain symbols such as the check mark.
SOURCES = [
    (
        "https://github.com/googlefonts/noto-emoji/raw/v2.047/fonts/NotoColorEmoji.ttf",
        "NotoColorEmoji.ttf",
        FONTS / "NotoColorEmoji-subset.ttf",
    ),
    (
        "https://github.com/notofonts/notofonts.github.io/raw/c16b117609abbe4e60b3f2bd4433bdb3d0accb2e/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf",
        "NotoSansSymbols2-Regular.ttf",
        FONTS / "NotoSansSymbols2-subset.ttf",
    ),
]

# Noto Sans CJK: language -> (folder, file prefix). Pinned to a commit.
CJK_COMMIT = "f8d157532fbfaeda587e826d4cd5b21a49186f7c"
CJK_BASE = f"https://github.com/notofonts/noto-cjk/raw/{CJK_COMMIT}/Sans/OTF"
CJK_LANGUAGES = {
    "ja": ("Japanese", "NotoSansCJKjp"),
    "ko": ("Korean", "NotoSansCJKkr"),
    "zh": ("SimplifiedChinese", "NotoSansCJKsc"),
}
CJK_WEIGHTS = ["Regular", "Bold"]
# Characters that the platform adds to dates and times (Material localizations).
CJK_EXTRA = "年月日時分秒午前後上下曜오전오후년월일시분"

# Arrows, technical symbols, dingbats and pictographs.
SYMBOLS = re.compile("[←-⇿⌀-⏿☀-➿⬀-⯿\U0001f000-\U0001faff]")


def language_texts(path, language, indent):
    """The source text of one language's block in a Dart map file."""
    text = path.read_text(encoding="utf-8")
    starts = [
        (m.start(), m.group(1))
        for m in re.finditer(rf"^{indent}'([a-z][a-z])': \{{", text, re.M)
    ]
    starts.append((len(text), None))
    for (begin, code), (end, _) in zip(starts, starts[1:]):
        if code == language:
            return text[begin:end]
    sys.exit(f"error: no '{language}' block in {path}")


def cjk_characters(language):
    texts = language_texts(ROOT / "lib" / "l10n" / "app_strings.dart", language, "    ")
    texts += language_texts(
        ROOT / "tool" / "screenshots" / "captions.dart", language, "  "
    )
    chars = {ch for ch in texts + CJK_EXTRA if 0x2E80 <= ord(ch) < 0x1F000}
    return chars


def build_cjk():
    for language, (folder, prefix) in CJK_LANGUAGES.items():
        wanted = {ord(ch) for ch in cjk_characters(language)}
        for weight in CJK_WEIGHTS:
            name = f"{prefix}-{weight}.otf"
            cache = ROOT / ".dart_tool" / name
            if not cache.exists():
                cache.parent.mkdir(parents=True, exist_ok=True)
                print(f"Downloading {CJK_BASE}/{folder}/{name}")
                urllib.request.urlretrieve(f"{CJK_BASE}/{folder}/{name}", cache)
            available = set(TTFont(str(cache)).getBestCmap())
            keep = sorted(wanted & available)
            options = subset.Options()
            options.layout_features = ["*"]
            options.notdef_outline = True
            font = subset.load_font(str(cache), options)
            subsetter = subset.Subsetter(options)
            subsetter.populate(unicodes=keep)
            subsetter.subset(font)
            out = FONTS / f"{prefix}-{weight}-subset.otf"
            subset.save_font(font, str(out), options)
            print(f"{out.relative_to(ROOT).as_posix()}: {out.stat().st_size // 1024} kB - {len(keep)} characters")


def main():
    build_cjk()
    used = set()
    for path in sorted((ROOT / "lib").rglob("*.dart")):
        used.update(SYMBOLS.findall(path.read_text(encoding="utf-8")))
    if not used:
        sys.exit("error: no emoji or symbols found in lib/")
    remaining = {ord(ch) for ch in used}

    for url, cached_name, out in SOURCES:
        cache = ROOT / ".dart_tool" / cached_name
        if not cache.exists():
            cache.parent.mkdir(parents=True, exist_ok=True)
            print(f"Downloading {url}")
            urllib.request.urlretrieve(url, cache)
        available = set(TTFont(str(cache)).getBestCmap())
        wanted = remaining & available
        remaining -= wanted
        if not wanted:
            sys.exit(f"error: nothing to take from {cached_name}")

        options = subset.Options()
        options.layout_features = ["*"]
        options.notdef_outline = True
        font = subset.load_font(str(cache), options)
        subsetter = subset.Subsetter(options)
        # Variation selector and joiner keep sequences such as
        # "shopping bags + VS16" shaping.
        subsetter.populate(unicodes=sorted(wanted | ({0x200D, 0xFE0F} & available)))
        subsetter.subset(font)
        out.parent.mkdir(parents=True, exist_ok=True)
        subset.save_font(font, str(out), options)
        names = " ".join(f"U+{cp:04X}" for cp in sorted(wanted))
        print(f"{out.relative_to(ROOT).as_posix()}: {out.stat().st_size // 1024} kB - {names}")

    if remaining:
        names = " ".join(f"U+{cp:04X}" for cp in sorted(remaining))
        sys.exit(f"error: no font has {names} - add a source for it")


if __name__ == "__main__":
    main()
