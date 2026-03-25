# Firewall Strategy: Two Layers

A misconfiguration in one doesn't expose you. Both must fail for an attacker to get through.

## Layer 1: Hetzner Cloud Firewall (Dashboard)

Set in the Hetzner web UI under Firewalls:

| Direction | Protocol | Port  | Source      | Description         |
|-----------|----------|-------|-------------|---------------------|
| Inbound   | TCP      | 22    | Any IPv4/v6 | SSH (temporary!)    |
| Inbound   | TCP      | 41122 | Any IPv4/v6 | SSH (after step 1)  |
| Inbound   | TCP      | 80    | Any IPv4/v6 | HTTP                |
| Inbound   | TCP      | 443   | Any IPv4/v6 | HTTPS               |
| Inbound   | UDP      | 41641 | Any IPv4/v6 | Tailscale WireGuard |

**Important:** Port 22 is only needed for the initial connection before running step 1. Remove it from the Hetzner firewall after SSH is moved to 41122.

Outbound: Leave as allow all (default).

## Layer 2: UFW on the Server (Script Step 2)

Configured by the script. Same ports, but enforced at the host level.

## Cloudflare-Only Mode (Optional)

If you use Cloudflare as a reverse proxy, you can restrict ports 80 and 443 to only accept traffic from Cloudflare's IP ranges. This hides your origin server from the public internet — anyone connecting directly to your server's IP on port 80 or 443 gets dropped.

**To enable:** Set `CLOUDFLARE_ONLY=true` in `scripts/common.sh` before running step 2.

**What changes:**

- Instead of `ufw allow 80/tcp` (from anywhere), the script creates individual rules for each Cloudflare IP range
- The same applies to port 443
- All other traffic to 80/443 is dropped by the default deny policy

**Why this matters:**

- DDoS attacks that bypass Cloudflare and target your IP directly are blocked at the firewall
- Attackers scanning the internet for vulnerable web servers won't see yours
- Your real server IP stays hidden (as long as you don't leak it via DNS history, email headers, etc.)

**Things to keep in mind:**

- The Hetzner Cloud Firewall (Layer 1) still allows 80/443 from anywhere — this is fine because UFW (Layer 2) handles the Cloudflare restriction. The dual-layer approach means either layer can be more permissive than the other.
- Cloudflare publishes their IP ranges at [cloudflare.com/ips](https://www.cloudflare.com/ips). They update these occasionally. If you notice connectivity issues, re-run the firewall script to refresh the rules.
- If you ever stop using Cloudflare, set `CLOUDFLARE_ONLY=false` and re-run the script, or your web traffic will break.
