PLUGIN_NAME="otx"

plugin_init() {
  [[ -n "${OTX_API_KEY:-}" ]] || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/osint/threat-intel"
  mkdir -p "$outdir"
  curl -s -H "X-OTX-API-KEY: $OTX_API_KEY" "https://otx.alienvault.com/api/v1/indicators/domain/$target" > "$outdir/otx-$target.json" 2>/dev/null
}

plugin_parse_output() {
  local json_file="$1"
  sniper_json_gron_grep "$json_file" "pulse" || true
}
