#!/bin/bash
set -e
clear

echo "[1/6] Install Java & dependency"
apt -qq install gpg curl jq wget git -y > /dev/null 2>&1
wget -qO - https://repos.azul.com/azul-repo.key | gpg --dearmor | tee /usr/share/keyrings/azul.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | tee /etc/apt/sources.list.d/zulu.list
apt update -qq
apt install -y -qq zulu21-jdk > /dev/null 2>&1

echo "[2/6] Create folder for minecraft server"
mkdir -p /etc/mc/
cd /etc/mc

echo "[3/6] Download minecraft fabric server 1.21.8 loader 1.1.0"
wget -O server.jar 'https://meta.fabricmc.net/v2/versions/loader/1.21.8/0.16.14/1.1.0/server/jar'

echo "[4/6] Install minecraft server & configure server"
echo "eula=true" > eula.txt

echo "[5/6] Adding bin shortcut"
cat > /usr/bin/fabric << 'EOF'
#!/bin/bash
cd /etc/mc
/usr/bin/java -Xmx5G -Xms5G -jar server.jar nogui
EOF
chmod +x /usr/bin/fabric

echo "[6/6] Starting MC server at screen sessions"
screen -dmS fabric /usr/bin/fabric

# >> Done
echo "

Minecraft server has been successfully installed.

"
