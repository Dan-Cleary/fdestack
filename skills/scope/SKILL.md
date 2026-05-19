---
name: scope
description: |
  Force the wedge question: smallest thing buildable this week that proves the
  core value. Require binary success criteria. Push vague answers to unknowns.md
  as HIGH so they surface in every future Session Brief.

  Proactively invoke this skill after /discovery when the FDE describes a
  problem they want to solve for the customer, references the wedge or first
  thing to build, or asks "what should we build first" / "what's the smallest
  thing". Always run before /poc or /value-frame.

  Usage: /scope <customer-name> <problem statement>
  Voice triggers: "scope this out", "what's the wedge",
  "smallest thing that proves value", "what should we build first".
---

# /scope

Force a tight, binary-criteria scope for a customer problem.

## Step 0: Parse inputs

The customer name is the first argument. Everything after it is the problem statement.

If no customer name is provided: ask "Which customer? (e.g. /scope acme <problem statement>)"
If no problem statement is provided: ask "What problem are we scoping? Paste a one-line summary or grab it from the latest discovery file."

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
> Run `/customer-context $CUSTOMER_NAME` first, then retry /scope.
> (Context must be loaded this session to ensure you're working with current information.)

Stop. Do not proceed.

## Step 2: Verify discovery has run

```bash
DISCOVERY_COUNT=$(ls customers/$CUSTOMER_NAME/discovery-*.md 2>/dev/null | wc -l | tr -d ' ')
echo "DISCOVERY_COUNT=$DISCOVERY_COUNT"
```

If `DISCOVERY_COUNT=0`:
> No discovery file found for $CUSTOMER_NAME. /scope needs a discovery first
> so we know what the customer actually said. Run /discovery $CUSTOMER_NAME <transcript>
> or paste call notes, then retry /scope.

Stop. Do not proceed.

## Step 3: Load cross-customer learnings

```bash
LEARNINGS_FILE="$HOME/.fdestack/learnings.jsonl"
if [ -f "$LEARNINGS_FILE" ] && [ -s "$LEARNINGS_FILE" ]; then
  tail -5 "$LEARNINGS_FILE" | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null || true
fi
```

If any past learning seems relevant to the problem statement (similar tech stack, similar customer type, similar problem shape), note it: "Prior learning: [x] — watch for this pattern here."

## Step 4: Load context

Read in this order:
1. `customers/<name>/profile.md` — what kind of company this is
2. `customers/<name>/stack.md` — what they have to work with
3. The most recent `customers/<name>/discovery-*.md` (sort by filename, take last) — what they said they want
4. `customers/<name>/unknowns.md` — what we don't yet know
5. `customers/<name>/scope-*.md` (if any prior scopes exist) — what we've already scoped

## Step 5: Force the wedge question

The problem statement from Step 0 is the starting point. Now force the wedge:

> What is the smallest thing we can build **this week** that proves the **core value**?

The FDE answers. Analyze the answer along two dimensions:

**Dimension 1 — Is the scope actually small?**
- "Build the whole product" → not small
- "Get one end-to-end happy path working with hardcoded inputs" → small
- "Make a Slack bot that answers any question over Confluence" → not small
- "Make a Slack bot that answers questions tagged with a specific Confluence space, hardcoded retrieval, no auth" → small

If the scope is too big, push back once: "That's a quarter, not a week. What's the absolute minimum slice that proves the value? Pretend you have 3 days, what would you build?"

**Dimension 2 — Are the success criteria binary?**
- "It feels faster" → not binary
- "Users say it's better" → not binary (subjective)
- "Query latency p95 under 2 seconds on 100 sample queries" → binary
- "Demo answers 8/10 hand-picked test questions correctly" → binary
- "Maya can use it without asking us a question for a full day" → binary
- "Tom signs off on the ACL-handling design" → binary

If the criteria are vague, push back once: "How will we know we succeeded? What's the pass/fail check we'd run on Friday?"

After at most one pushback per dimension: take whatever you have.

## Step 6: Identify vague items for the unknowns loop

If after the one pushback any of these are still missing or vague, mark them for the unknowns loop:

- Success criteria still not binary → `criteria` is vague
- "Explicitly out of scope" is empty or evasive ("we'll figure it out") → `out-of-scope` is vague
- Estimated build time is "I don't know" or unrealistic for a one-week wedge → `estimate` is vague
- No specified person/role validating success → `validator` is vague

For each vague item, before silently routing it to unknowns.md, use AskUserQuestion to give the FDE one last chance to resolve it. The decision brief format:

```
D<N> — <item label> is still vague after one pushback
ELI10: <plain English of what's vague and why it matters>
Stakes if we pick wrong: Vague <item> means the <POC|value frame|customer
conversation> can't be defended. The customer will ask the same question we
should have answered before starting work.
Recommendation: Push to unknowns.md HIGH — this is what the unknowns loop
is for, and resolving it now would burn the rest of the scoping session.
Pros / cons:
A) Push to unknowns.md HIGH (recommended)
  ✅ Preserves momentum — scope file ships now with [NEEDS CLARIFICATION]
  ✅ Audit trail via [scope-<date>] tag — surfaces every /customer-context
  ❌ FDE has to come back to resolve before /poc or customer conversation
B) Stop and resolve now
  ✅ Scope ships clean with no [NEEDS CLARIFICATION] markers
  ❌ Pulls the FDE into a sub-discovery that may not yet have inputs
C) Force the scope through as-is (no flag, no unknown)
  ✅ Fastest path to a scope file
  ❌ Hides the gap — vague criteria silently become real defects later
Net: Path A is the unknowns loop doing its job; B is the right move when
the answer is reachable in this session; C is almost never right.
```

Default to (A) if the FDE doesn't choose. For each vague item the FDE confirms (A):
1. Write it inline in the scope file as `> [NEEDS CLARIFICATION: <description>]` in the relevant section.
2. Append it to `customers/<name>/unknowns.md` under `## HIGH — Unknown, Blocking` with format:
   `- [scope-<date>] <description> — need answer to proceed past POC.`

For (B): pause Step 7, ask the FDE the specific clarifying question, fold the answer back in, and re-check. For (C): write the scope file without the flag, but log this in `decisions.md` as "FDE explicitly accepted <item> as vague — no audit trail" so the next session sees it.

This ensures vague items surface in every future Session Brief until resolved, but gives the FDE the choice rather than railroading.

## Step 7: Write the scope file

Set `SCOPE_DATE=$(date +%Y-%m-%d)`. Determine target file with collision handling (same pattern as /discovery):

```bash
SCOPE_FILE="customers/$CUSTOMER_NAME/scope-$SCOPE_DATE.md"
if [ -f "$SCOPE_FILE" ]; then
  i=2
  while [ -f "customers/$CUSTOMER_NAME/scope-$SCOPE_DATE-$i.md" ]; do
    i=$((i + 1))
  done
  SCOPE_FILE="customers/$CUSTOMER_NAME/scope-$SCOPE_DATE-$i.md"
fi
```

Set `FDE_NAME="$(git config user.name)"`. Write:

```markdown
# Scope: <one-line problem title>
**Date:** <SCOPE_DATE>
**FDE:** <FDE_NAME>
**Problem source:** <discovery-YYYY-MM-DD.md or "ad-hoc">

## Problem Statement (one sentence)
<the problem in one sentence — no compound clauses>

## Smallest Provable Value
<what we'll build this week. Concrete artifact. Not a goal — a thing>

## Success Criteria (binary)
- [ ] <pass/fail check 1>
- [ ] <pass/fail check 2>
<or, if vague:>
> [NEEDS CLARIFICATION: success criteria not yet binary — see unknowns.md]

## Explicitly Out of Scope
- <thing we are NOT doing this week>
- <thing we are NOT doing this week>

## Risks
- <what could derail this — technical, organizational, or schedule>

## Estimated Build Time
<hours or days — e.g., "2 dev-days, 1 review-day">

## Validator
<who decides this passes/fails — name or role>
```

## Step 8: Update unknowns.md if needed

For each vague item from Step 6, append a line to `customers/<name>/unknowns.md` under the `## HIGH — Unknown, Blocking` section. Format:

```
- [scope-<SCOPE_DATE>] <description> — need answer to proceed past POC.
```

Update the `## Last Updated` line in `unknowns.md`.

If no vague items were flagged, do not modify `unknowns.md`.

## Step 9: Commit

Show what will be committed:

```bash
git status --short -- "customers/$CUSTOMER_NAME/"
```

Then commit (no confirmation prompt — the FDE just reviewed the scope file content):

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "scope: $CUSTOMER_NAME $SCOPE_DATE"
```

If nothing staged: print "Nothing new to commit."

## Step 10: Summary

Print:
```
Scope written: <SCOPE_FILE>
Success criteria: <N binary checks> | <"vague — pushed to unknowns.md" if applicable>
Estimated build: <time>
Validator: <name/role>

[if any items pushed to unknowns.md]
Unresolved blockers added to unknowns.md (HIGH):
  - <each vague item>

Next: /poc $CUSTOMER_NAME  (after the vague items above are resolved)
```
