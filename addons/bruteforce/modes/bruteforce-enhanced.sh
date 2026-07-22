MODE_NAME="bruteforce-enhanced"
MODE_DESCRIPTION="Service-aware credential brute-forcing framework"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(hydra)

BRUTE_SERVICES="${BRUTE_SERVICES:-ssh,ftp,smtp,mysql,postgresql,smb,rdp,http}"
BRUTE_THREADS="${BRUTE_THREADS:-16}"
BRUTE_TIMEOUT="${BRUTE_TIMEOUT:-30}"
BRUTE_USERLIST="${BRUTE_USERLIST:-/usr/share/brutex/wordlists/simple-users.txt}"
BRUTE_PASSLIST="${BRUTE_PASSLIST:-/usr/share/brutex/wordlists/password.lst}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
  [[ -f "$BRUTE_USERLIST" ]] || log_warn "Userlist $BRUTE_USERLIST not found"
  [[ -f "$BRUTE_PASSLIST" ]] || log_warn "Passlist $BRUTE_PASSLIST not found"
}

mode_init() {
  mkdir -p "$LOOT_DIR/credentials/bruteforce"
}

mode_run() {
  local outdir="$LOOT_DIR/credentials/bruteforce"
  local target="$TARGET"

  section_banner
  section_header "ENHANCED BRUTE FORCE SCAN: $target"

  IFS=',' read -ra services <<< "$BRUTE_SERVICES"
  for service in "${services[@]}"; do
    local port=""
    case "$service" in
      ssh) port="22" ;;
      ftp) port="21" ;;
      smtp) port="25" ;;
      mysql) port="3306" ;;
      postgresql) port="5432" ;;
      smb) port="445" ;;
      rdp) port="3389" ;;
      http) port="80" ;;
      http-post) port="80" ;;
      https) port="443" ;;
    esac
    section_header "Brute-forcing $service on $target:$port"
    hydra -L "$BRUTE_USERLIST" -P "$BRUTE_PASSLIST" -t "$BRUTE_THREADS" -o "$outdir/hydra-$target-$service.txt" "$service://$target" -s "$port" 2>/dev/null
    if [[ -s "$outdir/hydra-$target-$service.txt" ]]; then
      sniper_findings_add "$target" "weak-credentials" "HIGH" "bruteforce" "Valid credentials found for $service: $(cat "$outdir/hydra-$target-$service.txt" | head -c 200)"
    fi
  done
}

mode_cleanup() {
  log_info "Brute force scan complete for $TARGET"
}

mode_execute
