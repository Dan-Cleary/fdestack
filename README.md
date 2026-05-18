# FDEstack

Claude Code skill pack for forward deployed engineers. Drop into any ops repo to get AI-assisted customer context management, discovery, scoping, POC, and integration skills — all git-backed and cross-customer aware.

## Quick start (5 minutes)

**1. Install FDEstack**

```bash
cd ~/fdestack
bash setup
```

This symlinks the skills into `~/.claude/skills/` and creates `~/.fdestack/learnings.jsonl`.

**2. Create your ops repo**

```bash
bash ~/fdestack/init-ops-repo
```

This creates `~/fde-ops/` with the right structure and an initial git commit. Pass a path to use a different location: `bash ~/fdestack/init-ops-repo ~/my-fde-ops`.

**3. Start your first customer session**

```bash
cd ~/fde-ops
claude
```

Then in Claude Code:
```
/customer-context acme
```

Claude will create context files from templates, print a session brief, and ask what's new.

**4. Process a meeting transcript**

After loading customer context, paste a transcript:
```
/discovery acme <transcript>
```

Claude extracts stack info, stakeholders, stated problem, real problem, and open questions — then commits to your ops repo.

## Skills

| Skill | What it does |
|---|---|
| `/customer-context <name>` | Load customer context, surface drift, update files, commit |
| `/discovery <name> <transcript>` | Process a meeting transcript and update customer context |
| `/scope <name> <problem>` | Force binary success criteria; push vague items to unknowns.md HIGH |
| `/value-frame <name> <opportunity>` | Translate inefficiency into defensible $ with lever taxonomy + sensitivity + defensibility check |

More skills coming in later phases (POC, integration, triage, retro).

## Customer context schema

Each customer gets 7 files under `customers/<name>/`:

| File | Contains |
|---|---|
| `profile.md` | Company overview, key contacts, engagement context |
| `stack.md` | Languages, infra, auth, data systems, constraints |
| `stakeholders.md` | Champions, decision makers, technical contacts, skeptics |
| `blockers.md` | Current blockers by severity |
| `unknowns.md` | Open unknowns by severity |
| `decisions.md` | Decisions made during the engagement |
| `timeline.md` | Key dates, upcoming milestones, history |

## Cross-customer learnings

Patterns that appear across engagements are saved to `~/.fdestack/learnings.jsonl` — surfaced at the start of each session.

## Tests

```bash
bash test/run-all.sh
```

## Structure

```
fdestack/
  setup              # install script
  VERSION            # semver
  templates/         # blank context files
  skills/
    customer-context/SKILL.md
    discovery/SKILL.md
  test/
    setup.test.sh
    marker.test.sh
    git-ops.test.sh
    run-all.sh
```
