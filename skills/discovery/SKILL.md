---
name: discovery
description: |
  Process any inbound source of customer context — meeting transcript, prior
  FDE's handoff notes, AE/sales briefing, customer-side RFP response, prior
  Discovery Workshop output, or your own raw notes. Extracts new stack info,
  stakeholders, stated problem, real problem, open questions, and context
  conflicts. Updates customer context files and commits.

  Proactively invoke this skill (do NOT just summarize) when the user pastes
  call notes, meeting transcripts, AE briefings, RFP responses, handoff docs,
  or any inbound document about a customer. Triggers on phrases like "I just
  had a meeting", "here are notes from", "process this call", or any content
  that looks like raw or synthesized customer information.

  Usage: /discovery <customer-name> <paste any source doc>
  Voice triggers: "process the call", "I just had a meeting",
  "process these notes", "discover for <customer>".
---

# /discovery

Process any source of customer context — raw or already-structured — and update the customer's context files.

## Step 0: Parse inputs

The customer name is the first argument. Everything after it is the source content — a transcript, notes, handoff doc, briefing, RFP response, or any other inbound material about the customer.

If no customer name is provided: ask "Which customer? (e.g. /discovery acme <source doc>)"
If no source content is provided after the name: ask "Paste the source content below — a transcript, handoff doc, briefing, or notes."

Note the source type at the top of the discovery file (Step 6): `Source: <transcript | handoff | briefing | RFP | notes | other>`. This is part of the audit trail — six months later, knowing whether a decision came from your own call vs. an inherited doc is important context.

When the source is **already structured** (e.g., a Solution Blueprint with sections like "Pain Points" and "Strategic Priorities"), treat it as input not output: extract the same six dimensions below, but expect more pre-organized content and less inference work. The stated-vs-real-problem distinction is still worth making — synthesized docs are usually the *upstream author's* take, not the customer's raw words.

Set CUSTOMER_NAME from the first argument.

## Step 1: Check session marker

```bash
MARKER="/tmp/fdestack-session-$CUSTOMER_NAME"
if [ -f "$MARKER" ]; then
  MARKER_TS=$(cat "$MARKER" | grep '^ts=' | cut -d= -f2)
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
> Run `/customer-context $CUSTOMER_NAME` first, then retry /discovery.
> (Context must be loaded this session to ensure you're working with current information.)

Stop. Do not proceed.

## Step 2: Load cross-customer learnings

```bash
LEARNINGS_FILE="$HOME/.fdestack/learnings.jsonl"
if [ -f "$LEARNINGS_FILE" ] && [ -s "$LEARNINGS_FILE" ]; then
  tail -5 "$LEARNINGS_FILE" | jq -r '"[learning] " + .key + ": " + .insight' 2>/dev/null || true
