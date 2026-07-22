PLUGIN_NAME="wfuzz"

plugin_init() {
  command -v wfuzz &>/dev/null
}

plugin_run() {
  local target="$1"
  local wordlist="${2:-$INSTALL_DIR/wordlists/web-brute-common.txt}"
  local outdir="$LOOT_DIR/web/fuzz"
  mkdir -p "$outdir"
  wfuzz -w "$wordlist" --hc 404 "http://$target/FUZZ" 2>/dev/null > "$outdir/wfuzz-$target.txt"
}

plugin_parse_output() {
  local result_file="$1"
  [[ -f "$result_file" ]] && head -50 "$result_file" || true
}
