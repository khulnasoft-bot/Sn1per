PLUGIN_NAME="masscan"

plugin_init() {
  command -v masscan &>/dev/null
}

plugin_run() {
  local target="$1"
  local ports="${2:-1-65535}"
  local rate="${PORTSCAN_RATE:-1000}"
  local iface="${PORTSCAN_INTERFACE:-eth0}"
  local outdir="$LOOT_DIR/nmap/masscan"
  mkdir -p "$outdir"
  masscan -p"$ports" --rate="$rate" -e "$iface" "$target" -oJ "$outdir/masscan-$target.json" 2>/dev/null
}

plugin_parse_output() {
  local json_file="$1"
  python3 -c "
import json,sys
try:
    with open('$json_file') as f:
        data=json.load(f)
    for host in data:
        for port_info in host.get('ports',[]):
            print(f\"{host.get('ip','')}:{port_info.get('port','')}/{port_info.get('proto','')}\")
except: pass
" 2>/dev/null || true
}
