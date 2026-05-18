---
name: customer-context
description: |
  Load a customer's context at the start of every session. Run this before any
  other FDEstack skill. Reads all 7 context files, surfaces drift since last
  session, asks what's new, and commits updates.
  Usage: /customer-context <customer-name>
---

# /customer-context

Load and update a customer's context. Run this at the start of every customer session.

## Step 0: Parse customer name

The customer name is the first argument after the skill invocation. If no name is
provided, ask: "Which customer? (e.g. /customer-context acme)"

Set CUSTOMER_NAME from the argument. All file paths below use this name.
The ops repo root is the current working directory — all paths are relative to it.

## Step 1: Ops repo safety check

Run:
```bash
git remote -v 2>/dev/null | head -4
[ -d customers/ ] && ls customers/ | head -3 || echo "NO_CUSTOMERS_DIR"
```

If `NO_CUSTOMERS_DIR` appears AND there are git remotes that don't look like a
personal ops repo (e.g., remote URL contains a company/project name that matches
obvious customer patterns), print:

> Warning: I don't see a `customers/` directory here. Are you sure you're in your
> FDE ops repo (e.g. ~/fde-ops/) and not inside a customer's codebase? Committing
> customer context here could expose internal notes to the customer's team.
> Type "yes" to proceed anyway, or cd to your ops repo first.

Wait for confirmation before continuing if this warning fires.

## Step 2: Check session marker freshness

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ -f "$MARKER" ]; then
  MARKER_TS=$(cat "$MARKER" | grep '^ts=' | cut -d= -f2)
  NOW=$(date +%s)
  AGE=$(( NOW - MARKER_TS ))
  if [ "$AGE" -lt 43200 ]; then
    echo "MARKER_FRESH=true AGE_HOURS=$(( AGE / 3600 ))"
  else
    echo "MARKER_FRESH=false AGE_HOURS=$(( AGE / 3600 ))"
  fi
  DECLINED=$(cat "$MARKER" | grep '^declined=true' || echo "")
  [ -n "$DECLINED" ] && echo "DECLINED_LAST_SESSION=true"
else
  echo "MARKER_FRESH=false MARKER_MISSING=true"
fi
```

If `DECLINED_LAST_SESSION=true`: print at the top of the Session Brief:
> Note: last session's changes were not committed — drift detection may show
> accumulated changes from multiple sessions.

## Step 3: Load cross-customer learnings

```bash
LEARNINGS_FILE="$HOME/.fdestack/learnings.jsonl"
if [ -f "$LEARNINGS_FILE" ] && [ -s "$LEARNINGS_FILE" ]; then
  echo "LEARNINGS: $(wc -l < "$LEARNINGS_FILE" | tr -d ' ') entries"
  # Surface top 3 most recent entries
  tail -3 "$LEARNINGS_FILE" | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null || true
else
  echo "LEARNINGS: 0"
fi
```

If learnings are found, incorporate relevant ones into your analysis during this session.
Display them under "PRIOR LEARNINGS" in the Session Brief if any seem applicable.

## Step 4: Load customer context files

```bash
CUSTOMER_DIR="customers/$CUSTOMER_NAME"
mkdir -p "$CUSTOMER_DIR"
for f in profile stack stakeholders blockers unknowns decisions timeline; do
  if [ ! -f "$CUSTOMER_DIR/$f.md" ]; then
    FDESTACK_DIR=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$HOME/.claude/skills/customer-context/SKILL.md")")")
    cp "$FDESTACK_DIR/templates/$f.md" "$CUSTOMER_DIR/$f.md" 2>/dev/null || \
    cp "$HOME/.claude/skills/fdestack/templates/$f.md" "$CUSTOMER_DIR/$f.md" 2>/dev/null || \
    echo "## Last Updated" > "$CUSTOMER_DIR/$f.md"
    echo "  created: $f.md from template"
  fi
