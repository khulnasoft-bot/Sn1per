if [[ $DORK_SEARCH == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING GOOGLE DORK SEARCH $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/dork.sh

    local dork_output_dir="$LOOT_DIR/web"
    local dork_max="${DORK_MAX_PER_CATEGORY:-15}"

    if [[ -n "$TARGET" ]]; then
        mkdir -p "$dork_output_dir" 2>/dev/null || true

        if command -v goohak &>/dev/null; then
            echo -e "$OKBLUE[*]$RESET Running GooHak Google hacking queries..."
            local goohak_output="$dork_output_dir/dorks-$TARGET/goohak-$TARGET"
            mkdir -p "$goohak_output" 2>/dev/null || true
            goohak "$TARGET" 2>/dev/null | tee "$goohak_output/goohak-raw-$TARGET.txt" > /dev/null 2>&1 || true
            echo -e "$OKGREEN[+]$RESET GooHak complete: $goohak_output"
        else
            echo -e "$OKORANGE[!]$RESET GooHak not installed. Install with: git clone https://github.com/1N3/Goohak.git"
        fi

        if command -v php &>/dev/null && [[ -f "$INSTALL_DIR/bin/inurlbr.php" ]]; then
            echo -e "$OKBLUE[*]$RESET Running inurlbr dork queries..."
            local inurlbr_output_dir="$dork_output_dir/dorks-$TARGET/inurlbr-$TARGET"
            mkdir -p "$inurlbr_output_dir" 2>/dev/null || true

            for dork_file in "$INSTALL_DIR/wordlists"/dorks-*.txt; do
                [[ ! -f "$dork_file" ]] && continue
                local cat_name
                cat_name=$(basename "$dork_file" .txt | sed "s/dorks-//")

                local dork_count=0
                while IFS= read -r dork; do
                    [[ -z "$dork" || "$dork" == "#"* ]] && continue
                    dork_count=$((dork_count + 1))
                    [[ $dork_count -gt $dork_max ]] && break

                    local resolved_dork
                    resolved_dork=$(echo "$dork" | sed "s/TARGET/$TARGET/g")
                    local outfile="$inurlbr_output_dir/inurlbr-$cat_name-$dork_count-$TARGET.txt"

                    php "$INSTALL_DIR/bin/inurlbr.php" --dork "$resolved_dork" -s "inurlbr-$TARGET" 2>/dev/null | \
                        sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > "$outfile" 2>/dev/null

                    if [[ -s "$outfile" ]]; then
                        echo -e "$OKGREEN[+]$RESET inurlbr $cat_name dork $dork_count: results saved"
                    fi
                done < "$dork_file"
            done
        else
            echo -e "$OKORANGE[!]$RESET inurlbr.php not found or PHP not installed"
        fi

        echo -e "$OKBLUE[*]$RESET Running curl-based Google dork queries..."

        local categories=("files" "admin" "vulns" "info")
        local dork_files=(
            "$INSTALL_DIR/wordlists/dorks-files.txt"
            "$INSTALL_DIR/wordlists/dorks-admin.txt"
            "$INSTALL_DIR/wordlists/dorks-vulns.txt"
            "$INSTALL_DIR/wordlists/dorks-info.txt"
        )

        for i in "${!categories[@]}"; do
            local cat="${categories[$i]}"
            local file="${dork_files[$i]}"

            sniper_dork_run_dork_file "$TARGET" "$file" "$dork_output_dir/dorks-$TARGET" "$cat" "$dork_max"
        done

        sniper_dork_summary "$TARGET" "$dork_output_dir/dorks-$TARGET"

        local all_dorks="$dork_output_dir/dorks-$TARGET/all-dork-urls-$TARGET.txt"
        cat "$dork_output_dir"/dorks-*-"$TARGET"/all-results-*.txt 2>/dev/null | sort -u > "$all_dorks" 2>/dev/null

        if [[ -f "$all_dorks" ]]; then
            local total_all
            total_all=$(wc -l < "$all_dorks" | tr -d ' ')
            echo -e "$OKGREEN[+]$RESET Total unique dork results: $total_all"

            if [[ -f "$LOOT_DIR/web/spider-$TARGET.txt" ]]; then
                cat "$all_dorks" >> "$LOOT_DIR/web/spider-$TARGET.txt"
                sort -u "$LOOT_DIR/web/spider-$TARGET.txt" -o "$LOOT_DIR/web/spider-$TARGET.txt"
                echo -e "$OKGREEN[+]$RESET Merged $total_all dork results into spider file"
            fi
        fi
    fi

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED GOOGLE DORK SEARCH COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
