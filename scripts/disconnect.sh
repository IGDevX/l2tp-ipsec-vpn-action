#!/usr/bin/env bash
set -euo pipefail

if [[ -f "$RUNNER_TEMP/vpn_connection" ]]; then
  VPN_CONN=$(cat "$RUNNER_TEMP/vpn_connection")
  echo "d $VPN_CONN" | sudo tee /var/run/xl2tpd/l2tp-control || true
  sudo ipsec down "$VPN_CONN" || true
  echo "VPN disconnected!"
else
  echo "No VPN connection info found — skipping disconnect."
fi
