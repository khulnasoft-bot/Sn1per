MODE_NAME="portscan-quick"
MODE_DESCRIPTION="Quick SYN scan with service detection on top ports"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(nmap)

PORTSCAN_QUICK_PORTS="${PORTSCAN_QUICK_PORTS:-21,22,23,25,53,80,110,111,135,139,143,389,443,445,993,995,1433,1521,2049,3306,3389,5432,5900,8080,8443}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/nmap/quick"
}

mode_run() {
  local outdir="$LOOT_DIR/nmap/quick"
  local target="$TARGET"
  local ports="${PORTSCAN_QUICK_PORTS}"

  section_banner
  section_header "QUICK PORT SCAN: $target"

  nmap -sS -sV -Pn -T4 -p "$ports" --open "$target" -oX "$outdir/nmap-quick-$target.xml" | tee "$outdir/nmap-quick-$target.txt" 2>/dev/null
  nmap_parse_xml_for_ports "$outdir/nmap-quick-$target.xml"

  local live_count
  live_count=$(grep -c "open" "$outdir/nmap-quick-$target.txt" 2>/dev/null || echo "0")
  log_ok "Found $live_count open ports on $target"
}

mode_cleanup() {
  log_info "Quick port scan complete for $TARGET"
}

mode_execute
