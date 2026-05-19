---
name: poc
description: |
  Build a throwaway proof-of-concept. Speed over quality. Hardcoded values OK,
  ugly code OK, no error handling beyond crash prevention. This code is NEVER
  going to production — /integrate will rebuild fresh. The skill's most
  important step is the learnings write-back at the end, which routes
  discoveries to stack.md / decisions.md / learnings.jsonl so /integrate can
  use them without ever reading POC code.

  Proactively invoke this skill after /scope when the FDE says "let me build
  a quick thing", "let me try this", "time to prototype", "let's hack
  something together", or otherwise indicates they're about to write
  throwaway code for a customer. Push back if no /scope exists yet.

  Usage: /poc <customer-name> [--purpose value|showcase|feasibility]
  Voice triggers: "build a poc", "throwaway prototype",
  "let me try this", "hack something together".
---

# /poc

Build a throwaway POC. Optimized for shipping signal fast, not code longevity.

## Step 0: Parse inputs

The customer name is the first argument.

Optional flag: `--purpose value | showcase | feasibility`
- **value** (default) — prove a financial case. POC must produce numbers defensible to a stakeholder. Hardcoded inputs OK, but the *output* must match what was framed in `/value-frame`.
- **showcase** — prove the demo path. POC must demo well in 60 seconds. Visual/UX matters more than correctness. Hardcoded happy path acceptable; failure modes ignored.
- **feasibility** — prove something is possible at all. POC must answer one yes/no question (can we do X?). Output is technical evidence, not a demo.

The three modes change what "done" means; pick deliberately. If unclear, ask the FDE: "What needs to be true Friday for this POC to have been worth the time?" Answer maps cleanly to one purpose.

Set `CUSTOMER_NAME` and `PURPOSE` (default `value`).

## Step 1: Check session marker

Same as `/scope` / `/discovery` / `/value-frame`:

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ -f "$MARKER" ]; then
  MARKER_TS=$(grep '^ts=' "$MARKER" | cut -d= -f2)
  AGE=$(( $(date +%s) - MARKER_TS ))
  [ "$AGE" -lt 43200 ] && echo "MARKER_OK=true" || echo "MARKER_STALE=true"
else
  echo "MARKER_MISSING=true"
fi
```

If missing or stale: print "Run /customer-context $CUSTOMER_NAME first." Stop.

## Step 2: Verify scope exists

```bash
SCOPE_COUNT=$(ls customers/$CUSTOMER_NAME/scope-*.md 2>/dev/null | wc -l | tr -d ' ')
```

If `SCOPE_COUNT=0`: print
> No /scope file found for $CUSTOMER_NAME. /poc needs binary success criteria
> to know when to stop. Run /scope $CUSTOMER_NAME <problem statement> first.

Stop. Do not proceed.

Read the most recent scope file. If it has `[NEEDS CLARIFICATION]` markers, print:
> The most recent scope has unresolved items in unknowns.md HIGH. Building
> a POC against ambiguous criteria usually wastes both the POC and the time.
> Resolve those items first or override with: /poc $CUSTOMER_NAME --force

Wait for FDE confirmation.

## Step 3: Load cross-customer learnings

```bash
tail -5 "$HOME/.fdestack/learnings.jsonl" 2>/dev/null | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null
```

Especially relevant: learnings tagged with the same purpose or similar tech stack. Surface them before coding starts — much cheaper to read a prior insight than rediscover it.

## Step 4: Load context

Read in this order:
1. Latest `customers/<name>/scope-*.md` — the success criteria
2. Latest `customers/<name>/value-frame-*.md` if present — for `--purpose value`, this defines what numbers the POC must produce
3. `customers/<name>/stack.md` — what tech the customer actually uses (POC should look like *their* stack as much as time allows)
4. `customers/<name>/decisions.md` — anything already locked in (don't relitigate)
5. `customers/<name>/profile.md` — for tone/audience awareness

## Step 5: Confirm POC defaults

State the defaults explicitly so the FDE can interrupt if they want a different shape:

```
POC defaults for $CUSTOMER_NAME (--purpose $PURPOSE):
  • Speed over quality. Hardcode values, no env config, no DB schemas
  • Error handling: crash prevention only. No retries, no fallbacks
  • Testing: smoke test that the happy path runs end-to-end. No unit tests
  • Code structure: single file/folder if possible, no premature abstraction
  • Documentation: a poc/README.md at the end. Nothing inline
  • This code will NEVER ship. /integrate will rebuild fresh.

