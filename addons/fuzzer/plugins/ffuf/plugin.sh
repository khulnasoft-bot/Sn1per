PLUGIN_NAME="ffuf"

plugin_init() {
  command -v ffuf &>/dev/null
}

plugin_run() {
  local target="$1"
  local wordlist="${2:-$INSTALL_DIR/wordlists/web-brute-common.txt}"
  local outdir="$LOOT_DIR/web/fuzz"
  mkdir -p "$outdir"
  ffuf -u "http://$target/FUZZ" -w "$wordlist" -t 40 -o "$outdir/ffuf-$target.json" 2>/dev/null
}

plugin_parse_output() {
  local json_file="$1"
  python3 -c "
import json,sys
try:
    with open('$json_file') as f:
        d=json.load(f)
    for r in d.get('results',[]):
        print(f\"{r.get('status',0)} {r.get('url','')}\")
except: pass
" 2>/dev/null || true
}
