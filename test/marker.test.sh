#!/usr/bin/env bash
# Tests for session marker read/write/age behavior

set -e
PASS=0; FAIL=0

ok() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1"; FAIL=$(( FAIL + 1 )); }

CUSTOMER="test-marker-$$"
MARKER="/tmp/fdestack-session-$CUSTOMER"
trap 'rm -f "$MARKER"' EXIT

# --- Write marker ---

NOW=$(date +%s)
printf "ts=%s\n" "$NOW" > "$MARKER"

if [ -f "$MARKER" ]; then
  ok "marker file created"
else
  fail "marker file not created"
fi

# --- Read ts ---

MARKER_TS=$(grep '^ts=' "$MARKER" | cut -d= -f2)
if [ "$MARKER_TS" = "$NOW" ]; then
  ok "ts reads back correctly"
else
  fail "ts mismatch: got $MARKER_TS, want $NOW"
fi

# --- Age check: fresh marker passes ---

AGE=$(( $(date +%s) - MARKER_TS ))
if [ "$AGE" -lt 43200 ]; then
  ok "fresh marker passes age check"
else
  fail "fresh marker failed age check (age=$AGE)"
fi

# --- Age check: stale marker fails ---

STALE_TS=$(( NOW - 50000 ))  # ~13.9 hours ago
printf "ts=%s\n" "$STALE_TS" > "$MARKER"
STALE_MARKER_TS=$(grep '^ts=' "$MARKER" | cut -d= -f2)
STALE_AGE=$(( $(date +%s) - STALE_MARKER_TS ))
if [ "$STALE_AGE" -ge 43200 ]; then
  ok "stale marker correctly identified (age=${STALE_AGE}s)"
else
  fail "stale marker not detected (age=${STALE_AGE}s, want >=43200)"
fi

# --- Declined flag ---

printf "ts=%s\ndeclined=true\n" "$NOW" > "$MARKER"
DECLINED=$(grep '^declined=true' "$MARKER" 2>/dev/null || echo "")
if [ -n "$DECLINED" ]; then
  ok "declined flag reads back"
else
  fail "declined flag not found"
fi

# --- No declined flag when not set ---

printf "ts=%s\n" "$NOW" > "$MARKER"
NOT_DECLINED=$(grep '^declined=true' "$MARKER" 2>/dev/null || echo "")
if [ -z "$NOT_DECLINED" ]; then
  ok "no declined flag when not written"
else
  fail "unexpected declined flag in clean marker"
fi

# --- Missing marker ---

rm -f "$MARKER"
if [ ! -f "$MARKER" ]; then
  ok "missing marker correctly absent"
else
  fail "marker should be absent"
fi

echo ""
echo "marker: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
