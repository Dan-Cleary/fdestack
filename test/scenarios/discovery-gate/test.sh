#!/usr/bin/env bash
# Automated test: /discovery refuses when session marker is missing or stale.

set -e
PASS=0; FAIL=0

ok() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1"; FAIL=$(( FAIL + 1 )); }

CUSTOMER="gate-test-$$"
MARKER="/tmp/fdestack-session-$CUSTOMER"
trap 'rm -f "$MARKER"' EXIT

# Step 1 logic from skills/discovery/SKILL.md:
#   if marker missing OR age >= 43200s → refuse + redirect to /customer-context
#   if marker present AND age < 43200s → proceed

check_gate() {
  local marker="$1"
  if [ ! -f "$marker" ]; then
    echo "MARKER_MISSING"
    return
  fi
  local ts age now
  ts=$(grep '^ts=' "$marker" | cut -d= -f2)
  now=$(date +%s)
  age=$(( now - ts ))
  if [ "$age" -ge 43200 ]; then
    echo "MARKER_STALE"
  else
    echo "MARKER_OK"
  fi
}

# Case 1: marker missing → MARKER_MISSING (refuse)
rm -f "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_MISSING" ] && ok "missing marker triggers refuse" || fail "missing marker — got $RESULT"

# Case 2: marker fresh (just now) → MARKER_OK (proceed)
printf "ts=%s\n" "$(date +%s)" > "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_OK" ] && ok "fresh marker allows /discovery to proceed" || fail "fresh marker — got $RESULT"

# Case 3: marker just under 12h old → MARKER_OK (proceed)
printf "ts=%s\n" "$(( $(date +%s) - 43000 ))" > "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_OK" ] && ok "marker at 11h57m allows proceed" || fail "11h57m marker — got $RESULT"

# Case 4: marker exactly at 12h → MARKER_STALE (refuse)
printf "ts=%s\n" "$(( $(date +%s) - 43200 ))" > "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_STALE" ] && ok "marker at exactly 12h refuses" || fail "12h marker — got $RESULT"

# Case 5: marker 24h old → MARKER_STALE (refuse)
printf "ts=%s\n" "$(( $(date +%s) - 86400 ))" > "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_STALE" ] && ok "24h-old marker refuses" || fail "24h marker — got $RESULT"

# Case 6: marker with declined=true flag still gates by age normally
printf "ts=%s\ndeclined=true\n" "$(date +%s)" > "$MARKER"
RESULT=$(check_gate "$MARKER")
[ "$RESULT" = "MARKER_OK" ] && ok "fresh marker with declined=true still allows proceed" || fail "declined+fresh — got $RESULT"

echo ""
echo "discovery-gate: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
