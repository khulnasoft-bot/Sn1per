# Sn1per plugin loader — discover, validate, and run plugins
# Each plugin lives in plugins/<name>/ and defines plugin.sh + plugin.json

SNIPER_PLUGINS_LOADED=()

sniper_plugin_discover() {
  local plugin_dir="${1:-$INSTALL_DIR/plugins}"
  SNIPER_PLUGINS_LOADED=()
  if [[ ! -d "$plugin_dir" ]]; then
    log_warn "Plugin directory $plugin_dir not found"
    return 1
  fi
  for d in "$plugin_dir"/*/; do
    [[ -d "$d" ]] || continue
    local plugin_name
    plugin_name="$(basename "$d")"
    if [[ -f "$d/plugin.sh" ]]; then
      SNIPER_PLUGINS_LOADED+=("$plugin_name")
    fi
  done
  log_info "Discovered ${#SNIPER_PLUGINS_LOADED[@]} plugin(s): ${SNIPER_PLUGINS_LOADED[*]}"
}

sniper_plugin_load() {
  local plugin_name="$1"
  local plugin_dir="$INSTALL_DIR/plugins/$plugin_name"
  if [[ ! -f "$plugin_dir/plugin.sh" ]]; then
    log_fail "Plugin '$plugin_name' not found at $plugin_dir/plugin.sh"
    return 1
  fi
  source "$plugin_dir/plugin.sh"
  if declare -F plugin_init &>/dev/null; then
    plugin_init
  fi
  log_ok "Loaded plugin: $plugin_name"
}

sniper_plugin_run() {
  local plugin_name="$1"
  shift
  if ! declare -F plugin_run &>/dev/null; then
    log_fail "Plugin '$plugin_name' has no plugin_run() function"
    return 1
  fi
  plugin_run "$@"
}

sniper_plugin_parse_output() {
  local plugin_name="$1"
  shift
  if declare -F plugin_parse_output &>/dev/null; then
    plugin_parse_output "$@"
  fi
}

sniper_plugin_run_all() {
  local target="$1"
  for pname in "${SNIPER_PLUGINS_LOADED[@]}"; do
    sniper_plugin_load "$pname" || continue
    sniper_plugin_run "$pname" "$target"
  done
}

sniper_plugin_metadata() {
  local plugin_name="$1"
  local meta_file="$INSTALL_DIR/plugins/$plugin_name/plugin.json"
  if [[ -f "$meta_file" ]]; then
    cat "$meta_file"
  fi
}
