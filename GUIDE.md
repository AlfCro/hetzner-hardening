# Your First Hardened VPS — A Plain-English Guide

So you just spun up a Hetzner VPS. Congratulations — you now own a small computer on the internet.

That also means the entire internet can try to get inside it.

Within minutes of your server going live, automated bots start scanning its IP and attempting to log in. This is not paranoia — it is the reality of any publicly addressable machine. This guide explains what is at risk, what each hardening step actually does for you, and how to run through the setup from scratch.

---

## Why Bother?

Most VPS breaches happen not because of clever hacking but because of simple, avoidable mistakes:

| Mistake | Consequence |
|---------|-------------|
| Root login allowed over SSH | One stolen password = full machine compromise |
| Password authentication enabled | Bots run millions of password guesses per day |
| Default SSH port (22) | Every scanner on the internet knows to look there |
| No firewall | Any service you accidentally expose is reachable by everyone |
| No auto-updates | A known CVE sits unpatched for weeks, bots exploit it |
| No rate limiting | Unlimited login attempts with no consequence |

This setup closes all of those gaps in about 15 minutes.

---

## What You Will Have When You Are Done

- **SSH hardened:** key-only login, root disabled, non-standard port, locked to one user
- **Dual firewall:** Hetzner's cloud firewall as the outer wall, UFW on the server as the inner wall
- **Intrusion prevention:** fail2ban bans attackers for 24 hours after 3 failed attempts
- **Mesh VPN:** Tailscale makes your server invisible on the public internet for trusted connections
- **Automatic security patches:** unattended-upgrades applies CVE fixes daily without manual intervention
- **Audit script:** one command to verify your security posture at any time

---

## Before You Start

You need three accounts and two apps. None of them cost anything to get started. Do all of this on your phone and laptop before touching the server.

### 1. Create a Hetzner Account

Hetzner is where your server lives.

