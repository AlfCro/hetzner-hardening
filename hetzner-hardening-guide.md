# Hetzner VPS Hardening - Complete Guide

Based on the levelsio/Claude VPS hardening checklist, with all decisions and knowledge gathered during setup.

---

## Server Specs

- **Provider:** Hetzner Cloud
- **Plan:** CX22 (cost optimized)
- **OS:** Ubuntu 24.04
- **Networking:** Public IPv4 + IPv6
- **Private network:** Skipped — Tailscale replaces this for single-server setups
- **Volumes:** Skipped — can add extra storage later if needed
- **Cloud config / labels / placement groups:** Skipped — not needed for single VPS
- **Backups:** Optional but recommended (~20% extra cost for weekly automatic backups, can enable later)

---

## SSH Keys

### Generating a Key

Run on your **local machine** (not the server):

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

- Accept default location (`~/.ssh/id_ed25519`)
- **Add a passphrase** — this is your second line of defense. If someone steals your device, they still need the passphrase to use the key

### Key Is Bound to the Device

The private key lives on the device that created it. Each device (phone, laptop, desktop) should have its own key. This way, one compromised device doesn't compromise others.

### Adding a Key From a Second Device

From the new device, generate its own key, then add it to the server:

```bash
# On new device
ssh-keygen -t ed25519

# Copy to server (if port already changed)
ssh-copy-id -p 41122 deploy@<server-ip>
```

Or manually from an existing session:

```bash
echo "ssh-ed25519 AAAA...your-new-key..." >> ~/.ssh/authorized_keys
```

This works anytime — the `deploy` user has full sudo access, so you're never locked out of adding keys.

### Passphrase vs Password Auth

- **Passphrase on key:** Protects the key file on your device. Recommended.
- **Password auth on server:** Disabled by the hardening script. These are two different things. The post says "key-only SSH auth, no passwords" — that means no password login to the server, not about key passphrases.

---

## SSH Client (Mobile)

- **Termius** — recommended for phone-based SSH. Purpose-built UI for managing hosts, keys, and connections. Easier than fighting a terminal keyboard.
- **Termux** — full Linux terminal on Android, more powerful but overkill for just running SSH commands.

---

## Connection Details

| Phase | Username | Port | Notes |
|-------|----------|------|-------|
| First connection (fresh server) | `root` | `22` | Before running any scripts |
| After script step 1 | `deploy` | `41122` | Root login disabled |

**Password:** Leave blank in your SSH client — the key handles authentication.

---

## Firewall Strategy: Two Layers

A misconfiguration in one doesn't expose you. Both must fail for an attacker to get through.

### Layer 1: Hetzner Cloud Firewall (Dashboard)

Set in the Hetzner web UI under Firewalls:

| Direction | Protocol | Port  | Source      | Description         |
|-----------|----------|-------|-------------|---------------------|
| Inbound   | TCP      | 22    | Any IPv4/v6 | SSH (temporary!)    |
| Inbound   | TCP      | 41122 | Any IPv4/v6 | SSH (after step 1)  |
| Inbound   | TCP      | 80    | Any IPv4/v6 | HTTP                |
| Inbound   | TCP      | 443   | Any IPv4/v6 | HTTPS               |
| Inbound   | UDP      | 41641 | Any IPv4/v6 | Tailscale WireGuard |

**Important:** Port 22 is only needed for the initial connection before running step 1. Remove it from the Hetzner firewall after SSH is moved to 41122.

Outbound: Leave as allow all (default).

### Layer 2: UFW on the Server (Script Step 2)

Configured by the script. Same ports, but enforced at the host level.

---

## Setup Order

### Prerequisites
1. Create VPS on Hetzner with SSH key and firewall attached
2. Temporarily open port 22 in Hetzner firewall
3. Connect as `root` on port 22

### Getting the Script

```bash
# On the server as root
git clone https://github.com/<your-repo>/hetzner-hardening.git
cd hetzner-hardening
chmod +x hetzner-hardening.sh
```

### Step 1: Initial Setup & SSH Hardening (as root)

