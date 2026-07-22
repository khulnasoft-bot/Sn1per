# Sn1per add-on framework — discover, load, and manage add-ons
# Each add-on lives in addons/<name>/ with addon.json + init.sh

SNIPER_ADDONS_DIR="${SNIPER_ADDONS_DIR:-$INSTALL_DIR/addons}"
SNIPER_ADDONS_LOADED=()
SNIPER_ADDON_MODES=()
SNIPER_ADDON_PLUGINS=()
SNIPER_ADDON_REGISTERED_MODES=()
SNIPER_ADDON_REGISTERED_PLUGINS=()

sniper_addon_discover() {
  local addons_dir="${1:-$SNIPER_ADDONS_DIR}"
  SNIPER_ADDONS_LOADED=()
  if [[ ! -d "$addons_dir" ]]; then
    log_warn "Add-ons directory $addons_dir not found"
    return 1
  fi
  for d in "$addons_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name
    name="$(basename "$d")"
    if [[ -f "$d/addon.json" ]]; then
      SNIPER_ADDONS_LOADED+=("$name")
    fi
  done
  log_info "Discovered ${#SNIPER_ADDONS_LOADED[@]} add-on(s): ${SNIPER_ADDONS_LOADED[*]}"
}

sniper_addon_enabled() {
  local name="$1"
  local toggle_var="ADDON_${name^^}_ENABLED"
  toggle_var="${toggle_var//-/_}"
  if [[ "${!toggle_var:-1}" == "0" ]]; then
    return 1
  fi
  return 0
}

sniper_addon_load() {
  local name="$1"
  local addon_dir="$SNIPER_ADDONS_DIR/$name"

  if [[ ! -f "$addon_dir/addon.json" ]]; then
    log_fail "Add-on '$name' not found at $addon_dir/addon.json"
    return 1
  fi

  if ! sniper_addon_enabled "$name"; then
    log_info "Add-on '$name' is disabled, skipping"
    return 0
  fi

  if [[ -f "$addon_dir/config.conf" ]]; then
    _sniper_dos2unix "$addon_dir/config.conf"
    source "$addon_dir/config.conf"
  fi

  if [[ -f "$addon_dir/init.sh" ]]; then
    _sniper_dos2unix "$addon_dir/init.sh"
    source "$addon_dir/init.sh"
  fi

  log_ok "Loaded add-on: $name"
}

sniper_addon_load_all() {
  for name in "${SNIPER_ADDONS_LOADED[@]}"; do
    sniper_addon_load "$name"
  done
}

sniper_addon_register_mode() {
  local addon_name="$1"
  local mode_path="$2"
  if [[ -f "$mode_path" ]]; then
    SNIPER_ADDON_REGISTERED_MODES+=("$mode_path")
    log_info "  Add-on '$addon_name' registered mode: $(basename "$mode_path")"
  else
    log_warn "  Add-on '$addon_name' mode not found: $mode_path"
  fi
}

sniper_addon_register_plugin() {
  local addon_name="$1"
  local plugin_dir="$2"
  if [[ -d "$plugin_dir" && -f "$plugin_dir/plugin.sh" ]]; then
    SNIPER_ADDON_REGISTERED_PLUGINS+=("$plugin_dir")
    log_info "  Add-on '$addon_name' registered plugin: $(basename "$plugin_dir")"
  else
    log_warn "  Add-on '$addon_name' plugin not found: $plugin_dir"
  fi
}

sniper_addon_source_modes() {
  for mode_path in "${SNIPER_ADDON_REGISTERED_MODES[@]}"; do
    if [[ -f "$mode_path" ]]; then
      source "$mode_path"
    fi
  done
}

sniper_addon_source_plugins() {
  for plugin_dir in "${SNIPER_ADDON_REGISTERED_PLUGINS[@]}"; do
    if [[ -f "$plugin_dir/plugin.sh" ]]; then
      local pname
      pname="$(basename "$plugin_dir")"
      sniper_plugin_load "$pname" 2>/dev/null || true
    fi
  done
}

sniper_addon_install() {
  local name="$1"
  local addon_dir="$SNIPER_ADDONS_DIR/$name"
  if [[ -f "$addon_dir/install.sh" ]]; then
    log_info "Installing add-on '$name' dependencies..."
    bash "$addon_dir/install.sh"
  else
    log_info "Add-on '$name' has no install.sh (no dependencies)"
  fi
}

sniper_addon_list() {
  local addons_dir="${1:-$SNIPER_ADDONS_DIR}"
  if [[ ! -d "$addons_dir" ]]; then
    echo "No add-ons directory found at $addons_dir"
    return
  fi
  printf "%-30s %-10s %s\n" "NAME" "VERSION" "DESCRIPTION"
  printf "%-30s %-10s %s\n" "----" "-------" "-----------"
  for d in "$addons_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d")"
    local meta="$d/addon.json"
    if [[ -f "$meta" ]]; then
      local ver desc
      ver=$(grep -oP '"version":\s*"\K[^"]+' "$meta" 2>/dev/null || echo "?")
      desc=$(grep -oP '"description":\s*"\K[^"]+' "$meta" 2>/dev/null || echo "?")
      local status="✓"
      sniper_addon_enabled "$name" || status="✗"
      printf "%-30s %-10s %s [%s]\n" "$name" "$ver" "$desc" "$status"
    fi
  done
}

sniper_addon_metadata() {
  local name="$1"
  local meta_file="$SNIPER_ADDONS_DIR/$name/addon.json"
  if [[ -f "$meta_file" ]]; then
    cat "$meta_file"
  else
    echo "{}"
  fi
}
