# xmr

# just fix in the address

sudo mkdir -p /opt
sudo chown -R ubuntu:ubuntu /opt

WALLET= \
POOL=pool.supportxmr.com:443 \
WORKER=$(hostname) \
PASS=x \
TLS=true \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Incrisz/xmr/main/install_xmrig.sh)"


# Watch logs / hashrate
tail -f /opt/xmrig-run/miner.log

# Stop / start
pkill xmrig                      # stop
bash /opt/xmrig-run/mine.sh      # start again (uses your env/config)
