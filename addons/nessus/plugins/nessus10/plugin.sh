PLUGIN_NAME="nessus10"

plugin_init() {
  [[ -n "${NESSUS_HOST:-}" && -n "${NESSUS_ACCESS_KEY:-}" && -n "${NESSUS_SECRET_KEY:-}" ]]
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/vulnerabilities/nessus"
  mkdir -p "$outdir"
  curl -sk -X POST "https://$NESSUS_HOST/scans" \
    -H "Content-Type: application/json" \
    -H "X-ApiKeys: accessKey=$NESSUS_ACCESS_KEY; secretKey=$NESSUS_SECRET_KEY" \
    -d "{\"uuid\":\"ad629e16-03b6-8c1d-cef6-ef8c9dd3c658\",\"settings\":{\"name\":\"sniper-$target\",\"text_targets\":\"$target\"}}" \
    > "$outdir/nessus10-create-$target.json" 2>/dev/null
}

plugin_parse_output() {
  local json_file="$1"
  python3 -c "
import json,sys
try:
    with open('$json_file') as f:
        d=json.load(f)
    sid=d.get('scan',{}).get('id','')
    if sid: print(f'Scan ID: {sid}')
except: pass
" 2>/dev/null || true
}
