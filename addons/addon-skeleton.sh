# Sn1per Add-on Skeleton
# Copy this template to create a new add-on:
#   cp addons/addon-skeleton.sh addons/<name>/init.sh
# Then edit addons/<name>/addon.json and addons/<name>/config.conf

# ---- Registration (called by framework) ----
# Register modes contributed by this add-on:
#   sniper_addon_register_mode "<addon-name>" "$SNIPER_ADDONS_DIR/<addon-name>/modes/<mode>.sh"
#
# Register plugins contributed by this add-on:
#   sniper_addon_register_plugin "<addon-name>" "$SNIPER_ADDONS_DIR/<addon-name>/plugins/<plugin-name>"

# ---- Mode Lifecycle ----
# Each mode in modes/*.sh should define:
#   MODE_NAME="<mode-name>"
#   MODE_DESCRIPTION="..."
#   MODE_REQUIRED_TOOLS=(tool1 tool2)
#   mode_validate() { ... }
#   mode_init() { ... }
#   mode_run() { ... }
#   mode_cleanup() { ... }
#   mode_execute

# ---- Directory Structure ----
# addons/<name>/
#   addon.json       # metadata (name, version, description, deps)
#   config.conf      # default config overrides (sourced at load)
#   init.sh          # registration calls + any init logic
#   install.sh       # dependency installation (run via --addon-install)
#   modes/           # contributed mode scripts
#   plugins/         # contributed plugins (each in own subdir)
#   wordlists/       # any bundled wordlists

echo "Add-on skeleton loaded"
