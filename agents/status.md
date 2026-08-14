# Status Worklog — hetzner-hardening

Append-only worklog. Newest entries at the top. Each entry: date, what changed,
why, and the resulting state.

## 2026-08-14

### Agent docs moved under `agents/`

- **What.** Adopted the `cronmalm-server` handoff layout. `WORKPLAN.md` →
  `agents/workplan.md` and `LESSONS.md` → `agents/lessons.md` (both via
  `git mv`, so history follows). Added this append-only worklog and
  `agents/plans/` with a README for future focused plans. Rewrote root
  `AGENTS.md` as the entry-point context file: what this repo is, where the
  agent files live, the hardening facts, and the conventions.
- **Why.** The two repos are worked on in the same sessions and referenced each
  other's paths; a single layout means an agent landing in either one looks in
  the same places. `cronmalm-server` moved first (its lessons entry of
  2026-07-03).
- **Unchanged.** `PROJECT.md`, `README.md`, `GUIDE.md`, `docs/`, `scripts/`, and
  `configs/` keep their locations. `CLAUDE.md` and `GEMINI.md` stay as
  pointer stubs to `AGENTS.md` (`cronmalm-server` has neither; they are kept
  here so agents that only look for their own filename still find the
  instructions).
- **Result.** No script or config was touched, so the hardening posture is
  unchanged. `cronmalm-server`'s references to this repo point at
  `scripts/06-audit.sh` and the repo root, both still valid.
