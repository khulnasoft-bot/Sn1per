PLUGIN_NAME="nessus6"

plugin_init() {
  [[ -n "${NESSUS_HOST:-}" && -n "${NESSUS_USERNAME:-}" && -n "${NESSUS_PASSWORD:-}" ]]
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/vulnerabilities/nessus"
  mkdir -p "$outdir"
  local token
  token=$(curl -sk -X POST "https://$NESSUS_HOST/session" -H "Content-Type: application/json" \
    -d "{\"username\":\"$NESSUS_USERNAME\",\"password\":\"$NESSUS_PASSWORD\"}" 2>/dev/null | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || true)
  echo "$token" > "$outdir/nessus-token.txt" 2>/dev/null
}

plugin_parse_output() {
  local token_file="$1"
  [[ -s "$token_file" ]] && echo "Nessus authenticated" || echo "Nessus auth failed"
}
