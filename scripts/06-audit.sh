#!/bin/bash
# Step 6: Security Audit (run as deploy, anytime)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

header "Server Security Audit - $(date)"

echo "--- SSH Configuration ---"
SSH_PORT_CFG=$(grep -E "^Port " /etc/ssh/sshd_config.d/hardened.conf 2>/dev/null | awk '{print $2}')
if [ "$SSH_PORT_CFG" != "22" ] && [ -n "$SSH_PORT_CFG" ]; then
    ok "SSH on non-standard port: ${SSH_PORT_CFG}"
else
    fail "SSH still on port 22!"
fi

if grep -q "PermitRootLogin no" /etc/ssh/sshd_config.d/hardened.conf 2>/dev/null; then
    ok "Root login disabled"
else
    fail "Root login may be enabled!"
fi

if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config.d/hardened.conf 2>/dev/null; then
    ok "Password auth disabled (key-only)"
else
    fail "Password authentication may be enabled!"
fi

echo ""
echo "--- Firewall Status ---"
if sudo ufw status | grep -q "Status: active"; then
    ok "UFW is active"
    echo "    Open ports:"
    sudo ufw status | grep ALLOW | while read -r line; do
        echo "      $line"
    done
else
    fail "UFW is NOT active!"
fi

echo ""
echo "--- Fail2Ban Status ---"
if systemctl is-active --quiet fail2ban; then
    ok "Fail2ban is running"
    BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    echo "    Currently banned IPs: ${BANNED:-0}"
    TOTAL=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $NF}')
    echo "    Total banned (all time): ${TOTAL:-0}"
else
    fail "Fail2ban is NOT running!"
fi

echo ""
echo "--- Tailscale Status ---"
if command -v tailscale &>/dev/null && tailscale status &>/dev/null; then
    ok "Tailscale is connected"
    echo "    IP: $(tailscale ip -4 2>/dev/null || echo 'unknown')"
else
    warn "Tailscale not connected or not installed"
fi

echo ""
echo "--- Open Ports (public) ---"
sudo ss -tlnp | grep -v "127.0.0" | grep -v "::1" | grep "LISTEN" | while read -r line; do
    PORT=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
    PROC=$(echo "$line" | awk '{print $NF}')
    echo "    Port ${PORT} - ${PROC}"
done

echo ""
echo "--- Zombie Processes ---"
ZOMBIES=$(ps aux | awk '$8 ~ /Z/' | wc -l)
if [ "$ZOMBIES" -eq 0 ]; then
    ok "No zombie processes"
else
    warn "${ZOMBIES} zombie processes found"
    ps aux | awk '$8 ~ /Z/ {print "    PID: "$2" CMD: "$11}'
fi

echo ""
echo "--- Auto-Updates ---"
if systemctl is-active --quiet unattended-upgrades; then
    ok "Unattended-upgrades is running"
else
    fail "Unattended-upgrades is NOT running!"
fi

if [ -f /var/run/reboot-required ]; then
    warn "System reboot required!"
else
    ok "No reboot pending"
fi

echo ""
echo "--- Failed Services ---"
FAILED=$(systemctl --failed --no-legend | wc -l)
if [ "$FAILED" -eq 0 ]; then
    ok "No failed services"
else
    warn "${FAILED} failed service(s):"
    systemctl --failed --no-legend
fi

echo ""
echo "--- Disk & Memory ---"
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -lt 80 ]; then
    ok "Disk usage: ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -lt 90 ]; then
    warn "Disk usage: ${DISK_USAGE}%"
else
    fail "Disk usage critical: ${DISK_USAGE}%"
fi
free -h | awk 'NR==2 {printf "    Memory: %s / %s (%s free)\n", $3, $2, $4}'

echo ""
echo "--- Systemd / Crontab Audit ---"
echo "    Enabled timers:"
systemctl list-timers --no-legend | head -5 | while read -r line; do
    echo "      $line"
done
echo ""
echo "    Crontab entries (root):"
sudo crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | while read -r line; do
    echo "      $line"
done || echo "      (none)"

header "Audit complete!"
