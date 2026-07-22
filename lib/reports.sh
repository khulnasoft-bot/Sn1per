report_sort_assets() {
  local loot_dir="$1"
  cat "$loot_dir/scans/notifications_new.txt" 2>/dev/null >> "$loot_dir/scans/notifications.txt" 2>/dev/null
  sort -u "$loot_dir/domains/"*-full.txt 2>/dev/null > "$loot_dir/domains/domains-all-presorted.txt" 2>/dev/null
  sed -E "s/^\.//g" "$loot_dir/domains/domains-all-presorted.txt" 2>/dev/null | sed -E "s/^\*\.//g" | tr '[:upper:]' '[:lower:]' | sort -u > "$loot_dir/domains/domains-all-presorted2.txt" 2>/dev/null
  sort -u "$loot_dir/domains/targets.txt" 2>/dev/null > "$loot_dir/domains/targets-all-presorted.txt" 2>/dev/null
  sed -E "s/^\.//g" "$loot_dir/domains/targets-all-presorted.txt" 2>/dev/null | sed -E "s/^\*\.//g" | tr '[:upper:]' '[:lower:]' | sort -u > "$loot_dir/domains/targets-all-sorted.txt" 2>/dev/null
  sort -u "$loot_dir/ips/ips-all-unsorted.txt" 2>/dev/null > "$loot_dir/ips/ips-all-sorted.txt" 2>/dev/null
  sed -i -E 's/address//g' "$loot_dir/ips/ips-all-sorted.txt" 2>/dev/null
  sort -u "$loot_dir/domains/domains-all-presorted2.txt" "$loot_dir/domains/targets-all-sorted.txt" 2>/dev/null > "$loot_dir/domains/domains-all-sorted.txt" 2>/dev/null
  diff "$loot_dir/domains/targets-all-sorted.txt" "$loot_dir/domains/domains-all-sorted.txt" 2>/dev/null | grep \> | awk '{print $2}' > "$loot_dir/domains/targets-all-unscanned.txt" 2>/dev/null
  rm -f "$loot_dir/domains/targets-all-presorted.txt" "$loot_dir/domains/targets-all-presorted2.txt" \
        "$loot_dir/domains/domains-all-presorted.txt" "$loot_dir/domains/domains-all-presorted2.txt" 2>/dev/null
  sort -u "$loot_dir/nmap/openports-unsorted.txt" 2>/dev/null > "$loot_dir/nmap/openports-sorted.txt" 2>/dev/null
  sort -u "$loot_dir/nmap/livehosts-unsorted.txt" 2>/dev/null > "$loot_dir/nmap/livehosts-sorted.txt" 2>/dev/null
  find "$loot_dir/web/" -type f -size -1c -delete 2>/dev/null
  cd "$loot_dir/web/" 2>/dev/null && rm -f webhosts-all-sorted-* 2>/dev/null
  cd "$loot_dir/domains/" 2>/dev/null && rm -f domains-all-sorted-* 2>/dev/null
  cd "$loot_dir/nmap/" 2>/dev/null && rm -f openports-all-sorted-* livehosts-all-sorted-* 2>/dev/null
  cd "$loot_dir/web/" 2>/dev/null
  grep -E -Hi 'HTTP/1.' headers-* 2>/dev/null | cut -d':' -f1 | sed "s/headers-http\|s-//g" | sed "s/\.txt//g" | cut -d - -f1 | sort -u > "$loot_dir/web/webhosts-sorted.txt" 2>/dev/null
  split -d -l "$MAX_HOSTS" -e "$loot_dir/web/webhosts-sorted.txt" "$loot_dir/web/webhosts-all-sorted-" 2>/dev/null
  cd "$loot_dir/domains/" 2>/dev/null
  split -d -l "$MAX_HOSTS" -e "$loot_dir/domains/domains-all-sorted.txt" "$loot_dir/domains/domains-all-sorted-" 2>/dev/null
  cd "$loot_dir/nmap/" 2>/dev/null
  split -d -l "$MAX_HOSTS" -e "$loot_dir/nmap/openports-sorted.txt" "$loot_dir/nmap/openports-all-sorted-" 2>/dev/null
  split -d -l "$MAX_HOSTS" -e "$loot_dir/nmap/livehosts-sorted.txt" "$loot_dir/nmap/livehosts-all-sorted-" 2>/dev/null
}

report_generate_html() {
  local loot_dir="$1"
  cd "$loot_dir/output" 2>/dev/null || return
  echo -en "$OKGREEN[$OKBLUE"
  for a in sniper-*.txt 2>/dev/null; do
    [[ -f "$a" ]] || continue
    cat "$a" | aha > "$loot_dir/reports/$a.html" 2>/dev/null
    echo -n '|'
  done
  echo -e "$OKGREEN]$RESET"
  cd "$loot_dir"
}

report_cleanup() {
  local loot_dir="$1"
  chmod 777 -Rf "$loot_dir" 2>/dev/null
  cd "$loot_dir/screenshots/" 2>/dev/null
  find "$loot_dir/screenshots/" -type f -size -9000c -delete 2>/dev/null
  find "$loot_dir/nmap/" "$loot_dir/ips/" "$loot_dir/osint/" "$loot_dir/vulnerabilities/" -type f -size -1c -delete 2>/dev/null
}

