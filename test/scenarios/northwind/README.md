# Northwind Logistics — synthetic test scenario

A fictional customer used to exercise FDEstack skills end-to-end. Reusable as a regression test as we add new skills.

## The fixture

**Customer:** Northwind Logistics — mid-size US freight broker, ~800 employees, headquartered in Columbus OH.

**Engagement type:** Anthropic POC. They're evaluating Claude for internal tooling. 60-day pilot, started 2026-04-15.

**Stated problem:** "We need a chatbot over our internal docs."

**Real problem (intended for /discovery to surface):** Their tier-1 ops support team is drowning — 40% of incoming tickets are "how do I do X in TMS" questions answered in Confluence. The chatbot is the vehicle; deflecting tier-1 volume is the actual goal. Executive sponsor wants headcount savings; champion in eng wants to ship anything that demonstrates Claude value before renewal conversations in Q3.

**Champion:** Maya Chen, Staff Engineer on Internal Platform team.
**Decision maker:** Raj Patel, VP Engineering.
**Skeptic:** Tom Reilly, Security & Compliance lead (worried about Confluence data exposure).

**Stack (intentionally messy):**
- Python/FastAPI internal services
- Confluence (200k pages, 10 years of accumulated knowledge)
- Snowflake for warehouse
- Okta SSO
- AWS (us-east-1), some legacy on-prem
- No vector DB yet — they've been told they need one

**Known constraints:**
- Confluence has page-level ACLs that must be respected
- Legal won't approve sending data outside us-east-1
- No production deployment without SOC2 review (6-week queue)

## Files

- `transcripts/kickoff-2026-04-15.md` — first call transcript (use with `/discovery`)
- `expected/` — what the customer context files should look like after both skills run cleanly
- `RUN-REPORT.md` — record of an actual end-to-end run, including any bugs found

## Reusing the scenario

```bash
# Spin up a throwaway ops repo
TMPDIR=$(mktemp -d)
cd "$TMPDIR" && git init -q -b main && git commit -q --allow-empty -m "init"

# Launch claude here and run the skills against customer "northwind"
# /customer-context northwind
# /discovery northwind <paste transcripts/kickoff-2026-04-15.md>

# Compare $TMPDIR/customers/northwind/ against expected/
```

When skills change in ways that affect output shape, regenerate `expected/` from a clean run and commit the diff.
