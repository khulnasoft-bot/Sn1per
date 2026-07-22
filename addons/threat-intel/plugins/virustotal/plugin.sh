PLUGIN_NAME="virustotal"

plugin_init() {
  [[ -n "${VIRUSTOTAL_API_KEY:-}" ]] || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/osint/threat-intel"
  mkdir -p "$outdir"
  curl -s "https://www.virustotal.com/api/v3/domains/$target" -H "x-apikey: $VIRUSTOTAL_API_KEY" > "$outdir/virustotal-$target.json" 2>/dev/null
  python3 -c "
import json,sys
try:
    with open('$outdir/virustotal-$target.json') as f:
        d=json.load(f)
    stats=d.get('data',{}).get('attributes',{}).get('last_analysis_stats',{})
    malicious=stats.get('malicious',0)
    if malicious>0:
        print(f'VT: {malicious} malicious detections')
        with open('$outdir/virustotal-$target-summary.txt','w') as sf:
            sf.write(f'{malicious} malicious detections\n')
except: pass
" 2>/dev/null || true
}

plugin_parse_output() {
  local summary_file="$1"
  [[ -f "$summary_file" ]] && cat "$summary_file" || true
}
