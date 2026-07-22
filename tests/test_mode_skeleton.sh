test_mode_skeleton_validate_requires_vars() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
  TARGET=""
  LOOT_DIR=""
  mode_execute && return 1  # should fail because TARGET is empty
  return 0
}

test_mode_skeleton_validate_passes_with_vars() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET)
  TARGET="example.com"
  LOOT_DIR="/tmp"
  mode_execute || return 1  # should pass validation
}

test_mode_skeleton_custom_hooks_fire() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET)
  TARGET="example.com"
  LOOT_DIR="/tmp"
  local hook_fired=0
  mode_validate() { hook_fired=1; return 0; }
  mode_execute
  [[ $hook_fired -eq 1 ]] || return 1
}

test_mode_skeleton_run_hook_fires() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET)
  TARGET="example.com"
  LOOT_DIR="/tmp"
  local run_fired=0
  mode_run() { run_fired=1; return 0; }
  mode_execute
  [[ $run_fired -eq 1 ]] || return 1
}

test_mode_skeleton_cleanup_hook_fires() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET)
  TARGET="example.com"
  LOOT_DIR="/tmp"
  local cleanup_fired=0
  mode_run()    { return 0; }
  mode_cleanup() { cleanup_fired=1; return 0; }
  mode_execute
  [[ $cleanup_fired -eq 1 ]] || return 1
}

test_mode_skeleton_run_failure_blocks_cleanup() {
  MODE_NAME="test"
  MODE_REQUIRED_VARS=(TARGET)
  TARGET="example.com"
  LOOT_DIR="/tmp"
  local cleanup_fired=0
  mode_run()    { return 1; }
  mode_cleanup() { cleanup_fired=1; return 0; }
  mode_execute && return 1  # should fail because mode_run fails
  [[ $cleanup_fired -eq 0 ]] || return 1  # cleanup should NOT fire
}

test_mode_require_tools_missing() {
  mode_require_tools "this_tool_does_not_exist_xyz" && return 1
  return 0
}

test_mode_require_tools_present() {
  mode_require_tools "bash" || return 1
  mode_require_tools "echo" || return 1
}

test_mode_require_vars_missing() {
  local undef=""
  mode_require_vars undef && return 1
  return 0
}

test_mode_require_vars_present() {
  local defined="value"
  mode_require_vars defined || return 1
}
