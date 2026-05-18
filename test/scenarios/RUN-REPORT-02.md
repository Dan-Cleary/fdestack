# Multi-scenario run report 02

**Date:** 2026-05-18
**Scope:** 4 scenarios covering paths not exercised by the initial Northwind happy-path run + 1 latent bug fix
**FDEstack version:** 0.1.0
**Result:** All 4 scenarios pass. 1 latent bug fixed (same-day discovery clobber). 3 design gaps documented for Phase 2.

## Scenarios run

### 1. Drift detection — PASS
Seeded ops repo with Northwind fixture, hand-edited two files between sessions (blockers.md and stakeholders.md), re-ran `/customer-context`. Step 5's `git diff HEAD -- customers/northwind/` rendered both file changes cleanly. The drift summary path — previously only exercised in the "no changes" case — now confirmed working with real diffs.

### 2. /discovery freshness gate — PASS (6/6 automated assertions)
Built `test/scenarios/discovery-gate/test.sh`. Verifies the 12-hour boundary precisely: `<43200s` proceeds, `≥43200s` refuses. Missing marker correctly distinguished from stale marker (different refuse paths). `declined=true` flag does not affect age gate.

### 3. Context conflict — PASS
Pre-populated `stakeholders.md` with intentionally-wrong titles (Maya = "Engineering Manager", Tom = "VP Security"). Ran `/discovery` on the Northwind transcript. Confirmed:
- Conflicting entries (Maya, Tom) **preserved** in `stakeholders.md`.
- New entry (Sandeep) **appended** without conflict.
- Matching entry (Raj) silently confirmed, no noise.
- Discovery file `## Context Conflicts` section lists both conflicts with the ask-FDE format.

### 4. Cross-customer learning recall — PASS
Seeded `~/.fdestack/learnings.jsonl` with 3 entries (one from Northwind run + 2 synthetic). Ran `/customer-context acme` — a brand new customer with no Northwind relationship. All 3 learnings surfaced cleanly in the Session Brief PRIOR LEARNINGS section.

## Bug fixed

**Same-day discovery clobber.** Two `/discovery` runs on the same day would silently overwrite `discovery-YYYY-MM-DD.md`. Fixed in `skills/discovery/SKILL.md` Step 6: collision detection with `-2`, `-3`, ... suffix.

## Design gaps documented for Phase 2

These are not blockers for Phase 1 but worth tracking:

1. **Learning relevance filtering.** `tail -3` is recency-only. At ~20+ learnings, older-but-relevant entries become invisible. Phase 2 fix candidates: tag with `tech_stack`/`customer_type` fields and filter, or add semantic search.

2. **Unreconciled context conflicts persist silently.** After `/discovery` flags conflicts, the FDE is expected to manually reconcile. If they forget, the next `/customer-context` session won't notice. Consider: scan the latest `discovery-*.md` for a non-empty `## Context Conflicts` section and prompt at session start.

3. **Confidence-weighted learning order.** Learnings with confidence 8 should probably surface before confidence 6. Currently chronological order only.

## Coverage gaps still open

- Declined commit flow (`/customer-context` Step 8 → "no")
- Long transcript warning (`/discovery` Step 3 — fires at >50 paragraphs)
- Same-day discovery rerun (fix landed in this commit, scenario not yet built)

These are queued for a future run.

## Final test counts

- Unit tests: 34/34 passing
- Scenario tests (automated): 6/6 passing
- Scenario walkthroughs (manual): 4/4 passing
