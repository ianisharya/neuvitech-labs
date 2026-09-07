#!/usr/bin/env bash
# Validates Markdown structure: balanced code fences and a single top-level
# heading per document. An unbalanced fence renders the remainder of a document
# as a code block, which is a silent failure in review.
set -euo pipefail

python3 - <<'PY'
import re, sys
from pathlib import Path

failures = []
for p in sorted(Path('.').rglob('*.md')):
    if '.git' in p.parts:
        continue
    lines = p.read_text(encoding='utf-8').splitlines()
    fences = sum(1 for l in lines if l.startswith('```'))
    if fences % 2:
        failures.append(f"{p}: {fences} code fences, unbalanced")
    h1 = sum(1 for l in lines if l.startswith('# '))
    if h1 == 0:
        failures.append(f"{p}: no top-level heading")

if failures:
    print("Markdown structure problems:")
    for f in failures:
        print(f"  {f}")
    sys.exit(1)

print("Markdown structure valid.")
PY
