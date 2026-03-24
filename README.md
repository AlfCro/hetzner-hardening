# Hetzner VPS Hardening

Step-by-step hardening scripts for a Hetzner Cloud VPS running Ubuntu 24.04. Based on the levelsio/Claude VPS hardening checklist.

## What's Included

- Non-standard SSH port with key-only auth
- Dual-layer firewall (Hetzner cloud + UFW)
- Fail2ban with 24h bans and Tailscale whitelisting
- Tailscale mesh VPN for private access
- Automatic security updates with auto-reboot
- Security audit script

## Usage

```bash
# On the server as root
git clone https://github.com/<your-repo>/vps.git
cd vps/scripts
chmod +x *.sh

# Run steps in order
./01-initial-setup.sh        # as root
./02-firewall.sh             # as deploy
./03-fail2ban.sh             # as deploy
./04-tailscale.sh            # as deploy
./05-unattended-upgrades.sh  # as deploy
./06-audit.sh                # as deploy, anytime

# Or use the main entry point
./hetzner-hardening.sh --step 1
./hetzner-hardening.sh --all
./hetzner-hardening.sh --ref
```

## Documentation

| Doc | Description |
|-----|-------------|
| [Server & SSH](docs/01-server-and-ssh.md) | Server specs, SSH key setup, connection details |
| [Firewall Strategy](docs/02-firewall-strategy.md) | Dual-layer firewall approach |
| [Setup Steps](docs/03-setup-steps.md) | Detailed walkthrough of each step |
| [Tailscale & Dev](docs/04-tailscale-and-dev.md) | Tailscale for Expo dev, VNC tunneling |
| [Quick Reference](docs/05-quick-reference.md) | Common admin commands |
| [Security Checklist](docs/06-security-checklist.md) | Full hardening checklist |
