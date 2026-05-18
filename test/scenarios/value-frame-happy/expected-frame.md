# Value frame: Tier-1 ticket deflection from Confluence chatbot
**Date:** 2026-05-18
**FDE:** Dan Cleary
**Problem source:** scope-2026-04-22.md (Confluence chatbot wedge)
**Customer-side audience:** Maya Chen (champion) + Raj Patel (VP Eng, renewal narrative)

## Opportunity (one sentence)
Deflecting tier-1 ops support tickets to a Claude-powered Confluence chatbot frees support FTE capacity currently spent answering questions already documented.

## Primary Lever
**Time** (FTE hours freed). Errors lever is secondary (fewer human-mediated answers = fewer mistakes) but not in headline.

## Unit Economics
```
annual_value = weekly_tickets × answerable_pct × deflection_rate × handle_time_hours × loaded_hourly_rate × 52
```

## Assumptions
- **weekly_tickets:** 800 [measured: pulled from their ticketing system in discovery]
- **answerable_pct:** 40% [measured: explicitly cited by Maya in kickoff workshop]
- **deflection_rate:** 50% [estimated: of answerable questions, chatbot wins half — conservative starting point given ACL constraints]
- **handle_time_hours:** 0.20 (12 min/ticket) [stated: industry benchmark for tier-1 ops support, MetricNet 2024]
- **loaded_hourly_rate:** $45 [stated: US ops support loaded compensation, BLS + 35% loading]

## Headline
**~$75,000/year** (annualized, likely case)

## Sensitivity
- Conservative (deflection 35% + handle time -30%): **~$37,000/year**
- Likely: **~$75,000/year**
- Aggressive (deflection 65% + handle time +30%): **~$127,000/year**

The real uncertainty is the deflection rate. Handle time and volume are well-measured; the 35-65% sensitivity band on deflection is honest about how much the actual chatbot performance will move the number.

## Defensibility
**Most likely pushback:** numbers — Maya will challenge the 50% deflection assumption directly because it's the term she has the most signal on from running the support team.

**Specifically:** "We haven't seen any chatbot hit 50% on ops content before — why should we believe this one will?"

**Response prepared:** Frame the wedge POC explicitly as the measurement instrument. The /scope success criterion is 8/10 hand-picked questions correct = directly informs the deflection rate empirically. Headline value is *conditional* on the POC meeting that bar; if it lands at 4/10 instead, conservative case ($37k) is the right number; if it lands at 9/10, aggressive case is in play. The wedge is calibration, not just feasibility.

## Additional Value (secondary, not in headline)
- Reduced ticket misroutes (tier-1 → tier-2 escalation when tier-1 doesn't know the answer)
- Faster onboarding for new support hires (institutional knowledge in chatbot, not human shadowing)
- Compounding value as Confluence grows — chatbot scales with documentation; FTE doesn't

## Open Items
All checks passed.
