MODE_NAME="fuzz-vhost"
MODE_DESCRIPTION="Virtual host brute-forcing via Host header"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(ffuf)

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/web/fuzz/vhost"
}

mode_run() {
  local outdir="$LOOT_DIR/web/fuzz/vhost"
  local target="$TARGET"
  local port="${PORT:-80}"
  local wordlist="${FUZZ_VHOST_WORDLIST:-$INSTALL_DIR/wordlists/vhosts.txt}"
  [[ -f "$wordlist" ]] || wordlist="/usr/share/wordlists/vhosts.txt"

  section_banner
  section_header "VHOST FUZZING: $target"

  if [[ -f "$wordlist" ]]; then
    ffuf -w "$wordlist" -u "http://$target:$port" -H "Host: FUZZ.$target" -t 20 -mc "200,301,302,401,403" -o "$outdir/ffuf-vhost-$target.json" 2>/dev/null
  else
    log_warn "No vhost wordlist found at $wordlist — skipping"
  fi
}

mode_cleanup() {
  log_info "VHost fuzzing complete for $TARGET"
}

mode_execute
