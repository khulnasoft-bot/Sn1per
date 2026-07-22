test_findings_init_creates_filepath() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  [[ -n "$SNIPER_FINDINGS_FILE" ]]
  [[ "$SNIPER_FINDINGS_FILE" == "$tmpdir/findings.json" ]]
  rm -rf "$tmpdir"
}

test_findings_add_and_save() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  sniper_findings_add "example.com" "vulnerability" "HIGH" "nuclei" "XSS found in /search"
  [[ -f "$SNIPER_FINDINGS_FILE" ]]
  local count
  count=$(python3 -c "import json; d=json.load(open('$SNIPER_FINDINGS_FILE')); print(len(d['findings']))")
  [[ "$count" -eq 1 ]]
  rm -rf "$tmpdir"
}

test_findings_multiple_entries() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  sniper_findings_add "a.com" "port" "INFO" "nmap" "port 80 open"
  sniper_findings_add "a.com" "vulnerability" "CRITICAL" "nuclei" "RCE"
  sniper_findings_add "b.com" "vulnerability" "MEDIUM" "nikto" "info leak"
  local count
  count=$(python3 -c "import json; d=json.load(open('$SNIPER_FINDINGS_FILE')); print(len(d['findings']))")
  [[ "$count" -eq 3 ]]
  rm -rf "$tmpdir"
}

test_findings_load_existing() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  echo '{"findings":[{"target":"x.com","type":"port","severity":"INFO","tool":"nmap","evidence":"ok","timestamp":"2026-01-01T00:00:00Z"}]}' > "$tmpdir/findings.json"
  sniper_findings_init "$LOOT_DIR"
  [[ ${#SNIPER_FINDINGS[@]} -eq 1 ]]
  rm -rf "$tmpdir"
}

test_findings_export_csv() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  sniper_findings_add "a.com" "vulnerability" "HIGH" "nuclei" "XSS"
  sniper_findings_export_csv "$tmpdir/reports/findings.csv"
  [[ -f "$tmpdir/reports/findings.csv" ]]
  local lines
  lines=$(wc -l < "$tmpdir/reports/findings.csv")
  [[ "$lines" -ge 2 ]]
  rm -rf "$tmpdir"
}

test_findings_export_html() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  sniper_findings_add "a.com" "vulnerability" "CRITICAL" "nuclei" "RCE"
  sniper_findings_export_html "$tmpdir/reports/findings.html"
  [[ -f "$tmpdir/reports/findings.html" ]]
  grep -q "CRITICAL" "$tmpdir/reports/findings.html"
  rm -rf "$tmpdir"
}

test_findings_summary() {
  local tmpdir
  tmpdir=$(mktemp -d)
  LOOT_DIR="$tmpdir"
  sniper_findings_init "$LOOT_DIR"
  sniper_findings_add "a.com" "vulnerability" "CRITICAL" "nuclei" "XSS"
  sniper_findings_add "a.com" "vulnerability" "HIGH" "nmap" "port 22"
  local summary
  summary=$(sniper_findings_summary)
  echo "$summary" | grep -q "CRITICAL"
  rm -rf "$tmpdir"
}
