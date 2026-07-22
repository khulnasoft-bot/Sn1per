MODE_NAME="apk-static"
MODE_DESCRIPTION="Quick static analysis of APK — manifest inspection and permission risk scoring only"
MODE_REQUIRED_VARS=(LOOT_DIR)
MODE_REQUIRED_TOOLS=(python3)

mode_validate() {
  if [[ -z "$APK_PATH" ]]; then
    log_fail "apk-static requires --apk <path/to.apk>"
    return 1
  fi
  [[ -f "$APK_PATH" ]] || { log_fail "APK not found: $APK_PATH"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/mobile/apk-static"
}

mode_run() {
  local outdir="$LOOT_DIR/mobile/apk-static"
  local apk="$APK_PATH"
  local base="$outdir/$(basename "$apk" .apk)"
  mkdir -p "$base"

  section_banner
  section_header "APK STATIC ANALYSIS: $(basename "$apk")"

  if command -v aapt &>/dev/null; then
    aapt dump badging "$apk" > "$base/badging.txt" 2>/dev/null
    aapt dump permissions "$apk" > "$base/permissions.txt" 2>/dev/null
    local risky_perms=0
    for p in "READ_SMS" "SEND_SMS" "RECORD_AUDIO" "CAMERA" "READ_CONTACTS" "ACCESS_FINE_LOCATION" "READ_CALL_LOG"; do
      if grep -q "$p" "$base/permissions.txt" 2>/dev/null; then
        risky_perms=$((risky_perms + 1))
      fi
    done
    log_info "Found $risky_perms risky permissions"
    if [[ $risky_perms -ge 3 ]]; then
      sniper_findings_add "$(basename "$apk")" "risky-permissions" "MEDIUM" "apk-static" "APK requests $risky_perms risky permissions"
    fi
  else
    log_warn "aapt not found — install Android SDK build-tools"
  fi
}

mode_cleanup() {
  log_info "APK static analysis complete"
}

mode_execute
