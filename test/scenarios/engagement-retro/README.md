# Scenario: /engagement-retro weekly reflection

**Tests:** `/engagement-retro` — collects activity within a date window, walks the FDE through 4 questions (shipped / stuck / learned / next), surfaces stale items as escalation candidates, and appends new unknowns to the unknowns.md HIGH section.

## Setup

1. Seed Northwind fixture + a `scope-2026-05-13.md` + a `decisions.md` entry dated 2026-05-15.
2. Run `/engagement-retro northwind --since 2026-05-12`.
3. Simulated FDE walks through the 4 questions:
   - **Shipped:** activity-extracted (2 commits, 1 scope, 1 decision) + no additions
   - **Stuck:** all 5 carried-from-prior HIGH unknowns; "Confluence read access" flagged as escalation candidate (5+ weeks open)
   - **Learned:** decisions.md 2026-05-15 entry; no cross-customer pattern this week
   - **Next:** ACL test harness must show zero leakage; **new unknown surfaces** — is the architecture proposal commitment from 4 weeks ago delivered or still open?

## Expected behavior

- `retro-2026-05-19.md` written with all 4 sections populated.
- New unknown appended to `unknowns.md` HIGH with `[retro-2026-05-19]` tag.
- "Pattern alert" callout for the 5-week-old `Confluence read access` unknown.
- Commit: `engagement-retro: northwind 2026-05-19`.

## Result: PASS

Retro file structured correctly. New `[retro-2026-05-19]` unknown landed in `unknowns.md` HIGH — closes the loop with `/customer-context`, which will surface it next session.

See `expected-retro.md` and `expected-unknowns.md`.

## Why this matters

`/engagement-retro` is the *cycle-completing* skill. Without it:
- `unknowns.md` accumulates without ever being audited for staleness.
- Cross-customer learnings get captured by `/poc` but never by week-over-week pattern recognition.
- Stale items (Confluence access open 5 weeks) stay invisible — the audit-trail tags from `/scope` and `/value-frame` accumulate without anyone noticing they've been there for months.

The retro is also the only skill that proactively *generates new unknowns* in response to a forward-looking question. Q4 ("what needs to be true at the next milestone?") consistently surfaces items the FDE was about to forget. Adding `[retro-DATE]` tags keeps the audit trail consistent with the rest of the unknowns-loop machinery.

## Pattern-alert mechanism

The skill includes a "items appearing 2+ retros in a row" callout. The scenario demonstrates this with the 5-week-old Confluence-access unknown — exactly the kind of item that quietly rots when there's no periodic audit. This is the only place in the skill pack where the FDE gets a *temporal* signal ("this has been here too long") rather than a state signal ("this is HIGH").
