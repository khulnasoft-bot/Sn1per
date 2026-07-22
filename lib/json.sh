sniper_json_save() {
  local json_data="$1"
  local output_base="$2"
  echo "$json_data" > "$output_base.json"
  if command -v gron &>/dev/null; then
    echo "$json_data" | gron 2>/dev/null > "$output_base.gron.txt" || true
  fi
  echo "$json_data" | python3 -m json.tool 2>/dev/null > "$output_base.pretty.json" || true
}

sniper_json_save_curl() {
  local url="$3"
  local output_base="$2"
  local extra_args="${1:--s}"
  local tmp
  tmp=$(curl $extra_args "$url" 2>/dev/null) || return
  echo "$tmp" > "$output_base.json"
  if command -v gron &>/dev/null; then
    echo "$tmp" | gron 2>/dev/null > "$output_base.gron.txt" || true
  fi
  echo "$tmp" | python3 -m json.tool 2>/dev/null > "$output_base.pretty.json" || true
  echo "$tmp"
}

sniper_json_gron_grep() {
  local json_file="$1"
  local pattern="$2"
  if [[ -f "$json_file" ]]; then
    if command -v gron &>/dev/null; then
      gron "$json_file" 2>/dev/null | grep -iE "$pattern" || true
    else
      grep -iE "$pattern" "$json_file" 2>/dev/null || true
    fi
  fi
}

sniper_gron_path() {
  if command -v gron &>/dev/null; then
    command -v gron
  elif [[ -x "$INSTALL_DIR/bin/gron" ]]; then
    echo "$INSTALL_DIR/bin/gron"
  else
    echo ""
  fi
}
