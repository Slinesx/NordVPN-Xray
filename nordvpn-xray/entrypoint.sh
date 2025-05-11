#!/usr/bin/env bash
set -euo pipefail

# 1) require the .ovpn file to have been mounted at /nordvpn.ovpn
if [[ ! -f /nordvpn.ovpn ]]; then
  echo "ERROR: .ovpn file not found at /nordvpn.ovpn" >&2
  exit 1
fi

# 1a) strip out any ping lines from the config
FILTERED_OVPN=/run/filtered.ovpn
grep -E -v '^\s*(ping|ping-restart|ping-exit)\b' /nordvpn.ovpn > "$FILTERED_OVPN"

# 2) record original default route for policy-routing
orig=$(ip route show default | head -n1)
gw=$(awk '/via/ {print $3}' <<<"$orig")
iface=$(awk '/dev/ {print $5}' <<<"$orig")

# 3) NordVPN & Shadowsocks creds from env
: "${NORD_USERNAME?Need NORD_USERNAME}"
: "${NORD_PASSWORD?Need NORD_PASSWORD}"
: "${SS_PASSWORD?Need SS_PASSWORD}"

# 4) start OpenVPN with keepalive & auth-nocache
printf '%s\n%s\n' "$NORD_USERNAME" "$NORD_PASSWORD" > /run/auth.txt
chmod 600 /run/auth.txt

openvpn \
  --config "$FILTERED_OVPN" \
  --auth-user-pass /run/auth.txt \
  --auth-nocache \
  --route-nopull --redirect-gateway def1 \
  --keepalive 10 60 \
  --pull-filter ignore "route-ipv6" \
  --pull-filter ignore "ifconfig-ipv6" &

# wait for tun0
echo -n "Waiting for tun0 "
until ip link show tun0 &>/dev/null; do
  sleep 0.5
  echo -n "."
done
echo " up."

# 5) policy-route all traffic from the container’s primary interface via host NIC
CONTAINER_IP=$(ip -4 addr show dev "$iface" \
               | awk '/inet /{sub(/\/.*/,"",$2); print $2; exit}')
echo "200 hosttable" >> /etc/iproute2/rt_tables
ip route add default via "$gw" dev "$iface" table hosttable
ip rule add from "$CONTAINER_IP" table hosttable priority 100

# 6) determine eth0 IP to bind Xray (UDP correctness)
listen_ip=$(ip -4 addr show eth0 \
            | awk '/inet /{sub(/\/.*/,"",$2); print $2; exit}')

# 7) render Xray config.json with tcpFastOpen and warning loglevel
mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
  "log": {
    "access": "none",
    "error": "",
    "loglevel": "warning",
    "dnsLog": false,
    "maskAddress": ""
  },
  "inbounds": [
    {
      "listen": "${listen_ip}",
      "port": 1080,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "${SS_PASSWORD}",
        "network": "tcp,udp"
      },
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": true
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# 8) exec Xray
exec xray -config /etc/xray/config.json
