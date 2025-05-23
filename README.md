# nordvpn-xray-proxy

**Dockerized NordVPN + Xray (Shadowsocks 2022) proxy**  
Dynamically downloads the correct OpenVPN config, starts NordVPN via OpenVPN, and runs Xray in a container exposing a SS proxy with emoji‐tagged server codes.

## Quickstart

1. **Run the one-liner installer & launcher**:

    ```bash
    bash -c "$(curl -H 'Cache-Control: no-cache, no-store' -fsSL https://raw.githubusercontent.com/Slinesx/NordVPN-Xray/main/install-nordvpn-xray.sh)"
    ```

2. **First-time setup**: If you don't have NordVPN credentials in your environment, the script will:
   - Prompt for your username and password
   - Save them to your shell's RC file (`.zshrc` or `.bashrc`)
   - Provide instructions to apply the changes
   - Exit so you can restart with credentials available

3. **Server selection**: When prompted, enter a NordVPN server code (e.g. `tr54`).

## Features

- **Credential management** — automatically prompts and saves credentials if needed
- **Public IP detection** — uses your public IP address for the proxy configuration
- **Auto‑download** `.ovpn` file by server code (e.g. `tr54`)
- **Dynamic** emoji 🇹🇷 𝐓𝐑𝐘·𝐍𝐑𝐃 ₅₄ tag based on ISO country code + server ID
- **Shadowsocks** over UDP/TCP with `2022-blake3-aes-128-gcm`
- **Lightweight** Alpine‐based Docker image (~25 MB)
- **One‑liner** installer via `bash -c "$(curl …/install-nordvpn-xray.sh)"`.

## Prerequisites

- Docker  
- NordVPN account

## Advanced Usage

You can pass the server code directly as an argument:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Slinesx/NordVPN-Xray/main/install-nordvpn-xray.sh)" _ us4721
```

