#!/bin/bash
# Step 1: Initial Setup & SSH Hardening (run as root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

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

# Ensure privilege separation directory exists (missing on some Ubuntu setups)
mkdir -p /run/sshd

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