```bash
./hetzner-hardening.sh --step 1
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

**⚠️ CRITICAL:** Before closing this session, open a NEW connection and verify:
```bash
ssh deploy@<server-ip> -p 41122
```

Only continue once this works! Then go to Hetzner dashboard and **remove port 22** from the firewall.

### Step 2: UFW Firewall (as deploy)

```bash
./hetzner-hardening.sh --step 2
```

**What it does:**
- Default deny all inbound
- Opens 41122 (SSH), 80 (HTTP), 443 (HTTPS)
- Allows all Tailscale interface traffic
- Rate limits SSH connections

### Step 3: Fail2Ban (as deploy)

```bash
./hetzner-hardening.sh --step 3
```

**What it does:**
- Bans IPs for 24 hours (not the default 10 minutes — makes brute force cost real time)
- Watches port 41122 (must match actual SSH port!)
- Whitelists Tailscale subnet (100.64.0.0/10) so you never lock yourself out
- 3 max retries before ban

### Step 4: Tailscale (as deploy)

```bash
./hetzner-hardening.sh --step 4
```

**What it does:**
- Installs Tailscale
- Prompts you to authenticate via browser URL
- Shows your Tailscale IP

**After this:** Install Tailscale on your phone and laptop too: https://tailscale.com/download

**Optional hardening:** Lock SSH to only listen on Tailscale IP (makes SSH completely invisible on public internet). But if Tailscale breaks, you'll need Hetzner's web console to recover.

### Step 5: Unattended Upgrades (as deploy)

```bash
./hetzner-hardening.sh --step 5
```

**What it does:**
- Auto-installs security updates daily
- Auto-reboots at 04:00 UTC if kernel updates require it
- Cleans up old packages weekly
- Most breaches exploit unpatched CVEs — this prevents that

### Step 6: Audit (run anytime)

```bash
./hetzner-hardening.sh --step 6
```

Checks: SSH config, UFW status, fail2ban bans, Tailscale, open ports, zombie processes, failed services, disk/memory usage, crontab entries.

---

## Tailscale & Expo Development

With Tailscale on both your phone and VPS, your phone can reach dev servers directly over the encrypted mesh network — no public ports needed.

```bash
# On VPS
npx expo start --host <tailscale-ip>

# Phone connects at
http://<tailscale-ip>:8081
```

This replaces the need for a Hetzner private network for dev purposes.

---

## Quick Reference

```bash
# Check listening ports
sudo ss -tlnp

# Open a new port
sudo ufw allow <port>/tcp comment 'description'

# Firewall status
sudo ufw status verbose

# Fail2ban status
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client unban <IP>

# Manually ban an IP
sudo fail2ban-client set sshd banip <IP>

# Tailscale status
tailscale status

# SSH auth logs
sudo journalctl -u ssh --since "1 hour ago"

# Kill zombie processes
ps aux | awk '$8 ~ /Z/ {print $2}' | xargs -r sudo kill -9

# Audit systemd services
systemctl --failed

# Check crontab
sudo crontab -l

# Check unattended upgrade logs
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

---

## Security Checklist (from the original post)

- [x] SSH on non-standard port (41122) — port 22 gets hammered by bots
- [x] Key-only SSH auth, no passwords, no root login
- [x] Tailscale to make server invisible, lock SSH to Tailscale subnet
- [x] Cloud-level firewall (Hetzner) AND host-level firewall (UFW) — two independent layers
- [x] Default deny all inbound, whitelist only what's needed
- [x] Fail2ban watching the correct port (not default 22)
- [x] Fail2ban bans set to 24h, not default 10 minutes
- [x] Whitelist VPN/Tailscale subnet in fail2ban to prevent self-lockout
- [x] Unattended upgrades with auto reboot — most breaches exploit unpatched CVEs
- [x] Block VNC at firewall level (tunnel through SSH if needed)
- [x] Audit script for open ports, zombie processes, failed services
- [x] Audit systemd services, crontab, and screen sessions regularly

### VNC If Needed (Tunnel Only)

```bash
ssh -L 5901:localhost:5901 deploy@<tailscale-ip> -p 41122
```

Never expose VNC ports publicly, even if the process is running.
