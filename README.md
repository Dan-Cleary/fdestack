# FDEstack

**A Claude Code skill pack for forward-deployed engineers.**

Customer context that survives sessions. Discovery that distinguishes stated from real problems. Scope that forces binary success criteria. Value framing that defends against the CFO. POCs that capture what they teach. Production rebuilds that can't smuggle in POC shortcuts. Cross-customer learning that compounds.

All git-backed. All in your own private ops repo. Eight skills, one workflow, zero magic.

---

## Why this exists

Forward-deployed engineering — the work of embedding with a customer to prove a technical product works for *their* environment — is heavy on context and light on tooling. The work is mostly:

1. Hold a meeting, take notes, lose them
2. Build a thing that's roughly right
3. Forget what you decided, why
4. Move to the next customer
5. Discover you needed last month's notes

The "second customer problem" — where the first engagement felt magical because everything was in your head, and the second one falls apart because nothing is — is the FDE failure mode. FDEstack is the workflow that makes it survive across customers without ceremony.

You commit notes the same way you commit code. You track unknowns with the same rigor as bugs. You force binary success criteria the same way you force types. The git history *is* the engagement.

---

## A day with FDEstack

```
$ cd ~/fde-ops && claude

> /triage
════════════════════════════════════════════════════════════
TRIAGE: active cohort | 3 customers | 2026-05-19
════════════════════════════════════════════════════════════
▶ globex — Live integration, prod rollout next month
  Urgency: 20  (blockers:2  unknowns:2  within-7d:1)
  HIGH blockers:
    - Compliance review stalled at risk committee — 3 weeks no movement
    - Data residency (EU) blocks GCP us-region plan
  Upcoming:
    - 2026-05-22: Risk committee re-review (escalated)
    - 2026-06-01: Production launch

▶ northwind — Anthropic POC, mid-pilot
  Urgency: 10  (blockers:0  unknowns:8  within-7d:0)
  ...

▶ acme — Anthropic POC, mid-pilot
  Urgency: 0

RECOMMENDED FIRST ACTION:
  globex — prod launch in 13 days, 2 HIGH blockers, 1 within-7d milestone

> /customer-context globex
[Session Brief: prior decisions, drift since last session, blockers, learnings]

> # ... call with risk committee chair ...
> /discovery globex <transcript>
[Extracts: new stakeholder, real-problem-vs-stated, 3 new HIGH unknowns]

> /scope globex "Get risk committee approval by 2026-05-22"
[Forces binary success criteria. Vague items flag → unknowns.md HIGH.]

> /value-frame globex "Delaying launch by 30 days"
[Lever: Capital. Headline: $X/yr from delayed revenue. Sensitivity: $Y-$Z.]

> /poc globex --purpose feasibility
[Builds throwaway. At Step 9: "What did we learn?" → routes discoveries to
 stack.md, decisions.md, learnings.jsonl so /integrate can use them without
 ever reading the POC code.]

> /integrate globex
[Production-grade build. Refuses to read customers/globex/poc/. Cleanroom
 rebuild from scope + stack + decisions + value-frame.]

> # ... Friday evening ...
> /engagement-retro globex
[Shipped / Stuck / Learned / Next. Surfaces stale items as escalation
 candidates. Appends "what needs to be true by Monday" as new HIGH unknowns.]
```

Eight skills, one loop. Each writes structured markdown into `customers/<name>/`, each commits to your ops repo, each surfaces in the next `/customer-context` session.

---

## Quick start (5 minutes)

```bash
# 1. Clone + install
git clone https://github.com/Dan-Cleary/fdestack.git ~/fdestack
cd ~/fdestack && bash setup

# 2. Bootstrap your private ops repo
bash ~/fdestack/init-ops-repo
# → creates ~/fde-ops/ with .git initialized

# 3. Start your first customer session
cd ~/fde-ops && claude
```

Then in Claude Code:

```
/customer-context acme        # creates customers/acme/ from templates,
                              # prints session brief, asks what's new
```

To process a meeting transcript:

```
/discovery acme <paste transcript or notes>
```

That's the loop. Every subsequent skill is in the same shape.

---

## The eight skills

Each skill is invoked the same way: `/skill <customer> [args]`. Each reads from `customers/<customer>/` and writes back to it. Each commits cleanly. None require any service beyond `git` and `jq`.

### `/customer-context <name>`
Load (or create) a customer's context. Prints a session brief: open unknowns, current blockers, drift since last session, prior cross-customer learnings, recommended first action. Routes "anything new?" answers into the right file. Commits.

This is the **only skill that doesn't require a prior session marker.** Always run it first when entering a customer session.

### `/discovery <name> <transcript-or-notes>`
Process a meeting transcript. Extracts: new stack info, new stakeholders, **stated problem vs. real problem (inferred from subtext)**, open questions, and any conflicts with existing context. Auto-commits a `discovery-YYYY-MM-DD.md`.

