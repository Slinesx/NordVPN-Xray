# nordvpn-xray-proxy

**Automated Dockerized NordVPN + Xray (Shadowsocks 2022) proxy**  
Dynamically downloads the correct OpenVPN config, starts NordVPN via NordLynx/TUN, and runs Xray in a container exposing a SS proxy with emoji‐tagged server codes.

## Quickstart

1. **Export your NordVPN credentials**:

    ```bash
    export NORD_USERNAME="you@nordvpn"
    export NORD_PASSWORD="your-nord-pw"
    ```

2. **Run the one-liner installer & launcher**:

    ```bash
    bash -c "$(curl -H 'Cache-Control: no-cache, no-store' -fsSL https://raw.githubusercontent.com/Slinesx/NordVPN-Xray/main/install-nordvpn-xray.sh)"
    ```

## Features

- **Auto‑download** `.ovpn` file by server code (e.g. `tr54`).  
- **Dynamic** emoji 🇹🇷 𝐓𝐑𝐘·𝐍𝐑𝐃 ₅₄ tag based on ISO country code + server ID.  
- **Shadowsocks** over UDP/TCP with `2022-blake3-aes-128-gcm`.  
- **Lightweight** Alpine‐based Docker image (~25 MB).  
- **One‑liner** installer via `bash -c "$(curl …/install-nordvpn-xray.sh)"`.

## Prerequisites

- Docker  
- nordvpn account credentials  
- `git` (if you’re cloning the repo)  
- (Optional) GitHub CLI `gh` for quick repo creation
