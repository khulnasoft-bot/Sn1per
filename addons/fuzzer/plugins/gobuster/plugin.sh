PLUGIN_NAME="gobuster"

plugin_init() {
  command -v gobuster &>/dev/null
}

plugin_run() {
  local target="$1"
  local wordlist="${2:-$INSTALL_DIR/wordlists/web-brute-common.txt}"
  local outdir="$LOOT_DIR/web/fuzz"
  mkdir -p "$outdir"
  gobuster dir -u "http://$target/" -w "$wordlist" -t 20 -o "$outdir/gobuster-$target.txt" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  [[ -f "$result_file" ]] && grep -E "^/" "$result_file" || true
}
