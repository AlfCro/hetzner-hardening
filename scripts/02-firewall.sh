#!/bin/bash
# Step 2: UFW Firewall (run as deploy)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

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
