#!/usr/bin/env bash
# XMRig one-shot installer + runner (Debian/Ubuntu/Parrot)
# Usage:
#   WALLET=... POOL=host:port [WORKER=name] [PASS=x] [TLS=true|false] [DONATE=1] [HUGEPAGES=1280] \
#   bash -c "$(curl -fsSL https://RAW_URL/install_xmrig.sh)"

set -euo pipefail

# ----- Read env (with sane defaults) -----
WALLET="${WALLET:-REPLACE_WITH_YOUR_XMR_WALLET}"
POOL="${POOL:-POOL_HOST:PORT}"
WORKER="${WORKER:-worker1}"
PASS="${PASS:-x}"
TLS="${TLS:-true}"              # true/false
DONATE="${DONATE:-1}"           # 0..99
HUGEPAGES="${HUGEPAGES:-1280}"  # tune for your RAM/cores

# Detect non-root user to own/run miner
MINER_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER}")}"

echo "==> Preparing system (user: ${MINER_USER})"
if ! command -v apt >/dev/null 2>&1; then
  echo "This script requires apt-based distro."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt -y upgrade
sudo apt -y install \
  git build-essential cmake automake libtool autoconf pkg-config \
  libhwloc-dev libuv1-dev libssl-dev \
  linux-headers-$(uname -r) libelf-dev bc flex bison \
  ufw

# SSH hardening (keys-only) – safe no-op if already set
# if sudo grep -qE '^[#\s]*PasswordAuthentication\s+yes' /etc/ssh/sshd_config; then
#   echo "==> Disabling SSH password login"
#   sudo sed -i 's/^[#\s]*PasswordAuthentication\s\+yes/PasswordAuthentication no/' /etc/ssh/sshd_config
#   sudo systemctl reload ssh || true
# fi

# Minimal firewall
echo "==> Configuring UFW"
sudo ufw default deny incoming || true
sudo ufw default allow outgoing || true
sudo ufw allow 22/tcp || true
yes | sudo ufw enable || true

# Huge pages
echo "==> Configuring Huge Pages (${HUGEPAGES})"
echo "${HUGEPAGES}" | sudo tee /proc/sys/vm/nr_hugepages >/dev/null
echo "vm.nr_hugepages=${HUGEPAGES}" | sudo tee /etc/sysctl.d/99-hugepages.conf >/dev/null
sudo sysctl --system >/dev/null

# Work dir
sudo mkdir -p /opt/xmrig-run
sudo chown -R "${MINER_USER}:${MINER_USER}" /opt/xmrig-run

# ----- Create the mining script (your main script, env-driven config) -----
cat >/opt/xmrig-run/mine.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# Read env (must be exported by caller or set inline)
WALLET="${WALLET:-REPLACE_WITH_YOUR_XMR_WALLET}"
POOL="${POOL:-POOL_HOST:PORT}"
WORKER="${WORKER:-worker1}"
PASS="${PASS:-x}"
TLS="${TLS:-true}"
DONATE="${DONATE:-1}"

cd /opt
# Clean old tree if present to ensure a fresh build
if [ -d "xmrig" ]; then
  echo "XMRig directory exists, removing for a clean build..."
  rm -rf xmrig
fi

echo "Cloning XMRig repository..."
git clone https://github.com/xmrig/xmrig.git
cd xmrig

echo "Creating build directory..."
mkdir -p build
cd build

echo "Configuring with CMake..."
cmake ..

echo "Building XMRig (this may take a few minutes)..."
make -j"$(nproc)"

if [ ! -f "./xmrig" ]; then
    echo "Build failed! XMRig executable not found."
    exit 1
fi

echo "Writing config.json from environment..."
cat > config.json <<EOF
{
  "api": { "id": null, "worker-id": null },
  "http": { "enabled": false, "host": "127.0.0.1", "port": 0, "access-token": null, "restricted": true },
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
  "opencl": { "enabled": false },
  "cuda":   { "enabled": false },
  "donate-level": ${DONATE},
  "donate-over-proxy": 1,
  "log-file": null,
  "pools": [
    {
      "algo": null,
      "coin": "monero",
      "url": "${POOL}",
      "user": "${WALLET}",
      "pass": "${PASS}",
      "rig-id": "${WORKER}",
      "nicehash": false,
      "keepalive": true,
      "enabled": true,
      "tls": ${TLS},
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
  "tls": { "enabled": false },
  "user-agent": null,
  "verbose": 0,
  "watch": true,
  "pause-on-battery": false,
  "pause-on-active": false
}
EOF

chmod +x ./xmrig

echo "Testing XMRig installation..."
./xmrig --version || true

echo "Starting mining in background with nohup..."
nohup ./xmrig > /opt/xmrig-run/miner.log 2>&1 &

sleep 3
if pgrep xmrig >/dev/null; then
  echo "Mining started. PID: $(pgrep xmrig | head -n1)"
  echo "Log: /opt/xmrig-run/miner.log"
  echo "Tail logs: tail -f /opt/xmrig-run/miner.log"
else
  echo "Failed to start mining. Check log: /opt/xmrig-run/miner.log"
  exit 1
fi
EOS

sudo chmod +x /opt/xmrig-run/mine.sh
sudo chown "${MINER_USER}:${MINER_USER}" /opt/xmrig-run/mine.sh

# Inform + optionally auto-run if WALLET/POOL provided
echo "==> Installer complete."

if [[ "${WALLET}" != REPLACE_* && "${POOL}" != "POOL_HOST:PORT" ]]; then
  echo "==> Detected WALLET/POOL in env; starting miner now…"
  sudo -u "${MINER_USER}" env WALLET="${WALLET}" POOL="${POOL}" WORKER="${WORKER}" PASS="${PASS}" TLS="${TLS}" DONATE="${DONATE}" \
    bash /opt/xmrig-run/mine.sh
else
  cat <<EONOTE

To start mining, run (example):

  WALLET=YOUR_XMR_ADDRESS \\
  POOL=pool.supportxmr.com:443 \\
  WORKER=\$(hostname) \\
  PASS=x \\
  TLS=true \\
  bash /opt/xmrig-run/mine.sh

Logs:
  tail -f /opt/xmrig-run/miner.log

Stop mining:
  pkill xmrig
EONOTE
fi
