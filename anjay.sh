#!/bin/bash
set -e
clear

read -p "Port Minecraft (default 25565): " MC_PORT
MC_PORT=${MC_PORT:-25565}

MC_USER="mcserver"
MC_BASE="/etc/mc"
VANILLA_DIR="$MC_BASE/servers/vanilla"
SERVICE_NAME="minecraft-vanilla"
echo "[1/6] Install Java & dependensi"
wget -qO - https://repos.azul.com/azul-repo.key | gpg --dearmor | tee /usr/share/keyrings/azul.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | tee /etc/apt/sources.list.d/zulu.list

apt update -qq
apt install -y -qq zulu21-jdk curl jq wget git python3 python3-pip build-essential > /dev/null

if ! id "$MC_USER" &>/dev/null; then
  useradd -r -m -U -d $MC_BASE -s /bin/bash $MC_USER
fi

mkdir -p "$VANILLA_DIR"
chown -R $MC_USER:$MC_USER $MC_BASE
cd "$VANILLA_DIR"

# >> Install nodejs
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

echo "[2/6] Download Minecraft server.jar (1.21.8)"
manifest=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json)
url=$(echo "$manifest" | jq -r '.versions[] | select(.id == "1.21.8") | .url')
server_url=$(curl -s "$url" | jq -r '.downloads.server.url')

wget -q "$server_url" -O server.jar
echo "eula=true" > eula.txt

echo "[3/6] Buat systemd service"
cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Minecraft Vanilla Server 1.21.8
After=network.target

[Service]
User=$MC_USER
WorkingDirectory=$VANILLA_DIR
ExecStart=/usr/bin/java -Xmx6G -Xms2G -jar server.jar nogui --port $MC_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "[4/6] Install MineOS WebUI"
cd /usr/games
rm -rf /usr/games/mineos-node
git clone https://github.com/hexparrot/mineos-node.git
cd mineos-node
npm install --omit=dev
npm install --global forever

adduser --disabled-password --gecos "" mcadmin
chown -R mcadmin:mcadmin /usr/games/mineos-node

echo "[5/6] Buat systemd untuk MineOS"
cat > /etc/systemd/system/mineos.service <<EOF
[Unit]
Description=MineOS WebUI
After=network.target

[Service]
User=mcadmin
WorkingDirectory=/usr/games/mineos-node
ExecStart=/usr/bin/forever start mineos.js
ExecStop=/usr/bin/forever stop mineos.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable mineos
systemctl start mineos

echo "[6/6] Atur Firewall"
ufw allow $MC_PORT comment 'Minecraft Vanilla'
ufw allow 8443 comment 'MineOS WebUI'
ufw --force enable > /dev/null

clear
echo "=== Instalasi Selesai ==="
echo "Minecraft Vanilla 1.21.8 aktif di port $MC_PORT"
echo "WebUI MineOS bisa dibuka di: https://<IP>:8443"
echo "Login WebUI pakai user: mcadmin"
echo ""
echo "Systemd services:"
echo "  systemctl status minecraft-vanilla"
echo "  systemctl status mineos"
