echo "  [command-exec] Initializing Command Execution Add-on v2.0..."

sniper_addon_register_mode "command-exec" "$SNIPER_ADDONS_DIR/command-exec/modes/command-inject.sh"
sniper_addon_register_plugin "command-exec" "$SNIPER_ADDONS_DIR/command-exec/plugins/commix"
sniper_addon_register_plugin "command-exec" "$SNIPER_ADDONS_DIR/command-exec/plugins/cmdi-payloads"
