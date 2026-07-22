if [[ $WORDLIST_GEN == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING TAXONOMY WORDLIST GENERATOR $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/taxonomy.sh

    local tax_output="$LOOT_DIR/web"

    if [[ -n "$TARGET" ]]; then
        mkdir -p "$tax_output" 2>/dev/null || true

        echo -e "$OKBLUE[*]$RESET Generating taxonomy wordlist from spider, wayback, gau, content, JS, and headers..."
        sniper_taxonomy_generate_full "$TARGET" "$tax_output"

        local tax_dir="$tax_output/taxonomy-$TARGET"
        local wordlist="$tax_dir/wordlist-$TARGET.txt"

        if [[ -f "$wordlist" ]]; then
            local total
            total=$(wc -l < "$wordlist" | tr -d ' ')
            echo -e "$OKGREEN[+]$RESET Generated wordlist with $total unique entries"

            local combined_wordlist="$INSTALL_DIR/wordlists/generated-$TARGET.txt"
            cp "$wordlist" "$combined_wordlist" 2>/dev/null
            echo -e "$OKGREEN[+]$RESET Copied wordlist to $combined_wordlist"

            if [[ $TAXONOMY_FFUF == "1" ]]; then
                if command -v ffuf &>/dev/null; then
                    echo -e "$OKBLUE[*]$RESET Running ffuf with generated wordlist..."

                    for proto in http https; do
                        local port="80"
                        [[ "$proto" == "https" ]] && port="443"
                        local header_file="$tax_output/headers-$proto-$TARGET.txt"
                        if [[ ! -f "$header_file" ]]; then
                            header_file="$tax_output/headers-$proto-$TARGET-$port.txt"
                        fi

                        if [[ -f "$header_file" ]]; then
                            ffuf -u "$proto://$TARGET:$port/FUZZ" -w "$wordlist" \
                                -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
                                sort -u > "$tax_dir/ffuf-$proto-$TARGET.txt" 2>/dev/null
                            local fc
                            fc=$(wc -l < "$tax_dir/ffuf-$proto-$TARGET.txt" 2>/dev/null | tr -d ' ')
                            echo -e "$OKGREEN[+]$RESET ffuf $proto results: ${fc:-0}"
                        fi
                    done
                fi
            fi

            echo -e "${OKGREEN}====================================================================================${RESET}"
            echo -e "$OKRED WORDLIST BREAKDOWN $RESET"
            echo -e "${OKGREEN}====================================================================================${RESET}"
            for f in "$tax_dir"/wordlist-*.txt "$tax_dir"/wordlist-*.txt; do
                [[ ! -f "$f" ]] && continue
                local name
                name=$(basename "$f" .txt | sed "s/-$TARGET//" | sed "s/wordlist-//")
                local count
                count=$(wc -l < "$f" | tr -d ' ')
                echo -e "$OKGREEN[+]$RESET $name: $count entries"
            done
        else
            echo -e "$OKORANGE[!]$RESET No wordlist generated - no source data available"
        fi
    fi

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED TAXONOMY WORDLIST GENERATOR COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
