MODE_NAME="fuzz-parameters"
MODE_DESCRIPTION="GET/POST parameter fuzzing for injection detection"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(ffuf)

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/web/fuzz/params"
}

mode_run() {
  local outdir="$LOOT_DIR/web/fuzz/params"
  local target="$TARGET"
  local port="${PORT:-80}"
  local url="http://$target:$port"
  local param_wordlist="$INSTALL_DIR/wordlists/taxonomy-params.txt"
  [[ -f "$param_wordlist" ]] || param_wordlist="/usr/share/wordlists/params.txt"

  section_banner
  section_header "PARAMETER FUZZING: $url"

  if [[ -f "$param_wordlist" ]]; then
    ffuf -u "$url/FUZZ" -w "$param_wordlist:FUZZ" -t 20 -mc "200,302" -o "$outdir/ffuf-params-$target.json" 2>/dev/null
  else
    log_warn "No parameter wordlist found at $param_wordlist"
  fi
}

mode_cleanup() {
  log_info "Parameter fuzzing complete for $TARGET"
}

mode_execute
