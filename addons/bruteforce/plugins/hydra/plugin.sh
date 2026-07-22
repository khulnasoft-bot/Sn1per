PLUGIN_NAME="hydra"

plugin_init() {
  command -v hydra &>/dev/null
}

plugin_run() {
  local target="$1"
  local service="${2:-ssh}"
  local port="${3:-22}"
  local userlist="${BRUTE_USERLIST:-/usr/share/brutex/wordlists/simple-users.txt}"
  local passlist="${BRUTE_PASSLIST:-/usr/share/brutex/wordlists/password.lst}"
  local outdir="$LOOT_DIR/credentials/bruteforce"
  mkdir -p "$outdir"
  hydra -L "$userlist" -P "$passlist" -t 16 -o "$outdir/hydra-$target-$service.txt" "$service://$target" -s "$port" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  if [[ -f "$result_file" && -s "$result_file" ]]; then
    grep -E "login:|password:" "$result_file" || true
  fi
}
