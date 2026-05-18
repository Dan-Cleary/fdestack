# Scenario: cross-customer learning recall

**Tests:** `/customer-context` Step 3 — `~/.fdestack/learnings.jsonl` is read and the entries surface in PRIOR LEARNINGS in the Session Brief, even for a customer different from the one the learning came from.

Without this, `learnings.jsonl` is a write-only graveyard.

## Setup

1. Seed `~/.fdestack/learnings.jsonl` with 3 entries from different customers:
   - `confluence-acl-retrieval` (from Northwind, conf 7) — discovery
   - `snowflake-no-udfs` (synthetic, conf 6) — poc
   - `renewal-narrative-driver` (synthetic, conf 8) — discovery
2. Start a fresh ops repo.
3. Simulate `/customer-context acme` (a brand new customer with no Northwind history).

## Expected behavior

Step 3 of `/customer-context` reads the file via:
```bash
tail -3 "$LEARNINGS_FILE" | jq -r '"[learning] " + .key + ": " + .insight'
```

All 3 entries surface in the Session Brief PRIOR LEARNINGS section, formatted as `<key> (conf <N>): <insight>`.

## Result: PASS

All 3 entries displayed cleanly. Brief renders them as a bulleted list.

## Known limitations (Phase 1 acceptable, worth Phase 2 attention)

1. **`tail -3` is recency-only, not relevance-aware.** Once `learnings.jsonl` has 20+ entries, the model only sees the 3 most recent. A learning from 6 months ago that's directly applicable to today's customer will be invisible.

   Phase 2 fix candidates: tag learnings with `tech_stack` / `customer_type` fields and filter, or add a `gstack-style` semantic search across them.

2. **No relevance check against current customer context.** The skill instructs the model to "incorporate relevant ones," but doesn't help the model decide WHICH are relevant for `acme` specifically. Right now the model has to figure it out from the customer's profile.md content alone.

3. **No confidence-weighted ordering.** Confidence 8 entries should probably surface ahead of confidence 6 entries — currently it's just chronological.

These are not blockers for Phase 1 since the user base is one FDE writing learnings sporadically. They become real problems at ~50 learnings.

Run via inspection: see `expected-output.txt` for the verified PRIOR LEARNINGS section rendering.
