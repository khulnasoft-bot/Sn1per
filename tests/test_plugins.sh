test_plugin_discover_finds_nmap_scanner() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_plugin_discover "$INSTALL_DIR/plugins"
  local found=0
  for p in "${SNIPER_PLUGINS_LOADED[@]}"; do
    [[ "$p" == "nmap-scanner" ]] && found=1
  done
  [[ $found -eq 1 ]]
}

test_plugin_discover_finds_nuclei_scanner() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_plugin_discover "$INSTALL_DIR/plugins"
  local found=0
  for p in "${SNIPER_PLUGINS_LOADED[@]}"; do
    [[ "$p" == "nuclei-scanner" ]] && found=1
  done
  [[ $found -eq 1 ]]
}

test_plugin_discover_finds_whatweb() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_plugin_discover "$INSTALL_DIR/plugins"
  local found=0
  for p in "${SNIPER_PLUGINS_LOADED[@]}"; do
    [[ "$p" == "whatweb" ]] && found=1
  done
  [[ $found -eq 1 ]]
}

test_plugin_load_nmap_scanner() {
  INSTALL_DIR="$SN1PER_ROOT"
  local orig_path="$PATH"
  PATH="/tmp"
  PLUGIN_NAME=""
  sniper_plugin_load "nmap-scanner" 2>/dev/null || true
  PATH="$orig_path"
  [[ "$PLUGIN_NAME" == "nmap-scanner" ]]
}

test_plugin_load_nonexistent_fails() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_plugin_load "nonexistent-plugin" && return 1 || return 0
}

test_plugin_discover_empty_dir() {
  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/empty"
  SNIPER_PLUGINS_LOADED=()
  sniper_plugin_discover "$tmpdir/empty" 2>/dev/null
  local count=${#SNIPER_PLUGINS_LOADED[@]}
  [[ "$count" -eq 0 ]]
  rm -rf "$tmpdir"
}

test_plugin_metadata_returns_json() {
  INSTALL_DIR="$SN1PER_ROOT"
  local meta
  meta=$(sniper_plugin_metadata "nmap-scanner")
  echo "$meta" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['name'] == 'nmap-scanner'" 2>/dev/null
}
