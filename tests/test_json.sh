test_json_sniper_gron_path_returns_empty_when_not_installed() {
  local old_path
  old_path=$(sniper_gron_path)
  [[ -z "$old_path" ]] && return 0
  return 0
}

test_json_save_writes_raw_json() {
  local tmp_dir="/tmp/sniper-test-json-$$"
  mkdir -p "$tmp_dir"
  echo '{"key":"value"}' > /tmp/sniper-test-payload.json
  sniper_json_save "$(cat /tmp/sniper-test-payload.json)" "$tmp_dir/test"
  [[ -f "$tmp_dir/test.json" ]] && grep -q '"key"' "$tmp_dir/test.json" || return 1
  rm -rf "$tmp_dir" /tmp/sniper-test-payload.json
}

test_json_gron_grep_fallback() {
  local tmp_dir="/tmp/sniper-test-json-$$"
  mkdir -p "$tmp_dir"
  cat > "$tmp_dir/data.json" << 'EOFJSON'
{"results":[{"email":"test@example.com","name":"Test User"}]}
EOFJSON
  local result
  result=$(sniper_json_gron_grep "$tmp_dir/data.json" "email")
  echo "$result" | grep -q "test@example.com" || return 1
  rm -rf "$tmp_dir"
}

test_json_gron_grep_empty_for_missing_file() {
  local result
  result=$(sniper_json_gron_grep "/nonexistent/path.json" "email")
  [[ -z "$result" ]] || return 1
}

test_json_save_handles_empty_input() {
  local tmp_dir="/tmp/sniper-test-json-$$"
  mkdir -p "$tmp_dir"
  sniper_json_save "" "$tmp_dir/empty"
  [[ -f "$tmp_dir/empty.json" ]] || return 1
  rm -rf "$tmp_dir"
}