Continue? (yes / let me redirect)
```

Wait for FDE.

## Step 6: Initialize POC directory

```bash
POC_DIR="customers/$CUSTOMER_NAME/poc"
mkdir -p "$POC_DIR"
```

If `$POC_DIR` already has content, ask: "POC directory already exists. Add to it / archive it as poc-prior-<timestamp>/ / overwrite?" Default to archive — never silently overwrite an FDE's prior work.

## Step 7: Build

Build the POC in `$POC_DIR/`. Apply the defaults from Step 5. Iterate with the FDE — they'll redirect when needed. Push back if the FDE proposes work that the chosen `$PURPOSE` doesn't require (e.g., asking for retries in a `--purpose showcase` POC, or asking for polish in a `--purpose feasibility` POC).

Track what's hardcoded, what's faked, and what's real — you'll need this in Step 9.

## Step 8: Write poc/README.md

```markdown
# POC: <one-line title>
**Date:** <YYYY-MM-DD>
**FDE:** <git user.name>
**Purpose:** <value | showcase | feasibility>
**Source scope:** <scope-YYYY-MM-DD.md>

## What this proves
<one sentence — what success criterion from scope.md does this satisfy?>

## How to demo it
<exact commands or click path. Should work on the FDE's laptop without further setup.>

## Shortcuts taken (do NOT carry to prod)
- Hardcoded: <list — values, API keys (placeholders), customer data substitutes>
- Faked: <list — services we mocked, data we synthesized>
- Skipped: <list — auth, error handling, retries, logging, etc.>

## What would need to change for production
<bullets — this is what /integrate will use as its starting point, alongside stack.md and decisions.md>
```

Notice: **this README documents the shortcuts so /integrate doesn't have to read the code**. The `## What would need to change for production` section IS the handoff.

## Step 9: MANDATORY learnings write-back

This is the most important step in the skill. Skipping it breaks the /integrate handoff.

Prompt the FDE:

> The POC is done. Before we wrap, three questions — your answers route into
> the customer context files so /integrate can use them without reading any
> POC code:
>
> 1. **What new technical fact did we learn about $CUSTOMER_NAME's environment?**
>    (Examples: an API has a lower rate limit than docs say, their auth proxy
>    requires a specific header, their data has nulls where their schema doesn't
>    admit them.) These go to `stack.md`.
>
> 2. **What design decision did we make, and why?**
>    (Examples: chose library X over Y because Z, used pattern A instead of B
>    because of constraint C.) These go to `decisions.md`.
>
> 3. **Did we discover anything that would apply to OTHER customers?**
>    (Examples: a class of bug specific to this CRM, a pattern that worked
>    surprisingly well, a vendor's docs being misleading.) These go to
>    `~/.fdestack/learnings.jsonl`.

Take each answer and route it:

**For stack.md:** append under the appropriate section (Infrastructure, Auth, Constraints, etc.). Update `## Last Updated`.

**For decisions.md:** prepend a new entry:
```markdown
## <YYYY-MM-DD>: <decision title>
**Context:** <what the POC was trying to achieve>
**Decision:** <what was chosen>
**Rationale:** <why — name the constraint or signal that drove this>
**Implications for /integrate:** <what should the production rebuild inherit / discard from this decision>
```

**For learnings.jsonl:** append with `jq -nc`:
```bash
jq -nc \
  --arg skill "poc" \
  --arg key "<short-kebab>" \
  --arg insight "<one sentence>" \
  --arg confidence "<1-10>" \
  --arg source "observed" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{skill:$skill,key:$key,insight:$insight,confidence:($confidence|tonumber),source:$source,ts:$ts}' \
  >> "$HOME/.fdestack/learnings.jsonl"
```

If the FDE answers "nothing" to all three questions, push back once: "Really? A POC that taught us nothing new is unusual — either we already knew this would work (in which case the POC was the wrong tool), or we're not paying attention. Any second thoughts?"

After the pushback, accept whatever they say. The point is to force the question, not to coerce an answer.

## Step 10: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "poc: $CUSTOMER_NAME <YYYY-MM-DD> (--purpose $PURPOSE)"
```

No confirmation prompt — the FDE just walked through the write-back step.

## Step 11: Summary

```
POC complete.
  Location: customers/<name>/poc/
  Purpose: <value/showcase/feasibility>
  Success criteria met: <list checkboxes from scope.md that this POC validates>

Learnings written back:
  stack.md: <N items>
  decisions.md: <N decisions>
  learnings.jsonl: <N cross-customer patterns>

Next: /integrate $CUSTOMER_NAME when ready to productionize.
  (/integrate will read scope + stack + decisions — it will NOT read the
   POC code. Anything important from the POC needs to be in the write-backs above.)
```
