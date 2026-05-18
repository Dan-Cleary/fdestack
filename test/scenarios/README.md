# FDEstack test scenarios

End-to-end scenario tests for FDEstack skills. Complements the unit tests in `test/*.test.sh`.

Unit tests cover individual primitives (symlinks, marker math, git diff). Scenarios cover the *integration* — how Claude executes a SKILL.md against a real ops repo.

## Scenarios

| # | Scenario | Skill | What it tests | Form |
|---|---|---|---|---|
| 1 | `northwind/` | `/customer-context` + `/discovery` | Happy path end-to-end on a fresh customer | Manual walkthrough |
| 2 | `drift/` | `/customer-context` | Step 5 surfaces multi-file git diff between sessions | Manual walkthrough |
| 3 | `discovery-gate/` | `/discovery` | Step 1 refuses when marker missing or ≥12h old | Automated (`bash test.sh`) |
| 4 | `context-conflict/` | `/discovery` | Step 5+7 flag conflicts; existing entries preserved | Manual walkthrough |
| 5 | `learning-recall/` | `/customer-context` | Step 3 surfaces cross-customer learnings on different customer | Manual walkthrough |
| 6 | `scope-happy/` | `/scope` | Binary criteria path — no unknowns appended, clean scope file | Manual walkthrough |
| 7 | `scope-vague/` | `/scope` | Vague criteria path — `[NEEDS CLARIFICATION]` + HIGH unknowns + loop verified | Manual walkthrough |
| 8 | `value-frame-happy/` | `/value-frame` | Time lever, clean headline + sensitivity + defensibility | Manual walkthrough |
| 9 | `value-frame-vague/` | `/value-frame` | Lever-unclear path — all 4 dims flagged, recommends /scope | Manual walkthrough |

## Two forms, on purpose

**Automated scenarios** (`discovery-gate/`) test pure bash logic — gate conditions, freshness math. Run with `bash test.sh`.

**Manual walkthrough scenarios** (the rest) test model judgment — extraction, conflict detection, file routing. The bash steps are reproducible but the *content* requires a model. Each scenario's `README.md` documents inputs, expected behavior, and the result of the most recent walkthrough.

When SKILL.md files change in ways that affect outputs, re-run the manual walkthroughs and update the `expected-*.md` / `expected-*.txt` fixtures.

## Running everything

```bash
# Unit tests
bash test/run-all.sh

# Automated scenario tests
bash test/scenarios/discovery-gate/test.sh

# Manual scenarios — see each scenario's README for the walkthrough steps
```

## Coverage gaps

- **Declined commit flow.** When FDE answers "no" at `/customer-context` Step 8, the `declined=true` flag should land in the marker, and the next session should warn that drift may span multiple sessions. Worth adding before Phase 2.
- **Long transcript warning.** Triggers at >50 paragraphs. Not yet exercised.
- **Same-day discovery rerun.** Fixed in this commit (suffix `-2`, `-3`, ...) but no end-to-end scenario yet.
