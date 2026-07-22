MODE_NAME="nessus-scan"
MODE_DESCRIPTION="Nessus vulnerability scan — create, launch, wait, and import findings"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(curl)

NESSUS_HOST="${NESSUS_HOST:-127.0.0.1:8834}"
NESSUS_USERNAME="${NESSUS_USERNAME:-admin}"
NESSUS_PASSWORD="${NESSUS_PASSWORD:-}"
NESSUS_POLL_INTERVAL="${NESSUS_POLL_INTERVAL:-30}"
NESSUS_MAX_POLLS="${NESSUS_MAX_POLLS:-120}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
  if [[ -z "$NESSUS_PASSWORD" ]]; then
    log_warn "NESSUS_PASSWORD is empty — Nessus authentication will fail"
    return 1
  fi
}

mode_init() {
  mkdir -p "$LOOT_DIR/vulnerabilities/nessus"
}

_nessus_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local full_url="https://$NESSUS_HOST$endpoint"
  if [[ -n "$data" ]]; then
    curl -sk -u "$NESSUS_USERNAME:$NESSUS_PASSWORD" -X "$method" -H "Content-Type: application/json" -d "$data" "$full_url" 2>/dev/null
  else
    curl -sk -u "$NESSUS_USERNAME:$NESSUS_PASSWORD" -X "$method" "$full_url" 2>/dev/null
  fi
}

mode_run() {
  local outdir="$LOOT_DIR/vulnerabilities/nessus"
  local target="$TARGET"

  section_banner
  section_header "NESSUS SCAN: $target"

  local session
  session=$(curl -sk -X POST "https://$NESSUS_HOST/session" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$NESSUS_USERNAME\",\"password\":\"$NESSUS_PASSWORD\"}" 2>/dev/null)
  local token
  token=$(echo "$session" | python3 -c "import json,sys; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || true)
  if [[ -z "$token" ]]; then
    log_fail "Nessus authentication failed"
    return 1
  fi

  local scan_name="sniper-${target}-$(date +%Y%m%d%H%M)"
  local create_payload
  create_payload=$(python3 -c "
import json
payload = {
    'uuid': '$NESSUS_SCAN_TEMPLATE',
    'settings': {
        'name': '$scan_name',
        'description': 'Sn1per Nessus scan for $target',
        'text_targets': '$target',
        'launch': 'ON_DEMAND'
    }
}
print(json.dumps(payload))
" 2>/dev/null)

  local create_result
  create_result=$(curl -sk -X POST "https://$NESSUS_HOST/scans" \
    -H "Content-Type: application/json" \
    -H "X-Cookie: token=$token" \
    -d "$create_payload" 2>/dev/null)

  local scan_id
  scan_id=$(echo "$create_result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('scan',{}).get('id',''))" 2>/dev/null || true)
  if [[ -z "$scan_id" ]]; then
    log_fail "Failed to create Nessus scan"
    return 1
  fi
  log_ok "Created Nessus scan ID $scan_id: $scan_name"

  curl -sk -X POST "https://$NESSUS_HOST/scans/$scan_id/launch" \
    -H "X-Cookie: token=$token" 2>/dev/null > /dev/null
  log_info "Nessus scan launched, polling every ${NESSUS_POLL_INTERVAL}s..."

  local polls=0
  local status="running"
  while [[ "$status" == "running" && $polls -lt $NESSUS_MAX_POLLS ]]; do
    sleep "$NESSUS_POLL_INTERVAL"
    local scan_status
    scan_status=$(curl -sk "https://$NESSUS_HOST/scans/$scan_id" -H "X-Cookie: token=$token" 2>/dev/null)
    status=$(echo "$scan_status" | python3 -c "import json,sys; print(json.load(sys.stdin).get('info',{}).get('status',''))" 2>/dev/null || echo "running")
    polls=$((polls + 1))
    log_info "  Nessus scan status: $status (poll $polls/$NESSUS_MAX_POLLS)"
  done

  if [[ "$status" == "completed" ]]; then
    log_ok "Nessus scan completed"
    curl -sk "https://$NESSUS_HOST/scans/$scan_id/export?format=json" -H "X-Cookie: token=$token" > "$outdir/nessus-$target.json" 2>/dev/null
    log_ok "Nessus results saved to $outdir/nessus-$target.json"
  else
    log_warn "Nessus scan did not complete (status: $status)"
  fi
}

mode_cleanup() {
  log_info "Nessus scan complete for $TARGET"
}

mode_execute