report_msf_import() {
  local loot_dir="$1" workspace="$2"
  echo -e "$OKORANGE + -- --=[ Starting Metasploit service...$RESET"
  /etc/init.d/metasploit start 2>/dev/null
  msfdb start 2>/dev/null
  echo -e "$OKORANGE + -- --=[ Importing NMap XML files into Metasploit...$RESET"
  msfconsole -x "workspace -a $workspace; workspace $workspace; db_import $loot_dir/nmap/nmap*.xml; hosts; services; exit;" \
    | tee "$loot_dir/notes/msf-$workspace.txt"
}

report_pro_integration() {
  local loot_dir="$1" workspace="$2"
  if [[ ! -f "$SNIPER_PRO" ]]; then
    echo -e "${OKBLUE}[${OKRED}i${RESET}${OKBLUE}]$RESET Upgrade to Sn1per Professional for Web UI and extended reporting."
    return
  fi
  wc -l "$loot_dir/scans/notifications.txt" 2>/dev/null | awk '{print $1}' > "$loot_dir/scans/notifications_total.txt" 2>/dev/null
  wc -l "$loot_dir/scans/notifications_new.txt" 2>/dev/null | awk '{print $1}' > "$loot_dir/scans/notifications_new_total.txt" 2>/dev/null
  cat "$loot_dir/scans/tasks-running.txt" 2>/dev/null > "$loot_dir/scans/tasks-running_total.txt" 2>/dev/null
  wc -l "$loot_dir/scans/tasks.txt" 2>/dev/null | awk '{print $1}' > "$loot_dir/scans/tasks_total.txt" 2>/dev/null
  wc -l "$loot_dir/scans/scheduled/"*.sh 2>/dev/null | awk '{print $1}' > "$loot_dir/scans/scheduled_tasks_total.txt" 2>/dev/null
  grep "Host status" "$loot_dir/scans/notifications.txt" 2>/dev/null | wc -l | awk '{print $1}' > "$loot_dir/scans/host_status_changes_total.txt" 2>/dev/null
  grep "Port change" "$loot_dir/scans/notifications.txt" 2>/dev/null | wc -l | awk '{print $1}' > "$loot_dir/scans/port_changes_total.txt" 2>/dev/null
  wc -l "$loot_dir/domains/domains_new-"*.txt 2>/dev/null | awk '{print $1}' > "$loot_dir/scans/domain_changes_total.txt" 2>/dev/null
  cat "$loot_dir/web/dirsearch-new-"*.txt "$loot_dir/web/spider-new-"*.txt 2>/dev/null | wc -l | awk '{print $1}' > "$loot_dir/scans/url_changes_total.txt" 2>/dev/null
  if [[ ! -f "$loot_dir/notes/notepad.html" ]]; then
    cp "$INSTALL_DIR/pro/notepad.html" "$loot_dir/notes/notepad.html" 2>/dev/null
    local pre_name; pre_name=$(echo "$workspace" | sed "s/\./-/g")
    sed -i "s/notepad/notepad-$pre_name/g" "$loot_dir/notes/notepad.html" 2>/dev/null
  fi
  echo -e "$OKORANGE + -- --=[ Generating Sn1per Professional reports...$RESET"
  source "$INSTALL_DIR/pro.sh"
}

report_run() {
  local loot_dir="$1" workspace="$2"
  [[ "$LOOT" == "0" ]] && return
  [[ -n "$workspace" ]] && loot_dir="$WORKSPACE_DIR"

  rm -f "$INSTALL_DIR/stash.sqlite" "$INSTALL_DIR/hydra.restore" /tmp/update-check.txt 2>/dev/null
  ls -lh "$loot_dir/scans/running_"*.txt 2>/dev/null | wc -l > "$loot_dir/scans/tasks-running.txt" 2>/dev/null

  echo -e "$OKBLUE[*]$RESET Opening loot directory $loot_dir ${OKBLUE}[${OKGREEN}OK${RESET}${OKBLUE}]"
  cd "$loot_dir" || return

  [[ "$METASPLOIT_IMPORT" == "1" ]] && report_msf_import "$loot_dir" "$workspace"

  echo -e "$OKORANGE + -- --=[ Generating reports...$RESET"
  report_generate_html "$loot_dir"

  chmod 777 -Rf "$loot_dir"
  echo -e "$OKORANGE + -- --=[ Sorting all files...$RESET"
  report_sort_assets "$loot_dir"

  echo -e "$OKORANGE + -- --=[ Removing blank screenshots and files...$RESET"
  report_cleanup "$loot_dir"

  cd "$loot_dir"
  report_pro_integration "$loot_dir" "$workspace"

  rm -f "$UPDATED_TARGETS" 2>/dev/null
  touch "$UPDATED_TARGETS" 2>/dev/null
  echo -e "$OKORANGE + -- --=[ Done!$RESET"
}
