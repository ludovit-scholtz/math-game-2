#!/usr/bin/env python3
"""Generates the store screenshots for every language of the app.

    python tool/screenshots/generate_all.py                  # all languages, all sizes
    python tool/screenshots/generate_all.py --locales sk,de  # some languages
    python tool/screenshots/generate_all.py --devices play-phone

The pictures are written to docs/screenshots/<language>/<store slot>/. Every
language takes about a minute. See docs/SCREENSHOTS.md.
"""
import argparse
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def available_locales():
    text = (ROOT / "tool" / "screenshots" / "captions.dart").read_text(encoding="utf-8")
    return re.findall(r"^  '([a-z][a-z])': \{", text, re.M)


def main():
    languages = available_locales()
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--locales",
        default=",".join(languages),
        help="comma separated language codes (default: %(default)s)",
    )
    parser.add_argument(
        "--devices",
        default="",
        help="comma separated store slots, e.g. play-phone (default: all)",
    )
    args = parser.parse_args()

    flutter = shutil.which("flutter")
    if flutter is None:
        sys.exit("error: flutter is not on the PATH")
    chosen = [code.strip() for code in args.locales.split(",") if code.strip()]
    unknown = [code for code in chosen if code not in languages]
    if unknown:
        sys.exit(f"error: no captions for {', '.join(unknown)} (known: {', '.join(languages)})")

    failed = []
    for code in chosen:
        started = time.time()
        command = [
            flutter,
            "test",
            "tool/screenshots/store_screenshots_test.dart",
            f"--dart-define=SCREENSHOT_LOCALE={code}",
        ]
        if args.devices:
            command.append(f"--dart-define=SCREENSHOT_DEVICES={args.devices}")
        print(f"== {code} ==", flush=True)
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
        if result.returncode != 0:
            failed.append(code)
            print(result.stdout[-3000:])
            print(result.stderr[-1000:])
        print(f"{code}: {'ok' if result.returncode == 0 else 'FAILED'} ({time.time() - started:.0f} s)", flush=True)

    if failed:
        sys.exit(f"error: failed for {', '.join(failed)}")
    print(f"Done: {len(chosen)} languages in docs/screenshots/")


if __name__ == "__main__":
    main()
