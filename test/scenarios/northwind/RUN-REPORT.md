# Northwind end-to-end run report

**Date:** 2026-05-18
**Skills tested:** `/customer-context`, `/discovery`
**FDEstack version:** 0.1.0
**Result:** Both skills ran cleanly end-to-end. 4 rough edges found, none blocking.

## What ran

1. Bootstrapped throwaway ops repo via `bash init-ops-repo /tmp/fdestack-test-ops-<pid>`.
2. Walked `/customer-context northwind` through all 9 steps manually (no SKILL.md tool invocation — followed instructions line-by-line in bash).
3. FDE answered "Anything to update?" with company overview → routed to `profile.md`.
4. Committed: `context: northwind session 2026-04-15`.
5. Walked `/discovery northwind <transcript>` through all 9 steps. Transcript: `transcripts/kickoff-2026-04-15.md` (709 words, 30 paragraphs — well under long-transcript threshold).
6. Extracted: 8 stack items, 4 stakeholders, real vs. stated problem, 2 HIGH / 4 MED / 2 LOW unknowns, no context conflicts.
7. Wrote `discovery-2026-04-15.md`, rewrote `stack.md` / `stakeholders.md` / `unknowns.md` / `timeline.md` in place.
8. Committed: `discovery: northwind 2026-04-15`.
9. Wrote a cross-customer learning to `~/.fdestack/learnings.jsonl` (`confluence-acl-retrieval`, confidence 7).

Final commit graph:
```
a9a4ab4 discovery: northwind 2026-04-15
3f62d8b context: northwind session 2026-04-15
4a13332 chore: add .gitignore
53d44d1 init: fde ops repo
```

## Rough edges found

### 1. Empty Session Brief on first session (low priority)

When all context files are blank templates, the Session Brief has every section empty except the placeholder messages. `RECOMMENDED FIRST ACTION` has nothing to anchor to. Currently prints `[empty]`.

**Fix:** Add a first-session fallback in Step 6 — if `DRIFT_CHECK=first_session` AND no unknowns/blockers exist, recommend: *"Tell me what you already know about this customer (company, engagement stage, who's involved) — I'll route it to the right context file."*

**File:** `skills/customer-context/SKILL.md` Step 6.

### 2. `customers/` directory existence check is unreliable (medium)

In Step 1: `ls customers/ 2>/dev/null | head -3 || echo "NO_CUSTOMERS_DIR"` does not actually detect a missing `customers/` directory. When `customers/` is missing, `ls` writes to stderr (silenced) and returns nonzero; `head -3` reads an empty pipe and returns 0. The `||` branch never fires.

**Fix:** Use `[ -d customers/ ] || echo "NO_CUSTOMERS_DIR"`.

**File:** `skills/customer-context/SKILL.md` Step 1.

**Caught by:** none of the existing unit tests cover this path. Add to `test/git-ops.test.sh`.

### 3. `<git user.name>` placeholder in discovery file (low)

The SKILL.md template for the discovery file uses literal `<git user.name>` — meant as a Claude-resolved placeholder, but easy to miss. Worth making explicit: "set `FDE_NAME=$(git config user.name)` and substitute in the heredoc."

**File:** `skills/discovery/SKILL.md` Step 6.

### 4. Date assumption in commit message + discovery filename (medium)

Both commit messages and the `discovery-YYYY-MM-DD.md` filename use `$(date +%Y-%m-%d)` — today's date. But meeting transcripts often arrive days late. If the kickoff was Mon and the FDE runs `/discovery` Thu, the filename is `discovery-Thu.md` for a Mon meeting. Confusing.

**Fix:** Accept an optional `--date YYYY-MM-DD` arg, or extract the date from a `**Date:**` line in the transcript, or just ask once: *"What date should this discovery be tagged with? (default: today)"*

**File:** `skills/discovery/SKILL.md` Step 6 + Step 8.

## What worked well

- Session marker logic is tight — 22s age, well under 12h, gate let `/discovery` proceed.
- Drift detection correctly identified first_session (no git history yet).
- Confirm-before-commit flow in `/customer-context` showed clean `?? customers/northwind/` and committed cleanly.
- `/discovery` auto-commit (no confirmation) felt right — the FDE just reviewed the extracted output.
- Extraction quality was solid: real vs. stated problem distinction came through, Tom's veto-capable position was captured without overplaying it, learnings.jsonl entry was specific enough to be useful for a future Confluence engagement.
- Cross-customer learning JSON validated cleanly with `jq`.

## Regenerating this fixture

When skills change in ways that affect output shape:

```bash
TEST_OPS=$(mktemp -d)
bash ~/fdestack/init-ops-repo "$TEST_OPS"
# (re-run the two skill walkthroughs against $TEST_OPS)
cp -r "$TEST_OPS/customers/northwind/." ~/fdestack/test/scenarios/northwind/expected/
git -C ~/fdestack diff test/scenarios/northwind/expected/  # review
```

## Next test scenarios worth adding

- **Existing customer, drift detection** — second session against a populated ops repo, where files have changed since last commit. Verifies the drift summary in Session Brief.
- **Declined commit** — FDE answers "no" to the commit prompt. Verifies the `declined=true` flag in session marker and the warning shown in the next session.
- **Stale session marker** — `/discovery` against a marker older than 12h. Verifies the stop-and-redirect message.
- **Context conflict** — transcript says X, existing stakeholders.md says Y. Verifies the conflict gets flagged in discovery file rather than silently overwritten.
- **Long transcript** — 100+ paragraph transcript. Verifies the warning prints but extraction still proceeds (no truncation).
