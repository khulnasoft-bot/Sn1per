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
}
