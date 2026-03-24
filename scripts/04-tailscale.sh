#!/bin/bash
# Step 4: Tailscale (run as deploy)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

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
