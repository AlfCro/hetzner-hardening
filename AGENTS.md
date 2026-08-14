# AGENTS.md — hetzner-hardening

> Entry-point context file for AI coding agents (Claude Code, Codex,
> OpenCode, ...) working on this repo. Read this first. Keep it accurate.
> Implementation status lives in [agents/workplan.md](agents/workplan.md) and
> [agents/status.md](agents/status.md).

## What this is

`hetzner-hardening` holds the hardening scripts and documentation for a Hetzner
Cloud VPS running Ubuntu 24.04 — SSH hardening, a dual-layer firewall, fail2ban,
Tailscale, unattended upgrades, and an audit script. It is the **owning repo for
the box's security posture**: `~/cronmalm-server` (the app/deploy repo on the
same VPS) depends on it and calls `scripts/06-audit.sh`. Changes here change a
live server — see "Scripts are the source of truth" below.

## Where the agent files live

- **[agents/workplan.md](agents/workplan.md)** — live roadmap, current status,
  and next steps.
- **[agents/status.md](agents/status.md)** — append-only worklog.
- **[agents/lessons.md](agents/lessons.md)** — gotchas, decisions about
  conventions, and operational facts worth remembering.
- **[agents/plans/](agents/plans/)** — focused implementation plans. New plan:
  create `agents/plans/NN-<name>.md` and link it from
  [agents/workplan.md](agents/workplan.md).
- **[PROJECT.md](PROJECT.md)** — architecture, tech stack, constraints, and the
  numbered decisions.

`CLAUDE.md` and `GEMINI.md` are immutable pointer stubs to this file — do not
edit them, and do not put instructions there.

## Repo layout

| Path | Contents |
| --- | --- |
| `scripts/` | The hardening steps `01`–`06`, `common.sh` helpers, and the `hetzner-hardening.sh` entry point (`--step`, `--all`, `--ref`) |
| `docs/` | Numbered reference docs — server/SSH, firewall strategy, setup steps, Tailscale, quick reference, security checklist |
| `configs/` | Reusable config templates (currently `fail2ban/` jails for extra public listeners) |
| `GUIDE.md` | Plain-English walkthrough for a first-time setup |

## Scripts are the source of truth

- Scripts must stay **idempotent** — they are re-run against a live box to
  correct drift, not run once at build time.
- Step 1 runs as `root`; steps 2–6 run as `deploy`.
- A change to intended policy is not done until the matching **assertion in
  `scripts/06-audit.sh`** exists. Audit the *effective* state (ask the running
  service), never the presence of a config file — see the 2026-07-04 lesson.
- **Every public listener gets a fail2ban jail in the same change that opens
  it.** Ports that answer with a credential prompt get `ufw limit`, not `allow`.
- Never weaken the posture as a side effect: SSH port/auth, the deny-by-default
  UFW, fail2ban, and unattended-upgrades stay as they are unless that is
  explicitly the task.

## Lessons Learned Protocol

- **Read [agents/lessons.md](agents/lessons.md)** at the start of every session
  before making changes.
- **Append an entry** whenever: a bug took multiple attempts to fix, something
  behaved unexpectedly, you were corrected by the user, or a new convention was
  established.
- Follow the existing entry format. Append only — never edit or remove existing
  entries.
- Tags: `[backend] [frontend] [database] [devops] [testing] [gotcha]
  [performance] [pattern]` · Severity: 🔴 critical | 🟡 important | 🟢 nice-to-know

## Git Workflow

After each logical change, **ask the user if you should commit** and suggest a
concise commit message describing the "why". Do **not** push to remote unless
explicitly asked.

- Stage only the specific files that were changed (no `git add -A`)
- Do not commit without user confirmation
- Never commit secrets, keys, or real IP/host inventories beyond what is
  already documented

## Clean Code

- **Naming**: Names should reveal intent. No abbreviations unless universally
  understood (e.g. `id`, `url`). If you need a comment to explain what a
  variable holds, rename it instead.
- **Functions**: Do one thing. If a function needs "and" in its description,
  split it.
- **No magic values**: Extract unnamed numbers and strings into well-named
  constants — shared ones belong in `scripts/common.sh`.
- **DRY within reason**: Deduplicate when logic is truly shared. Three similar
  lines are fine — a premature abstraction is not.
- **Fail early**: Validate at the boundary, return/throw early, avoid deep
  nesting.
- **Delete dead code**: Don't comment it out. Git remembers.

## Conventions

- Keep [agents/workplan.md](agents/workplan.md) current — status, completed
  slices, and an explicit next step. [agents/status.md](agents/status.md) is an
  append-only worklog.
- Record decisions in [PROJECT.md](PROJECT.md) as they are made; record gotchas
  in [agents/lessons.md](agents/lessons.md).
- For larger efforts, create `agents/plans/NN-<name>.md` instead of overloading
  `PROJECT.md` or `agents/workplan.md`, and link it from the workplan.
- If the agreed direction changes, update the relevant markdown plan before
  continuing implementation.
- After each logical slice, update the relevant plan or checklist so the next
  session can continue from the saved state.
- Keep [README.md](README.md) and `docs/` up to date when scripts change setup,
  structure, or the resulting posture.
