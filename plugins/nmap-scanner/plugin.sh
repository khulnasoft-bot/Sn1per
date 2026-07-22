# nmap-scanner plugin
PLUGIN_NAME="nmap-scanner"

plugin_init() {
  mode_require_tools nmap || return 1
}

plugin_run() {
  local target="$1"
  local port="${2:-}"
  local outdir="$LOOT_DIR/nmap"
  mkdir -p "$outdir"
  local xml_file="$outdir/nmap-$target.xml"
  local txt_file="$outdir/nmap-$target.txt"

  if [[ -n "$port" ]]; then
    nmap -p "$port" $NMAP_OPTIONS --open "$target" -oX "$xml_file" | sed -r "s/</\&lh\;/g" | tee "$txt_file"
  else
    nmap -p "${DEFAULT_PORTS:-T:1-10000}" $NMAP_OPTIONS --open "$target" -oX "$xml_file" | sed -r "s/</\&lh\;/g" | tee "$txt_file"
  fi

  nmap_parse_xml_for_ports "$xml_file"
  if nmap_host_is_up "$txt_file"; then
    echo "$target" >> "$LOOT_DIR/nmap/livehosts-unsorted.txt" 2>/dev/null
  fi
}

plugin_parse_output() {
  local xml_file="$1"
  nmap_get_open_ports "$xml_file"
}
