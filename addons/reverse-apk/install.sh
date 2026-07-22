#!/bin/bash
echo "[*] Installing ReverseAPK dependencies..."

if ! command -v apktool &>/dev/null; then
  echo "  Installing apktool..."
  wget -q -O /usr/local/bin/apktool https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool 2>/dev/null
  chmod +x /usr/local/bin/apktool
fi

if ! command -v jadx &>/dev/null; then
  echo "  Installing jadx..."
  git clone https://github.com/skylot/jadx /opt/jadx 2>/dev/null
  cd /opt/jadx && ./gradlew dist 2>/dev/null
  ln -sf /opt/jadx/build/jadx/bin/jadx /usr/local/bin/jadx 2>/dev/null
  cd "$INSTALL_DIR"
fi

echo "[*] ReverseAPK dependencies installed."
