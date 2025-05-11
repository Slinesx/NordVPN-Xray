#!/usr/bin/env bash
# install-nordvpn-xray.sh — online installer & launcher for nordvpn‑xray container
set -Eeuo pipefail

# 0) prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Install Docker first" >&2; exit 1; }
command -v curl   >/dev/null 2>&1 || { echo "❌ Install curl first" >&2;   exit 1; }

# 1) credentials: prompt & save if missing, then source them
if [[ -z "${NORD_USERNAME:-}" || -z "${NORD_PASSWORD:-}" ]]; then
  echo "❗️ NordVPN credentials not found in your environment."
  read -rp "Enter NordVPN username: " NORD_USERNAME
  read -rsp "Enter NordVPN password: " NORD_PASSWORD
  echo
  case "${SHELL##*/}" in
    zsh) RCFILE="$HOME/.zshrc" ;;
    *) RCFILE="$HOME/.bashrc" ;;
  esac
  {
    echo ""
    echo "# NordVPN credentials added by install-nordvpn-xray.sh"
    echo "export NORD_USERNAME=\"$NORD_USERNAME\""
    echo "export NORD_PASSWORD=\"$NORD_PASSWORD\""
  } >> "$RCFILE"
  echo "✅ Saved credentials to $RCFILE."
  echo "→ Please run this command to apply the changes:"
  echo "  source $RCFILE"
  exit 0
fi

# 3) make a temp workspace
TMPDIR="$(mktemp -d)"
cleanup(){ rm -rf "$TMPDIR"; }
trap cleanup EXIT

# 4) download emoji mapping scripts into TMPDIR
echo "→ Fetching emoji mappings…"
curl -H 'Cache-Control: no-cache, no-store' -fsSL \
  "https://raw.githubusercontent.com/Slinesx/NordVPN-Xray/main/emoji_data.sh" \
  -o "$TMPDIR/emoji_data.sh"
curl -H 'Cache-Control: no-cache, no-store' -fsSL \
  "https://raw.githubusercontent.com/Slinesx/NordVPN-Xray/main/emoji_utils.sh" \
  -o "$TMPDIR/emoji_utils.sh"

# 5) source the utils
source "$TMPDIR/emoji_utils.sh"

# 6) server code from arg or prompt
if [[ $# -ge 1 ]]; then
  srv="$1"
else
  read -rp "NordVPN server code (e.g. tr54): " srv
fi
[[ -n "$srv" ]] || { echo "❌ No server code provided" >&2; exit 1; }

# 7) download the .ovpn into TMPDIR
OVPN_URL="https://downloads.nordcdn.com/configs/files/ovpn_udp/servers/${srv}.nordvpn.com.udp.ovpn"
OVPN_TMP="$TMPDIR/${srv}.nordvpn.ovpn"
echo "→ Downloading OpenVPN config for: $srv"
curl -fsSL "$OVPN_URL" -o "$OVPN_TMP"

# 8) generate tag & Shadowsocks password
generate_tag "$srv"
SS_PASSWORD="${SS_PASSWORD:-$(openssl rand -base64 16)}"

# 9) pick a free host port
while :; do
  PORT=$(shuf -i20000-65000 -n1)
  ss -tln | awk '{print $4}' | grep -q ":${PORT}$" || break
done

# 10) set up the container
container="nordxray-${srv}"
docker rm -f "$container" &>/dev/null || true

docker run -d --name "$container" \
  --pull=always \
  --cap-add=NET_ADMIN --device=/dev/net/tun \
  -p "0.0.0.0:${PORT}:1080/tcp" \
  -p "0.0.0.0:${PORT}:1080/udp" \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  --sysctl net.ipv6.conf.default.disable_ipv6=1 \
  -e NORD_SERVER="$srv" \
  -e NORD_USERNAME="$NORD_USERNAME" \
  -e NORD_PASSWORD="$NORD_PASSWORD" \
  -e SS_PASSWORD="$SS_PASSWORD" \
  -v "$OVPN_TMP":/nordvpn.ovpn:ro \
  liafonx/nordvpn-xray:latest

# 11) verify
sleep 2
if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != "true" ]]; then
  echo "❌ Container failed to start — logs:" >&2
  docker logs --tail 50 "$container" >&2
  exit 1
fi

# 12) final output
HOST_IP=$(curl -s https://api.ipify.org)
cat <<EOF
-----------------------------------------------------------------
  ✅  Shadowsocks proxy is ready!

  Container   : ${container}
  Xray: shadowsocks=${HOST_IP}:${PORT}, method=2022-blake3-aes-128-gcm, password=${SS_PASSWORD}, fast-open=false, udp-relay=true, tag=${TAG}
-----------------------------------------------------------------
EOF
