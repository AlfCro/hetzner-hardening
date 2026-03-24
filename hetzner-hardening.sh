#!/bin/bash
# ============================================================
# Hetzner VPS Hardening - All-in-One
# 
# This file contains all scripts. Run it to extract them:
#   chmod +x hetzner-hardening.sh
#   ./hetzner-hardening.sh --extract
#
# Or run each step individually:
#   ./hetzner-hardening.sh --step 1
#   ./hetzner-hardening.sh --step 2
#   ... etc
# ============================================================
set -euo pipefail

SSH_PORT=41122
USERNAME="deploy"
TAILSCALE_SUBNET="100.64.0.0/10"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
header() { echo -e "\n${CYAN}==========================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}==========================================${NC}\n"; }

# ============================================================
step1_initial_setup() {
# ============================================================
header "Step 1: Initial Setup & SSH Hardening"

echo "[1/7] Updating system packages..."
apt update && apt upgrade -y

echo "[2/7] Creating user '${USERNAME}'..."
if id "$USERNAME" &>/dev/null; then
    echo "User ${USERNAME} already exists, skipping."
else
    adduser --disabled-password --gecos "" "$USERNAME"
    usermod -aG sudo "$USERNAME"
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}
    chmod 440 /etc/sudoers.d/${USERNAME}
fi

echo "[3/7] Copying SSH keys to ${USERNAME}..."
mkdir -p /home/${USERNAME}/.ssh
cp /root/.ssh/authorized_keys /home/${USERNAME}/.ssh/authorized_keys
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
chmod 700 /home/${USERNAME}/.ssh
chmod 600 /home/${USERNAME}/.ssh/authorized_keys

echo "[4/7] Hardening SSH on port ${SSH_PORT}..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)

cat > /etc/ssh/sshd_config.d/hardened.conf << EOF
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ${USERNAME}
EOF

sshd -t && echo "SSH config valid." || { echo "SSH config INVALID! Aborting."; exit 1; }

echo "[5/7] Installing essential packages..."
apt install -y \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    curl \
    wget \
    git \
    htop \
    tmux \
    net-tools \
    lsof \
    jq

echo "[6/7] Setting timezone to UTC..."
timedatectl set-timezone UTC

echo "[7/7] Restarting SSH..."
systemctl restart sshd

header "IMPORTANT: Before closing this session!"
echo "  1. Open a NEW terminal and test SSH:"
echo "     ssh ${USERNAME}@<your-server-ip> -p ${SSH_PORT}"
echo ""
echo "  2. Only proceed to step 2 once confirmed!"
echo ""
echo "  SSH port: ${SSH_PORT}"
echo "  User:     ${USERNAME}"
}

# ============================================================
step2_firewall() {
# ============================================================
header "Step 2: UFW Firewall (Host-Level)"

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ${SSH_PORT}/tcp comment 'SSH on custom port'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow in on tailscale0 comment 'Allow all Tailscale traffic'
sudo ufw limit ${SSH_PORT}/tcp comment 'Rate limit SSH'

sudo ufw --force enable

echo ""
echo "Firewall status:"
sudo ufw status verbose

header "UFW configured!"
echo "  To add ports later:"
echo "    sudo ufw allow <port>/tcp comment 'description'"
echo ""
echo "  To check open ports:"
echo "    sudo ss -tlnp"
}

# ============================================================
step3_fail2ban() {
# ============================================================
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
}

# ============================================================
step4_tailscale() {
# ============================================================
header "Step 4: Tailscale"

echo "[1/3] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[2/3] Starting Tailscale..."
sudo tailscale up

echo ""
echo "Follow the URL above to authenticate."
echo "Press Enter once authenticated..."
read -r

TAILSCALE_IP=$(tailscale ip -4)

header "Tailscale is running!"
echo "  Your Tailscale IP: ${TAILSCALE_IP}"
echo ""
echo "  SSH via Tailscale:"
echo "    ssh deploy@${TAILSCALE_IP} -p ${SSH_PORT}"
echo ""
echo "  OPTIONAL - Lock SSH to Tailscale only:"
echo "  Edit /etc/ssh/sshd_config.d/hardened.conf and add:"
echo "    ListenAddress ${TAILSCALE_IP}"
echo "    ListenAddress 127.0.0.1"
echo "  Then: sudo systemctl restart sshd"
echo ""
echo "  Next: Install Tailscale on your phone/laptop too!"
echo "  https://tailscale.com/download"
echo ""
echo "  Expo dev from phone:"
echo "    http://${TAILSCALE_IP}:<expo-port>"
}

