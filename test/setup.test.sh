#!/usr/bin/env bash
# Tests for fdestack setup script — symlink creation and ~/.fdestack init

set -e
PASS=0; FAIL=0

ok() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1"; FAIL=$(( FAIL + 1 )); }

FDESTACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# --- Symlink tests ---

for skill in customer-context discovery scope value-frame poc integrate triage engagement-retro; do
  target="$SKILLS_DIR/$skill/SKILL.md"
  if [ -L "$target" ]; then
    ok "symlink exists: $skill/SKILL.md"
  else
    fail "symlink missing: $skill/SKILL.md (run ./setup first)"
  fi

  if [ -f "$target" ]; then
    ok "symlink resolves: $skill/SKILL.md"
  else
    fail "symlink broken: $skill/SKILL.md"
  fi

  resolved=$(readlink -f "$target" 2>/dev/null || realpath "$target" 2>/dev/null)
  expected="$FDESTACK_DIR/skills/$skill/SKILL.md"
  if [ "$resolved" = "$expected" ]; then
    ok "symlink target correct: $skill"
  else
    fail "symlink target wrong: $skill — got $resolved, want $expected"
  fi
done

# --- ~/.fdestack init ---

if [ -d "$HOME/.fdestack" ]; then
  ok "~/.fdestack directory exists"
else
  fail "~/.fdestack directory missing"
fi

if [ -f "$HOME/.fdestack/learnings.jsonl" ]; then
  ok "learnings.jsonl exists"
else
  fail "learnings.jsonl missing"
fi

# --- Template files ---

for tpl in profile stack stakeholders blockers unknowns decisions timeline; do
  if [ -f "$FDESTACK_DIR/templates/$tpl.md" ]; then
    ok "template exists: $tpl.md"
  else
    fail "template missing: $tpl.md"
  fi
done

echo ""
echo "setup: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
