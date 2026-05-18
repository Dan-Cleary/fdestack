# Scenario: /value-frame vague path (no lever identifiable)

**Tests:** `/value-frame` Steps 5-10 when the FDE can't pick a primary lever. The skill should refuse to produce a fake headline number and instead flag all 4 dimensions to `unknowns.md` HIGH.

This is the integrity mechanism. The worst failure mode for value framing is a confident-looking dollar number with no defensible methodology — that destroys credibility the moment a customer challenges it. The vague path proves the skill prefers honest "we don't know yet" over confident bullshit.

## Setup

1. Seed ops repo with Northwind fixture.
2. Run `/value-frame northwind "make the chatbot better for users"`.
3. Simulated FDE answers all dimensions vaguely:
   - **Lever:** "all of them — it's just better"
   - **Unit econ:** can't write without a lever
   - **Assumptions:** can't surface without a formula
   - **Defensibility:** "if it's better, they'll see it"

## Expected behavior

- `value-frame-YYYY-MM-DD.md` written with 5 `[NEEDS CLARIFICATION]` blocks. No fake headline number.
- `unknowns.md` HIGH section gains 4 entries tagged `[value-frame-YYYY-MM-DD]`, each naming the specific gap.
- Commit message reflects the vague flag.
- Recommendation surfaced: rerun `/scope` to pick a specific lever first.

## Result: PASS

All 4 dimensions flagged. 4 entries appended to `unknowns.md` HIGH. The simulated next `/customer-context` Session Brief would render all 4 alongside the 2 pre-existing kickoff items.

The Defensibility section correctly identified this as a *scoping* problem masquerading as a value-framing problem — and recommended kicking it back to `/scope` rather than trying to fix it inside `/value-frame`. That's the right behavior; trying to coerce a value frame out of a vague scope produces exactly the kind of number that gets a CFO push back.

## Why this matters

The "categorize the pushback" step in /value-frame Step 9 has a routing built in:
- Methodology pushback → fix in /value-frame
- Numbers pushback → fix in /value-frame
- Strategic relevance pushback → kick to /scope

The vague path exercises that last routing. Without it, FDEs would keep iterating on the value frame for a problem that was never properly scoped.

See `expected-frame.md` and `expected-unknowns.md` for verified outputs.
