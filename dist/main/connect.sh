#!/usr/bin/env bash
set -euo pipefail

echo "::add-mask::${VPN_PASSWORD}"
echo "::add-mask::${VPN_PSK}"

sudo apt-get update
sudo apt-get install -y strongswan=5.9.13-2ubuntu4 xl2tpd=1.3.18-1build2

# --- Configure IPSec ---
sudo tee /etc/ipsec.conf > /dev/null <<EOF
conn myvpn
  auto=add
  keyexchange=ikev1
  authby=secret
  type=transport
  left=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=${VPN_GATEWAY}
  ike=${VPN_IKE}
  esp=${VPN_ESP}
EOF

sudo tee /etc/ipsec.secrets > /dev/null <<EOF
: PSK "${VPN_PSK}"
EOF
sudo chmod 600 /etc/ipsec.secrets

# --- Configure L2TP ---
sudo tee /etc/xl2tpd/xl2tpd.conf > /dev/null <<EOF
[lac myvpn]
lns = ${VPN_GATEWAY}
ppp debug = no
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

sudo tee /etc/ppp/options.l2tpd.client > /dev/null <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
domain "${VPN_NT_DOMAIN}"
name "${VPN_USERNAME}"
password "${VPN_PASSWORD}"
EOF
sudo chmod 600 /etc/ppp/options.l2tpd.client

# --- Start VPN ---
sudo mkdir -p /var/run/xl2tpd
sudo touch /var/run/xl2tpd/l2tp-control

sudo service ipsec restart
sudo service xl2tpd restart

sudo ipsec up myvpn
echo "c myvpn" | sudo tee /var/run/xl2tpd/l2tp-control

# Wait for PPP interface
TIMEOUT=90
COUNT=0
while true; do
  PPP_IFACE=$(ip -o link show | awk -F': ' '/ppp/ {print $2; exit}') || true
  PPP_IP=$(ip -4 addr show "$PPP_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}') || true
  if [[ -n "$PPP_IFACE" && -n "$PPP_IP" ]]; then break; fi
  [[ $COUNT -ge $TIMEOUT ]] && { echo "Timeout: PPP interface did not come up after $TIMEOUT seconds"; exit 1; }
  echo "Waiting for PPP interface... ($COUNT/$TIMEOUT)"
  sleep 1
  COUNT=$((COUNT+1))
done

echo "PPP interface: $PPP_IFACE"
echo "PPP IP: $PPP_IP"

echo "ppp_interface=$PPP_IFACE" >> "$GITHUB_OUTPUT"
echo "ppp_ip=$PPP_IP" >> "$GITHUB_OUTPUT"

# Persist the connection name for cleanup
echo "myvpn" > "$RUNNER_TEMP/vpn_connection"
