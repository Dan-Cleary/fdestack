#!/usr/bin/env bash
# Tests for git ops: drift detection, auto-commit, ops repo safety check patterns

set -e
PASS=0; FAIL=0

ok() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1"; FAIL=$(( FAIL + 1 )); }

# Create a temp ops repo to test against
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
git init -q -b main
git config user.email "test@fdestack.test"
git config user.name "FDEstack Test"

# --- Ops repo check: customers/ dir ---

if [ -d customers/ ]; then
  fail "customers/ should not exist yet"
else
  ok "no customers/ dir in fresh repo — safety check would fire"
fi

# Regression: the original `ls | head` pattern silently returned 0 even when
# customers/ was missing. Verify the corrected `[ -d ]` form actually flags it.
SAFETY_OUT=$([ -d customers/ ] && ls customers/ | head -3 || echo "NO_CUSTOMERS_DIR")
if [ "$SAFETY_OUT" = "NO_CUSTOMERS_DIR" ]; then
  ok "safety check fires on missing customers/ dir"
else
  fail "safety check did not fire (got: $SAFETY_OUT)"
fi

mkdir -p customers/acme
for f in profile stack stakeholders blockers unknowns decisions timeline; do
  echo "## Last Updated" > "customers/acme/$f.md"
done

if ls customers/ 2>/dev/null | grep -q acme; then
  ok "customers/ dir exists after setup"
else
  fail "customers/ dir not created correctly"
fi

# --- Drift detection: first session (no git history) ---

HAS_HISTORY=$(git log --oneline -1 -- "customers/acme/" 2>/dev/null || echo "")
if [ -z "$HAS_HISTORY" ]; then
  ok "first session: no git history detected"
else
  fail "expected no history, got: $HAS_HISTORY"
fi

# --- Drift detection: after commit, no changes ---

git add customers/
git commit -q -m "context: acme session 2026-05-18"

HAS_HISTORY=$(git log --oneline -1 -- "customers/acme/" 2>/dev/null || echo "")
if [ -n "$HAS_HISTORY" ]; then
  ok "git history exists after commit"
else
  fail "expected history after commit"
fi

DIFF=$(git diff HEAD -- "customers/acme/" 2>/dev/null)
if [ -z "$DIFF" ]; then
  ok "no drift after clean commit"
else
  fail "unexpected diff after clean commit"
fi

# --- Drift detection: after file change ---

echo "## New stack info" >> "customers/acme/stack.md"
DIFF=$(git diff HEAD -- "customers/acme/" 2>/dev/null)
if [ -n "$DIFF" ]; then
  ok "drift detected after file modification"
else
  fail "expected drift after modifying stack.md"
fi

# --- Auto-commit produces correct message format ---

git add customers/acme/
COMMIT_MSG="discovery: acme $(date +%Y-%m-%d)"
git commit -q -m "$COMMIT_MSG"
LAST_MSG=$(git log --oneline -1 --format=%s)
if echo "$LAST_MSG" | grep -q "^discovery: acme"; then
  ok "discovery commit message format correct"
else
  fail "commit message wrong: $LAST_MSG"
fi

# --- Ops repo remote check: no remote = safe ---

REMOTES=$(git remote -v 2>/dev/null | head -4)
if [ -z "$REMOTES" ]; then
  ok "no remotes in test repo — ops repo check passes"
fi

# --- learnings.jsonl: valid jq output ---

LEARNINGS_FILE="$TMPDIR/learnings.jsonl"
jq -nc \
  --arg skill "discovery" \
  --arg key "test-pattern" \
  --arg insight "A test insight for unit testing" \
  --arg confidence "7" \
  --arg source "observed" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{skill:$skill,key:$key,insight:$insight,confidence:($confidence|tonumber),source:$source,ts:$ts}' \
  >> "$LEARNINGS_FILE"

if [ -s "$LEARNINGS_FILE" ]; then
  ok "learnings.jsonl written successfully"
else
  fail "learnings.jsonl is empty"
fi

LINE=$(tail -1 "$LEARNINGS_FILE")
if echo "$LINE" | jq -e '.key == "test-pattern"' >/dev/null 2>&1; then
  ok "learnings entry parses correctly with jq"
else
  fail "learnings entry is not valid JSON or key mismatch"
fi

RENDERED=$(echo "$LINE" | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null)
if echo "$RENDERED" | grep -q "\[learning\] test-pattern:"; then
  ok "learnings renders correctly for Session Brief"
else
  fail "learnings render format wrong: $RENDERED"
fi

echo ""
echo "git-ops: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
