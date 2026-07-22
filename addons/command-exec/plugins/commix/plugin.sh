PLUGIN_NAME="commix"

plugin_init() {
  command -v commix &>/dev/null || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/vulnerabilities/command-exec"
  mkdir -p "$outdir"
  commix --url="http://$target/" --batch --output-dir="$outdir/commix-$target" 2>/dev/null
}

plugin_parse_output() {
  local result_dir="$1"
  if [[ -d "$result_dir" ]]; then
    find "$result_dir" -name "*.txt" -exec cat {} \; 2>/dev/null | grep -i "vulnerable\|injection\|uid=" || true
  fi
}
