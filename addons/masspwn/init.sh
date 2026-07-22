echo "  [masspwn] Initializing MassPwn Add-on v1.0..."

sniper_addon_register_mode "masspwn" "$SNIPER_ADDONS_DIR/masspwn/modes/masspwn.sh"
sniper_addon_register_plugin "masspwn" "$SNIPER_ADDONS_DIR/masspwn/plugins/metasploit-pwn"
sniper_addon_register_plugin "masspwn" "$SNIPER_ADDONS_DIR/masspwn/plugins/autoexploit"
