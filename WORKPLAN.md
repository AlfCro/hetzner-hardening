# Work Plan: Hetzner VPS Hardening

Use this file as the live handoff between sessions. Keep it short, update the checkboxes as work is completed or re-scoped, and make the next logical step explicit.

## Current Status

- Summary: All six hardening scripts are implemented and working. Documentation (README, GUIDE, docs/) is complete and aligned with the scripts. The project is in a stable, usable state.
- Current focus: Maintenance — no active development.
- Next session should: Review for any improvements or address new issues as they arise.

## Active Work

No active work items. The project is complete.

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
