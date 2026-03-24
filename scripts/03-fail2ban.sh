#!/bin/bash
# Step 3: Fail2Ban (run as deploy)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

header "Step 3: Fail2Ban"

sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
bantime  = 86400
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1 ${TAILSCALE_SUBNET}
backend = systemd

[sshd]
enabled  = true
port     = ${SSH_PORT}
filter   = sshd
maxretry = 3
bantime  = 86400
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

echo ""
echo "Fail2ban status:"
sudo fail2ban-client status
echo ""
sudo fail2ban-client status sshd

header "Fail2ban configured!"
echo "  Useful commands:"
echo "    sudo fail2ban-client status sshd"
echo "    sudo fail2ban-client unban <IP>"
echo "    sudo tail -f /var/log/fail2ban.log"
