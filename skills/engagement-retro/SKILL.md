---
name: engagement-retro
description: |
  Weekly retrospective for a single customer engagement. Reads commit history,
  recent discovery/scope/value-frame/poc/integrate files, and current
  blockers/unknowns. Produces a structured retro: what shipped, what's stuck,
  what we learned, what's next. Optional cross-customer learnings write-back
  for patterns worth remembering. Distinct from gstack's /retro (which is
  engineering-retro per-codebase).

  Proactively invoke this skill on Fridays or end-of-week, or when the FDE
  asks "where did the week go", "weekly retro", "what shipped this week",
  or seems to be wrapping up an engagement phase. Always per-customer —
  use /triage for the portfolio view.

  Usage: /engagement-retro <customer-name> [--since <YYYY-MM-DD>]
  Voice triggers: "weekly retro", "where did the week go",
  "what shipped this week", "wrap up <customer>".
---

# /engagement-retro

Weekly per-customer retrospective. Honest snapshot of what happened, what's stuck, what we learned.

## Step 0: Parse inputs

The customer name is the first argument.

Optional flag: `--since <YYYY-MM-DD>`. Default: 7 days ago (`$(date -v-7d +%Y-%m-%d)` on macOS / `$(date -d '7 days ago' +%Y-%m-%d)` on Linux).

Set `CUSTOMER_NAME` and `SINCE_DATE`.

## Step 1: Check session marker

Same gate as /scope / /discovery / /poc / /integrate / /value-frame:

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ ! -f "$MARKER" ]; then echo "MARKER_MISSING=true"; fi
MARKER_TS=$(grep '^ts=' "$MARKER" 2>/dev/null | cut -d= -f2)
AGE=$(( $(date +%s) - ${MARKER_TS:-0} ))
[ "$AGE" -lt 43200 ] && [ -n "$MARKER_TS" ] && echo "MARKER_OK=true" || echo "MARKER_STALE_OR_MISSING=true"
```

If missing/stale: "Run /customer-context $CUSTOMER_NAME first." Stop.

## Step 2: Collect activity since SINCE_DATE

```bash
CUSTOMER_DIR="customers/$CUSTOMER_NAME"

# Commits touching this customer
COMMITS=$(git log --since="$SINCE_DATE" --oneline -- "$CUSTOMER_DIR/" 2>/dev/null)
COMMIT_COUNT=$(echo "$COMMITS" | grep -c . || echo 0)

# Files modified in window
MODIFIED=$(git log --since="$SINCE_DATE" --name-only --format= -- "$CUSTOMER_DIR/" 2>/dev/null | sort -u | grep -v '^$')

# Discovery / scope / value-frame / poc artifacts written this week
NEW_DISCOVERY=$(ls -t "$CUSTOMER_DIR"/discovery-*.md 2>/dev/null | while read f; do
  ft=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f"); st=$(date -j -f %Y-%m-%d "$SINCE_DATE" +%s 2>/dev/null || date -d "$SINCE_DATE" +%s)
  [ "$ft" -gt "$st" ] && echo "$f"
done)
# (similar for scope-*.md, value-frame-*.md, poc commit, integrate commit)
```

Capture: `COMMITS`, `MODIFIED`, `NEW_DISCOVERY`, `NEW_SCOPE`, `NEW_VALUE_FRAME`, `POC_RAN`, `INTEGRATE_RAN`.

## Step 3: Load current state

Read:
- `profile.md` — engagement context
- `blockers.md` — HIGH section (what's still in the way)
- `unknowns.md` — HIGH section (what's still unanswered)
- `timeline.md` — Upcoming section (what's next)
- `decisions.md` — most recent 5 entries (what we just decided)

## Step 4: Walk the FDE through the retro

Ask the FDE four questions in sequence. These map to the four sections of the output file.

### Question 1: What shipped?

Summarize from the activity in Step 2:
```
This week, customers/<name>/ saw <N> commits across <M> files:
  - <key commit message 1>
  - <key commit message 2>
  ...
Artifacts: <N discoveries, M scopes, K value-frames>, POC: <yes/no>, integrate: <yes/no>

Did anything ship that's not in this list?
```

Collect FDE additions (e.g., "Maya signed off on the ACL design out-of-band — no commit yet" or "we delivered the executive readout").

### Question 2: What's stuck?

Surface the HIGH blockers and HIGH unknowns from Step 3:
```
Carrying into next week:

