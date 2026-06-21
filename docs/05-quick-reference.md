# Quick Reference

```bash
# Check listening ports
sudo ss -tlnp

# Open a new port
sudo ufw allow <port>/tcp comment 'description'

# Firewall status
sudo ufw status verbose

# Confirm app backends are loopback-only
sudo ss -ltnp | grep -E '127\.0\.0\.1:|Local Address'

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

# Persistent session — survives SSH drops; use instead of mosh (no UDP port to open)
tmux new -A -s cc    # start or reattach the shared "cc" session
tmux attach -t cc    # reattach
# detach (leaves work running): Ctrl-b then d
# fix scrollback (wheel/touch) — add to ~/.tmux.conf once:  set -g mouse on
```
