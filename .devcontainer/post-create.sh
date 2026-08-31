#!/usr/bin/env bash
# Runs once after the container is created, on BOTH machines.
# Sprint 1: verify the toolchain and print versions so the Day 7
# cross-platform comparison is a copy/paste rather than a hunt.
set -euo pipefail

echo ""
echo "=============================================="
echo " NeuViTech Labs — Dev Container ready"
echo "=============================================="
printf "  python  %s\n" "$(python --version 2>&1 | cut -d' ' -f2)"
printf "  node    %s\n" "$(node --version)"
printf "  npm     %s\n" "$(npm --version)"
printf "  uv      %s\n" "$(uv --version | cut -d' ' -f2)"
printf "  psql    %s\n" "$(psql --version | awk '{print $3}')"
printf "  git     %s\n" "$(git --version | awk '{print $3}')"
printf "  make    %s\n" "$(make --version | head -1 | awk '{print $3}')"
echo "=============================================="
echo ""

# Dependencies only exist from Sprint 2 onward. Absence is expected now.
[ -f apps/api/pyproject.toml ] && { echo "Installing Python deps..."; (cd apps/api && uv sync); }
[ -f apps/web/package.json ]   && { echo "Installing Node deps...";   (cd apps/web && npm ci); }

echo "Next: run 'make help' to see available commands."
echo ""
