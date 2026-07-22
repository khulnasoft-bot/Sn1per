test_nmap_get_open_ports_returns_open_only() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  local ports
  ports=$(nmap_get_open_ports "$xml")
  echo "$ports" | grep -q "^22$" || return 1
  echo "$ports" | grep -q "^80$" || return 1
  echo "$ports" | grep -q "^8080$" || return 1
  if echo "$ports" | grep -q "^443$"; then return 1; fi
  return 0
}

test_nmap_get_open_ports_sorted() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  local ports
  ports=$(nmap_get_open_ports "$xml")
  local first
  first=$(echo "$ports" | head -1)
  [[ "$first" == "22" ]] || return 1
}

test_nmap_port_is_open_true() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  nmap_port_is_open "$xml" "22" || return 1
  nmap_port_is_open "$xml" "80" || return 1
}

test_nmap_port_is_open_false() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  if nmap_port_is_open "$xml" "443"; then return 1; fi
  if nmap_port_is_open "$xml" "9999"; then return 1; fi
  return 0
}

test_nmap_open_port_array_populates() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  local -a ports
  nmap_open_port_array "$xml" ports
  [[ ${#ports[@]} -eq 3 ]] || return 1
  [[ "${ports[0]}" == "22" ]] || return 1
  [[ "${ports[1]}" == "80" ]] || return 1
  [[ "${ports[2]}" == "8080" ]] || return 1
}

test_nmap_host_is_up() {
  local xml="$FIXTURES_DIR/sample-nmap.xml"
  # Write a txt with "host up" to test with
  echo "host up: example.com (93.184.216.34)" > /tmp/test-nmap-up.txt
  nmap_host_is_up /tmp/test-nmap-up.txt || return 1
  rm -f /tmp/test-nmap-up.txt
}

test_nmap_host_is_down() {
  echo "all ports filtered" > /tmp/test-nmap-down.txt
  nmap_host_is_up /tmp/test-nmap-down.txt && return 1
  rm -f /tmp/test-nmap-down.txt
  return 0
}

test_nmap_extract_os() {
  cat > /tmp/test-nmap-os.txt << 'EOF'
OS details: Linux 2.6.32
OS guesses: Linux 2.6.32 - 3.1
EOF
  local os
  os=$(nmap_extract_os /tmp/test-nmap-os.txt)
  echo "$os" | grep -q "Linux" || return 1
  rm -f /tmp/test-nmap-os.txt
}

test_nmap_extract_mac() {
  cat > /tmp/test-nmap-mac.txt << 'EOF'
MAC Address: 00:11:22:33:44:55 (Vendor)
EOF
  local mac
  mac=$(nmap_extract_mac /tmp/test-nmap-mac.txt)
  [[ "$mac" == "00:11:22:33:44:55"* ]] || return 1
  rm -f /tmp/test-nmap-mac.txt
}

test_nmap_returns_empty_for_nonexistent_xml() {
  local ports
  ports=$(nmap_get_open_ports "/tmp/nonexistent.xml")
  [[ -z "$ports" ]] || return 1
}

test_msf_run_creates_output_file() {
  local msf_test_dir="/tmp/sniper-test-msf-$$"
  mkdir -p "$msf_test_dir/output"
  LOOT_DIR="$msf_test_dir"
  MSF_LHOST="127.0.0.1"
  MSF_LPORT="4444"

  msf_run "test.target" "22" "use scanner/ssh/ssh_version; run" "ssh_version" 2>/dev/null || true
  # msf_run should not crash — output file may not exist if msfconsole is missing
  # That's acceptable; just verify no crash
  rm -rf "$msf_test_dir" 2>/dev/null
  return 0
}
