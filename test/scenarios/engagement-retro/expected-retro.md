# Engagement retro: northwind — week of 2026-05-12 → 2026-05-19
**FDE:** Dan Cleary
**Window:** 2026-05-12 to 2026-05-19 (7 days)

## Shipped
- /scope ACL filter test harness (scope-2026-05-13.md). Tom Reilly named as validator — clears the SOC2-veto risk path.
- Decision logged: build 5-query negative ACL test harness against staging Confluence (decisions.md 2026-05-15).
- Total: 2 commits touching customers/northwind/ this window.

(Activity: 2 commits, 1 scope, 0 value-frames, 0 POC, 0 integrate)

## Stuck
**HIGH blockers:** None new.

**HIGH unknowns (carried from prior weeks):**
- ACL-aware retrieval design over Confluence — *carrying from prior week*. The scope landed; impl still pending.
- FDE-owned: architecture proposal due next week — *carrying from prior week*.
- Confluence read access for FDE — *carrying from prior week, 4+ weeks late at this point — escalation candidate*.
- Intro to ops support team — *carrying from prior week*.
- Vector DB selection — *carrying from prior week*.

Items appearing 2+ retros in a row are flagged for escalation:
- "Confluence read access" — first appeared in discovery-2026-04-15, now 5 weeks open. Recommend IT escalation via Raj.

## Learned
**Decisions made:**
- 2026-05-15: Phase 1 ACL test harness scope — Tom Reilly named validator.

**Cross-customer learnings written back:**
- None this week. (Prior week's confluence-per-user-tokens learning still in learnings.jsonl.)

## Next
**Upcoming milestones (next 14d):**
- 2026-04-21 (Tue): Working session — bring ACL-aware retrieval proposal *(past — needs status update)*

**What needs to be true at the next milestone:**
- ACL test harness must show zero leakage on 5 negative queries before main chatbot wedge starts.

**New unknowns surfaced this retro:**
- [retro-2026-05-19] Is the architecture proposal commitment (originally due "next week" 2026-04-15) considered delivered, or still open? Resolve before the next session.
