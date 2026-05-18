# wakeweb

**Wake-on-LAN in your browser** – wake up devices on your network with a single click.

A modern web interface to manage and wake devices via Magic Packet. Runs as a lightweight Node.js server on a home server, NAS, or Proxmox LXC container.

---

## Quick Start

Run a single command on your server – everything else happens automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/Orangezeiger/wakeweb/master/install.sh | sudo bash
```

The installer will:
- install Node.js 20 LTS (if not already present)
- clone the repository to `/opt/wakeweb`
- install all dependencies
- set up a systemd service (starts automatically on boot)
- print the finished URL

**Supported systems:** Debian, Ubuntu, Proxmox LXC (Debian), Arch/Manjaro

---

## Manual Install

```bash
# 1. Clone the repository
git clone https://github.com/Orangezeiger/wakeweb /opt/wakeweb
cd /opt/wakeweb

# 2. Install dependencies
npm install

# 3. Configuration (optional)
cp .env.example .env

# 4. Start
npm start
```

App runs at: **http://localhost:3000**

---

## Configuration

Edit the `.env` file in the project folder:

| Variable         | Default | Description                                                  |
|------------------|---------|--------------------------------------------------------------|
| `PORT`           | `3000`  | Port the server listens on                                   |
| `BROADCAST_ADDR` | –       | Broadcast address (required when server runs inside LXC/VM) |

**Example for Proxmox LXC:**
```env
PORT=3000
BROADCAST_ADDR=192.168.1.255
```

---

## systemd Service

The installer sets this up automatically. To do it manually:

```bash
sudo nano /etc/systemd/system/wakeweb.service
```

```ini
[Unit]
Description=wakeweb Wake-on-LAN
After=network.target

[Service]
WorkingDirectory=/opt/wakeweb
ExecStart=/usr/bin/node server.js
Restart=always
User=nobody
EnvironmentFile=/opt/wakeweb/.env

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now wakeweb
```

---

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/Orangezeiger/wakeweb/master/install.sh | sudo bash
```

The installer detects an existing installation and only runs `git pull` + restart.

---

## Setup Guide

Detailed step-by-step instructions (server setup, enabling WoL on target devices) are available directly in the web app at `/guide`.

---

## API

| Method   | Path                    | Description           |
|----------|-------------------------|-----------------------|
| `GET`    | `/api/devices`          | List all devices      |
| `POST`   | `/api/devices`          | Add a device          |
| `PUT`    | `/api/devices/:id`      | Update a device       |
| `DELETE` | `/api/devices/:id`      | Delete a device       |
| `POST`   | `/api/devices/:id/wake` | Send Magic Packet     |
| `GET`    | `/api/status`           | Ping status of all devices |

**POST /api/devices** – Body:
```json
{ "name": "Home Server", "mac": "AA:BB:CC:DD:EE:FF", "ip": "192.168.1.100" }
```

---

## Prerequisites

- Wake-on-LAN enabled in the BIOS/UEFI of the target device
- Server and target device on the same network segment (or `BROADCAST_ADDR` configured)
