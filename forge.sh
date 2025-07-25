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

echo "[3/6] Download minecraft forge server 1.21.8-58.0.1"
wget -O forge-installer.jar 'https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.8-58.0.1/forge-1.21.8-58.0.1-installer.jar'

echo "[4/6] Install minecraft server & configure server"
java -jar forge-installer.jar --installServer . > /dev/null 2>&1
rm -rf forge-installer.jar # remove installer file
rm -rf *log *bat *sh
echo "eula=true" > eula.txt

echo "[5/6] Adding bin shortcut"
cat > /usr/bin/mc << 'EOF'
#!/bin/bash
cd /etc/mc
/usr/bin/java -Xmx5G -Xms5G -jar forge-1.21.8-58.0.1-shim.jar nogui
EOF
chmod +x /usr/bin/mc

echo "[6/6] Starting MC server at screen sessions"
screen -dmS mc /usr/bin/mc

# >> Done
echo "

Minecraft server has been successfully installed.

"
