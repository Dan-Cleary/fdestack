# Scenario: /integrate cleanroom rebuild

**Tests:** `/integrate` Step 3 + Step 5 — the cleanroom contract. The skill must produce production code by reading scope.md + stack.md + decisions.md + value-frame.md, and explicitly NOT reading anything under `customers/<name>/poc/`.

This is the single most architecturally interesting test in the pack. If `/integrate` reads POC code, it copies POC shortcuts (hardcoded values, missing error handling, fake tokens) into production. The cleanroom contract prevents this by design — POC learnings reach `/integrate` only through the structured write-backs that `/poc` performs.

## Setup

1. Seed ops repo with Northwind fixture + scope file.
2. Run `/poc` first (per `poc-learnings-writeback/` scenario) — this populates stack.md with the technical fact, decisions.md with the design decision, and learnings.jsonl with the cross-customer pattern.
3. Plant a **sentinel string** in `customers/northwind/poc/chatbot.py`: `PURPLE_HEDGEHOG_42`. This is a unique token that would only appear in `integrate/` files if the skill accidentally read or copied POC content.
4. Add a `value-frame-*.md` so /integrate has the $ bar.
5. Run `/integrate northwind`.

## Expected behavior

- `customers/northwind/integrate/` populated with production code + README.
- Production code references `decisions.md` entry **by date** (proves it consumed the structured handoff, not the POC).
- Production code matches stack.md patterns (Okta SSO, audit logger), not POC shortcuts (hardcoded tokens).
- README's "Decisions inherited" section names the specific decisions.md entries.
- Sentinel `PURPLE_HEDGEHOG_42` does NOT appear anywhere under `integrate/`.

## Result: PASS

```
sentinel check: PURPLE_HEDGEHOG_42 should NOT appear in integrate/
  PASS: no POC sentinel in integrate/ — cleanroom held

integrate/ references decisions.md by date?
  PASS: integrate/ explicitly cites decisions.md entry (proper handoff)
```

The production code's docstring explicitly states "Built from scope-2026-04-22.md + decisions.md (per-user-token decision, 2026-04-25). This is a CLEANROOM rebuild — no reference to POC code." Production implementation reaches for production primitives (Okta token exchange, audit logger) rather than the POC's hardcoded shortcuts. README's "Decisions inherited" section cites decisions.md by date.

See `expected-integrate-code.py` and `expected-integrate-readme.md` for verified outputs.

## Why this matters

The cleanroom contract isn't enforced by file permissions — it's enforced behaviorally by the SKILL.md instructions. The model agent reads `/integrate` Step 3 ("DO NOT READ THE POC DIRECTORY") and Step 5 ("Do not list `customers/<name>/poc/`. Do not Read any file under it.") and honors them.

This works because the structured write-back in `/poc` Step 9 has already routed everything important into stack.md and decisions.md. If `/integrate` is missing critical context, that's a signal that the write-back was incomplete — and that's a **/poc gap, not a /integrate gap**. The cleanroom contract makes missing write-backs immediately visible, instead of letting them hide as "I'll just peek at the POC."

The sentinel-string check is the regression test. If a future edit to `/integrate` SKILL.md weakens the prohibition, the sentinel scenario will fail.
