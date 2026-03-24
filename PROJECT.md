# Project: Hetzner VPS Hardening

## Overview

Step-by-step hardening scripts and documentation for a Hetzner Cloud VPS running Ubuntu 24.04. Based on the levelsio/Claude VPS hardening checklist. Automates SSH hardening, dual-layer firewalls, intrusion prevention, mesh VPN setup, automatic security updates, and security auditing.

## Architecture

```
┌─────────────────────────────────────────────┐
│              Hetzner Cloud                  │
│  ┌───────────────────────────────────────┐  │
│  │  Cloud Firewall (Layer 1)             │  │
│  │  Drops packets before reaching OS     │  │
│  │  Ports: 41122, 80, 443               │  │
│  └───────────────┬───────────────────────┘  │
│                  │                           │
│  ┌───────────────▼───────────────────────┐  │
│  │  Ubuntu 24.04 VPS (CX22)             │  │
│  │                                       │  │
│  │  UFW (Layer 2)     ← deny by default  │  │
│  │  Fail2ban          ← 24h bans        │  │
│  │  SSH on 41122      ← key-only auth   │  │
│  │  Tailscale (ts0)   ← mesh VPN        │  │
│  │  Unattended upgrades ← auto-patch    │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Tech Stack

| Component           | Technology                          |
| ------------------- | ----------------------------------- |
| Server              | Hetzner Cloud CX22 (2 vCPU, 4 GB)  |
| OS                  | Ubuntu 24.04 LTS                    |
| SSH                 | OpenSSH on port 41122, Ed25519 keys |
| Outer firewall      | Hetzner Cloud Firewall              |
| Inner firewall      | UFW                                 |
| Intrusion prevention| Fail2ban                            |
| VPN                 | Tailscale (WireGuard-based)         |
| Auto-updates        | unattended-upgrades                 |
| Shell scripts       | Bash                                |

## Domain / Data Model

Not applicable — this is an infrastructure/DevOps project with no application data model. The "data" consists of system configuration files:

- `/etc/ssh/sshd_config.d/hardened.conf` — SSH hardening
- `/etc/fail2ban/jail.local` — Fail2ban rules
- `/etc/apt/apt.conf.d/50unattended-upgrades` — Auto-update policy
- `/etc/apt/apt.conf.d/20auto-upgrades` — Update schedule
- UFW rules managed via `ufw` CLI

## Key Constraints & Decisions

1. Scripts must run in order (step 1 as root, steps 2–6 as deploy user)
2. SSH port 41122 chosen as non-standard port to reduce bot noise
3. Fail2ban ban time set to 24 hours (not the 10-minute default)
4. Tailscale subnet (100.64.0.0/10) whitelisted in fail2ban to prevent self-lockout
5. Auto-reboot window set to 04:00 UTC for kernel patches
6. `hetzner-hardening.sh` provides a single entry point with `--step`, `--all`, and `--ref` flags

## Roadmap / Active Initiatives

- Active initiative: Initial release — scripts and documentation complete
- Current status: Complete
- Next milestone: None planned — project is stable and usable

## Open Questions

- [ ] Whether to add an optional step to lock SSH exclusively to the Tailscale interface (currently documented as manual/optional in step 4)
