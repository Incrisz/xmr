#!/bin/bash

# XMRig Mining Setup Script
echo "Starting XMRig mining setup..."

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y \
    git \
    build-essential \
    cmake \
    automake \
    libtool \
    autoconf \
    libhwloc-dev \
    libuv1-dev \
    libssl-dev \
    pkg-config

# Clone XMRig repository
echo "Cloning XMRig repository..."
if [ -d "xmrig" ]; then
    echo "XMRig directory exists, removing it..."
    rm -rf xmrig
fi

git clone https://github.com/xmrig/xmrig.git
cd xmrig

# Create build directory
echo "Creating build directory..."
mkdir -p build
cd build

# Configure and build
echo "Configuring with CMake..."
cmake ..

echo "Building XMRig (this may take a few minutes)..."
make -j$(nproc)

# Check if build was successful
if [ ! -f "./xmrig" ]; then
    echo "Build failed! XMRig executable not found."
    exit 1
fi

echo "Build successful! Creating configuration file..."

# Create config.json
cat > config.json << 'EOF'
{
  "api": {
    "id": null,
    "worker-id": null
  },
  "http": {
    "enabled": false,
    "host": "127.0.0.1",
    "port": 0,
    "access-token": null,
    "restricted": true
  },
  "autosave": true,
  "background": false,
  "colors": true,
  "title": true,
  "randomx": {
    "init": -1,
    "mode": "auto",
    "1gb-pages": false,
    "rdmsr": true,
    "wrmsr": true,
    "cache_qos": false,
    "numa": true,
    "scratchpad_prefetch_mode": 1
  },
  "cpu": {
    "enabled": true,
    "huge-pages": true,
    "huge-pages-jit": false,
    "hw-aes": null,
    "priority": null,
    "memory-pool": false,
    "yield": true,
    "max-threads-hint": 100,
    "asm": true,
    "argon2-impl": null,
    "cn/0": false,
    "cn-lite/0": false
  },
  "opencl": {
    "enabled": false
  },
  "cuda": {
    "enabled": false
  },
  "donate-level": 1,
  "donate-over-proxy": 1,
  "log-file": null,
  "pools": [
    {
      "algo": null,
      "coin": "monero",
      "url": "pool.supportxmr.com:443",
      "user": "wallet_address",
      "pass": "x",
      "rig-id": null,
      "nicehash": false,
      "keepalive": true,
      "enabled": true,
      "tls": true,
      "tls-fingerprint": null,
      "daemon": false,
      "socks5": null,
      "self-select": null,
      "submit-to-origin": false
    }
  ],
  "print-time": 60,
  "health-print-time": 60,
  "retries": 5,
  "retry-pause": 5,
  "syslog": false,
  "tls": {
    "enabled": false,
    "protocols": null,
    "cert": null,
    "cert_key": null,
    "ciphers": null,
    "ciphersuites": null,
    "dhparam": null
  },
  "user-agent": null,
  "verbose": 0,
  "watch": true,
  "pause-on-battery": false,
  "pause-on-active": false
}
EOF

echo "Configuration file created successfully!"

# Make xmrig executable
chmod +x ./xmrig

# Test the miner
echo "Testing XMRig installation..."
./xmrig --version

echo "Setup complete!"
echo ""
echo "To start mining:"
echo "  cd $(pwd)"
echo "  nohup ./xmrig > miner.log 2>&1 &"
echo ""
echo "To check mining status:"
echo "  tail -f miner.log"
echo ""
echo "To stop mining:"
echo "  pkill xmrig"
echo ""

# Start mining automatically
echo "Starting mining in background..."
nohup ./xmrig > miner.log 2>&1 &
sleep 3

# Check if mining started successfully
if pgrep xmrig > /dev/null; then
    echo "Mining started successfully! PID: $(pgrep xmrig)"
    echo "Hash rate and status will appear in the log..."
    echo ""
    echo "Useful commands:"
    echo "  Check status: tail -f miner.log"
    echo "  Stop mining: pkill xmrig"
    echo "  Restart: nohup ./xmrig > miner.log 2>&1 &"
    echo ""
    echo "Mining is now running in the background!"
else
    echo "Failed to start mining! Check the log file for errors:"
    echo "cat miner.log"
fi

echo "Script completed!"