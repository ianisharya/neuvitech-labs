#!/usr/bin/env bash
# Reports the toolchain. A missing tool is reported, not fatal — the point of
# this script is to tell you what is wrong, so it must survive things being wrong.
#
# Run this on both machines on Day 7 and compare the output line by line.
# Any difference is a bug in .devcontainer/ and is fixed there. Never work
# around a difference locally: that reintroduces exactly the drift the
# container exists to prevent.

check() {
  local name="$1" cmd="$2" extract="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "  %-12s %s\n" "$name" "$(eval "$extract" 2>/dev/null || echo '?')"
  else
    printf "  %-12s MISSING\n" "$name"
    MISSING=$((MISSING + 1))
  fi
}

MISSING=0
check python    python    "python --version 2>&1 | cut -d' ' -f2"
check node      node      "node --version | tr -d v"
check npm       npm       "npm --version"
check uv        uv        "uv --version | awk '{print \$2}'"
check psql      psql      "psql --version | awk '{print \$3}'"
check redis-cli redis-cli "redis-cli --version | awk '{print \$2}'"
check git       git       "git --version | awk '{print \$3}'"
check make      make      "make --version | head -1 | awk '{print \$3}'"
check jq        jq        "jq --version | tr -d 'jq-'"
check docker    docker    "docker --version | awk '{print \$3}' | tr -d ,"

echo ""
if [ "$MISSING" -gt 0 ]; then
  echo "  $MISSING tool(s) missing. If you are inside the Dev Container this is a"
  echo "  bug in .devcontainer/Dockerfile — report it, do not install by hand."
  exit 1
fi
echo "  All tools present."
