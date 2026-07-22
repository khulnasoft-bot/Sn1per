nmap_get_open_ports() {
  local xml_file="$1"
  grep 'state="open"' "$xml_file" 2>/dev/null | grep -oP 'portid="\K[0-9]+' | sort -u
}

nmap_port_is_open() {
  local xml_file="$1" port="$2"
  grep -q "portid=\"$port\".*state=\"open\"" "$xml_file" 2>/dev/null
}

nmap_open_port_array() {
  local xml_file="$1"
  local -n arr="$2"
  mapfile -t arr < <(nmap_get_open_ports "$xml_file")
}

nmap_port_status() {
  local xml_file="$1" port="$2"
  grep "portid=\"$port\".*open" "$xml_file" 2>/dev/null | grep -q open
  return $?
}

nmap_host_is_up() {
  local txt_file="$1"
  grep -q "host up" "$txt_file" 2>/dev/null
}

nmap_extract_os() {
  local txt_file="$1"
  grep -E "OS details:|OS guesses:" "$txt_file" 2>/dev/null | cut -d: -f2 | sed 's/,//g' | head -c50 -
}

nmap_extract_mac() {
  local txt_file="$1"
  grep "MAC Address:" "$txt_file" 2>/dev/null | awk '{print $3 " " $4 " " $5 " " $6}'
}

nmap_parse_xml_for_ports() {
  local xml_file="$1"
  nmap_get_open_ports "$xml_file" > "$(dirname "$xml_file")/ports-$(basename "$xml_file" .xml).txt" 2>/dev/null
}

msf_run() {
  local target="$1" port="$2" module="$3" label="$4"
  local outfile="$LOOT_DIR/output/msf-$target-port${port}-${label}"
  msfconsole -q -x "setg RHOSTS $target; setg RHOST $target; setg LHOST $MSF_LHOST; setg LPORT $MSF_LPORT; $module; exit;" \
    | tee "${outfile}.raw" 2>/dev/null
  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" "${outfile}.raw" > "${outfile}.txt" 2>/dev/null
  rm -f "${outfile}.raw" 2>/dev/null
}

msf_run_simple() {
  local target="$1" port="$2" module="$3" label="$4"
  local outfile="$LOOT_DIR/output/msf-$target-port${port}-${label}"
  msfconsole -q -x "$module; exit;" \
    | tee "${outfile}.raw" 2>/dev/null
  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" "${outfile}.raw" > "${outfile}.txt" 2>/dev/null
  rm -f "${outfile}.raw" 2>/dev/null
}

nmap_run() {
  local target="$1" port="$2" extra_args="$3" label="$4"
  nmap -A -sV -Pn -p "$port" -v --script-timeout 90 --script="${extra_args}" "$target" \
    | tee "$LOOT_DIR/output/nmap-$target-port${port}${label:+-$label}.txt" 2>/dev/null
}
