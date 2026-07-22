MODE_NAME=""
MODE_DESCRIPTION=""
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=()

mode_validate()   { return 0; }
mode_init()       { return 0; }
mode_run()        { return 0; }
mode_cleanup()    { return 0; }

mode_require_tools() {
  local missing=0
  for tool in "$@"; do
    if ! command -v "$tool" &>/dev/null; then
      log_warn "Required tool '$tool' not found in PATH"
      missing=1
    fi
  done
  return $missing
}

mode_require_vars() {
  local missing=0
  for var in "$@"; do
    if [[ -z "${!var}" ]]; then
      log_fail "Required variable $var is not set"
      missing=1
    fi
  done
  return $missing
}

mode_execute() {
  mode_require_vars "${MODE_REQUIRED_VARS[@]}" || return 1
  mode_require_tools "${MODE_REQUIRED_TOOLS[@]}" || return 1

  mode_validate || { log_fail "Mode '$MODE_NAME' validation failed"; return 1; }
  mode_init    || { log_fail "Mode '$MODE_NAME' init failed"; return 1; }
  mode_run     || { log_fail "Mode '$MODE_NAME' run failed"; return 1; }
  mode_cleanup
}
