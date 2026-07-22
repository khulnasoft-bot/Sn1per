test_log_info_prints_blue_prefix() {
  local out
  out=$(log_info "hello" 2>&1)
  echo "$out" | grep -q "\[*\]" || return 1
  echo "$out" | grep -q "hello" || return 1
}

test_log_ok_prints_ok_suffix() {
  local out
  out=$(log_ok "test" 2>&1)
  echo "$out" | grep -q "OK" || return 1
}

test_log_fail_prints_fail_suffix() {
  local out
  out=$(log_fail "test" 2>&1)
  echo "$out" | grep -q "FAIL" || return 1
}

test_log_warn_prints_warning() {
  local out
  out=$(log_warn "caution" 2>&1)
  echo "$out" | grep -q "i" || return 1
  echo "$out" | grep -q "caution" || return 1
}

test_section_banner_prints_equals() {
  local out
  out=$(section_banner 2>&1)
  echo "$out" | grep -q "====" || return 1
}

test_section_header_prints_text() {
  local out
  out=$(section_header "GATHERING DNS INFO" 2>&1)
  echo "$out" | grep -q "GATHERING DNS INFO" || return 1
}

test_notify_slack_skips_when_disabled() {
  SLACK_NOTIFICATIONS="0"
  local out
  out=$(notify_slack "test" 2>&1)
  [[ -z "$out" ]] || return 1
}

test_notify_slack_file_skips_when_disabled() {
  SLACK_NOTIFICATIONS="0"
  local out
  out=$(notify_slack_file "test" 2>&1)
  [[ -z "$out" ]] || return 1
}

test_logging_handles_empty_string() {
  local out
  out=$(log_info "" 2>&1)
  [[ -n "$out" ]] || return 1
}
