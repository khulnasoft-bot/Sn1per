_test_assert_dir_exists() {
  [[ -d "$1" ]] && return 0
  echo "FAIL: directory not found: $1" >&2
  return 1
}

_test_assert_file_exists() {
  [[ -f "$1" ]] && return 0
  echo "FAIL: file not found: $1" >&2
  return 1
}

test_workspace_init_creates_directories() {
  local test_dir="/tmp/sniper-test-ws-$$"
  mkdir -p "$test_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"

  sniper_init_workspace "$LOOT_DIR" "test-target.com" ""

  _test_assert_dir_exists "$LOOT_DIR/domains" || return 1
  _test_assert_dir_exists "$LOOT_DIR/ips" || return 1
  _test_assert_dir_exists "$LOOT_DIR/screenshots" || return 1
  _test_assert_dir_exists "$LOOT_DIR/nmap" || return 1
  _test_assert_dir_exists "$LOOT_DIR/reports" || return 1
  _test_assert_dir_exists "$LOOT_DIR/output" || return 1
  _test_assert_dir_exists "$LOOT_DIR/osint" || return 1
  _test_assert_dir_exists "$LOOT_DIR/credentials" || return 1
  _test_assert_dir_exists "$LOOT_DIR/web" || return 1
  _test_assert_dir_exists "$LOOT_DIR/vulnerabilities" || return 1
  _test_assert_dir_exists "$LOOT_DIR/notes" || return 1
  _test_assert_dir_exists "$LOOT_DIR/scans/scheduled" || return 1

  _test_assert_file_exists "$LOOT_DIR/scans/scheduled/daily.sh" || return 1
  _test_assert_file_exists "$LOOT_DIR/scans/scheduled/weekly.sh" || return 1
  _test_assert_file_exists "$LOOT_DIR/scans/scheduled/monthly.sh" || return 1

  rm -rf "$test_dir"
}

test_workspace_init_writes_targets() {
  local test_dir="/tmp/sniper-test-ws-$$"
  mkdir -p "$test_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"
  OUT_OF_SCOPE=(" *.sn1persecurity.com")

  sniper_init_workspace "$LOOT_DIR" "example.com" ""

  _test_assert_file_exists "$LOOT_DIR/domains/targets.txt" || return 1
  grep -q "example.com" "$LOOT_DIR/domains/targets.txt" || return 1

  rm -rf "$test_dir"
}

test_workspace_init_with_workspace_dir() {
  local test_dir="/tmp/sniper-test-ws-$$"
  local ws_dir="/tmp/sniper-test-ws-sub-$$"
  mkdir -p "$test_dir" "$ws_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"
  OUT_OF_SCOPE=("")

  sniper_init_workspace "$LOOT_DIR" "example.com" "$ws_dir"

  _test_assert_dir_exists "$ws_dir/domains" || return 1

  rm -rf "$test_dir" "$ws_dir"
}

test_workspace_init_target_sanitization() {
  local test_dir="/tmp/sniper-test-ws-$$"
  mkdir -p "$test_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"
  OUT_OF_SCOPE=("")

  sniper_init_workspace "$LOOT_DIR" "https://example.com" ""
  grep -q "example.com" "$LOOT_DIR/domains/targets.txt" || return 1

  rm -rf "$test_dir"
}

test_workspace_init_out_of_scope_skips_target() {
  local test_dir="/tmp/sniper-test-ws-$$"
  mkdir -p "$test_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"
  OUT_OF_SCOPE=("sn1persecurity.com")

  ( sniper_init_workspace "$LOOT_DIR" "www.sn1persecurity.com" "" ) 2>/dev/null || true

  if grep -q "www.sn1persecurity.com" "$LOOT_DIR/domains/targets.txt" 2>/dev/null; then
    rm -rf "$test_dir"
    return 1
  fi

  rm -rf "$test_dir"
  return 0
}

test_workspace_init_provides_chmod() {
  local test_dir="/tmp/sniper-test-ws-$$"
  mkdir -p "$test_dir"
  LOOT_DIR="$test_dir"
  INSTALL_DIR="$SN1PER_ROOT"
  OUT_OF_SCOPE=("")

  sniper_init_workspace "$LOOT_DIR" "example.com" ""
  local perms
  perms=$(stat -c "%a" "$LOOT_DIR" 2>/dev/null || stat -f "%A" "$LOOT_DIR" 2>/dev/null)
  if [[ "$perms" != "777" ]]; then
    rm -rf "$test_dir"
    return 1
  fi

  rm -rf "$test_dir"
  return 0
}
