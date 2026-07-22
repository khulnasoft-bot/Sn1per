# nuclei-scanner plugin
PLUGIN_NAME="nuclei-scanner"

plugin_init() {
  mode_require_tools nuclei || return 1
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/vulnerabilities"
  mkdir -p "$outdir"
  local outfile="$outdir/nuclei-$target.txt"
  nuclei -u "$target" -o "$outfile" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  if [[ -f "$result_file" && -s "$result_file" ]]; then
    awk '{print "NUCLEI:" $0}' "$result_file"
  fi
}
