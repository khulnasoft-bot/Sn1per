PLUGIN_NAME="jadx"

plugin_init() {
  command -v jadx &>/dev/null
}

plugin_run() {
  local apk_path="$1"
  local outdir="${2:-$LOOT_DIR/mobile/reverse-apk}"
  mkdir -p "$outdir"
  local base="$outdir/$(basename "$apk_path" .apk)"
  jadx -d "$base/java" "$apk_path" 2>/dev/null
}

plugin_parse_output() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -name "*.java" | wc -l
  fi
}
