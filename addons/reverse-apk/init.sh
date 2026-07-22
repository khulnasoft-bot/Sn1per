echo "  [reverse-apk] Initializing ReverseAPK Add-on v1.0..."

sniper_addon_register_mode "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/modes/reverse-apk.sh"
sniper_addon_register_mode "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/modes/apk-static.sh"
sniper_addon_register_plugin "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/plugins/apktool"
sniper_addon_register_plugin "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/plugins/jadx"
sniper_addon_register_plugin "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/plugins/mobsf"
sniper_addon_register_plugin "reverse-apk" "$SNIPER_ADDONS_DIR/reverse-apk/plugins/enjarify"