HIGH BLOCKERS:
  - <bullet>

HIGH UNKNOWNS:
  - <bullet>
  - [scope-...] <bullet>
  - [value-frame-...] <bullet>

Of these, which moved this week vs. which are still where they were last week?
```

The audit-trail tags ([scope-...], [value-frame-...]) are especially worth checking — if the same one shows up week after week, that's a pattern that needs a different intervention.

### Question 3: What did we learn?

```
This week's decisions.md entries:
  - <2026-XX-XX>: <title>
  - <2026-XX-XX>: <title>

Did anything happen that should be a learning for OTHER customers?
(Examples: a vendor docs gap, a pattern that worked, a class of bug.)
```

If yes, route to `~/.fdestack/learnings.jsonl` (same jq pattern as /poc Step 9). This is how the retro feeds cross-customer learning — most patterns aren't visible inside a single POC; they're visible across weeks of work.

### Question 4: What's next?

```
Next 14 days from timeline.md Upcoming:
  - <date>: <event>

What needs to be true at the next milestone for it to be considered a win?
```

This is a forward-looking question. The answer often surfaces NEW unknowns that should be appended to `unknowns.md` HIGH — e.g., "we need to confirm Tom's team can review the SOC2 docs by Wednesday." If so, append them (same pattern as /scope Step 8).

## Step 5: Write the retro file

Set `RETRO_DATE=$(date +%Y-%m-%d)`. Handle collision with the same -2, -3 suffix pattern:

```bash
RETRO_FILE="customers/$CUSTOMER_NAME/retro-$RETRO_DATE.md"
if [ -f "$RETRO_FILE" ]; then
  i=2
  while [ -f "customers/$CUSTOMER_NAME/retro-$RETRO_DATE-$i.md" ]; do i=$((i + 1)); done
  RETRO_FILE="customers/$CUSTOMER_NAME/retro-$RETRO_DATE-$i.md"
fi
```

Set `FDE_NAME="$(git config user.name)"`. Write:

```markdown
# Engagement retro: <customer> — week of <SINCE_DATE> → <RETRO_DATE>
**FDE:** <FDE_NAME>
**Window:** <SINCE_DATE> to <RETRO_DATE> (<N> days)

## Shipped
- <bullet>
- <bullet>

(Activity: <N> commits, <M> artifacts: <discoveries / scopes / value-frames / poc / integrate>)

## Stuck
**HIGH blockers:**
- <bullet> — <"new this week" | "carrying from prior week" | "older — flagging">

**HIGH unknowns:**
- <bullet> — <same annotation>

Items appearing 2+ retros in a row are flagged for escalation:
- <bullet, if any>

## Learned
**Decisions made:**
- <YYYY-MM-DD>: <title> — <one-line>

**Cross-customer learnings written back:**
- <key>: <insight>  *(if any pushed to ~/.fdestack/learnings.jsonl)*
- <"None this week" if no cross-customer pattern emerged>

## Next
**Upcoming milestones (next 14d):**
- <date>: <event>

**What needs to be true at the next milestone:**
- <bullet — the FDE's answer to Q4>

**New unknowns surfaced this retro:**
- <if any appended to unknowns.md>
```

## Step 6: Update unknowns.md if needed

For any new items surfaced in Q4, append to `customers/<name>/unknowns.md` under `## HIGH — Unknown, Blocking` with format:

```
- [retro-<RETRO_DATE>] <description> — surfaced in retro, need answer before next milestone.
```

## Step 7: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "engagement-retro: $CUSTOMER_NAME $RETRO_DATE"
```

## Step 8: Summary

```
Retro written: <RETRO_FILE>
Window: <SINCE_DATE> → <RETRO_DATE>

Activity:
  Commits: <N>
  Artifacts: <list>

Shipped: <N items>
Stuck: <N HIGH blockers + N HIGH unknowns>
Learned: <N decisions + N cross-customer learnings>
Next: <N upcoming milestones>

[if any items repeat across retros]
Pattern alert: <item> has appeared in <N> consecutive retros. Consider escalating.

Next:
  - /triage to see this customer in portfolio context
  - /customer-context <next-customer> to move to your next engagement
```
