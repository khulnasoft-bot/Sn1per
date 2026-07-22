sniper_init_workspace() {
  local loot_dir="${1:-$LOOT_DIR}"
  local target="$2"
  local workspace_dir="$3"
  local auto_brute="${4:-0}"
  local fullnmapscan="${5:-0}"
  local osint_enabled="${6:-0}"
  local recon_enabled="${7:-0}"

  [[ -n "$workspace_dir" ]] && loot_dir="$workspace_dir"

  echo -e "$OKBLUE[*]$RESET Saving loot to $loot_dir ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"

  mkdir -p "$loot_dir"/{domains,ips,screenshots,nmap,reports,output,osint,credentials,web,vulnerabilities,notes,scans/scheduled}
  touch "$loot_dir/scans/scheduled/"{daily,weekly,monthly}.sh 2>/dev/null
  touch "$loot_dir/scans/"{notifications,notifications_new}.txt 2>/dev/null

  chmod 777 -Rf "$INSTALL_DIR" 2>/dev/null || true
  chown root "$INSTALL_DIR/sniper" 2>/dev/null || true
  chmod 4777 "$INSTALL_DIR/sniper" 2>/dev/null || true

  target="$(echo "$target" | sed 's/https:\/\///g; s/http:\/\///g')"

  local is_out_of_scope=0
  for scope_item in "${OUT_OF_SCOPE[@]}"; do
    if echo "$target" | grep -q "${scope_item}" 2>/dev/null; then
      is_out_of_scope=1
      break
    fi
  done

  if [[ $is_out_of_scope -eq 1 ]]; then
    echo -e "${OKBLUE}[${OKRED}i${RESET}${OKBLUE}] $target is out of scope. Skipping! $RESET"
    exit 0
  fi

  echo -e "$OKBLUE[*]$RESET Scanning $target ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"
  echo "$target" >> "$loot_dir/domains/targets.txt" 2>/dev/null

  service postgresql start 2>/dev/null >/dev/null || true
  msfdb start 2>/dev/null >/dev/null || true

  chown root /run/user/1000/gdm/Xauthority 2>/dev/null || true
  local last_user
  last_user=$(last 2>/dev/null | head -n 1 | awk '{print $1}') || true
  sudo cp -a "/home/$last_user/.Xauthority" /root/.Xauthority 2>/dev/null || true
  sudo cp -a /root/.Xauthority /root/.Xauthority.bak 2>/dev/null || true
  sudo cp -a "/home/$USER/.Xauthority" /root/.Xauthority 2>/dev/null || true
  sudo cp -a /home/kali/.Xauthority /root/.Xauthority 2>/dev/null || true
  sudo chown root: /root/.Xauthority 2>/dev/null || true
  XAUTHORITY=/root/.Xauthority

  if [[ "$auto_brute" == "1" ]]; then
    echo "$target AUTO_BRUTE $(date +"%Y-%m-%d %H:%M")" >> "$loot_dir/scans/tasks.txt" 2>/dev/null
    touch "$loot_dir/scans/$target-AUTO_BRUTE.txt" 2>/dev/null
  fi
  if [[ "$fullnmapscan" == "1" ]]; then
    echo "$target fullnmapscan $(date +"%Y-%m-%d %H:%M")" >> "$loot_dir/scans/tasks.txt" 2>/dev/null
    touch "$loot_dir/scans/$target-fullnmapscan.txt" 2>/dev/null
  fi
  if [[ "$osint_enabled" == "1" ]]; then
    echo "$target osint $(date +"%Y-%m-%d %H:%M")" >> "$loot_dir/scans/tasks.txt" 2>/dev/null
    touch "$loot_dir/scans/$target-osint.txt" 2>/dev/null
  fi
  if [[ "$recon_enabled" == "1" ]]; then
    echo "$target recon $(date +"%Y-%m-%d %H:%M")" >> "$loot_dir/scans/tasks.txt" 2>/dev/null
    touch "$loot_dir/scans/$target-recon.txt" 2>/dev/null
  fi
}
