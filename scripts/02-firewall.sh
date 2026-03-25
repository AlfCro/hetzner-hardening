#!/bin/bash
# Step 2: UFW Firewall (run as deploy)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

header "Step 2: UFW Firewall (Host-Level)"

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ${SSH_PORT}/tcp comment 'SSH on custom port'

if [ "$CLOUDFLARE_ONLY" = true ]; then
    echo "Fetching Cloudflare IP ranges..."
    CF_IPS_V4=$(curl -s https://www.cloudflare.com/ips-v4)
    CF_IPS_V6=$(curl -s https://www.cloudflare.com/ips-v6)

    if [ -z "$CF_IPS_V4" ]; then
        echo ""
        fail "Could not fetch Cloudflare IPs. Aborting."
        echo "  Check your internet connection and try again."
        echo "  You can also set CLOUDFLARE_ONLY=false in common.sh to allow all traffic."
        exit 1
    fi

    echo "Allowing HTTP/HTTPS from Cloudflare IPv4 ranges only..."
    for ip in $CF_IPS_V4; do
        sudo ufw allow from "$ip" to any port 80 proto tcp comment "Cloudflare HTTP"
        sudo ufw allow from "$ip" to any port 443 proto tcp comment "Cloudflare HTTPS"
    done

    echo "Allowing HTTP/HTTPS from Cloudflare IPv6 ranges only..."
    for ip in $CF_IPS_V6; do
        sudo ufw allow from "$ip" to any port 80 proto tcp comment "Cloudflare HTTP"
        sudo ufw allow from "$ip" to any port 443 proto tcp comment "Cloudflare HTTPS"
    done

    ok "HTTP/HTTPS restricted to Cloudflare IPs"
else
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
fi

sudo ufw allow in on tailscale0 comment 'Allow all Tailscale traffic'
sudo ufw limit ${SSH_PORT}/tcp comment 'Rate limit SSH'

sudo ufw --force enable

echo ""
echo "Firewall status:"
sudo ufw status verbose

header "UFW configured!"

if [ "$CLOUDFLARE_ONLY" = true ]; then
    echo "  Ports 80/443 are restricted to Cloudflare IPs only."
    echo "  Direct connections to your server's IP will be dropped."
    echo ""
    echo "  IMPORTANT: Cloudflare updates their IP ranges occasionally."
    echo "  Re-run this script to refresh the rules if connectivity breaks."
    echo ""
fi

echo "  To add ports later:"
echo "    sudo ufw allow <port>/tcp comment 'description'"
echo ""
echo "  To check open ports:"
echo "    sudo ss -tlnp"
