PLUGIN_NAME="nmap-vuln"

plugin_init() {
  command -v nmap &>/dev/null
}

plugin_run() {
  local target="$1"
  local port="${2:-}"
  local outdir="$LOOT_DIR/vulnerabilities/nmap-vuln"
  mkdir -p "$outdir"
  if [[ -n "$port" ]]; then
    nmap -sV --script-timeout 90 --script="vulners,/usr/share/nmap/scripts/vuln" -p "$port" "$target" -oX "$outdir/nmap-vuln-$target-port$port.xml" | tee "$outdir/nmap-vuln-$target-port$port.txt" 2>/dev/null
  else
    nmap -sV --script-timeout 90 --script="vulners,/usr/share/nmap/scripts/vuln" "$target" -oX "$outdir/nmap-vuln-$target.xml" | tee "$outdir/nmap-vuln-$target.txt" 2>/dev/null
  fi
}

plugin_parse_output() {
  local result_file="$1"
  grep -E "VULNERABLE|CVE-" "$result_file" 2>/dev/null || true
}
