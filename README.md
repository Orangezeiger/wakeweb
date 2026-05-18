# wakeweb

**Wake-on-LAN im Browser** – Geräte im Netzwerk per Mausklick aufwecken.

Modernes Web-Interface zum Verwalten und Aufwecken von Geräten per Magic Packet. Läuft als leichter Node.js-Server auf einem Heimserver, NAS oder Proxmox-LXC-Container.

---

## Schnellstart

Einen Befehl auf dem Server ausführen – der Rest passiert automatisch:

```bash
curl -fsSL https://raw.githubusercontent.com/Orangezeiger/wakeweb/master/install.sh | sudo bash
```

Der Installer:
- installiert Node.js 20 LTS (falls nicht vorhanden)
- klont das Repository nach `/opt/wakeweb`
- installiert alle Abhängigkeiten
- richtet einen systemd-Dienst ein (startet automatisch beim Boot)
- gibt die fertige URL aus

**Unterstützte Systeme:** Debian, Ubuntu, Proxmox LXC (Debian), Arch/Manjaro

---

## Manueller Install

```bash
# 1. Repository klonen
git clone https://github.com/Orangezeiger/wakeweb /opt/wakeweb
cd /opt/wakeweb

# 2. Abhängigkeiten installieren
npm install

# 3. Konfiguration (optional)
cp .env.example .env

# 4. Starten
npm start
```

App läuft auf: **http://localhost:3000**

---

## Konfiguration

Datei `.env` im Projektordner:

| Variable         | Standard | Beschreibung                                              |
|------------------|----------|-----------------------------------------------------------|
| `PORT`           | `3000`   | Port auf dem der Server lauscht                          |
| `BROADCAST_ADDR` | –        | Broadcast-Adresse (nötig wenn Server in LXC/VM läuft)   |

**Beispiel für Proxmox LXC:**
```env
PORT=3000
BROADCAST_ADDR=192.168.1.255
```

---

## Als systemd-Dienst

Der Installer richtet dies automatisch ein. Manuell:

```bash
# Service-Datei anlegen
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

Der Installer erkennt eine bestehende Installation und führt nur ein `git pull` + Neustart durch.

---

## Einrichtungsanleitung

Detaillierte Schritt-für-Schritt-Anleitungen (Server-Setup, WoL am Zielgerät aktivieren) gibt es direkt in der Web-App unter **`/guide`** oder in der [Online-Anleitung](https://github.com/Orangezeiger/wakeweb/blob/master/public/guide.html).

---

## API

| Methode  | Pfad                    | Beschreibung          |
|----------|-------------------------|-----------------------|
| `GET`    | `/api/devices`          | Alle Geräte abrufen   |
| `POST`   | `/api/devices`          | Gerät hinzufügen      |
| `DELETE` | `/api/devices/:id`      | Gerät löschen         |
| `POST`   | `/api/devices/:id/wake` | Magic Packet senden   |

**POST /api/devices** – Body:
```json
{ "name": "Heimserver", "mac": "AA:BB:CC:DD:EE:FF" }
```

---

## Voraussetzungen

- Node.js ≥ 18
- Wake-on-LAN im BIOS/UEFI des Zielgeräts aktiviert
- Server und Zielgerät im selben Netzwerksegment (oder `BROADCAST_ADDR` gesetzt)
