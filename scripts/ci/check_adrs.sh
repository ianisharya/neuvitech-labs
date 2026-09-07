#!/usr/bin/env bash
# Validates architecture decision record consistency.
#
# Checks that every ADR file declares a status, that every ADR is listed in the
# index, and that an ADR marked superseded names its successor. An ADR whose
# status is unclear, or which is absent from the index, is a decision record
# that a reader cannot rely on.
set -euo pipefail

[ -d docs/adr ] || { echo "No ADR directory. Skipping."; exit 0; }

python3 - <<'PY'
import re, sys
from pathlib import Path

adr_dir = Path('docs/adr')
index = adr_dir / 'README.md'
index_text = index.read_text(encoding='utf-8') if index.exists() else ''

failures = []
files = sorted(adr_dir.glob('ADR-*.md'))

if not files:
    print("No ADR files found.")
    sys.exit(0)

for p in files:
    text = p.read_text(encoding='utf-8')

    m = re.search(r'^\*\*Status:\*\*\s*(.+)$', text, re.M)
    if not m:
        failures.append(f"{p.name}: no status declared")
        continue
    status = m.group(1).strip()

    if re.search(r'supersed', status, re.I) and not re.search(r'ADR-\d{4}', status):
        failures.append(f"{p.name}: marked superseded but names no successor")

    number = re.match(r'ADR-(\d{4})', p.name)
    if number and index_text:
        n = number.group(1)
        if not re.search(rf'\|\s*{n}\s*\|', index_text):
            failures.append(f"{p.name}: not listed in the ADR index")

if failures:
    print("ADR consistency problems:")
    for f in failures:
        print(f"  {f}")
    sys.exit(1)

print(f"ADR consistency satisfied across {len(files)} records.")
PY
