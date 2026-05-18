## Last Updated
2026-04-15

## Languages & Frameworks
- Python / FastAPI (internal services)

## Infrastructure
- AWS us-east-1 only (legal-mandated, hard constraint, no cross-region)
- Some legacy on-prem (details TBD)

## Auth Patterns
- Okta SSO

## Data Systems
- Snowflake warehouse (no AI-shaped usage yet)
- Confluence — ~200k pages, 10 years of accumulated knowledge
  - Page-level ACLs (legal docs, exec comp, M&A) — MUST be respected at retrieval time

## Constraints & Quirks
- No vector DB selected yet
- SOC2 review required before any production deployment touching internal data
  - Queue is ~6 weeks minimum
  - Tom Reilly owns review
- ACL-aware retrieval is unsolved — Tom hasn't seen a pattern he likes

## POC learnings (2026-04-25)
- Confluence's `/content/search` endpoint inherits the requester's token ACLs at the API level — pages the token holder can't see do not appear in results. This is the retrieval-security primitive we'll build on, and it removes the need to implement ACL filtering downstream.
