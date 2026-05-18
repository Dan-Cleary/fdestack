# Scope: Confluence chatbot wedge — prove ACL-aware retrieval
**Date:** 2026-05-18
**FDE:** Dan Cleary
**Problem source:** discovery-2026-04-15.md

## Problem Statement (one sentence)
Build a wedge slice of the Confluence chatbot that proves ACL-aware retrieval is feasible before committing to the full integration.

## Smallest Provable Value
Slack bot that answers questions from ONE Confluence space (Ops SOPs only). Hardcoded retrieval. Reads Maya's Confluence token only (no per-user auth proxy yet).

## Success Criteria (binary)
- [ ] Maya runs 10 hand-picked Ops SOP questions, bot answers ≥8/10 correctly.
- [ ] Bot returns zero content from Confluence spaces Maya does not have access to (verified with 5 negative test queries against restricted spaces).
- [ ] End-to-end latency p95 under 4 seconds.

## Explicitly Out of Scope
- Full Confluence (200k pages) — only Ops SOPs space this week.
- Per-user auth proxy / SSO integration.
- Production deployment.
- Persistent chat history.
- Multi-turn refinement.

## Risks
- ACL-aware filter is the architectural unknown (already HIGH in unknowns.md).
- Confluence read access for FDE not yet provisioned — could block testing if not landed by Wednesday.
- Maya's 10 sample questions may not be representative of real tier-1 ticket distribution.

## Estimated Build Time
2 dev-days for the bot + retrieval; 1 day for the 10-question evaluation harness.

## Validator
Maya Chen.
