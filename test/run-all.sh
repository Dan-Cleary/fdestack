#!/usr/bin/env bash
# Run all FDEstack unit tests

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0; TOTAL_FAIL=0

run_suite() {
  local script="$1"
  local name="$(basename "$script")"
  echo "=== $name ==="
  if bash "$script"; then
    : # pass/fail counts printed by each suite
  fi
  echo ""
}

run_suite "$DIR/setup.test.sh"
run_suite "$DIR/marker.test.sh"
run_suite "$DIR/git-ops.test.sh"

echo "All suites done. Check output above for any FAIL lines."
