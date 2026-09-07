#!/usr/bin/env bash
# Enforces the documentation prose standard: no emojis, no em-dashes.
# Unicode matching is done in Python because shell pattern matching over
# multibyte characters is unreliable across platforms.
set -euo pipefail

python3 - <<'PY'
import re, sys
from pathlib import Path

EMDASH = '\u2014'
EMOJI = re.compile('['
    '\U0001F300-\U0001FAFF'
    '\U00002600-\U000026FF'
    '\U00002700-\U000027BF'
    '\U00002B00-\U00002BFF'
    '\U0001F000-\U0001F02F'
    '\U00002705\U0000274C\U0000FE0F'
    ']')

emdash_files, emoji_files = [], []
for p in Path('.').rglob('*.md'):
    if '.git' in p.parts:
        continue
    text = p.read_text(encoding='utf-8')
    if EMDASH in text:
        emdash_files.append(str(p))
    if EMOJI.search(text):
        emoji_files.append(str(p))

if emdash_files:
    print("Em-dash (U+2014) found in:")
    for f in sorted(emdash_files):
        print(f"  {f}")
if emoji_files:
    print("Emoji found in:")
    for f in sorted(emoji_files):
        print(f"  {f}")

if emdash_files or emoji_files:
    print()
    print("The documentation standard is prose without emojis or em-dashes.")
    print("Substitute a comma or colon for an em-dash as the sentence requires.")
    sys.exit(1)

print("Prose standard satisfied.")
PY
