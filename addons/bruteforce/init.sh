echo "  [bruteforce] Initializing Brute Force Add-on v1.0..."

sniper_addon_register_mode "bruteforce" "$SNIPER_ADDONS_DIR/bruteforce/modes/bruteforce-enhanced.sh"
sniper_addon_register_plugin "bruteforce" "$SNIPER_ADDONS_DIR/bruteforce/plugins/hydra"
sniper_addon_register_plugin "bruteforce" "$SNIPER_ADDONS_DIR/bruteforce/plugins/medusa"
sniper_addon_register_plugin "bruteforce" "$SNIPER_ADDONS_DIR/bruteforce/plugins/crowbar"
