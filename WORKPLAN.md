# Work Plan: Hetzner VPS Hardening

Use this file as the live handoff between sessions. Keep it short, update the checkboxes as work is completed or re-scoped, and make the next logical step explicit.

## Current Status

- Summary: All six hardening scripts are implemented and documented, **but a 2026-07-04 posture review of the cronmalm VPS found live drift**: `/etc/fail2ban/jail.local` (written by `03-fail2ban.sh`) is missing on the box — fail2ban runs Debian defaults (10-min bans, maxretry 5, **no Tailscale whitelist**) instead of the documented 24h/3/whitelist. Root cause unknown (script never run, or file removed later); `06-audit.sh` did not catch it. The same review produced generic hardening patterns to fold into this repo (see Active Work).
- Current focus: restore the fail2ban baseline + absorb the generic patterns from the review. **Intended executor: a simpler/cheaper model** — the box-specific worked example with exact commands/verification lives in `~/cronmalm-server/agents/plans/01-security-hardening.md`; the items below are the generic halves.
- Next session should: do the first Active Work item (fail2ban baseline), then the rest in order.

## Active Work

- [ ] **Fail2ban baseline drift — restore + make auditable.** Re-run `scripts/03-fail2ban.sh` (idempotent: `tee`s `jail.local`, restarts fail2ban). Verify: `sudo fail2ban-client get sshd bantime` → `86400`, `maxretry` → `3`, `ignoreip` includes `100.64.0.0/10`. Then extend `06-audit.sh` to assert those three effective values (via `fail2ban-client get sshd …`, not by file presence) so this drift can't silently recur. Append a LESSONS.md entry (🔴 [devops][gotcha]): documented-vs-effective drift — the docs and the dependent repo both claimed settings the box didn't have; audit effective state, not intent. This is the **prerequisite (Task 0)** for the cronmalm plan's new jails.
- [ ] **Reusable fail2ban jail templates for extra public listeners.** Add `configs/fail2ban/` with two tested templates + a short doc section: (a) `mosquitto-auth` (MQTT broker auth failures — filter must be built against an observed log line, see cronmalm plan 01 Task 2 for the discovery procedure and the connection-rate fallback when the failure line lacks the IP); (b) `caddy-auth` (repeated 401/403 in Caddy JSON access logs — plan 01 Task 3 has the failregex and testing steps). Document the rule: **every public listener gets a jail in the same change that opens it.** Consider a `06-audit.sh` warning when `ss -tlnp` shows a public listener with no matching jail.
- [ ] **Firewall pattern: `ufw limit` for non-HTTP public listeners.** Update `docs/02-firewall-strategy.md` + `docs/06-security-checklist.md`: ports that answer with a credential prompt (MQTT, SMTP, etc.) get `sudo ufw limit <port>/tcp` (6 conns/30s/IP), not plain `allow` — brute force needs fresh TCP connections; a persistent legit client is unaffected. Worked example: cronmalm plan 01 Task 1 (MQTT 8883).
- [ ] **Access-model pattern: public vs household-only apps.** Add to `docs/02-firewall-strategy.md` (or GUIDE): apps meant to be reachable from anywhere stay public behind the reverse proxy with **app-level auth + edge throttling** (the jails above) — a CDN/identity proxy (e.g. Cloudflare Access) is not required at this scale and adds a second login + DNS migration for little gain when the origin IP is already public. Apps meant for household/private use are **never published on 80/443**: bind them to the tailscale0 interface or gate the vhost with a `remote_ip 100.64.0.0/10` matcher (Tailscale is already part of this hardening, script 04). The cronmalm-specific ruling is recorded as PROJECT.md decision 15 in that repo; this item is the generic pattern.

## Completed Recently

- [x] Initial setup script (01-initial-setup.sh) — creates deploy user, hardens SSH, installs tools
- [x] UFW firewall script (02-firewall.sh) — dual-layer firewall with rate limiting
- [x] Fail2ban script (03-fail2ban.sh) — 24h bans, Tailscale whitelist
- [x] Tailscale script (04-tailscale.sh) — mesh VPN installation and setup
- [x] Unattended upgrades script (05-unattended-upgrades.sh) — auto-patching with scheduled reboots
- [x] Security audit script (06-audit.sh) — comprehensive posture check
- [x] Main entry point (hetzner-hardening.sh) — --step, --all, --ref flags
- [x] Shared helpers (common.sh) — variables and colored output
- [x] README with usage instructions and documentation index
- [x] Plain-English setup guide (GUIDE.md) — beginner-friendly walkthrough
- [x] Detailed docs (docs/) — server specs, firewall strategy, setup steps, Tailscale/dev, quick reference, security checklist
- [x] PROJECT.md populated with actual project details

## Risks / Open Questions

- [ ] Optional Tailscale-only SSH lockdown not scripted (documented as manual step)
