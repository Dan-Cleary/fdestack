---
name: value-frame
description: |
  Translate a scoped process inefficiency into a defensible dollar value with
  stated assumptions and sensitivity. Forces lever taxonomy, explicit unit
  economics, and a defensibility check. Vague items get pushed to unknowns.md
  HIGH so they surface in every future Session Brief until resolved.
  Usage: /value-frame <customer-name> <opportunity descriptor>
---

# /value-frame

Frame a customer opportunity in defensible dollar terms.

## Step 0: Parse inputs

The customer name is the first argument. Everything after it is the opportunity descriptor (e.g., "payment terms optimization", "ticket deflection from chatbot", "stockout reduction").

If no customer name is provided: ask "Which customer? (e.g. /value-frame acme <opportunity>)"
If no opportunity is provided: ask "What opportunity are we framing? Reference the latest /scope file or describe in one line."

Set `CUSTOMER_NAME` from the first argument.

## Step 1: Check session marker

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ -f "$MARKER" ]; then
  MARKER_TS=$(grep '^ts=' "$MARKER" | cut -d= -f2)
  NOW=$(date +%s)
  AGE=$(( NOW - MARKER_TS ))
  if [ "$AGE" -lt 43200 ]; then
    echo "MARKER_OK=true"
  else
    echo "MARKER_STALE=true AGE_H=$(( AGE / 3600 ))"
  fi
else
  echo "MARKER_MISSING=true"
fi
```

If `MARKER_MISSING=true` or `MARKER_STALE=true`:
> Run `/customer-context $CUSTOMER_NAME` first, then retry /value-frame.

Stop. Do not proceed.

## Step 2: Verify scope exists (recommended, not required)

```bash
SCOPE_COUNT=$(ls customers/$CUSTOMER_NAME/scope-*.md 2>/dev/null | wc -l | tr -d ' ')
echo "SCOPE_COUNT=$SCOPE_COUNT"
```

If `SCOPE_COUNT=0`: print
> No /scope file found for $CUSTOMER_NAME. /value-frame works best when the
> opportunity is already scoped — the scope file gives us the wedge size and
> success criteria to translate into value. You can proceed without one, but
> the resulting value frame may be harder to defend.
> Continue anyway? (yes / no)

If FDE says no, stop. If yes, proceed and note "no-scope" in the value-frame file's "Problem source" line.

## Step 3: Load cross-customer learnings

```bash
LEARNINGS_FILE="$HOME/.fdestack/learnings.jsonl"
if [ -f "$LEARNINGS_FILE" ] && [ -s "$LEARNINGS_FILE" ]; then
  tail -5 "$LEARNINGS_FILE" | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null || true
fi
```

Note any learnings that mention value framing patterns, customer industry, or this opportunity type.

## Step 4: Load context

Read in this order:
1. `customers/<name>/profile.md` — company size, industry, what numbers will land
2. `customers/<name>/stack.md` — data we have access to (which assumptions are computable vs. estimated)
3. Most recent `customers/<name>/scope-*.md` (if any) — the wedge problem this is framing value for
4. Most recent `customers/<name>/discovery-*.md` — stakeholder context (who's the audience, what numbers do they already throw around)
5. `customers/<name>/value-frame-*.md` (if any prior) — what we've already framed for this customer
6. `customers/<name>/decisions.md` — any methodological decisions already locked in

## Step 5: Identify the lever

Every value frame translates a process improvement into one of these levers. Force the FDE to pick exactly ONE primary lever. If two apply, the secondary one goes into "Additional Value" — never into the headline number.

| Lever | What it captures | Typical unit economics |
|---|---|---|
| **Time** | FTE hours freed, cycle time compressed | hours/week × $/hour × 52 weeks |
| **Errors** | Rework avoided, escalations prevented | error rate × $/error × annual volume |
| **Capital** | Working capital freed, inventory reduced | $ tied up × cost-of-capital × duration |
| **Volume** | Incremental revenue, throughput gains | incremental units × margin × probability |
| **Risk** | Compliance fines avoided, downtime prevented | P(event) × $/event annually |

Ask: "Which lever is this primarily about?" If the FDE answers "all of them" or "I'm not sure" or names something not in this taxonomy → mark `lever-unclear` for the unknowns loop.

## Step 6: State unit economics

For the chosen lever, write the formula explicitly. Examples:

- Time lever: `value = hours_saved_per_week × loaded_hourly_rate × 52`
- Capital lever: `value = working_capital_freed × cost_of_capital_pct × (days_held / 365)`
- Errors lever: `value = error_rate_pct × $_per_error × annual_volume`

If the formula has more than 4 terms, it's probably trying to do too much — ask the FDE to simplify or split into primary + additional.

## Step 7: Surface assumptions

Every term in the unit economics formula is either:
- **Measured** — comes from the customer's data, defensible
- **Stated** — comes from a public benchmark or industry source, defensible if cited
- **Estimated** — comes from FDE judgment, must be flagged

For each term, label it `[measured]`, `[stated: <source>]`, or `[estimated]`. If more than 50% of terms are `[estimated]`, mark `assumptions-thin` for the unknowns loop.

## Step 8: Compute headline + sensitivity

**Headline:** plug expected values into the formula. State the annualized number.

**Sensitivity:** compute three points unless the FDE has a reason to use a different range:
- **Conservative:** each assumption set 30% worse than expected
- **Likely:** expected values (= headline)
- **Aggressive:** each assumption set 30% better than expected

If the conservative and aggressive numbers are within ±15% of each other, the model is too smooth — the FDE is probably hiding uncertainty. Ask: "Where's the real uncertainty in this estimate?"

If they can't name it → mark `sensitivity-suspicious` for the unknowns loop.

## Step 9: Defensibility check

Ask the FDE: "If a skeptical CFO at $CUSTOMER_NAME sees this, what's the first thing they push back on?"

Categorize the answer:
- **Methodology** ("how did you arrive at the rate?") → fix by citing the source or marking the assumption explicitly
- **Numbers** ("that volume seems high") → fix by showing where it came from in their data
- **Strategic relevance** ("we already do this") → not a value-frame problem; this is a scoping problem. Push back to `/scope`.

If the FDE can't articulate a likely pushback → mark `defensibility-untested` for the unknowns loop.

## Step 10: Push vague items to unknowns.md HIGH

For each item flagged in Steps 5-9 (lever-unclear, assumptions-thin, sensitivity-suspicious, defensibility-untested), append a line to `customers/<name>/unknowns.md` under `## HIGH — Unknown, Blocking` with format:

