# xmr

bash -c "$(curl -fsSL https://RAW_URL/install_xmrig.sh)" \
  && WALLET=YOUR_XMR_ADDRESS POOL=pool.supportxmr.com:443 WORKER=$(hostname) PASS=x TLS=true bash /opt/xmrig-run/mine.sh

# or

WALLET=YOUR_XMR_ADDRESS POOL=pool.supportxmr.com:443 WORKER=$(hostname) PASS=x TLS=true \
bash -c "$(curl -fsSL https://RAW_URL/install_xmrig.sh)"

# or 

WALLET=YOUR_XMR_ADDRESS \
POOL=pool.supportxmr.com:443 \
WORKER=$(hostname) \
PASS=x \
TLS=true \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Incrisz/xmr/main/install_xmrig.sh)"
