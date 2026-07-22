# whatweb plugin
PLUGIN_NAME="whatweb"

plugin_init() {
  mode_require_tools whatweb || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/web"
  mkdir -p "$outdir"
  local outfile="$outdir/whatweb-$target.txt"
  whatweb "$target" -v > "$outfile" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  if [[ -f "$result_file" && -s "$result_file" ]]; then
    head -20 "$result_file"
  fi
}