fi
```

If relevant past learnings exist (e.g., similar customer type, similar problem), note them
in your analysis — "Prior learning: [x] — watch for this pattern here."

## Step 3: Transcript length check

Estimate word count from the transcript length. If the transcript appears very long
(rough heuristic: more than ~50 paragraphs or obvious multi-hour raw transcript with
timestamps on every line), note:

> This is a long transcript — I'll extract what matters.
> For faster runs next time, paste only the key sections (decisions, action items, new info).

Then proceed normally. Do not truncate or refuse to process.

## Step 4: Read current customer context

Read these files to understand existing knowledge before extracting from the transcript:
- `customers/<name>/profile.md`
- `customers/<name>/stack.md`
- `customers/<name>/stakeholders.md`
- `customers/<name>/unknowns.md`

This lets you identify what's NEW (not already captured) and what CONFLICTS with existing context.

## Step 5: Extract from transcript

Working through the transcript, identify:

1. **New stack info** — tools, APIs, languages, data systems, auth patterns, rate limits, constraints mentioned
2. **New stakeholders** — people mentioned by name or role who aren't in stakeholders.md
3. **Stated problem** — what the customer said they want ("we need X")
4. **Real problem** — what you infer from subtext, what wasn't said, what seems to actually be driving this
5. **Open questions** — things the customer said they'd find out, things that came up without resolution, things you need to follow up on
6. **Context conflicts** — anything that contradicts what's currently in the context files

## Step 6: Write discovery file

Determine the meeting date. If the transcript contains a `**Date:**` or `Date:` line near the top, use that. Otherwise default to today (`$(date +%Y-%m-%d)`). If you're unsure, ask the FDE once: "What date should this discovery be tagged with? (default: today)"

Set `MEETING_DATE` accordingly and use it for both the filename and the commit message in Step 8.

Set `FDE_NAME="$(git config user.name)"` so the "FDE:" line renders the real name, not the literal placeholder.

If `customers/<name>/discovery-<MEETING_DATE>.md` already exists (multiple meetings same day, or rerunning /discovery), append a suffix:

```bash
DISCOVERY_FILE="customers/$CUSTOMER_NAME/discovery-$MEETING_DATE.md"
if [ -f "$DISCOVERY_FILE" ]; then
  i=2
  while [ -f "customers/$CUSTOMER_NAME/discovery-$MEETING_DATE-$i.md" ]; do
    i=$((i + 1))
  done
  DISCOVERY_FILE="customers/$CUSTOMER_NAME/discovery-$MEETING_DATE-$i.md"
fi
```

Then write to `$DISCOVERY_FILE`:

```markdown
# Discovery: <YYYY-MM-DD>
FDE: <git user.name>

## New Stack Info
[bullets — only things not already in stack.md]

## New Stakeholders
[name, role, notes — only people not already in stakeholders.md]

## Stated Problem
[one paragraph — what the customer said they want]

## Real Problem (inferred)
[one paragraph — what you think is actually going on based on subtext]

## Open Questions / Follow-ups
[bullets — things to find out or follow up on]

## Context Conflicts
[anything that contradicts existing context files — flag for FDE to reconcile]
[if none: "None — transcript is consistent with existing context."]

## Updates Made
[list of which files were updated and what changed]
```

## Step 7: Update context files in place

For each item extracted in Step 5:

- **New stack info** → append to `customers/<name>/stack.md` under the relevant section
- **New stakeholders** → append to `customers/<name>/stakeholders.md` under the relevant section
- **Open questions** → append to `customers/<name>/unknowns.md` under the appropriate risk level (default MED unless clearly HIGH)
- **Context conflicts** → note in the discovery file; do NOT silently overwrite existing context. Ask the FDE: "stakeholders.md says X but the transcript says Y — which is current?"

Update the `## Last Updated` line in each file you modify.

## Step 8: Commit

```bash
git add "customers/$CUSTOMER_NAME/"
git commit -m "discovery: $CUSTOMER_NAME $MEETING_DATE"
```

No confirmation prompt for discovery — the FDE just reviewed the extracted output in
Steps 6-7. If the commit fails (e.g., nothing staged), note "Nothing new to commit."

## Step 9: Check for cross-customer learnings

After updating context, consider: does anything from this transcript represent a
pattern likely to appear with other customers? Examples:
- A surprising technical constraint (e.g., "their Snowflake environment doesn't allow UDFs")
- An organizational pattern (e.g., "legal review takes 6 weeks at companies this size")
- An approach that worked (e.g., "showing the demo before the technical deep-dive changed the conversation")

If yes, ask: "This seems like a generalizable pattern — want me to save it to your learnings for future engagements?"

If yes:

```bash
jq -nc \
  --arg skill "discovery" \
  --arg key "<short-key>" \
  --arg insight "<one sentence>" \
  --arg confidence "7" \
  --arg source "observed" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{skill:$skill,key:$key,insight:$insight,confidence:($confidence|tonumber),source:$source,ts:$ts}' \
  >> "$HOME/.fdestack/learnings.jsonl"
echo "Saved to learnings."
```

Print a summary: "Discovery complete. Updated [list of files changed]. [N] open questions added to unknowns.md."
