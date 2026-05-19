---
name: triage
description: |
  Cross-customer dashboard. Scan every customers/<name>/ directory, surface
  the highest-urgency blockers and unresolved unknowns across the FDE's
  portfolio. Optional filter to one cohort. No session marker required —
  this skill is the "where do I look first today?" view.

  Proactively invoke this skill at the start of a session in an FDE ops repo
  when no specific customer has been named, OR when the FDE asks "where should
  I look first", "what's most urgent", "what's on my plate today", or any
  variant of "what should I be working on?".

  Usage: /triage [active|blocked|all]
  Voice triggers: "what's urgent", "where do I look first",
  "what should I work on", "what's on my plate".
---

# /triage

Multi-customer portfolio view. Answer: where should the FDE spend the next hour?

## Step 0: Parse cohort filter

Optional first argument: `active | blocked | all`. Default: `active`.

- **active** — customers with at least one commit to their dir in the last 14 days
- **blocked** — customers with at least one HIGH blocker or HIGH unknown
- **all** — every customer dir, regardless of recency

Set `COHORT` from the argument or default to `active`.

## Step 1: NO session marker check

Unlike `/discovery` / `/scope` / `/poc` / `/integrate` / `/value-frame`, /triage runs without requiring `/customer-context` first. It's the *meta* view — the FDE is deciding which customer to load context for. Requiring a per-customer marker here is backwards.

## Step 2: List customers

```bash
CUSTOMERS=$(ls -d customers/*/ 2>/dev/null | xargs -n1 basename 2>/dev/null)
COUNT=$(echo "$CUSTOMERS" | grep -c . || echo 0)
echo "FOUND_CUSTOMERS=$COUNT"
```

If `FOUND_CUSTOMERS=0`: "No customers/ subdirectories. Run /customer-context <name> for your first customer." Stop.

## Step 3: Context-window guard

If `FOUND_CUSTOMERS > 10` AND `COHORT=all`:

> You have $COUNT customers. Loading profile.md + blockers.md + unknowns.md
> for all of them may exhaust the context window. Filter to a smaller cohort?
> Options: active (last 14d) / blocked (HIGH items only) / all (proceed anyway).

Wait for FDE response. Default to `active` if they don't pick.

## Step 4: Apply cohort filter

For `active`:
```bash
ACTIVE_CUSTOMERS=""
for c in $CUSTOMERS; do
  LAST=$(git log -1 --format=%ct -- "customers/$c/" 2>/dev/null)
  if [ -n "$LAST" ] && [ $(( $(date +%s) - LAST )) -lt 1209600 ]; then
    ACTIVE_CUSTOMERS="$ACTIVE_CUSTOMERS $c"
  fi
done
```

For `blocked`:
```bash
BLOCKED_CUSTOMERS=""
for c in $CUSTOMERS; do
  HIGH=$(grep -A100 '^## HIGH' "customers/$c/blockers.md" "customers/$c/unknowns.md" 2>/dev/null | grep -c '^- ' || echo 0)
  [ "$HIGH" -gt 0 ] && BLOCKED_CUSTOMERS="$BLOCKED_CUSTOMERS $c"
done
```

For `all`: use the full `$CUSTOMERS` list.

## Step 5: Load + extract per customer

For each customer in the filtered cohort, read:
- `customers/<name>/profile.md` — for the company one-liner and engagement stage
- `customers/<name>/blockers.md` — HIGH section only
- `customers/<name>/unknowns.md` — HIGH section only
- `customers/<name>/timeline.md` — for upcoming key dates

Extract:
- `STAGE`: from profile.md "Engagement Context" — POV / Integration / Production / Renewal / etc.
- `HIGH_BLOCKERS[name]`: bullets under `## HIGH` in blockers.md
- `HIGH_UNKNOWNS[name]`: bullets under `## HIGH` in unknowns.md (including any `[scope-...]` and `[value-frame-...]` audit-tagged items)
- `UPCOMING[name]`: items under `## Upcoming` in timeline.md, especially any with dates in the next 14 days

## Step 6: Compute urgency score per customer

Rough scoring — the goal is ranking, not precision:

```
urgency = (HIGH_BLOCKERS_count × 3)
       + min(HIGH_UNKNOWNS_count, 5) × 2
       + (UPCOMING_within_7_days × 10)
       + (DAYS_SINCE_LAST_COMMIT > 7 ? -1 : 0)
```

Two design choices worth noting:

1. **Unknown count is capped at 5.** A customer accumulating 12 HIGH unknowns isn't 6x more urgent than one with 2 — it's a sign the customer has been neglected, not a sign of imminent crisis. Capping prevents discovery-stage customers (which naturally have many open questions) from shadowing integration-stage customers facing real deadlines.

2. **Within-7d items dominate.** Each weighs 10, so a single imminent deadline (1 × 10 = 10) outweighs 5 unknowns (5 × 2 = 10) and ties 3 blockers (3 × 3 = 9). A near-term deadline almost always trumps accumulated unresolved items.

## Step 7: Print Triage Brief

Sort customers descending by urgency. Print:

```
════════════════════════════════════════════════════════════
TRIAGE: <COHORT> cohort | <COUNT> customers | <DATE>
════════════════════════════════════════════════════════════

[for each customer, ranked by urgency:]
▶ <name> — <one-line from profile> — <STAGE>
  Urgency: <score>
  HIGH blockers:
    - <bullet>
    - <bullet>
  HIGH unknowns:
    - <bullet>
  Upcoming (next 14d):
    - <date>: <event>
  Last activity: <N days ago>

[footer]
RECOMMENDED FIRST ACTION:
  <top-ranked customer's most urgent item>
════════════════════════════════════════════════════════════
```

If `[scope-*]` or `[value-frame-*]` tagged items appear in HIGH unknowns, note them — those are the audit trail from earlier skills. They're disproportionately worth resolving because they're blocking forward progress on already-scoped work.

## Step 8: No file writes, no commit

/triage is read-only. It does NOT:
- Modify any customer file
- Commit anything to the repo
- Write a session marker for any customer

The FDE chooses where to focus, then runs `/customer-context <name>` to enter a per-customer session.

## Step 9: Suggest next step

After the brief, print:

```
Next:
  /customer-context <name>   # enter session for top-ranked customer
  /triage blocked            # narrow to only blocked customers
  /triage all                # see every customer regardless of activity
```
