PLUGIN_NAME="apktool"

plugin_init() {
  command -v apktool &>/dev/null
}

plugin_run() {
  local apk_path="$1"
  local outdir="${2:-$LOOT_DIR/mobile/reverse-apk}"
  mkdir -p "$outdir"
  local base="$outdir/$(basename "$apk_path" .apk)"
  apktool d -f -o "$base/smali" "$apk_path" 2>/dev/null
}

plugin_parse_output() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -name "*.smali" | wc -l
  fi
}
