# Changelog

All notable changes to FDEstack. Format inspired by [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.2.0] — 2026-05-19

The "make it feel like a real skill pack" release. Same 9 skills (now with `/learnings`), plus the proactive/voice/AskUserQuestion polish that makes the workflow self-evident.

### Added
- **`/learnings`** — management skill for `~/.fdestack/learnings.jsonl`. List, search, prune (with AskUserQuestion-driven review of each entry), edit, export. Pre-empts the "write-only graveyard" failure mode.
- **Proactive suggestion + voice triggers** on every skill. Skills now auto-invoke when the user's intent matches, and they recognize natural-language phrasings ("I just had a meeting", "where should I look first") and dictation aliases.
- **AskUserQuestion in `/scope` vague path** — vague items no longer silently push to unknowns.md. Decision brief gives FDE three options: push to unknowns / resolve now / force-through (logged in decisions.md).
- **AskUserQuestion in `/discovery` context-conflict path** — conflicts surface as a structured choice (trust existing / trust new / edit manually) instead of being flagged in prose.
- **`init-ops-repo` writes a `CLAUDE.md`** with FDEstack routing rules + conventions, so Claude knows the skill catalog and intended order of operations from the first session.

### Changed
- **`/discovery` description** broadened to "any inbound source of customer context" (transcript, handoff doc, briefing, RFP, etc.) rather than "meeting transcript or notes." Reflects what the skill actually does.

## [0.1.0] — 2026-05-18

Initial release. All 8 skills from the original design doc shipped + 1 added from a field test (`/value-frame`). 13 end-to-end scenarios. 33 unit tests passing.

### Added
- **`/customer-context`** — per-session brief, drift detection, confirm-before-commit, cross-customer learnings surfaced.
- **`/discovery`** — meeting transcript processor; extracts stated-vs-real problem, stakeholders, stack, unknowns, conflicts.
- **`/scope`** — wedge question forcing function; binary success criteria; unknowns loop.
- **`/value-frame`** — dollar framing with lever taxonomy (Time/Errors/Capital/Volume/Risk), explicit unit economics, sensitivity, defensibility check. Added after a real-artifact field test exposed the gap.
- **`/poc`** — throwaway proof-of-concept with `--purpose value|showcase|feasibility` flag. Mandatory learnings write-back to stack.md / decisions.md / learnings.jsonl.
- **`/integrate`** — production rebuild. Refuses to read `customers/<name>/poc/`. Cleanroom contract enforced behaviorally.
- **`/triage`** — cross-customer portfolio view with urgency scoring. Cohort filter (active/blocked/all).
- **`/engagement-retro`** — weekly per-customer reflection (renamed from `/retro` to avoid gstack conflict). 4 questions + stale-item escalation flag.
- 7 customer context templates, `setup` script, `init-ops-repo` bootstrapper.
- 13 scenarios under `test/scenarios/`, 33 unit tests under `test/`.

### Notable design choices
- **The unknowns loop**: vague items from `/scope` and `/value-frame` get `[scope-DATE]` / `[value-frame-DATE]` audit tags in `unknowns.md` HIGH and surface in every future Session Brief.
- **The cleanroom contract**: `/integrate` is behaviorally forbidden from reading `customers/<name>/poc/`. POC discoveries reach `/integrate` through structured write-backs only.
- **Stated vs. real problem**: `/discovery` separates them on every transcript.
- **Git history is the engagement**: every skill commits. `git log -- customers/acme/` is the audit trail.

### Bugs found and fixed during scenario testing
- `/customer-context` Step 1 used `ls | head` to check for `customers/` dir — succeeded when dir was missing. Fixed with `[ -d ]`.
- `/discovery` Step 6 was clobbering same-day discovery files. Fixed with `-2`, `-3`, ... suffix.
- `/triage` urgency formula over-weighted unknowns. Real test ranked a discovery-stage customer above an integration-stage customer with a prod launch in 13 days. Fixed: cap unknown count at 5, 2x within-7d weight.