done
ls "$CUSTOMER_DIR/"
```

Read all 7 files:
- `customers/<name>/profile.md`
- `customers/<name>/stack.md`
- `customers/<name>/stakeholders.md`
- `customers/<name>/blockers.md`
- `customers/<name>/unknowns.md`
- `customers/<name>/decisions.md`
- `customers/<name>/timeline.md`

## Step 5: Drift detection

```bash
CUSTOMER_DIR="customers/$CUSTOMER_NAME"
# Check if files have git history
HAS_HISTORY=$(git log --oneline -1 -- "$CUSTOMER_DIR/" 2>/dev/null)
if [ -n "$HAS_HISTORY" ]; then
  git diff HEAD -- "$CUSTOMER_DIR/" 2>/dev/null
  echo "DRIFT_CHECK=done"
else
  echo "DRIFT_CHECK=first_session"
fi
```

If `DRIFT_CHECK=first_session`: note "First session — no drift to show."
If diff output is non-empty: summarize as "DRIFT SINCE LAST SESSION" in the Brief.
If diff is empty: note "No changes since last session."

## Step 6: Print Session Brief

Print this to the terminal:

```
════════════════════════════════════════════════════════════
CUSTOMER: <name> | SESSION: <YYYY-MM-DD> | FDE: <git user.name>
════════════════════════════════════════════════════════════

CURRENT STATE:
  [3-5 bullets synthesized from profile.md + recent decisions.md]

OPEN UNKNOWNS:
  [unknowns.md items, HIGH first, then MED, then LOW]
  [if none: "No open unknowns — nice."]

CURRENT BLOCKERS:
  [blockers.md items, HIGH first]
  [if none: "No active blockers."]

DRIFT SINCE LAST SESSION:
  [summary of git diff, or "No changes" or "First session"]
  [if DECLINED_LAST_SESSION: "Note: last session not committed — diff may span multiple sessions"]

[PRIOR LEARNINGS: <applicable entries from learnings.jsonl, if any>]

RECOMMENDED FIRST ACTION:
  [one sentence based on highest-priority blocker or unknown]
  [first session with empty context: "Tell me what you already know about this customer
   (company, engagement stage, who's involved) — I'll route it to the right context file."]
════════════════════════════════════════════════════════════
```

## Step 7: Ask what's new

Ask: "Anything to update before we start?"

Route answers to the right file by content type:
- New person / contact / org chart change → `stakeholders.md`
- New tool / system / infra / API / data format → `stack.md`
- New deadline / date / milestone → `timeline.md`
- New blocker / stuck / can't proceed → `blockers.md`
- New unknown / unclear / need to find out → `unknowns.md`
- Decision made / resolved / agreed → `decisions.md`
- General company / product info → `profile.md`

If the answer is ambiguous (could go to 2+ files), ask which file before writing.
If nothing to update, skip to Step 8.

Update the `## Last Updated` line in each file you modify with today's date.

## Step 8: Confirm before committing

Show what changed:
```bash
git diff -- "customers/$CUSTOMER_NAME/" 2>/dev/null
git status --short -- "customers/$CUSTOMER_NAME/" 2>/dev/null
```

If nothing changed: write the session marker (Step 9) and stop. Print "Nothing changed — context is current."

If changes exist, print:
> Here's what I'm about to commit to your ops repo:
> [show the diff summary — which files changed and what]
> Commit these changes? (yes / no / let me edit first)

- **yes**: proceed to commit in Step 8a
- **no**: write declined flag to session marker (Step 9), print "OK — changes not committed. Next session will note that drift detection may be incomplete.", stop
- **let me edit first**: wait for the user to make edits, then re-show the diff and ask again

### Step 8a: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "context: $CUSTOMER_NAME session $(date +%Y-%m-%d)"
```

## Step 9: Write session marker

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
printf "ts=%s\n" "$(date +%s)" > "$MARKER"
# If commit was declined, add the flag:
# printf "declined=true\n" >> "$MARKER"
```

Write `ts=<unix_timestamp>` to the marker. If the commit was declined in Step 8, also write `declined=true` on a second line.

Print: "Session marker written. Other FDEstack skills are ready to use for $CUSTOMER_NAME."
