PLUGIN_NAME="mobsf"

plugin_init() {
  [[ -n "${MOBSF_URL:-}" && -n "${MOBSF_API_KEY:-}" ]]
}

plugin_run() {
  local apk_path="$1"
  local outdir="$LOOT_DIR/mobile/reverse-apk/mobsf"
  mkdir -p "$outdir"
  curl -s -X POST "$MOBSF_URL/api/v1/upload" \
    -H "Authorization: $MOBSF_API_KEY" \
    -F "file=@$apk_path" > "$outdir/upload.json" 2>/dev/null
  local hash
  hash=$(python3 -c "import json,sys; d=json.load(open('$outdir/upload.json')); print(d.get('hash',''))" 2>/dev/null || true)
  if [[ -n "$hash" ]]; then
    curl -s -X POST "$MOBSF_URL/api/v1/scan" \
      -H "Authorization: $MOBSF_API_KEY" \
      -d "hash=$hash&scan_type=apk" > "$outdir/scan.json" 2>/dev/null
    curl -s -X POST "$MOBSF_URL/api/v1/report_json" \
      -H "Authorization: $MOBSF_API_KEY" \
      -d "hash=$hash" > "$outdir/report.json" 2>/dev/null
  fi
}

plugin_parse_output() {
  local json_file="$1"
  python3 -c "
import json,sys
try:
    d=json.load(open('$json_file'))
    sec=d.get('security_score',0)
    vulns=d.get('vulnerabilities',[])
    print(f'Score: $sec')
    for v in vulns:
        print(f'  {v.get(\"title\",\"\")} ({v.get(\"severity\",\"\")})')
except: pass
" 2>/dev/null || true
}
