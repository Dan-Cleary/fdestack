# Scenario: /scope vague path (unknowns loop)

**Tests:** `/scope` Steps 6-8 when the FDE cannot articulate binary criteria. Verifies the *unknowns loop* — vague items get `[NEEDS CLARIFICATION]` inline AND HIGH appendages to `unknowns.md`, which then surface in every future `/customer-context` Session Brief until resolved.

This is the wedge skill's integrity mechanism. Without it, vague scopes fail silently and the project drifts.

## Setup

1. Seed ops repo with Northwind fixture.
2. Run `/scope northwind "make the chatbot better"`.
3. Simulated FDE answers, after one pushback each:
   - **Criteria:** "users like it" → pushback → "it feels useful" (still vague)
   - **Out of scope:** "we'll figure it out" (evasive)
   - **Estimate:** "a few weeks" (too long for a one-week wedge)
   - **Validator:** unnamed

## Expected behavior

- `scope-YYYY-MM-DD.md` has `[NEEDS CLARIFICATION: ...]` blocks in 4 sections.
- `unknowns.md` has 4 new entries under `## HIGH — Unknown, Blocking`, each tagged `[scope-YYYY-MM-DD]`.
- Commit: `scope: northwind YYYY-MM-DD (vague — 4 items flagged)`.
- A subsequent `/customer-context northwind` renders all 4 scope items in OPEN UNKNOWNS in the Session Brief.

## Result: PASS

All 4 vague items appended to `unknowns.md` HIGH section. Loop verified — the simulated next `/customer-context` Session Brief lists all 4 scope items alongside the 2 pre-existing kickoff unknowns:

```
scope-tagged HIGH unknowns visible in Session Brief: 4
PASS: unknowns loop closed — all 4 scope items will surface every session until resolved
```

See `expected-scope.md` and `expected-unknowns.md` for verified outputs.

## Why this matters

The `[scope-YYYY-MM-DD]` tag is the audit trail. When an FDE resolves an item (gets the binary criteria, names the validator, etc.) they can grep for the tag, find the scope file it came from, update the scope doc to remove the `[NEEDS CLARIFICATION]`, and delete the line from `unknowns.md`. Until then, every future session reminds the FDE that the scope is unresolved.
