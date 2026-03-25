#!/bin/bash
# Shared variables and helpers for all hardening scripts
set -euo pipefail

SSH_PORT=41122
USERNAME="deploy"
TAILSCALE_SUBNET="100.64.0.0/10"
CLOUDFLARE_ONLY=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()     { echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()   { echo -e "${RED}[FAIL]${NC} $1"; }
header() { echo -e "\n${CYAN}==========================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}==========================================${NC}\n"; }
