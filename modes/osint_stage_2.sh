  if [[ $SCAN_TYPE == "DOMAIN" ]] && [[ $OSINT == "1" ]]; then
    echo "[sn1persecurity.com] •?((¯°·._.• Started Sn1per stage 2 OSINT scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•" >> $LOOT_DIR/scans/notifications_new.txt
    if [[ "$SLACK_NOTIFICATIONS" == "1" ]]; then
      /bin/bash "$INSTALL_DIR/bin/slack.sh" "[sn1persecurity.com] •?((¯°·._.• Started Sn1per stage 2 OSINT scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•"
    fi
    if [[ $DORK_SEARCH == "1" ]]; then
      source $INSTALL_DIR/lib/dork.sh
    fi
    if [[ $GOOHAK = "1" ]]; then
      echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
      echo -e "$OKRED RUNNING GOOGLE HACKING QUERIES (GooHak) $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
      if command -v goohak &>/dev/null; then
        local goohak_out="$LOOT_DIR/osint/goohak-$TARGET"
        mkdir -p "$goohak_out" 2>/dev/null || true
        goohak $TARGET 2>/dev/null | tee "$goohak_out/goohak-output-$TARGET.txt" > /dev/null 2>&1 || true
        echo -e "$OKGREEN[+]$RESET GooHak results saved to $goohak_out"
      else
        echo -e "$OKORANGE[!]$RESET GooHak not installed"
      fi
    fi
    if [[ $INURLBR == "1" ]]; then
      echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
      echo -e "$OKRED RUNNING INURLBR OSINT QUERIES $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
      if command -v php &>/dev/null && [[ -f "$INSTALL_DIR/bin/inurlbr.php" ]]; then
        local inurlbr_out="$LOOT_DIR/osint/inurlbr-$TARGET"
        mkdir -p "$inurlbr_out" 2>/dev/null || true
        php $INSTALL_DIR/bin/inurlbr.php --dork "site:$TARGET" -s "inurlbr-$TARGET" 2>/dev/null | \
          sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > "$inurlbr_out/inurlbr-site-$TARGET.txt" 2>/dev/null

        if [[ $DORK_SEARCH == "1" ]]; then
          local max_dorks="${DORK_MAX_PER_CATEGORY:-10}"
          for dork_file in "$INSTALL_DIR/wordlists"/dorks-*.txt; do
            [[ ! -f "$dork_file" ]] && continue
            local cat_name
            cat_name=$(basename "$dork_file" .txt | sed "s/dorks-//")
            local dork_count=0
            while IFS= read -r dork; do
              [[ -z "$dork" || "$dork" == "#"* ]] && continue
              dork_count=$((dork_count + 1))
              [[ $dork_count -gt $max_dorks ]] && break
              local resolved_dork
              resolved_dork=$(echo "$dork" | sed "s/TARGET/$TARGET/g")
              local dork_result="$inurlbr_out/inurlbr-$cat_name-$dork_count-$TARGET.txt"
              php $INSTALL_DIR/bin/inurlbr.php --dork "$resolved_dork" -s "inurlbr-$TARGET" 2>/dev/null | \
                sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > "$dork_result" 2>/dev/null
              if [[ -s "$dork_result" ]]; then
                echo -e "$OKGREEN[+]$RESET inurlbr $cat_name dork $dork_count: results"
              fi
            done < "$dork_file"
          done

          local all_inurlbr="$inurlbr_out/all-inurlbr-$TARGET.txt"
          cat "$inurlbr_out"/inurlbr-*.txt 2>/dev/null | sort -u > "$all_inurlbr" 2>/dev/null
          echo -e "$OKGREEN[+]$RESET All inurlbr results: $(wc -l < "$all_inurlbr" 2>/dev/null | tr -d ' ') URLs"
        fi
      else
        echo -e "$OKORANGE[!]$RESET inurlbr.php not found or PHP not installed"
      fi
      rm -Rf output/ cookie.txt exploits.conf 2>/dev/null
    fi
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED STAGE 2 OSINT COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo "[sn1persecurity.com] •?((¯°·._.• Finished Sn1per stage 2 OSINT scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•" >> $LOOT_DIR/scans/notifications_new.txt
    if [[ "$SLACK_NOTIFICATIONS" == "1" ]]; then
      /bin/bash "$INSTALL_DIR/bin/slack.sh" "[sn1persecurity.com] •?((¯°·._.• Finished Sn1per stage 2 OSINT scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•"
    fi
  fi
