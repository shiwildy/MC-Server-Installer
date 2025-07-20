#!/bin/bash
set -e
clear

read -p "Port Minecraft (default 25565): " MC_PORT
MC_PORT=${MC_PORT:-25565}

MC_USER="mcserver"
MC_BASE="/etc/mc"
VANILLA_DIR="$MC_BASE/servers/vanilla"
SERVICE_NAME="mc"
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
ExecStart=/usr/bin/java -Xmx8G -Xms4G -jar server.jar nogui --port $MC_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

clear
echo "=== Instalasi Selesai ==="
echo "Minecraft Vanilla 1.21.8 aktif di port $MC_PORT"
echo ""
echo "Systemd services:"
echo "  systemctl status mc"
