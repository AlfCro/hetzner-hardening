# Lessons Learned

<!-- Tags: [backend] [frontend] [database] [devops] [testing] [gotcha] [performance] [pattern] -->
<!-- Severity: 🔴 critical | 🟡 important | 🟢 nice-to-know -->
<!-- Append only — never edit or remove existing entries. -->

---

### 2026-08-14 · 🟢 [devops][pattern] Agent docs live under `agents/`

This repo follows the same handoff layout as `~/cronmalm-server`: root
`AGENTS.md` is the entry point, `agents/workplan.md` is the live roadmap,
`agents/status.md` is the append-only worklog, `agents/lessons.md` (this file)
holds gotchas, and focused plans go in `agents/plans/NN-<name>.md` linked from
the workplan. `WORKPLAN.md` and `LESSONS.md` used to sit in the repo root —
they were moved with `git mv` on 2026-08-14, so old paths in commit messages
and in `cronmalm-server`'s append-only `status.md` still refer to the root
names. `CLAUDE.md` and `GEMINI.md` stay as immutable pointer stubs to
`AGENTS.md`. Both repos are worked on in the same sessions, so keeping one
layout means an agent looks in the same places whichever repo it lands in.

### 2026-07-04 · 🔴 [devops][gotcha] Audit effective hardening state, not intended files

The cronmalm posture review found documented-vs-effective drift: this repo's
docs and `scripts/03-fail2ban.sh` promised 24-hour sshd bans, `maxretry = 3`,
and the Tailscale `100.64.0.0/10` ignore range, but the live box had no
`/etc/fail2ban/jail.local`, so fail2ban was running Debian defaults (600-second
bans, `maxretry = 5`, no ignore list). The audit only checked that fail2ban was
running, so it missed the weaker effective policy. Fix: `06-audit.sh` now asks
fail2ban for the live sshd jail values (`bantime`, `maxretry`, `ignoreip`) and
flags drift directly. Also note that `systemctl restart fail2ban` can return
before the fail2ban socket is ready; scripts that query it immediately should
wait for `fail2ban-client ping`.

### 2026-06-21 · 🟡 [devops][gotcha] Use tmux for long sessions, not mosh — mosh would breach the firewall

Long AI coding / build sessions kept dying when the operator's mobile SSH client
(Termius on Android) was backgrounded: the connection resets and the SIGHUP
aborts the foreground process. The tempting fix, `mosh`, is the wrong one here —
it needs a UDP port range (60000–61000) opened, which contradicts the
deny-by-default UFW this repo enforces. The right fix is a persistent `tmux`
session (`tmux new -A -s cc`, detach with `Ctrl-b` `d`, reattach with
`tmux attach -t cc`) over the existing `41122/tcp` SSH. `tmux` is already
installed by step 1. Takeaway: a session-persistence problem is never a reason
to open a port — reach for tmux, not mosh. Documented in
`docs/02-firewall-strategy.md` and `docs/05-quick-reference.md`.

### 2026-06-21 · 🟢 [devops][gotcha] tmux eats the scroll wheel until `set -g mouse on`

After moving long sessions into tmux, mouse/touch scrollback stopped working —
the wheel did nothing, which is disorienting on a mobile SSH client where the
wheel is the only practical way to look back. tmux doesn't pass the scroll wheel
through by default. Fix: `set -g mouse on` in `~/.tmux.conf` (also gives
click-to-select and drag-to-resize panes), then `tmux source-file ~/.tmux.conf`.
The box's `~/.tmux.conf` already carries this line.
