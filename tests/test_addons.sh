test_addon_discover_finds_command_exec() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  sniper_addon_discover "$SNIPER_ADDONS_DIR"
  local found=0
  for a in "${SNIPER_ADDONS_LOADED[@]}"; do
    [[ "$a" == "command-exec" ]] && found=1
  done
  [[ $found -eq 1 ]]
}

test_addon_discover_finds_all() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  sniper_addon_discover "$SNIPER_ADDONS_DIR"
  local expected=("command-exec" "threat-intel" "bruteforce" "port-scanner" "fuzzer" "nessus" "masspwn" "reverse-apk" "json-api")
  for exp in "${expected[@]}"; do
    local found=0
    for a in "${SNIPER_ADDONS_LOADED[@]}"; do
      [[ "$a" == "$exp" ]] && found=1
    done
    [[ $found -eq 1 ]] || return 1
  done
}

test_addon_discover_nonexistent_dir() {
  SNIPER_ADDONS_DIR="/tmp/nonexistent-addons-dir"
  sniper_addon_discover "$SNIPER_ADDONS_DIR" && return 1 || return 0
}

test_addon_enabled_by_default() {
  ADDON_TEST_ENABLED="1"
  sniper_addon_enabled "test"
  unset ADDON_TEST_ENABLED
}

test_addon_disabled_explicitly() {
  ADDON_TEST_ENABLED="0"
  sniper_addon_enabled "test" && return 1 || return 0
  unset ADDON_TEST_ENABLED
}

test_addon_load_command_exec() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  SNIPER_ADDON_REGISTERED_MODES=()
  SNIPER_ADDON_REGISTERED_PLUGINS=()
  ADDON_COMMAND_EXEC_ENABLED="1"
  sniper_addon_load "command-exec" 2>/dev/null || true
  [[ ${#SNIPER_ADDON_REGISTERED_MODES[@]} -ge 1 ]] || return 1
  [[ ${#SNIPER_ADDON_REGISTERED_PLUGINS[@]} -ge 1 ]] || return 1
  unset ADDON_COMMAND_EXEC_ENABLED
}

test_addon_load_all() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  SNIPER_ADDONS_LOADED=("command-exec" "threat-intel" "bruteforce")
  SNIPER_ADDON_REGISTERED_MODES=()
  SNIPER_ADDON_REGISTERED_PLUGINS=()
  for a in "${SNIPER_ADDONS_LOADED[@]}"; do
    ADDON_ENABLED="1"
    local toggle="ADDON_${a^^}_ENABLED"
    toggle="${toggle//-/_}"
    printf -v "$toggle" "1"
    sniper_addon_load "$a" 2>/dev/null || true
  done
  local mode_count=${#SNIPER_ADDON_REGISTERED_MODES[@]}
  [[ $mode_count -ge 3 ]] || return 1
}

test_addon_install_no_install_sh() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  mkdir -p /tmp/test-addon-noinstall
  echo '{"name":"test-noinstall"}' > /tmp/test-addon-noinstall/addon.json
  local old_dir="$SNIPER_ADDONS_DIR"
  SNIPER_ADDONS_DIR="/tmp"
  sniper_addon_install "test-addon-noinstall" 2>/dev/null
  SNIPER_ADDONS_DIR="$old_dir"
  rm -rf /tmp/test-addon-noinstall
}

test_addon_list_output() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  local output
  output=$(sniper_addon_list "$SNIPER_ADDONS_DIR" 2>/dev/null)
  echo "$output" | grep -q "NAME"
  echo "$output" | grep -q "command-exec"
  echo "$output" | grep -q "reverse-apk"
}

test_addon_metadata() {
  INSTALL_DIR="$SN1PER_ROOT"
  SNIPER_ADDONS_DIR="$INSTALL_DIR/addons"
  local meta
  meta=$(sniper_addon_metadata "command-exec")
  echo "$meta" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['name'] == 'command-exec'" 2>/dev/null
}

test_addon_discover_empty_dir() {
  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/empty"
  SNIPER_ADDONS_LOADED=()
  sniper_addon_discover "$tmpdir/empty" 2>/dev/null
  local count=${#SNIPER_ADDONS_LOADED[@]}
  [[ $count -eq 0 ]]
  rm -rf "$tmpdir"
}
