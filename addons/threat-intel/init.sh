echo "  [threat-intel] Initializing Threat Intel Add-on v1.0..."

sniper_addon_register_mode "threat-intel" "$SNIPER_ADDONS_DIR/threat-intel/modes/threat-intel.sh"
sniper_addon_register_plugin "threat-intel" "$SNIPER_ADDONS_DIR/threat-intel/plugins/otx"
sniper_addon_register_plugin "threat-intel" "$SNIPER_ADDONS_DIR/threat-intel/plugins/virustotal"
sniper_addon_register_plugin "threat-intel" "$SNIPER_ADDONS_DIR/threat-intel/plugins/threatfox"
