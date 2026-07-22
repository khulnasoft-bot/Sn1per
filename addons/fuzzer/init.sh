echo "  [fuzzer] Initializing Fuzzer Add-on v1.0..."

sniper_addon_register_mode "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/modes/fuzz-directory.sh"
sniper_addon_register_mode "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/modes/fuzz-parameters.sh"
sniper_addon_register_mode "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/modes/fuzz-vhost.sh"
sniper_addon_register_plugin "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/plugins/ffuf"
sniper_addon_register_plugin "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/plugins/gobuster"
sniper_addon_register_plugin "fuzzer" "$SNIPER_ADDONS_DIR/fuzzer/plugins/wfuzz"
