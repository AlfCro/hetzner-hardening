# Setup Steps

## Prerequisites

1. Generate an Ed25519 key in Termius (Keychain > Keys > Generate)
2. Create VPS on Hetzner with that SSH key and firewall attached
3. Temporarily open port 22 in Hetzner firewall
4. Connect as `root` on port 22 via Termius

## Getting the Scripts

SSH into your server as `root` on port 22 using Termius (or any SSH client) with your Ed25519 key. Then clone this repo and prepare the scripts:

```bash
# On the server as root
git clone https://github.com/AlfCro/hetzner-hardening.git
cd hetzner-hardening/scripts
chmod +x *.sh
```

> **Note:** `git` is pre-installed on Ubuntu 24.04. If for some reason it is missing, run `apt update && apt install -y git` first.

---

## Step 1: Initial Setup & SSH Hardening (as root)

```bash
./01-initial-setup.sh
```

**What it does:**
- Updates all packages
- Creates `deploy` user with sudo (no password needed for sudo)
- Copies root's SSH keys to deploy
- Moves SSH to port 41122
- Disables root login, password auth
- Limits auth attempts to 3
- Installs essential tools (ufw, fail2ban, curl, git, htop, tmux, etc.)
- Sets timezone to UTC

**CRITICAL:** Before closing this Termius session, open a NEW connection and verify you can connect as `deploy` on port `41122`. Update your Termius host entry accordingly.

Only continue once this works! Then go to Hetzner dashboard and **remove port 22** from the firewall.

---

## Step 2: UFW Firewall (as deploy)

```bash
./02-firewall.sh
```

**What it does:**
- Default deny all inbound
- Opens 41122 (SSH), 80 (HTTP), 443 (HTTPS)
- Allows all Tailscale interface traffic
- Rate limits SSH connections

---

## Step 3: Fail2Ban (as deploy)

```bash
./03-fail2ban.sh
```

**What it does:**
- Bans IPs for 24 hours (not the default 10 minutes)
- Watches port 41122 (must match actual SSH port!)
- Whitelists Tailscale subnet (100.64.0.0/10) so you never lock yourself out
- 3 max retries before ban

---

## Step 4: Tailscale (as deploy)

```bash
./04-tailscale.sh
```

**What it does:**
- Installs Tailscale
- Prompts you to authenticate via browser URL
- Shows your Tailscale IP

**After this:** Install Tailscale on your phone and laptop too: https://tailscale.com/download

**Optional hardening:** Lock SSH to only listen on Tailscale IP (makes SSH completely invisible on public internet). But if Tailscale breaks, you'll need Hetzner's web console to recover.

---

## Step 5: Unattended Upgrades (as deploy)

```bash
./05-unattended-upgrades.sh
```

**What it does:**
- Auto-installs security updates daily
- Auto-reboots at 04:00 UTC if kernel updates require it
- Cleans up old packages weekly
- Most breaches exploit unpatched CVEs -- this prevents that

---

## Step 6: Audit (run anytime)

```bash
./06-audit.sh
```

Checks: SSH config, UFW status, fail2ban bans, Tailscale, open ports, zombie processes, failed services, disk/memory usage, crontab entries.

---

## Run All Steps

You can also use the main entry point:

```bash
./hetzner-hardening.sh --step 1   # Individual step
./hetzner-hardening.sh --all      # Steps 1-5 sequentially
./hetzner-hardening.sh --ref      # Quick reference card
```