```
- [value-frame-<DATE>] <description> — need answer to defend value to customer.
```

Update the `## Last Updated` line on unknowns.md.

If no vague items, do not modify unknowns.md.

## Step 11: Write the value-frame file

Set `FRAME_DATE=$(date +%Y-%m-%d)`. Handle collision with the same -2, -3 suffix pattern:

```bash
FRAME_FILE="customers/$CUSTOMER_NAME/value-frame-$FRAME_DATE.md"
if [ -f "$FRAME_FILE" ]; then
  i=2
  while [ -f "customers/$CUSTOMER_NAME/value-frame-$FRAME_DATE-$i.md" ]; do
    i=$((i + 1))
  done
  FRAME_FILE="customers/$CUSTOMER_NAME/value-frame-$FRAME_DATE-$i.md"
fi
```

Set `FDE_NAME="$(git config user.name)"`. Write:

```markdown
# Value frame: <opportunity title>
**Date:** <FRAME_DATE>
**FDE:** <FDE_NAME>
**Problem source:** <scope-YYYY-MM-DD.md, or "no-scope (ad-hoc)">
**Customer-side audience:** <CFO / CRO / Procurement Head / etc.>

## Opportunity (one sentence)
<the process inefficiency being framed>

## Primary Lever
<one of: Time / Errors / Capital / Volume / Risk>
<one-line justification for why this is the primary lever>

## Unit Economics
<formula with explicit variables>

## Assumptions
- **<term1>:** <value> [measured | stated: <source> | estimated]
- **<term2>:** <value> [measured | stated: <source> | estimated]
- **<term3>:** <value> [measured | stated: <source> | estimated]

## Headline
**$<X>/year** (annualized, likely case)

## Sensitivity
- Conservative (assumptions -30%): **$<Y>/year**
- Likely: **$<X>/year**
- Aggressive (assumptions +30%): **$<Z>/year**

<one sentence on where the real uncertainty lives>

## Defensibility
**Most likely pushback:** <methodology | numbers | strategic relevance>
**Specifically:** <what the customer would challenge>
**Response prepared:** <how the FDE plans to handle it>

## Additional Value (secondary, not in headline)
- <secondary lever if any — e.g., "also reduces ticket volume but not framed here">

## Open Items
<if any vague items pushed to unknowns.md, list them here for cross-reference>
<if none: "All checks passed.">
```

## Step 12: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "value-frame: $CUSTOMER_NAME $FRAME_DATE"
```

No confirmation prompt — the FDE just walked through Steps 5-10 interactively.

## Step 13: Summary

Print:
```
Value frame written: <FRAME_FILE>
Primary lever: <Time/Errors/Capital/Volume/Risk>
Headline: $<X>/year (sensitivity: $<Y> — $<Z>)
Defensibility pushback type: <methodology/numbers/strategic>

[if any items pushed to unknowns.md]
Unresolved items added to unknowns.md (HIGH):
  - <each>

Next:
  - If unresolved items: address them before the customer conversation
  - If clean: this number is ready to defend. /poc <customer> when you want to prove it
```
