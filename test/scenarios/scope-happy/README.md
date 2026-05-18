# Scenario: /scope happy path (binary criteria)

**Tests:** `/scope` Steps 5-8 when the FDE provides crisp, binary success criteria — no `[NEEDS CLARIFICATION]`, no appends to `unknowns.md`.

## Setup

1. Seed ops repo with Northwind fixture (has discovery-2026-04-15.md).
2. Run `/scope northwind "Confluence chatbot wedge — prove ACL-aware retrieval works"`.
3. Simulated FDE answer:
   - **Wedge:** "Slack bot answering ONE Confluence space (Ops SOPs), hardcoded retrieval, Maya's token only."
   - **Criteria:** "8/10 hand-picked questions correct; zero leakage from restricted spaces (5 negative tests); p95 < 4s."
   - **Out of scope:** Full Confluence, per-user auth, prod deploy, history, multi-turn.
   - **Estimate:** 2 dev-days + 1 eval-day.
   - **Validator:** Maya Chen.

## Expected behavior

- `scope-YYYY-MM-DD.md` written with 3 binary checkboxes, 5 out-of-scope items, named validator, concrete estimate.
- No `[NEEDS CLARIFICATION]` markers.
- `unknowns.md` is **unchanged** — no `[scope-...]` lines appended.
- Commit: `scope: northwind YYYY-MM-DD`.

## Result: PASS

See `expected-scope.md` for the verified output.
