#!/usr/bin/env bash
# Verifies that environment files holding real values are not tracked, and that
# the example template is. A committed environment file is a common cause of
# credential exposure.
set -euo pipefail

fail=0

while IFS= read -r f; do
  case "$f" in
    .env.example|*.env.example) continue ;;
    .env|.env.*|*/.env|*/.env.*)
      echo "Environment file is tracked: $f"
      fail=1
      ;;
  esac
done < <(git ls-files)

if [ "$fail" -ne 0 ]; then
  echo
  echo "Environment files hold real values and must not be committed."
  echo "Remove from tracking and confirm the ignore rules exclude them."
  echo "If a credential was committed, rotate it. Removal from a later commit"
  echo "does not remove it from history."
  exit 1
fi

if ! git ls-files --error-unmatch .env.example >/dev/null 2>&1; then
  echo "Note: .env.example is not tracked. It is the documented template for"
  echo "bootstrap configuration and should be tracked once it exists."
fi

echo "Environment file handling satisfied."
