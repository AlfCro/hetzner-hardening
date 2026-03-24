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