### `/scope <name> <problem statement>`
Force the wedge question: *"What's the smallest thing buildable this week that proves the core value?"* Requires **binary success criteria** — "feels faster" gets rejected; "8/10 hand-picked questions correct" gets accepted. Vague answers (no validator, no estimate, fuzzy criteria) push to `unknowns.md` HIGH with audit-trail tags so they surface in every future session until resolved.

### `/value-frame <name> <opportunity>`
Translate a process inefficiency into a defensible dollar value. Picks **exactly one primary lever** (Time / Errors / Capital / Volume / Risk). Writes the unit economics formula explicitly. Labels every assumption `[measured]`, `[stated]`, or `[estimated]`. Computes headline + sensitivity. Forces the question *"what's the most likely customer pushback?"* — and routes strategic-relevance pushback back to `/scope` instead of patching the value frame.

### `/poc <name> [--purpose value|showcase|feasibility]`
Build a throwaway proof-of-concept. **Speed over quality.** Hardcoded values, ugly code, no error handling beyond crash prevention. The POC is *never* going to production.

The skill's most important step is **mandatory learnings write-back** at the end. Three questions, three routing targets:
- "What new technical fact did we learn?" → `stack.md`
- "What design decision did we make, and why?" → `decisions.md`
- "Does anything apply to OTHER customers?" → `~/.fdestack/learnings.jsonl`

This is what makes `/integrate` possible.

### `/integrate <name>`
Production-grade rebuild. **Refuses to read `customers/<name>/poc/`.** Reads scope + stack + decisions + value-frame and builds fresh.

The cleanroom contract is the architectural pivot of the whole pack: POC discoveries reach production through structured write-backs, not by copying POC code. If `/integrate` is missing critical context, that's a `/poc` write-back gap — and it's *immediately visible* instead of hiding as "I'll just peek at the POC."

### `/triage [active|blocked|all]`
Cross-customer portfolio view. Scans every `customers/<name>/` directory, ranks by urgency (`blockers × 3 + min(unknowns, 5) × 2 + within_7d × 10`), prints a brief with recommended first action. Cohort filter: `active` (commit in last 14 days), `blocked` (HIGH items only), or `all`.

The only skill that doesn't write or commit. Pure read-only "where do I look first today?" view.

### `/engagement-retro <name> [--since YYYY-MM-DD]`
Weekly per-customer retrospective. Four questions: **shipped / stuck / learned / next**. Surfaces items that have appeared across multiple retros as escalation candidates. The forward-looking *"what needs to be true at the next milestone?"* consistently produces new HIGH unknowns the FDE was about to forget — tagged `[retro-DATE]` so the audit trail stays clean.

