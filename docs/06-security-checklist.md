# Security Checklist

Based on the levelsio/Claude VPS hardening checklist.

- [x] SSH on non-standard port (41122) -- port 22 gets hammered by bots
- [x] Key-only SSH auth, no passwords, no root login
- [x] Tailscale to make server invisible, lock SSH to Tailscale subnet
- [x] Cloud-level firewall (Hetzner) AND host-level firewall (UFW) -- two independent layers
- [x] Default deny all inbound, whitelist only what's needed
- [x] Fail2ban watching the correct port (not default 22)
- [x] Fail2ban bans set to 24h, not default 10 minutes
- [x] Whitelist VPN/Tailscale subnet in fail2ban to prevent self-lockout
- [x] Unattended upgrades with auto reboot -- most breaches exploit unpatched CVEs
- [x] Block VNC at firewall level (tunnel through SSH if needed)
- [x] Audit script for open ports, zombie processes, failed services
- [x] Audit systemd services, crontab, and screen sessions regularly
