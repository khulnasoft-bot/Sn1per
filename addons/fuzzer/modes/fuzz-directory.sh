MODE_NAME="fuzz-directory"
MODE_DESCRIPTION="Directory and file path fuzzing with smart wordlists"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(ffuf)

FUZZ_THREADS="${FUZZ_THREADS:-40}"
FUZZ_MATCH_CODES="${FUZZ_MATCH_CODES:-200,204,301,302,307,401,403,405}"
FUZZ_EXCLUDE_CODES="${FUZZ_EXCLUDE_CODES:-400,404,429,500,502,503}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/web/fuzz"
}

mode_run() {
  local outdir="$LOOT_DIR/web/fuzz"
  local target="$TARGET"
  local port="${PORT:-80}"
  local wordlist="${WEB_BRUTE_COMMON:-$INSTALL_DIR/wordlists/web-brute-common.txt}"
  local url="http://$target:$port"

  section_banner
  section_header "DIRECTORY FUZZING: $url"

  ffuf -u "$url/FUZZ" -w "$wordlist" -t "$FUZZ_THREADS" -mc "$FUZZ_MATCH_CODES" -fc "$FUZZ_EXCLUDE_CODES" -o "$outdir/ffuf-$target.json" 2>/dev/null

  if [[ -s "$outdir/ffuf-$target.json" ]]; then
    python3 -c "
import json,sys
try:
    with open('$outdir/ffuf-$target.json') as f:
        d=json.load(f)
    for r in d.get('results',[]):
        u=r.get('url','')
        s=r.get('status',0)
        print(f'{s} {u}')
" 2>/dev/null | tee "$outdir/ffuf-$target-results.txt"
  fi
}

mode_cleanup() {
  log_info "Directory fuzzing complete for $TARGET"
}

mode_execute
