# Scenario: context conflict flagged, not silently overwritten

**Tests:** `/discovery` Step 5 (extract — identify conflicts) and Step 7 (update — preserve conflicting entries pending FDE reconciliation).

This is the integrity guarantee: if a transcript contradicts existing context, `/discovery` must NOT silently overwrite — it must surface the conflict so the FDE chooses.

## Setup

1. Pre-populate `customers/northwind/stakeholders.md` with intentionally-wrong info:
   - Maya Chen as "Engineering Manager" (transcript says Staff Engineer)
   - Tom Reilly as "VP Security" (transcript says Security & Compliance lead)
2. Leave Raj Patel as "VP Engineering" — matches transcript (control case).
3. Run `/discovery` on the Northwind kickoff transcript.

## Expected behavior

- `Sandeep Iyer` (new, no conflict) → appended to `stakeholders.md` Technical Contacts.
- `Maya Chen` and `Tom Reilly` entries → **NOT modified** in `stakeholders.md`.
- Discovery file `## Context Conflicts` section → lists both conflicts with format: `<who>: existing says X, transcript says Y. Ask FDE which is current.`
- Discovery file `## Updates Made` → explicitly notes "Maya and Tom entries LEFT UNCHANGED pending conflict resolution."
- `Raj Patel` (matches transcript) → no conflict flagged.

## Result: PASS

After the simulated run:
- `stakeholders.md` still says Maya is "Engineering Manager" and Tom is "VP Security" — preserved.
- Sandeep was appended cleanly.
- Discovery file lists both conflicts with the ask-FDE prompt.

The skill correctly distinguishes:
- **New info → append** (Sandeep)
- **Confirming info → no-op** (Raj)
- **Conflicting info → flag, don't overwrite** (Maya, Tom)

## Follow-up the SKILL doesn't yet specify

After `/discovery` flags conflicts, the FDE needs a way to reconcile. Currently the skill ends and assumes the FDE will manually edit `stakeholders.md`. Consider: should `/customer-context` on the next session detect unreconciled conflicts (perhaps by parsing the latest `discovery-*.md` for a `## Context Conflicts` section that's non-empty) and prompt for resolution? Not blocking — but worth thinking about before Phase 2.
