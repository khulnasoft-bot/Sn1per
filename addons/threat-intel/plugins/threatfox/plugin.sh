PLUGIN_NAME="threatfox"

plugin_init() {
  [[ -n "${THREATFOX_API_KEY:-}" ]] || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/osint/threat-intel"
  mkdir -p "$outdir"
  curl -s -X POST "https://threatfox-api.abuse.ch/api/v1/" \
    -d "{\"query\":\"search_ioc\",\"search_term\":\"$target\"}" \
    > "$outdir/threatfox-$target.json" 2>/dev/null
}

plugin_parse_output() {
  local json_file="$1"
  python3 -c "
import json,sys
try:
    with open('$json_file') as f:
        d=json.load(f)
    if d.get('query_status')=='ok':
        for ioc in d.get('data',[]):
            print(f\"{ioc.get('ioc','')} ({ioc.get('threat_type','')})\")
except: pass
" 2>/dev/null || true
}
