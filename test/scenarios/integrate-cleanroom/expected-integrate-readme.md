# Production: Northwind Confluence chatbot
**Date:** 2026-04-28
**FDE:** Dan Cleary
**Source scope:** scope-2026-04-22.md
**Source decisions:** decisions.md entry dated 2026-04-25

## What this does
Slack-integrated chatbot that answers Ops SOP questions for Northwind employees by retrieving from Confluence with per-user ACLs enforced automatically.

## How to deploy
`./deploy.sh prod` — gates: Tom Reilly SOC2 review (6-week queue, started 2026-04-26).

## How to monitor
- Datadog dashboard `northwind/chatbot/prod`
- Audit log stream: `audit.confluence_chatbot` (per decisions.md, every retrieval is logged)
- Alert on 5xx rate > 1%, p95 latency > 4s (matches scope.md success criterion)

## How to roll back
`./deploy.sh prod --rollback-to <prior-version>` — DNS-level cutover, < 60s.

## Acceptance tests (from scope.md success criteria)
- [ ] 8/10 hand-picked Ops questions answered correctly — verified by `test/eval_harness.py`
- [ ] Zero ACL leakage on 5 negative tests — verified by `test/acl_negative_tests.py`
- [ ] p95 latency < 4s — verified by Datadog SLO dashboard

## Decisions inherited
- Per-user Confluence OAuth via Okta (NOT service account) — see decisions.md 2026-04-25

## Known limitations / future work
- Full Confluence corpus (currently OPSSOP only) — Phase 2
- Multi-turn refinement — explicitly out of scope per scope-2026-04-22.md
