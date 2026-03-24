# Quick Reference

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
