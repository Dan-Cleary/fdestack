---
name: integrate
description: |
  Production-grade implementation. Reads scope.md + stack.md + decisions.md +
  value-frame.md. EXPLICITLY DOES NOT READ customers/<name>/poc/ — that
  directory is throwaway. POC discoveries reach /integrate via the learnings
  write-back that /poc performs into stack.md and decisions.md.

  Proactively invoke this skill after /poc has run AND its learnings write-back
  is complete when the FDE says "let's productionize", "time to integrate",
  "build the real thing", or "cleanroom rebuild". Refuse to run if no /poc
  exists yet — surface the gap rather than building blind.

  Usage: /integrate <customer-name>
  Voice triggers: "productionize", "build the real thing",
  "integrate this", "cleanroom rebuild".
---

# /integrate

Build the production version. Cleanroom rebuild from the customer context files — never from POC code.

## Step 0: Parse inputs

The customer name is the first argument. No optional flags — `/integrate` has one mode (production).

Set `CUSTOMER_NAME`.

## Step 1: Check session marker

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ ! -f "$MARKER" ]; then echo "MARKER_MISSING=true"; fi
MARKER_TS=$(grep '^ts=' "$MARKER" 2>/dev/null | cut -d= -f2)
AGE=$(( $(date +%s) - ${MARKER_TS:-0} ))
[ "$AGE" -lt 43200 ] && [ -n "$MARKER_TS" ] && echo "MARKER_OK=true" || echo "MARKER_STALE_OR_MISSING=true"
```

If missing or stale: "Run /customer-context $CUSTOMER_NAME first." Stop.

## Step 2: Verify prerequisites

```bash
SCOPE_COUNT=$(ls customers/$CUSTOMER_NAME/scope-*.md 2>/dev/null | wc -l | tr -d ' ')
POC_COUNT=$(ls -d customers/$CUSTOMER_NAME/poc 2>/dev/null | wc -l | tr -d ' ')
echo "SCOPE_COUNT=$SCOPE_COUNT POC_COUNT=$POC_COUNT"
```

- `SCOPE_COUNT=0` → REFUSE: "No /scope file. /integrate requires the scope's binary success criteria as its acceptance bar."
- `POC_COUNT=0` → WARN: "No POC found for $CUSTOMER_NAME. /integrate can run without one, but typically /poc proved feasibility first and wrote learnings back to stack.md and decisions.md. Confirm you want to proceed without that signal? (yes / let me run /poc first)"

## Step 3: Hard rule — DO NOT READ THE POC DIRECTORY

This is the most important rule in this skill. Print it to the FDE so they know what's about to happen:

> /integrate is a cleanroom rebuild. I will NOT read `customers/$CUSTOMER_NAME/poc/`
> — not the code, not the README, not the demo script. Anything the POC taught
> us must already be in:
>   • stack.md (technical facts about the customer's environment)
>   • decisions.md (design decisions and their rationale)
>   • value-frame.md (the value bar the production code must defend)
>
> If you find yourself wanting me to "just look at the POC for a sec," that's
> a signal that /poc's learnings write-back step skipped something important.
> Stop /integrate, finish the write-back, then restart.

This is enforced behaviorally, not by file-system permissions. **You as the model must refuse to read any file under `customers/<name>/poc/` for the duration of this skill.** If the FDE pastes POC code into the conversation, acknowledge but do not adopt: "I see this, but per the /integrate contract I'm not going to copy from it. If there's a constraint or pattern here that should inform the production build, capture it in stack.md or decisions.md first, then we'll continue."

## Step 4: Load cross-customer learnings

```bash
tail -10 "$HOME/.fdestack/learnings.jsonl" 2>/dev/null | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null
```

Production-relevant learnings — auth quirks, rate limits, vendor docs gaps — should inform the build.

## Step 5: Load context (everything EXCEPT poc/)

Read in this order:
1. Latest `customers/<name>/scope-*.md` — success criteria. These are the acceptance tests.
2. Latest `customers/<name>/value-frame-*.md` — the dollar bar production code must defend.
3. `customers/<name>/stack.md` — the customer's actual tech, including anything /poc wrote back about constraints.
4. `customers/<name>/decisions.md` — design decisions to inherit, with their rationale.
5. `customers/<name>/profile.md` — audience and stakes.
6. Latest `customers/<name>/discovery-*.md` — for stakeholder context (who reviews this, who runs it post-handoff).

**Do not list `customers/<name>/poc/`. Do not Read any file under it.** Treat the directory as not existing for the purposes of this skill.

## Step 6: Production defaults

State the defaults explicitly so the FDE can interrupt:

```
Production defaults for $CUSTOMER_NAME:
  • Match customer's stack patterns (see stack.md — auth, frameworks, conventions)
  • Real error handling (retry where transient, fail loud where unexpected)
  • Real logging at decision points (their stack.md should name the logger)
  • Config via env vars or their existing config system — no hardcoded values
  • Tests at acceptance level (the binary criteria from scope.md become test cases)
  • A README that says how it deploys, how it's monitored, who owns it post-handoff

Continue? (yes / let me redirect)
```

## Step 7: Build

Build the production implementation. The acceptance tests from `scope.md` are the bar. Decisions inherited from `decisions.md` are the architecture.

When you would normally have said "let me check how the POC handled X," instead:
- Look in `stack.md` and `decisions.md` for the relevant write-back.
- If it's not there, surface it to the FDE: "stack.md / decisions.md don't mention how the customer's auth proxy handles long-lived tokens. The POC may have figured this out. Can you confirm / write it back to stack.md before we continue?"

This is how the cleanroom rebuild stays honest. Missing write-backs become visible the moment they bite.

## Step 8: Write the integration README

Build target: `customers/<name>/integrate/README.md` (or wherever your shipped artifact lives — under the customer dir for traceability):

```markdown
# Production: <title>
**Date:** <YYYY-MM-DD>
**FDE:** <git user.name>
**Source scope:** <scope-YYYY-MM-DD.md>
**Source decisions:** <decisions.md entries dated X, Y, Z>

## What this does
<one-paragraph plain-English description for the on-call who'll handle this at 3am>

## How to deploy
<exact commands, including env vars and any approval gates>

## How to monitor
<dashboards, alerts, logs — name the actual systems from stack.md>

## How to roll back
<actual rollback procedure, not "redeploy the prior version">

## Acceptance tests (from scope.md success criteria)
- [ ] <criterion 1> — verified by <test path or manual procedure>
- [ ] <criterion 2> — verified by <test path or manual procedure>

## Decisions inherited
- <decision 1 from decisions.md, in one line>
- <decision 2 from decisions.md, in one line>

## Known limitations / future work
<what we explicitly chose NOT to build, and why>
```

## Step 9: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "integrate: $CUSTOMER_NAME <YYYY-MM-DD>"
```

## Step 10: Summary

```
Production build complete.
  Location: customers/<name>/integrate/
  Acceptance tests: <N criteria from scope.md mapped to tests>
  Decisions inherited: <N entries from decisions.md>
  POC code consulted: ZERO (cleanroom rebuild)

If anything from the POC didn't make it into the build, it's because the
write-back in /poc Step 9 didn't capture it. That's a /poc gap, not a
/integrate gap — and it's visible now, which is the whole point.

Next:
  - Verify acceptance tests pass against scope.md criteria
  - Hand off per the README ownership line
```
