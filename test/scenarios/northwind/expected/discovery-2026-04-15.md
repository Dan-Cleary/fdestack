# Discovery: 2026-04-15
FDE: Dan Cleary

## New Stack Info
- Python/FastAPI for internal services
- AWS us-east-1 (legal won't approve cross-region — hard constraint)
- Okta SSO
- Snowflake warehouse (no AI-shaped usage yet)
- Confluence (~200k pages, 10 years, page-level ACLs that MUST be respected)
- No vector DB yet — "told they need one"
- Some legacy on-prem
- SOC2 review queue ~6 weeks; required for any new system touching internal data

## New Stakeholders
- **Maya Chen** — Staff Engineer, Internal Platform team. Day-to-day owner. Champion. Pragmatic — explicitly named the "shipping a chatbot nobody uses = maintenance burden" failure mode.
- **Raj Patel** — VP Engineering. Decision maker / executive sponsor. Renewal narrative is a personal stake (told his boss he'd have AI shipped before Q3).
- **Tom Reilly** — Security & Compliance lead. Skeptic. Owns SOC2 review. Sees ACL-aware retrieval as the biggest risk and "hasn't seen a pattern he loves." Veto power — "fireable offense" framing.
- **Sandeep (last name TBD)** — on Maya's team, has been experimenting with LangChain on the side. To be brought into future conversations.

## Stated Problem
Ship a Claude-powered chatbot over internal Confluence by end of June. Employees can use it. Working pilot, then SOC2 review for wider rollout.

## Real Problem (inferred)
Two real problems stacked.

First: **Raj needs a renewal story.** He committed to his boss that there'd be a working Anthropic-powered internal product before Q3 board conversations. The chatbot's existence matters more to him than its impact. This is what drove the meeting.

Second: **Maya needs ticket deflection.** 40% of tier-1 support volume is "how do I do X in TMS" — already answered in Confluence, but employees Slack support instead. A chatbot that doesn't drive measurable deflection is net-negative for her team because of the maintenance cost.

The unstated risk is **Tom**. ACL-aware retrieval is the technical crux; if we propose a design Tom rejects, the project doesn't ship to production no matter how good the model performance is. He's not a hostile skeptic — he's a "show me a pattern" skeptic, which is more tractable.

## Open Questions / Follow-ups
**HIGH:**
- How will ACL-aware retrieval work over Confluence with page-level permissions enforced at query time? (Tom's blocker.)
- FDE commit: bring an ACL-aware retrieval architecture proposal back next week.

**MED:**
- Confluence read access for Dan (Maya owns, target Friday).
- Intro to ops support team — need ticket data to validate the 40% deflection hypothesis.
- Which vector DB to use — no decision yet, options open.
- What is Sandeep building with LangChain? Could conflict or accelerate.

**LOW:**
- SOC2 queue mechanics — when does the 6-week clock start, what gates does it have?
- Definition of "200+ weekly active employees" — total employees? specific teams? measurement plan?

## Context Conflicts
None — transcript is consistent with existing context.

## Updates Made
- stack.md: added languages, infra, auth, data systems, constraints sections
- stakeholders.md: added Maya, Raj, Tom, Sandeep
- unknowns.md: added 2 HIGH, 4 MED, 2 LOW
