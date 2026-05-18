#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/Orangezeiger/wakeweb.git"
INSTALL_DIR="/opt/wakeweb"
SERVICE_FILE="/etc/systemd/system/wakeweb.service"
PORT="${PORT:-3000}"

# ── Colors ─────────────────────────────────────────────────────────────────
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${CYAN}${BOLD}→${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}!${RESET} $*"; }
die()     { echo -e "${RED}${BOLD}✗${RESET} $*" >&2; exit 1; }

# ── Root check ──────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  die "Bitte als root ausführen: sudo bash install.sh"
fi

echo ""
echo -e "${BOLD}  wakeweb – Installer${RESET}"
echo -e "  Wake-on-LAN im Browser"
echo ""

# ── Detect package manager ──────────────────────────────────────────────────
if command -v apt-get &>/dev/null; then
  PKG="apt"
elif command -v pacman &>/dev/null; then
  PKG="pacman"
else
  die "Kein unterstützter Paketmanager gefunden (apt / pacman)."
fi

# ── Install git ──────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  info "Installiere git…"
  if [[ "$PKG" == "apt" ]]; then
    apt-get update -qq && apt-get install -y -qq git
  else
    pacman -Sy --noconfirm git
  fi
fi
success "git verfügbar"

# ── Install Node.js ──────────────────────────────────────────────────────────
if ! command -v node &>/dev/null || [[ "$(node -e 'process.exit(+process.version.slice(1).split(".")[0] < 18)')" ]]; then
  info "Installiere Node.js 20 LTS…"
  if [[ "$PKG" == "apt" ]]; then
    apt-get install -y -qq curl
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
    apt-get install -y -qq nodejs
  else
    pacman -Sy --noconfirm nodejs npm
  fi
fi
success "Node.js $(node -v) verfügbar"

# ── Clone / update repo ──────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Aktualisiere $INSTALL_DIR…"
  git -C "$INSTALL_DIR" pull --ff-only
else
  info "Klone Repository nach $INSTALL_DIR…"
  git clone --depth=1 "$REPO" "$INSTALL_DIR"
fi
success "Code bereit"

# ── Install dependencies ─────────────────────────────────────────────────────
info "Installiere npm-Pakete…"
npm install --prefix "$INSTALL_DIR" --omit=dev --silent
success "Abhängigkeiten installiert"

# ── Config ───────────────────────────────────────────────────────────────────
if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  sed -i "s/^PORT=.*/PORT=$PORT/" "$INSTALL_DIR/.env"
  success ".env erstellt (PORT=$PORT)"
else
  warn ".env existiert bereits – wird nicht überschrieben"
fi

# ── systemd service ──────────────────────────────────────────────────────────
NODE_BIN="$(command -v node)"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=wakeweb Wake-on-LAN
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
ExecStart=$NODE_BIN server.js
Restart=always
RestartSec=5
User=nobody
EnvironmentFile=$INSTALL_DIR/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wakeweb --quiet
systemctl restart wakeweb

success "systemd-Dienst aktiv"

# ── Done ─────────────────────────────────────────────────────────────────────
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "SERVER-IP")

echo ""
echo -e "${GREEN}${BOLD}  wakeweb läuft!${RESET}"
echo -e "  ${BOLD}http://${LOCAL_IP}:${PORT}${RESET}"
echo ""
