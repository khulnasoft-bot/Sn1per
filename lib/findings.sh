# Sn1per structured findings — JSON-based result aggregation and export

SNIPER_FINDINGS_FILE=""
SNIPER_FINDINGS=()

sniper_findings_init() {
  local outdir="${1:-$LOOT_DIR}"
  SNIPER_FINDINGS_FILE="$outdir/findings.json"
  SNIPER_FINDINGS=()
  if [[ -f "$SNIPER_FINDINGS_FILE" ]]; then
    sniper_findings_load
  fi
}

sniper_findings_load() {
  if [[ ! -f "$SNIPER_FINDINGS_FILE" ]]; then
    SNIPER_FINDINGS=()
    return
  fi
  local raw
  raw=$(python3 -c "
import json, sys
try:
    with open('$SNIPER_FINDINGS_FILE') as f:
        data = json.load(f)
    for item in data.get('findings', []):
        print(json.dumps(item))
except Exception:
    pass
" 2>/dev/null)
  SNIPER_FINDINGS=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    SNIPER_FINDINGS+=("$line")
  done <<< "$raw"
}

sniper_findings_add() {
  local target="$1"
  local finding_type="$2"
  local severity="${3:-INFO}"
  local tool="$4"
  local evidence="$5"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local entry
  entry=$(python3 -c "
import json
print(json.dumps({
    'target': '$target',
    'type': '$finding_type',
    'severity': '$severity',
    'tool': '$tool',
    'evidence': '''$evidence''',
    'timestamp': '$timestamp'
}))
" 2>/dev/null)
  [[ -z "$entry" ]] && return
  SNIPER_FINDINGS+=("$entry")
  sniper_findings_save
}

sniper_findings_save() {
  local outdir
  outdir=$(dirname "$SNIPER_FINDINGS_FILE")
  mkdir -p "$outdir"
  local json
  json=$(python3 -c "
import json
findings = []
for line in '''$(printf "%s\n" "${SNIPER_FINDINGS[@]}")'''.strip().split('\n'):
    if line:
        findings.append(json.loads(line))
print(json.dumps({'findings': findings}, indent=2))
" 2>/dev/null)
  echo "$json" > "$SNIPER_FINDINGS_FILE"
}

sniper_findings_export_csv() {
  local outfile="${1:-$LOOT_DIR/reports/findings.csv}"
  mkdir -p "$(dirname "$outfile")"
  python3 -c "
import json, csv, sys
try:
    with open('$SNIPER_FINDINGS_FILE') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)
if not data.get('findings'):
    sys.exit(0)
with open('$outfile', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['target','type','severity','tool','evidence','timestamp'])
    for item in data['findings']:
        w.writerow([item.get('target',''), item.get('type',''), item.get('severity',''),
                    item.get('tool',''), item.get('evidence',''), item.get('timestamp','')])
" 2>/dev/null || true
  log_ok "Exported findings CSV to $outfile"
}

sniper_findings_export_html() {
  local outfile="${1:-$LOOT_DIR/reports/findings.html}"
  mkdir -p "$(dirname "$outfile")"
  python3 -c "
import json, sys
try:
    with open('$SNIPER_FINDINGS_FILE') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)
findings = data.get('findings', [])
html = '<html><head><title>Sn1per Findings</title>'
html += '<style>body{font-family:monospace;padding:20px}'
html += 'table{border-collapse:collapse;width:100%}'
html += 'th,td{border:1px solid #ccc;padding:8px;text-align:left}'
html += 'th{background:#333;color:#fff}'
html += '.CRITICAL{color:red;font-weight:bold}'
html += '.HIGH{color:orange;font-weight:bold}'
html += '.MEDIUM{color:gold}'
html += '.INFO{color:green}'
html += '</style></head><body>'
html += '<h1>Sn1per Findings</h1>'
html += '<table><tr><th>Target</th><th>Type</th><th>Severity</th><th>Tool</th><th>Evidence</th><th>Timestamp</th></tr>'
for item in findings:
    sev = item.get('severity', 'INFO')
    html += f'<tr class=\"{sev}\"><td>{item.get(\"target\",\"\")}</td>'
    html += f'<td>{item.get(\"type\",\"\")}</td>'
    html += f'<td>{sev}</td>'
    html += f'<td>{item.get(\"tool\",\"\")}</td>'
    html += f'<td>{item.get(\"evidence\",\"\")}</td>'
    html += f'<td>{item.get(\"timestamp\",\"\")}</td></tr>'
html += '</table></body></html>'
with open('$outfile', 'w') as f:
    f.write(html)
" 2>/dev/null || true
  log_ok "Exported findings HTML to $outfile"
}

sniper_findings_summary() {
  local total=${#SNIPER_FINDINGS[@]}
  if [[ $total -eq 0 ]]; then
    echo "No findings recorded."
    return
  fi
  local json_input
  json_input=$(printf "%s\n" "${SNIPER_FINDINGS[@]}")
  python3 -c "
import json, sys
lines = '''$json_input'''.strip().split('\n')
severities = {}
types = {}
for line in lines:
    if not line: continue
    item = json.loads(line)
    s = item.get('severity', 'INFO')
    t = item.get('type', 'unknown')
    severities[s] = severities.get(s, 0) + 1
    types[t] = types.get(t, 0) + 1
print('Findings summary:')
print(f'  Total: {len(lines)}')
for sev in sorted(severities):
    print(f'  {sev}: {severities[sev]}')
print('  By type:')
for t in sorted(types):
    print(f'    {t}: {types[t]}')
"
}
