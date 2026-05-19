# Scenario: /triage portfolio dashboard

**Tests:** `/triage` — cohort filtering (`active`/`blocked`/`all`), urgency scoring, ranking, and the "where do I look first today?" recommendation.

## Setup

Seed an ops repo with 4 customers in different states:

| Customer | Recency | HIGH blockers | HIGH unknowns | Within-7d items | Expected |
|---|---|---|---|---|---|
| **northwind** | active (0d) | 0 | 8 (accumulated) | 0 | mid-rank |
| **acme** | active (0d) | 0 | 0 | 0 | low-rank (healthy) |
| **globex** | active (7d) | 2 | 2 | 1 (risk committee in 3d) | **TOP** — imminent prod launch |
| **initech** | stale (48d) | 0 | 0 | 0 | filtered OUT of active cohort |

Run `/triage active`.

## Expected behavior

- `initech` excluded (no commit within 14 days).
- 3 customers ranked by urgency formula:
  ```
  urgency = blockers * 3 + min(unknowns, 5) * 2 + within_7d * 10 - (days_since_commit > 7 ? 1 : 0)
  ```
- Ranking: globex (20) > northwind (10) > acme (0).
- RECOMMENDED FIRST ACTION names globex with a one-line justification.

## Result: PASS (after one heuristic fix)

```
PASS: globex ranks #1 (imminent prod launch outweighs accumulated unknowns)
PASS: initech correctly excluded from active cohort
```

See `expected-brief.txt` for the verified output.

## Finding from the test: original urgency formula was wrong

The initial formula was:
```
urgency = blockers * 3 + unknowns * 2 + within_7d * 5
```

This produced **northwind (16) > globex (15)** — backwards. Northwind, mid-discovery with 8 unresolved architecture questions, outranked Globex, which has a production launch in 13 days and a risk-committee meeting in 3 days. That's the wrong urgency signal.

**Fix:** Cap the unknown contribution at 5, and increase within-7d weight from 5 to 10.

Rationale:
1. **Accumulated unknowns ≠ urgency.** A discovery-stage customer naturally has many open questions. That doesn't make them more urgent than an integration-stage customer with a deadline. Capping at 5 prevents discovery customers from shadowing the portfolio view.
2. **Near-term deadlines dominate.** Each within-7d item now weighs 10, so one imminent milestone outweighs five HIGH unknowns and ties three HIGH blockers. That's the right ranking signal for "where do I look first?"

This is the kind of bug you can only find by building a test scenario with realistic state diversity. A single-customer test wouldn't have surfaced it.

## Why this matters

`/triage` is the first skill an FDE runs each morning — it shapes the entire day's prioritization. Getting the urgency heuristic wrong means the FDE works on the wrong customer first. The fix means the heuristic now correctly bubbles imminent-deadline customers above accumulated-debt customers.
