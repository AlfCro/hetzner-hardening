#!/bin/bash
# Hetzner VPS Hardening - Main entry point
# Dispatches to individual step scripts in the scripts/ directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

show_reference() {
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
  +───────────+──────────+───────+─────────────+──────────────────+
  | Direction | Protocol | Port  | Source       | Description      |
  +───────────+──────────+───────+─────────────+──────────────────+
  | Inbound   | TCP      | 41122 | Any IPv4/v6 | SSH              |
  | Inbound   | TCP      | 80    | Any IPv4/v6 | HTTP             |
  | Inbound   | TCP      | 443   | Any IPv4/v6 | HTTPS            |
  | Inbound   | UDP      | 41641 | Any IPv4/v6 | Tailscale        |
  +───────────+──────────+───────+─────────────+──────────────────+

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
            1) "${SCRIPT_DIR}/01-initial-setup.sh" ;;
            2) "${SCRIPT_DIR}/02-firewall.sh" ;;
            3) "${SCRIPT_DIR}/03-fail2ban.sh" ;;
            4) "${SCRIPT_DIR}/04-tailscale.sh" ;;
            5) "${SCRIPT_DIR}/05-unattended-upgrades.sh" ;;
            6) "${SCRIPT_DIR}/06-audit.sh" ;;
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
        "${SCRIPT_DIR}/01-initial-setup.sh"
        "${SCRIPT_DIR}/02-firewall.sh"
        "${SCRIPT_DIR}/03-fail2ban.sh"
        "${SCRIPT_DIR}/04-tailscale.sh"
        "${SCRIPT_DIR}/05-unattended-upgrades.sh"
        header "All steps complete! Run --step 6 for audit."
        ;;
    *)
        usage
        ;;
esac
