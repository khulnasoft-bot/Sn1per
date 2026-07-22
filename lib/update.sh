sniper_check_online() {
  ONLINE=$(curl --connect-timeout 3 --insecure -s \
    "https://sn1persecurity.com/community/updates.txt?$VER&mid=$(cat /etc/machine-id 2>/dev/null)" 2>/dev/null)
  if [[ -z "$ONLINE" ]]; then
    ONLINE=$(curl --connect-timeout 3 -s \
      https://api.github.com/repos/1N3/Sn1per/tags | grep -Po '"name":.*?[^\\]",' | head -1 | cut -c11-13)
    if [[ -z "$ONLINE" ]]; then
      ONLINE="0"
      echo -e "$OKBLUE[*]$RESET Checking for active internet connection ${OKBLUE}[${OKRED}FAIL${RESET}${OKBLUE}]"
      echo -e "${OKBLUE}[${OKRED}i${RESET}${OKBLUE}]$RESET sniper is running in offline mode.$RESET"
    else
      ONLINE="1"
      echo -e "$OKBLUE[*]$RESET Checking for active internet connection ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]"
    fi
  else
    ONLINE="1"
    echo -e "$OKBLUE[*]$RESET Checking for active internet connection ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]"
  fi
}

sniper_check_update() {
  if [[ "$ENABLE_AUTO_UPDATES" == "1" ]] && [[ "$ONLINE" == "1" ]]; then
    local latest
    latest=$(curl --connect-timeout 5 -s \
      https://api.github.com/repos/1N3/Sn1per/tags | grep -Po '"name":.*?[^\\]",' | head -1 | cut -c11-13)
    if [[ "$latest" != "$VER" ]]; then
      echo -e "${OKBLUE}[${OKRED}i${RESET}${OKBLUE}] sniper v$latest is available to download... To update, type${OKRED} \"sniper -u\" $RESET"
    fi
  fi
  touch /tmp/update-check.txt 2>/dev/null
}

sniper_update() {
  logo
  echo -e "$OKBLUE[*]$RESET Checking for updates...${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]"
  if [[ "$ONLINE" == "0" ]]; then
    echo "You will need to download the latest release manually at https://github.com/1N3/Sn1per/"
    return
  fi
  local latest
  latest=$(curl --connect-timeout 5 -s \
    https://api.github.com/repos/1N3/Sn1per/tags | grep -Po '"name":.*?[^\\]",' | head -1 | cut -c11-13)
  if [[ "$latest" == "$VER" ]]; then
    echo "Already up to date."
    return
  fi
  echo -e "${OKBLUE}[${OKRED}i${RESET}${OKBLUE}] Sn1per $latest is available to download...Do you want to update? (y or n)$RESET"
  read ans
  if [[ "$ans" == "y" ]]; then
    rm -Rf /tmp/Sn1per/ 2>/dev/null
    git clone https://github.com/1N3/Sn1per /tmp/Sn1per/
    cd /tmp/Sn1per/
    chmod +rx install.sh
    bash install.sh
    rm -Rf /tmp/Sn1per/ 2>/dev/null
    exit
  fi
}
