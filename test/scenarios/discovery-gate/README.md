# Scenario: /discovery gate when marker missing or stale

**Tests:** `/discovery` Step 1 — the freshness gate that requires `/customer-context` to have run within the last 12h before `/discovery` is allowed.

This is the guardrail that prevents `/discovery` from running against stale customer context. Without it, an FDE might overwrite a stakeholders.md they haven't read recently.

## Cases

| Case | Marker state | Expected |
|---|---|---|
| 1 | Missing | MARKER_MISSING → refuse |
| 2 | Fresh (now) | MARKER_OK → proceed |
| 3 | 11h57m old | MARKER_OK → proceed |
| 4 | Exactly 12h old | MARKER_STALE → refuse |
| 5 | 24h old | MARKER_STALE → refuse |
| 6 | Fresh + declined=true | MARKER_OK → proceed (declined flag doesn't affect age gate) |

## Result: PASS (6/6)

The 12-hour boundary is correct: `<43200s` proceeds, `>=43200s` refuses. Missing marker correctly distinguishes from stale.

Run: `bash test.sh`
