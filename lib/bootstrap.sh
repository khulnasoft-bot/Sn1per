# Sn1per bootstrap — version, paths, colors, config loading
VER="9.2"
SNIPER_HOME="${SNIPER_HOME:-/usr/share/sniper}"

# Colors (defined here so all libs and modes can use them without config)
OKBLUE='\033[94m'
OKRED='\033[91m'
OKGREEN='\033[92m'
OKORANGE='\033[93m'
RESET='\e[0m'
REGEX='^[0-9]+$'

sniper_require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
  fi
}

# Load configuration from the domain-split config files
# Falls back to loading the monolithic sniper.conf for backward compat
_sniper_dos2unix() {
  command -v dos2unix &>/dev/null && dos2unix "$1" 2>/dev/null || true
}

sniper_load_config() {
  local config_dir="${1:-$SNIPER_HOME/conf}"

  if [[ -d "$config_dir" ]] && ls "$config_dir"/*.conf &>/dev/null 2>&1; then
    for f in "$config_dir"/core.conf "$config_dir"/tools.conf \
             "$config_dir"/integrations.conf "$config_dir"/plugins.conf \
             "$config_dir"/detection.conf; do
      if [[ -f "$f" ]]; then
        _sniper_dos2unix "$f"
        source "$f"
      fi
    done
    echo -e "$OKBLUE[*]$RESET Loaded config from $config_dir/*.conf ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"
  else
    local legacy_config="${2:-$SNIPER_HOME/sniper.conf}"
    if [[ -f "$legacy_config" ]]; then
      _sniper_dos2unix "$legacy_config"
      source "$legacy_config"
      echo -e "$OKBLUE[*]$RESET Loaded config from $legacy_config ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"
    fi
  fi

  local user_config="/root/.sniper.conf"
  if [[ -f "$user_config" ]]; then
    _sniper_dos2unix "$user_config"
    source "$user_config"
    echo -e "$OKBLUE[*]$RESET Loaded user config from $user_config ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"
  fi

  local api_config="/root/.sniper_api_keys.conf"
  if [[ -f "$api_config" ]]; then
    _sniper_dos2unix "$api_config"
    source "$api_config"
    echo -e "$OKBLUE[*]$RESET Loaded API keys from $api_config ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]$RESET"
  fi

  sniper_apply_env_overrides
}

sniper_apply_env_overrides() {
  local varname snipref val
  for varname in NMAP_OPTIONS DEFAULT_PORTS QUICK_PORTS FULL_PORTSCAN_PORTS \
                 THREADS MAX_HOSTS BURP_PORT BURP_HOST \
                 MSF_LHOST MSF_LPORT SLACK_NOTIFICATIONS; do
    snipref="SNIPER_${varname}"
    val="${!snipref}"
    if [[ -n "$val" ]]; then
      printf -v "$varname" "%s" "$val"
      echo -e "$OKBLUE[*]$RESET Env override: $OKGREEN$varname$RESET = $val"
    fi
  done
}

# Validate that required config variables are set and warn about common issues.
# Call this after sniper_load_config and before entering a mode.
sniper_validate_config() {
  local mode="${1:-normal}"
  local errors=0

  local required_vars=(INSTALL_DIR LOOT_DIR)
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
      log_warn "Required config variable '$var' is not set"
      errors=1
    fi
  done

  if [[ -n "${INSTALL_DIR:-}" && ! -d "$INSTALL_DIR" ]]; then
    log_warn "INSTALL_DIR=$INSTALL_DIR does not exist"
    errors=1
  fi

  if [[ -z "${DEFAULT_PORTS:-}" && -z "${QUICK_PORTS:-}" ]]; then
    log_warn "Neither DEFAULT_PORTS nor QUICK_PORTS is defined — nmap scans may fail"
    errors=1
  fi

  if [[ "${NMAP_SCRIPTS:-0}" == "1" && -z "${NMAP_OPTIONS:-}" ]]; then
    log_warn "NMAP_SCRIPTS is enabled but NMAP_OPTIONS is empty"
  fi

  if [[ "${SC0PE_VULNERABLITY_SCANNER:-0}" == "1" ]]; then
    if [[ ! -d "${INSTALL_DIR:-}/templates/active" ]]; then
      log_warn "SC0PE active templates directory not found at \$INSTALL_DIR/templates/active"
    fi
  fi

  if [[ "${SLACK_NOTIFICATIONS:-0}" == "1" ]]; then
    if [[ ! -f "${INSTALL_DIR:-}/bin/slack.sh" ]]; then
      log_warn "SLACK_NOTIFICATIONS is enabled but bin/slack.sh not found"
    fi
  fi

  return $errors
}
