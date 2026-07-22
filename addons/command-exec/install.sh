#!/bin/bash
echo "[*] Installing Command Execution Add-on dependencies..."
if ! command -v commix &>/dev/null; then
  echo "  Installing commix..."
  git clone https://github.com/commixproject/commix /opt/commix 2>/dev/null
  ln -sf /opt/commix/commix.py /usr/local/bin/commix 2>/dev/null
fi
echo "[*] Command Execution Add-on dependencies installed."
