test_config_loads_core_settings() {
  INSTALL_DIR="$FIXTURES_DIR/.."
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ -n "$ENABLE_AUTO_UPDATES" ]] || return 1
  [[ -n "$OUT_OF_SCOPE" ]] || return 1
  [[ -n "$MAX_HOSTS" ]] || return 1
}

test_config_sets_default_paths() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$PLUGINS_DIR" == "$SN1PER_ROOT/plugins" ]] || return 1
}

test_config_slack_notifications_default_off() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$SLACK_NOTIFICATIONS" == "0" ]] || return 1
}

test_config_burp_defaults() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$BURP_HOST" == "127.0.0.1" ]] || return 1
  [[ "$BURP_PORT" == "1338" ]] || return 1
}

test_config_nmap_options() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$NMAP_OPTIONS" == *"--open"* ]] || return 1
}

test_config_grep_patterns_loaded() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ -n "$GREP_XSS" ]] || return 1
  [[ -n "$GREP_SSRF" ]] || return 1
  [[ -n "$GREP_RCE" ]] || return 1
  [[ -n "$GREP_SQL" ]] || return 1
  [[ -n "$GREP_LFI" ]] || return 1
}

test_config_plugin_toggles_loaded() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$NMAP_SCRIPTS" == "1" ]] || return 1
  [[ "$METASPLOIT_EXPLOIT" == "1" ]] || return 1
  [[ "$SC0PE_VULNERABLITY_SCANNER" == "1" ]] || return 1
}

test_config_api_keys_default_empty() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ -z "$SHODAN_API_KEY" ]] || return 1
  [[ -z "$CENSYS_APP_ID" ]] || return 1
  [[ -z "$HUNTERIO_KEY" ]] || return 1
}

test_config_quick_ports_defined() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$QUICK_PORTS" == "21,22,80,443,8000,8080,8443" ]] || return 1
}

test_config_default_ports_defined() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$DEFAULT_PORTS" == *"3306"* ]] || return 1
  [[ "$DEFAULT_PORTS" == *"3389"* ]] || return 1
  [[ "$DEFAULT_PORTS" == *"8080"* ]] || return 1
}

test_config_vulnscan_default() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$VULNSCAN" == "0" ]] || return 1
}

test_config_nmap_scripts_network_discovery() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$NMAP_SCRIPTS" == "1" ]] || return 1
  [[ "$SSH_AUDIT" == "1" ]] || return 1
  [[ "$SMB_ENUM" == "1" ]] || return 1
}

test_config_osint_recon_toggles() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$WHOIS" == "1" ]] || return 1
  [[ "$THEHARVESTER" == "1" ]] || return 1
  [[ "$CRTSH" == "1" ]] || return 1
}

test_config_wordlist_paths_use_install_dir() {
  INSTALL_DIR="$SN1PER_ROOT"
  sniper_load_config "$SN1PER_ROOT/conf" "$SN1PER_ROOT/sniper.conf"
  [[ "$WEB_BRUTE_STEALTH" == "$SN1PER_ROOT/wordlists/web-brute-stealth.txt" ]] || return 1
  [[ "$DOMAINS_DEFAULT" == "$SN1PER_ROOT/wordlists/domains-default.txt" ]] || return 1
}
