# Scenario: /poc learnings write-back

**Tests:** `/poc` Step 9 — the MANDATORY learnings write-back that's the entire reason /integrate can be a cleanroom rebuild.

If the write-back is skipped or incomplete, the POC's discoveries never reach `/integrate`. The skill's value-add isn't the throwaway code — it's the structured routing of learnings into the three durable surfaces.

## Setup

1. Seed ops repo with Northwind fixture + scope file.
2. Run `/poc northwind --purpose feasibility`.
3. POC code lives at `customers/northwind/poc/chatbot.py` (intentionally minimal).
4. POC discovers: Confluence `/content/search` enforces ACLs at the API layer when called with a user token (vs. service account).

## Expected behavior

Step 9 routes the discovery into three places:

- **stack.md** — appends "POC learnings (DATE)" section with the technical fact ("/content/search inherits requester token ACLs").
- **decisions.md** — prepends a decision entry: per-user OAuth tokens (NOT service account), with Rationale + Implications for /integrate.
- **learnings.jsonl** — appends `{key: "confluence-per-user-tokens", confidence: 8, ...}` for cross-customer reuse.

Commit: `poc: northwind DATE (--purpose feasibility)`.

## Result: PASS

All three surfaces updated correctly. The `Implications for /integrate` line in decisions.md is the critical artifact — that's what `/integrate` will read instead of the POC code. Verified that line is present and specific ("implement per-user OAuth flow via Okta, secure token storage, token refresh, audit logging — do NOT implement downstream ACL filter").

See `expected-stack.md`, `expected-decisions.md`, `expected-poc-readme.md` for verified outputs.

## Why this matters

The write-back step is what makes the whole /poc → /integrate handoff honest. Without it:
- POC discoveries either get lost or force /integrate to read POC code (defeating the cleanroom).
- The customer context never reflects what was actually learned.
- Future `/customer-context` sessions surface stale unknowns ("is per-user-token approach viable?") that were already resolved.

This scenario verifies the routing works. The follow-up scenario (`integrate-cleanroom/`) verifies /integrate honors the write-back rather than reading POC code.
