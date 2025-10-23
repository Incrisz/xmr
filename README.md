# xmr

bash -c "$(curl -fsSL https://RAW_URL/install_xmrig.sh)" \
  && WALLET=YOUR_XMR_ADDRESS POOL=pool.supportxmr.com:443 WORKER=$(hostname) PASS=x TLS=true bash /opt/xmrig-run/mine.sh

# or

WALLET=YOUR_XMR_ADDRESS POOL=pool.supportxmr.com:443 WORKER=$(hostname) PASS=x TLS=true \
bash -c "$(curl -fsSL https://RAW_URL/install_xmrig.sh)"

# or 

WALLET=43Yz52kitioUcdTy2Wkpj3B9YURrm9VNKTQaQSNRPwztTkjge63sUbXipkK8VgBkDmdiAYQBNPYFERfW1dnUoyiTVZWE8YE \
POOL=pool.supportxmr.com:443 \
WORKER=$(hostname) \
PASS=x \
TLS=true \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Incrisz/xmr/main/install_xmrig.sh)"
