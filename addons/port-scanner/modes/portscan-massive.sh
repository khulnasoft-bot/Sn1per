MODE_NAME="portscan-massive"
MODE_DESCRIPTION="Masscan discovery scan + Nmap detailed scan on open ports"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(nmap masscan)

PORTSCAN_RATE="${PORTSCAN_RATE:-1000}"
PORTSCAN_INTERFACE="${PORTSCAN_INTERFACE:-eth0}"
PORTSCAN_MASSIVE_PORTS="${PORTSCAN_MASSIVE_PORTS:-1-65535}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/nmap/massive"
}

mode_run() {
  local outdir="$LOOT_DIR/nmap/massive"
  local target="$TARGET"

  section_banner
  section_header "MASSIVE PORT SCAN: $target (all $PORTSCAN_MASSIVE_PORTS ports)"

  masscan -p"$PORTSCAN_MASSIVE_PORTS" --rate="$PORTSCAN_RATE" -e "$PORTSCAN_INTERFACE" "$target" 2>/dev/null | tee "$outdir/masscan-$target.txt"

  local open_ports
  open_ports=$(grep -oP 'port \K[0-9]+' "$outdir/masscan-$target.txt" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')
  if [[ -n "$open_ports" ]]; then
    section_header "Running Nmap detailed scan on $open_ports"
    nmap -sV -sC -p "$open_ports" "$target" -oX "$outdir/nmap-massive-$target.xml" | tee "$outdir/nmap-massive-$target.txt" 2>/dev/null
    nmap_parse_xml_for_ports "$outdir/nmap-massive-$target.xml"
  else
    log_warn "No open ports found on $target"
  fi
}

mode_cleanup() {
  log_info "Massive port scan complete for $TARGET"
}

mode_execute
