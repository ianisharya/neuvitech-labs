#!/usr/bin/env bash
# Rejects tracked files above a size limit. Large files in git history are
# retained permanently and are downloaded by every clone. Media belongs in
# object storage.
set -euo pipefail

LIMIT=$((2 * 1024 * 1024))
fail=0

while IFS= read -r f; do
  [ -f "$f" ] || continue
  size=$(wc -c < "$f")
  if [ "$size" -gt "$LIMIT" ]; then
    printf 'Exceeds 2 MB (%s bytes): %s\n' "$size" "$f"
    fail=1
  fi
done < <(git ls-files)

if [ "$fail" -ne 0 ]; then
  echo
  echo "Tracked files must remain under 2 MB. Media belongs in object storage."
  exit 1
fi

echo "File size limits satisfied."
