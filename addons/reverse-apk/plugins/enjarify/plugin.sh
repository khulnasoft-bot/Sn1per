PLUGIN_NAME="enjarify"

plugin_init() {
  command -v enjarify &>/dev/null || python3 -c "import enjarify" 2>/dev/null
}

plugin_run() {
  local apk_path="$1"
  local outdir="$LOOT_DIR/mobile/reverse-apk/enjarify"
  mkdir -p "$outdir"
  python3 -m enjarify "$apk_path" -o "$outdir" 2>/dev/null || enjarify "$apk_path" -o "$outdir" 2>/dev/null
}

plugin_parse_output() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -name "*.class" | wc -l
  fi
}
