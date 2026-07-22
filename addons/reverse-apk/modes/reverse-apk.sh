MODE_NAME="reverse-apk"
MODE_DESCRIPTION="Full Android APK reverse engineering pipeline — extract, decompile, analyze secrets, detect endpoints"
MODE_REQUIRED_VARS=(LOOT_DIR)
MODE_REQUIRED_TOOLS=(apktool java python3)

mode_validate() {
  if [[ -z "$APK_PATH" && -z "$TARGET" ]]; then
    log_fail "ReverseAPK requires --apk <path/to.apk> or -t <target> (for URL download)"
    return 1
  fi
}

mode_init() {
  mkdir -p "$LOOT_DIR/mobile/reverse-apk"
}

_apk_download() {
  local url="$1"
  local outdir="$2"
  local filename
  filename=$(basename "${url%%\?*}")
  [[ "$filename" == *.apk ]] || filename="app.apk"
  curl -sL -o "$outdir/$filename" "$url" 2>/dev/null || wget -q -O "$outdir/$filename" "$url" 2>/dev/null
  echo "$outdir/$filename"
}

_apk_analyze_manifest() {
  local apk="$1"
  local outdir="$2"
  aapt dump badging "$apk" 2>/dev/null > "$outdir/manifest-summary.txt" || true
  python3 -c "
import zipfile, xml.etree.ElementTree as ET, sys
try:
    with zipfile.ZipFile('$apk') as z:
        if 'AndroidManifest.xml' in z.namelist():
            raw=z.read('AndroidManifest.xml')
            with open('$outdir/AndroidManifest.xml','wb') as f:
                f.write(raw)
except: pass
" 2>/dev/null || true
}

_apk_find_secrets() {
  local src_dir="$1"
  local outfile="$2"
  grep -r -E '(api[_-]?key|apikey|secret|password|token|auth[_-]?token|aws[_-]?[a-z]+|s3[_-]?[a-z]+)' \
    --include="*.java" --include="*.kt" --include="*.xml" --include="*.smali" \
    "$src_dir" 2>/dev/null | sort -u > "$outfile" || true
}

_apk_find_endpoints() {
  local src_dir="$1"
  local outfile="$2"
  grep -r -E 'https?://[a-zA-Z0-9./_-]+' \
    --include="*.java" --include="*.kt" --include="*.xml" --include="*.smali" \
    "$src_dir" 2>/dev/null | sort -u > "$outfile" || true
}

mode_run() {
  local outdir="$LOOT_DIR/mobile/reverse-apk"
  local apk_path=""

  if [[ -n "$APK_PATH" ]]; then
    apk_path="$APK_PATH"
  elif [[ -n "$TARGET" ]]; then
    log_info "Downloading APK from $TARGET..."
    apk_path=$(_apk_download "$TARGET" "$outdir")
  fi

  if [[ -z "$apk_path" || ! -f "$apk_path" ]]; then
    log_fail "APK not found: $apk_path"
    return 1
  fi

  section_banner
  section_header "REVERSE APK: $(basename "$apk_path")"
  log_info "APK size: $(du -h "$apk_path" | cut -f1)"

  mkdir -p "$outdir/$(basename "$apk_path" .apk)"
  local base="$outdir/$(basename "$apk_path" .apk)"

  _apk_analyze_manifest "$apk_path" "$base"
  log_ok "Manifest analysis complete"

  if [[ "$APK_DECOMPILE_SOURCES" != "0" ]]; then
    section_header "Decompiling with apktool..."
    apktool d -f -o "$base/smali" "$apk_path" 2>/dev/null && log_ok "Smali decompilation complete"

    if command -v jadx &>/dev/null; then
      section_header "Decompiling with jadx..."
      jadx -d "$base/java" "$apk_path" 2>/dev/null && log_ok "Java decompilation complete"
    fi
  fi

  if [[ "$APK_SCAN_SECRETS" != "0" && -d "$base/java" ]]; then
    section_header "Scanning for hardcoded secrets..."
    _apk_find_secrets "$base/java" "$base/secrets.txt"
    local secret_count
    secret_count=$(wc -l < "$base/secrets.txt" 2>/dev/null || echo 0)
    log_ok "Found $secret_count potential secrets"
    if [[ $secret_count -gt 0 ]]; then
      sniper_findings_add "$(basename "$apk_path")" "hardcoded-secret" "HIGH" "reverse-apk" "Found $secret_count potential hardcoded secrets in $(basename "$apk_path")"
    fi
  fi

  if [[ "$APK_SCAN_ENDPOINTS" != "0" && -d "$base/java" ]]; then
    section_header "Extracting network endpoints..."
    _apk_find_endpoints "$base/java" "$base/endpoints.txt"
    local endpoint_count
    endpoint_count=$(wc -l < "$base/endpoints.txt" 2>/dev/null || echo 0)
    log_ok "Extracted $endpoint_count network endpoints"
    cat "$base/endpoints.txt" >> "$LOOT_DIR/domains/domains-all-sorted.txt" 2>/dev/null
  fi

  section_header "Analysis complete for $(basename "$apk_path")"
}

mode_cleanup() {
  log_info "ReverseAPK analysis complete"
}

mode_execute
