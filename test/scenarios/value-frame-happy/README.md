# Scenario: /value-frame happy path (Time lever)

**Tests:** `/value-frame` Steps 5-12 when the FDE has a clean lever, computable assumptions, and a known defensibility pushback.

## Setup

1. Seed ops repo with Northwind fixture + a scope file (Confluence chatbot wedge).
2. Run `/value-frame northwind "Tier-1 ticket deflection from chatbot"`.
3. Simulated FDE walks through:
   - **Lever:** Time (FTE hours freed)
   - **Unit econ:** `tickets × answerable% × deflection% × handle_time × hourly_rate × 52`
   - **Assumptions:** 2 measured, 2 stated (industry benchmarks), 1 estimated (deflection rate)
   - **Headline:** ~$75k/yr
   - **Sensitivity:** $37k – $127k (±30% on the squishy assumptions)
   - **Defensibility:** anticipated pushback on deflection rate; mitigation = wedge POC empirically measures it

## Expected behavior

- `value-frame-YYYY-MM-DD.md` written with all sections populated, no `[NEEDS CLARIFICATION]` markers.
- `unknowns.md` unchanged.
- Commit: `value-frame: northwind YYYY-MM-DD`.

## Result: PASS

Headline + sensitivity render cleanly. Defensibility section names a *specific* anticipated pushback (deflection rate) with a *specific* response strategy (wedge as measurement instrument) — exactly the shape the skill is supposed to enforce.

The estimated:stated:measured ratio (1:2:2) is healthy — under the 50% estimated threshold, so no `assumptions-thin` flag.

See `expected-frame.md` for the verified output.

## Why this matters

The wedge-as-measurement framing only emerged because Step 9 forced the FDE to articulate the specific pushback. Without that step, the value frame would have hand-waved the deflection rate and Maya would have killed it in 30 seconds at the readout. This is the skill earning its keep.