# ============================================================
step5_unattended_upgrades() {
# ============================================================
header "Step 5: Unattended Upgrades"

sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::SyslogEnable "true";
EOF

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

sudo unattended-upgrades --dry-run --debug 2>&1 | tail -5

header "Auto-updates configured!"
echo "  Security updates install automatically."
echo "  Auto-reboot at 04:00 UTC if kernel updates require it."
echo ""
echo "  Check status:"
echo "    sudo systemctl status unattended-upgrades"
echo "    cat /var/log/unattended-upgrades/unattended-upgrades.log"
}

# ============================================================
step6_audit() {
# ============================================================
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
}

# ============================================================
show_reference() {
# ============================================================
cat << 'REFERENCE'
============================================================
  QUICK REFERENCE
============================================================

  SSH port:          41122
  SSH user:          deploy
  Fail2ban bantime:  24 hours
  Auto-reboot:       04:00 UTC
  Tailscale subnet:  100.64.0.0/10

  HETZNER CLOUD FIREWALL (set in dashboard):
  ┌───────────┬──────────┬───────┬─────────────┬──────────────────┐
  │ Direction │ Protocol │ Port  │ Source       │ Description      │
  ├───────────┼──────────┼───────┼─────────────┼──────────────────┤
  │ Inbound   │ TCP      │ 41122 │ Any IPv4/v6 │ SSH              │
  │ Inbound   │ TCP      │ 80    │ Any IPv4/v6 │ HTTP             │
  │ Inbound   │ TCP      │ 443   │ Any IPv4/v6 │ HTTPS            │
  │ Inbound   │ UDP      │ 41641 │ Any IPv4/v6 │ Tailscale        │
  └───────────┴──────────┴───────┴─────────────┴──────────────────┘

  COMMON TASKS:
    sudo ss -tlnp                        # Check listening ports
    sudo ufw allow <port>/tcp            # Open a port
    sudo ufw status                      # Firewall status
    sudo fail2ban-client status sshd     # Check bans
    sudo fail2ban-client unban <IP>      # Unban IP
    tailscale status                     # Tailscale peers
    sudo journalctl -u ssh --since "1h"  # SSH auth logs

  ADD SSH KEY FOR NEW DEVICE:
    echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys

  EXPO DEV VIA TAILSCALE:
    npx expo start --host <tailscale-ip>
    # Phone connects at http://<tailscale-ip>:8081

  VNC (tunnel only, never expose):
    ssh -L 5901:localhost:5901 deploy@<tailscale-ip> -p 41122

REFERENCE
}

# ============================================================
# Main - parse args
# ============================================================
usage() {
    echo "Usage: $0 [option]"
    echo ""
    echo "  --step 1   Initial setup & SSH hardening (run as root)"
    echo "  --step 2   UFW firewall (run as deploy)"
    echo "  --step 3   Fail2ban (run as deploy)"
    echo "  --step 4   Tailscale (run as deploy)"
    echo "  --step 5   Unattended upgrades (run as deploy)"
    echo "  --step 6   Security audit (run as deploy)"
    echo "  --ref      Quick reference card"
    echo "  --all      Run steps 1-5 sequentially (careful!)"
    echo ""
}

case "${1:-}" in
    --step)
        case "${2:-}" in
            1) step1_initial_setup ;;
            2) step2_firewall ;;
            3) step3_fail2ban ;;
            4) step4_tailscale ;;
            5) step5_unattended_upgrades ;;
            6) step6_audit ;;
            *) usage; exit 1 ;;
        esac
        ;;
    --ref)
        show_reference
        ;;
    --all)
        echo "This will run steps 1-5 sequentially."
        echo "Only do this if you know what you're doing!"
        echo "Press Enter to continue or Ctrl+C to abort..."
        read -r
        step1_initial_setup
        step2_firewall
        step3_fail2ban
        step4_tailscale
        step5_unattended_upgrades
        header "All steps complete! Run --step 6 for audit."
        ;;
    *)
        usage
        ;;
esac
