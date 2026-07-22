echo "  [port-scanner] Initializing Port Scanner Add-on v1.0..."

sniper_addon_register_mode "port-scanner" "$SNIPER_ADDONS_DIR/port-scanner/modes/portscan-massive.sh"
sniper_addon_register_mode "port-scanner" "$SNIPER_ADDONS_DIR/port-scanner/modes/portscan-quick.sh"
sniper_addon_register_plugin "port-scanner" "$SNIPER_ADDONS_DIR/port-scanner/plugins/masscan"
sniper_addon_register_plugin "port-scanner" "$SNIPER_ADDONS_DIR/port-scanner/plugins/nmap-vuln"