1. Go to [hetzner.com/cloud](https://www.hetzner.com/cloud) and click **Get started**
2. Sign up with your email and verify it
3. Add a payment method — a CX22 server costs around €4/month
4. Once in the dashboard, navigate to **Cloud** → your project (or create one)

### 2. Create a Tailscale Account

Tailscale is the private VPN that connects your devices to your server securely.

1. Go to [tailscale.com](https://tailscale.com) and click **Get started free**
2. Sign up — you can use a Google, Microsoft, or GitHub account
3. That's it for now. You'll come back to this during Step 4.

### 3. Download Termius on Your Phone

Termius is the SSH client you'll use to connect to your server. Start with your phone — it's where you'll generate the SSH key and do the initial server setup.

1. Install **Termius** from the App Store or Google Play
2. Open it and create a free account when prompted (needed to sync keys across devices)
3. Also install Termius on your laptop: [termius.com](https://termius.com) — sign in with the same account so your keys sync automatically

### 4. Download Tailscale on Your Phone and Laptop

You'll need the Tailscale app on both your phone and laptop so they join the same private network as your server.

**Phone first:**
1. Install **Tailscale** from the App Store or Google Play
2. Open it and **sign in with the same account** you created in step 2 above

**Then laptop:**
1. Go to [tailscale.com/download](https://tailscale.com/download) and install for your OS
2. Open it and sign in with the same Tailscale account
3. Both devices are now on your Tailscale network — the server will join it later

---

### 5. Generate Your SSH Key in Termius

SSH keys replace passwords. Instead of typing a secret that can be guessed or stolen in transit, your device holds a cryptographic key that mathematically proves your identity. Anyone without the key simply cannot get in — no matter how many times they try.

Do this on your phone (it will sync to your laptop automatically via your Termius account):

1. Open Termius → **Keychain** → **Keys** → **New Key**
2. Choose **Ed25519** (smaller and more secure than RSA)
3. Give it a name like `hetzner-deploy`
4. Copy the **public key** — you will paste it into Hetzner in the next step

### Create Your Server on Hetzner

1. Go to [console.hetzner.cloud](https://console.hetzner.cloud) → **New Server**
2. **Location:** pick one close to you
3. **Image:** Ubuntu 24.04
4. **Type:** CX22 (2 vCPU, 4 GB RAM) is plenty for most projects
5. **SSH Keys:** paste your public key from Termius
6. **Firewall:** create a new cloud firewall and attach it (see next section)
7. **Create** the server

### Set Up the Hetzner Cloud Firewall

Before connecting, create a firewall in the Hetzner dashboard:

- Allow **TCP port 22** inbound (temporary — only for the first connection)
- Allow **TCP port 80** inbound (HTTP)
- Allow **TCP port 443** inbound (HTTPS)
- Allow all outbound

> **Why two firewalls?** The Hetzner cloud firewall sits outside your server — it drops packets before they even reach the OS. UFW (the second firewall you will set up in Step 2) runs inside the server. If one layer has a misconfiguration, the other still protects you. Defense in depth.

---

## Getting the Scripts onto Your Server

Your server is running but empty. You need to pull down the hardening scripts from GitHub before you can do anything else. This is done over SSH — the same secure connection you will use to manage the server from now on.

### 1. Connect to Your Server via SSH

Open Termius and create a new host:

- **Address:** your server's public IPv4 (shown in the Hetzner dashboard after creation)
- **Username:** `root`
- **Port:** `22`
- **Key:** select the Ed25519 key you generated earlier

Connect. You should see a root shell prompt. If the connection is refused, double-check that **TCP port 22 is open** in your Hetzner cloud firewall.

### 2. Clone This Repository

Once you are logged in as root, run:

```bash
git clone https://github.com/AlfCro/hetzner-hardening.git
```

This downloads all the hardening scripts and documentation to a folder called `hetzner-hardening` in root's home directory.

### 3. Navigate to the Scripts and Make Them Executable

```bash
cd hetzner-hardening/scripts
chmod +x *.sh
```

You are now ready to run Step 1. Everything from here on happens inside this `scripts` directory.

---

## Step 1 — Initial Setup & SSH Hardening

**Run as:** `root`

```bash
./01-initial-setup.sh
```

**What it does for you:**

- Updates all packages so you start from a patched baseline
- Creates a `deploy` user — you will never log in as root again
- Copies your SSH keys to the `deploy` user automatically
- Moves SSH to port **41122** — most bots only scan port 22, so this alone cuts noise dramatically
- Disables root login over SSH entirely — even with the right key, root cannot connect remotely
- Disables password authentication — keys only, no brute-force target
- Limits auth attempts to 3 per connection
- Installs essential tools: ufw, fail2ban, curl, git, htop, tmux, and more
- Sets the server clock to UTC

**CRITICAL — do not skip this:**

Before closing your root session, open a **second Termius connection** and verify you can log in as `deploy` on port `41122`. Then update your Termius host entry to use port 41122 and the `deploy` user going forward.

Once that works:
1. Go to the Hetzner firewall dashboard
2. **Remove the rule for port 22** — it is no longer needed and should not be open
3. Add a rule for **TCP port 41122**

---

## Step 2 — Host Firewall (UFW)

**Run as:** `deploy`

```bash
./02-firewall.sh
```

**What it does for you:**

Sets the server's own firewall to deny everything by default, then only opens what you need:

| Port | Purpose |
|------|---------|
| 41122 | SSH (your non-standard port) |
| 80 | HTTP |
| 443 | HTTPS |
| Tailscale interface | All traffic allowed (encrypted private network) |

SSH connections are also rate-limited, which throttles scanners even if they do find your port.

> Even if a future misconfiguration opens a port in the Hetzner cloud firewall, UFW is a second line of defense sitting right on the server.

---

## Step 3 — Fail2Ban (Intrusion Prevention)

**Run as:** `deploy`

```bash
./03-fail2ban.sh
```

**What it does for you:**

Fail2ban watches your SSH logs and automatically bans IPs that fail login attempts.

- **3 failed attempts** triggers a ban
- **24-hour ban** (the default is only 10 minutes — long enough for bots to rotate IPs and try again)
- **Tailscale subnet whitelisted** so you can never accidentally lock yourself out when connecting through Tailscale
- **Localhost whitelisted** for the same reason

> Without fail2ban, a bot can try unlimited passwords. With it, they get three guesses and then 24 hours of silence.

---

## Step 4 — Tailscale (Mesh VPN)

**Run as:** `deploy`

```bash
./04-tailscale.sh
```

**What it does for you:**

Tailscale creates a private encrypted network between all your devices (phone, laptop, server). Once set up:

- Your server gets a stable private IP (starts with `100.`)
- Traffic between your devices is end-to-end encrypted via WireGuard
- You can reach your server by name from any device on your Tailscale network

The script will print a URL — open it in your browser to authenticate your server to your Tailscale account.

**After the script finishes:**

If you followed the pre-setup steps, Tailscale is already on your phone and laptop — they will appear in the same network automatically.

**Optional advanced hardening:**

You can configure SSH to only listen on the Tailscale IP (making it completely invisible on the public internet). The trade-off: if Tailscale ever breaks, you need Hetzner's browser-based rescue console to get back in. Only do this if you are comfortable with that recovery path.

---

## Step 5 — Automatic Security Updates

**Run as:** `deploy`

```bash
./05-unattended-upgrades.sh
```

**What it does for you:**

Security patches for the Linux kernel and system packages are released constantly. Without auto-updates, you are responsible for manually patching — and most people forget or deprioritise it.

- **Daily checks** for new security patches
- **Automatic installation** of security-only updates (not major version upgrades)
- **Auto-reboot at 04:00 UTC** if a kernel patch requires it — scheduled for the quietest time
- **Cleanup** of old packages and kernel images weekly

> The majority of real-world breaches exploit vulnerabilities that already have patches available. This step closes that gap automatically.

---

## Step 6 — Security Audit (Run Anytime)

**Run as:** `deploy`

```bash
./06-audit.sh
```

Run this after finishing setup to confirm everything is configured correctly. Run it again any time you want to check on your security posture.

**It checks:**

- SSH: non-standard port, root login disabled, key-only auth
- UFW: enabled, correct ports open
- Fail2ban: running, current bans, total ban count
- Tailscale: connected, your Tailscale IP
- Open ports: anything listening that shouldn't be
- Zombie processes
- Failed systemd services
- Disk and memory usage
- Pending reboots
- Active timers and cron jobs

---

## Quick Reference After Setup

| Task | Command |
|------|---------|
| Check open ports | `ss -tlnp` |
| View fail2ban bans | `sudo fail2ban-client status sshd` |
| Unban an IP | `sudo fail2ban-client set sshd unbanip <IP>` |
| Check UFW rules | `sudo ufw status numbered` |
| View auth log | `sudo journalctl -u ssh -n 50` |
| Run security audit | `./06-audit.sh` |
| Check Tailscale status | `tailscale status` |
| Your Tailscale IP | `tailscale ip -4` |

---

## What Stays Your Responsibility

This setup hardens the server's access controls and keeps it patched. It does not cover:

- **Application security** — vulnerabilities in your own code or the apps you run
- **Secrets management** — keeping API keys, database passwords, etc. out of your codebase
- **Backups** — set up regular snapshots in the Hetzner dashboard or use a backup tool
- **Monitoring** — consider adding uptime monitoring (e.g. UptimeRobot) and log aggregation

A hardened base is necessary but not sufficient for a production system. This is a strong foundation to build on.

---

## Troubleshooting

**Locked out of SSH?**
Use the Hetzner web console (server page → Console) to access the machine without SSH.

**Accidentally banned your own IP?**
Connect via Tailscale (which is whitelisted), then run:
```bash
sudo fail2ban-client set sshd unbanip <your-IP>
```

**SSH connection refused after Step 1?**
Double-check you are connecting on port 41122, as the `deploy` user, with your SSH key selected in Termius.

**Tailscale not connecting?**
Run `sudo tailscale up` and follow the authentication URL again.
