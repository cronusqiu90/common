#! /bin/bash
cd /tmp
wget https://github.com/astral-sh/python-build-standalone/releases/download/20251217/cpython-3.10.19+20251217-x86_64-unknown-linux-gnu-install_only.tar.gz
mkdir -p /usr/local/python3.10 && tar -xzf /tmp/cpython-3.10.19+20251217-x86_64-unknown-linux-gnu-install_only.tar.gz -C /usr/local/python3.10 --strip-components=1
/usr/local/python3.10/bin/python3.10 -c "import ssl; print(ssl.OPENSSL_VERSION)"
rm -rf /tmp/cpython-3.10.19+20251217-x86_64-unknown-linux-gnu-install_only.tar.gz
