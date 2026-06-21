# Lessons Learned

<!-- Tags: [backend] [frontend] [database] [devops] [testing] [gotcha] [performance] [pattern] -->
<!-- Severity: 🔴 critical | 🟡 important | 🟢 nice-to-know -->
<!-- Append only — never edit or remove existing entries. -->

---

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