Renamed from `/retro` to avoid conflict with [gstack](https://gstack.dev)'s engineering-retrospective skill of the same name.

---

## Philosophy

A few opinions baked into the workflow:

**1. The git history is the engagement.**
Every skill commits. Every commit message follows `<skill>: <customer> <YYYY-MM-DD>`. `git log -- customers/acme/` answers "what happened on this engagement, in what order, who decided what." No external system to maintain. No notes-app to forget.

**2. Stated problem ≠ real problem.**
`/discovery` separates them on every transcript. The stated problem is what the customer said. The real problem is what you infer from subtext — the renewal narrative, the political dynamics, the unstated constraint. They're almost never the same. The skill forces you to write both.

**3. Binary success criteria or it goes to unknowns.md.**
"Make it better" is rejected by `/scope`. "Users like it" is rejected by `/value-frame`. The escape hatch isn't "fine, I'll skip it" — it's `[NEEDS CLARIFICATION]` inline plus a HIGH-priority entry in `unknowns.md` with an audit tag. The next `/customer-context` session shows it. The retro flags it if it's been there too long. The vague answer becomes visible debt.

**4. POC code is never read by `/integrate`.**
This is the cleanroom contract. `/poc`'s mandatory write-back routes every relevant discovery into `stack.md` / `decisions.md` / `learnings.jsonl`. `/integrate` reads those. If something important didn't make it into the write-back, `/integrate` will hit the gap and flag it — instead of letting POC shortcuts (hardcoded tokens, missing error handling, fake data) silently leak into production. **Cleanroom is the mechanism that makes the write-back honest.**

**5. The unknowns loop closes itself.**
`/scope` and `/value-frame` and `/engagement-retro` all push vague items to `unknowns.md` HIGH. `/customer-context` surfaces them in the Session Brief. `/triage` includes their count in urgency scoring. `/engagement-retro` flags items appearing across multiple weeks. There's no separate todo system because the customer context files *are* the todo system.

**6. Cross-customer learning compounds.**
`~/.fdestack/learnings.jsonl` accumulates patterns: "Snowflake environments often disallow UDFs," "Confluence per-user tokens beat service-account ACL filters," "renewal-narrative customers care about demo over correctness." `/customer-context` surfaces the top entries on every session. After three engagements, you stop rediscovering things.

---

## Customer context schema

Each customer has 7 files under `customers/<name>/`:

| File | Contains |
|---|---|
| `profile.md` | Company overview, engagement stage |
| `stack.md` | Languages, infra, auth, data systems, constraints |
| `stakeholders.md` | Champions, decision makers, technical contacts, skeptics |
| `blockers.md` | Current blockers by severity (HIGH/MED/LOW) |
| `unknowns.md` | Open unknowns by severity |
| `decisions.md` | Decision log with rationale |
| `timeline.md` | Key dates, upcoming milestones, history |

Plus, as a session unfolds, the skills add dated artifacts:
- `discovery-<DATE>.md` — one per meeting
- `scope-<DATE>.md` — one per problem scoped
- `value-frame-<DATE>.md` — one per opportunity framed
- `poc/` — throwaway POC code + README
- `integrate/` — production code + README
- `retro-<DATE>.md` — one per weekly retro

Plus the cross-customer:
- `~/.fdestack/learnings.jsonl` — generalizable patterns

Templates live in `templates/`. Skills create files from templates on first run; never silently overwrite.

---

## Roadmap

**Shipped (v0.1):**
- All 8 skills above, with 13 end-to-end scenario tests in `test/scenarios/`
- 33 unit tests for primitives (symlink setup, session marker math, git ops)
- The unknowns loop, the cleanroom contract, the cross-customer learnings file

**Possible next:**
- `/handoff <name> <doc>` — consume a structured handoff doc (prior FDE's exit notes, AE call summary, Solution Blueprint) and populate context files in one shot. Surfaced as a gap during a Celonis VE field test.
- Learning-relevance filtering — current `tail -3` is recency-only. At ~20+ learnings, older-but-relevant entries become invisible.
- Unreconciled-conflict detector — `/customer-context` could scan the latest `discovery-*.md` for non-empty `## Context Conflicts` sections and prompt for resolution at session start.

Not on the roadmap on purpose: a dashboard UI, a hosted service, anything that takes the work outside your ops repo.

---

## Testing

```bash
# Unit tests (33 assertions across symlinks, marker math, git ops)
bash test/run-all.sh

# Automated scenario test
bash test/scenarios/discovery-gate/test.sh

# Manual walkthrough scenarios
ls test/scenarios/
```

13 scenarios documented in `test/scenarios/README.md`. Each scenario has a `README.md` explaining the test, an `expected-*.md` set showing verified outputs, and (where automated) a `test.sh`.

---

## Structure

```
fdestack/
├── README.md
├── VERSION
├── setup                     # symlinks skills into ~/.claude/skills/
├── init-ops-repo             # bootstraps an FDE's private ops repo
├── templates/                # 7 blank customer context files
├── skills/
│   ├── customer-context/SKILL.md
│   ├── discovery/SKILL.md
│   ├── scope/SKILL.md
│   ├── value-frame/SKILL.md
│   ├── poc/SKILL.md
│   ├── integrate/SKILL.md
│   ├── triage/SKILL.md
│   └── engagement-retro/SKILL.md
└── test/
    ├── *.test.sh             # unit tests
    ├── run-all.sh
    └── scenarios/            # 13 end-to-end scenarios
```

---

## Background

FDEstack is built on the same conceptual scaffolding as [gstack](https://github.com/garrytan/gstack) — Claude Code skills as opinionated workflows, git as the persistence layer, structured markdown as the data format. If you're a software engineer, install gstack instead and use FDEstack as a complement for customer work.

If gstack's `/retro` and FDEstack's `/engagement-retro` are both installed, they coexist — different scopes (codebase retro vs. customer retro), no conflict.

---

## Contributing

Skills follow a consistent shape. To add one:

1. Create `skills/<your-skill>/SKILL.md` with the standard frontmatter:
   ```yaml
   ---
   name: <your-skill>
   description: |
     <one-paragraph summary>
     Usage: /<your-skill> <args>
   ---
   ```
2. Re-run `bash setup` to symlink it into `~/.claude/skills/`.
3. Add an end-to-end scenario under `test/scenarios/<your-skill>-<happy|vague>/`.
4. Update `test/setup.test.sh` to expect the new symlink.
5. Update `test/scenarios/README.md` and this README's skill table.

Most skills follow this step structure: parse inputs → check session marker → load learnings → load context → force-an-opinion step → write structured output → route vague items to `unknowns.md` HIGH → commit.

PRs welcome.

---

## License

MIT. See `LICENSE`.
