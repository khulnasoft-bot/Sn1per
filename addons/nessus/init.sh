echo "  [nessus] Initializing Nessus Add-on v2.0..."

sniper_addon_register_mode "nessus" "$SNIPER_ADDONS_DIR/nessus/modes/nessus-scan.sh"
sniper_addon_register_plugin "nessus" "$SNIPER_ADDONS_DIR/nessus/plugins/nessus6"
sniper_addon_register_plugin "nessus" "$SNIPER_ADDONS_DIR/nessus/plugins/nessus10"
