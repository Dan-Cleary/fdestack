# Scenario: drift detection between sessions

**Tests:** `/customer-context` Step 5 — git diff rendering when a previous session committed and files have changed since.

## Setup

1. Seed a temp ops repo with the Northwind fixture (`test/scenarios/northwind/expected/`).
2. Commit it (`context: northwind session 2026-04-15`).
3. Hand-edit two files (simulating an FDE editing notes directly):
   - Append a HIGH blocker to `blockers.md`
   - Update `stakeholders.md` (Sandeep last name discovered)
4. Re-run `/customer-context northwind`.

## Expected behavior

Step 5 emits a multi-file `git diff` showing both edits. Step 6 surfaces them as "DRIFT SINCE LAST SESSION."

## Result: PASS

Both file changes appeared in the diff (see `expected-diff.txt`). The path is exercised correctly — `git log --oneline -1 -- customers/northwind/` returned the prior commit (so HAS_HISTORY is set), then `git diff HEAD -- customers/northwind/` rendered the full multi-file diff.

## Test-setup gotcha worth noting

Initial attempts to edit `stakeholders.md` with `sed -i.bak 's/Sandeep (last name TBD)/Sandeep Iyer/'` silently no-op'd because the line is actually `**Sandeep** (last name TBD)` (markdown bold) and the pattern didn't match. This is irrelevant to the skill itself — but it's a reminder that any future test that programmatically pre-edits fixtures should `grep` to confirm the edit landed before running the assertion.
