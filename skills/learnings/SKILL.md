---
name: learnings
description: |
  Manage ~/.fdestack/learnings.jsonl — the cross-customer pattern library.
  List, search, prune stale entries, edit incorrect insights, or export the
  file for sharing with another FDE. No write to customer files; this is
  meta over the learnings file itself.

  Proactively invoke this skill when the FDE asks "what have we learned",
  "what patterns have we seen", "didn't we hit this before", or wants to
  share/export accumulated insights. Distinct from /customer-context Step 3,
  which only surfaces the top 3 most recent — /learnings is the full
  management UI.

  Usage: /learnings [list | search <kw> | prune | edit | export]
  Voice triggers: "what have we learned", "show learnings",
  "prune learnings", "have we seen this before".
---

# /learnings

Management UI for `~/.fdestack/learnings.jsonl`.

## Step 0: Parse subcommand

The first argument is the subcommand. Default: `list`.

| Subcommand | What it does |
|---|---|
| `list` | Show all entries, formatted, sorted by ts (newest first) |
| `search <kw>` | Show entries where `key` or `insight` matches `<kw>` (case-insensitive) |
| `prune` | Walk the FDE through each entry, ask whether to keep, edit, or delete |
| `edit` | Pick a specific entry by `key`, walk through edit fields |
| `export <path>` | Write a copy to `<path>` for sharing |

If the subcommand is invalid, list options and stop.

## Step 1: Verify the learnings file exists

```bash
LEARNINGS_FILE="$HOME/.fdestack/learnings.jsonl"
if [ ! -f "$LEARNINGS_FILE" ] || [ ! -s "$LEARNINGS_FILE" ]; then
  echo "No learnings yet. Run /poc or /engagement-retro to start capturing."
  exit 0
fi
COUNT=$(wc -l < "$LEARNINGS_FILE" | tr -d ' ')
echo "LEARNINGS: $COUNT entries"
```

## Step 2: Execute subcommand

### `list`

```bash
jq -s 'sort_by(.ts) | reverse | .[]' "$LEARNINGS_FILE" | jq -c .
```

Render each entry as:
```
▶ <key>   (conf <N> | skill: <skill> | <ts>)
  <insight>
```

If there are more than 20 entries, paginate (show 10 per page, ask "more? (y/n)").

### `search <kw>`

```bash
jq --arg kw "$KW" 'select(
  (.key | ascii_downcase | contains($kw | ascii_downcase)) or
  (.insight | ascii_downcase | contains($kw | ascii_downcase))
)' "$LEARNINGS_FILE"
```

Render same as `list`. If zero matches: "No matches for '<kw>'."

### `prune`

For each entry (newest first), use AskUserQuestion:

```
D<N> — Prune review: <key>
ELI10: This learning was captured <N days> ago from /<skill> for a customer.
The insight was: <insight>. Confidence: <N>/10.
Stakes if we pick wrong: Stale learnings poison future /customer-context
sessions (we surface the top 3 most recent). Wrong learnings are worse
than no learnings.
Recommendation: <Keep | Edit | Delete> because <reason from age + signal>
Pros / cons:
A) Keep as-is
  ✅ Still applicable; the pattern hasn't changed
  ❌ Continues to surface even if confidence has eroded
B) Edit
  ✅ Fix the framing or update confidence
  ❌ Slower per-entry; only worth it for partially-true insights
C) Delete
  ✅ Removes a stale or wrong signal
  ❌ Irreversible (the JSONL is the source of truth)
Net: Keep what still matches reality; delete what doesn't.
```

For (B), prompt for new `insight` and/or `confidence`, then rewrite the entry. For (C), remove the line. Track changes in memory and commit them atomically at the end.

After walking all entries, summarize:
```
Pruning complete.
  Kept: <N>
  Edited: <N>
  Deleted: <N>
```

### `edit`

Ask: "Which learning key to edit?" then walk the FDE through fields: `key`, `insight`, `confidence`, `skill`, `source`. Show current value, accept new value (blank = no change). Rewrite the entry.

### `export <path>`

```bash
cp "$LEARNINGS_FILE" "$PATH"
echo "Exported $COUNT learnings to $PATH"
```

If `<path>` has no `.jsonl` extension, warn but proceed.

## Step 3: Atomic write (for prune / edit)

When mutating, write to a tempfile then `mv` over the original. Never edit in place:

```bash
TMPFILE=$(mktemp)
# write filtered/edited content to $TMPFILE
mv "$TMPFILE" "$LEARNINGS_FILE"
```

## Step 4: No commits

The learnings file is in `~/.fdestack/`, not the ops repo. It's per-FDE state, not per-customer engagement state. No git involvement.

## Step 5: Summary

```
<subcommand> done.
  Total learnings: <N>
  [if prune/edit] Changes: <summary>
  [if export] Path: <path>
```
