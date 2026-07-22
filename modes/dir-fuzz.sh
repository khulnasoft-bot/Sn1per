if [[ $DIR_FUZZ == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING FFUF DIRECTORY BRUTE FORCE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/dir.sh

    local dir_output="$LOOT_DIR/web"
    local ffuf_wordlist="${DIR_FUZZ_WORDLIST:-$INSTALL_DIR/wordlists/web-brute-common.txt}"

    if [[ -n "$PORT" ]]; then
        if echo "$PORT" | grep -q "443"; then
            sniper_dir_ffuf "$TARGET" "$PORT" "https" "$ffuf_wordlist" "$dir_output" "$WEB_BRUTE_EXTENSIONS" "$WEB_BRUTE_EXCLUDE_CODES"
        else
            sniper_dir_ffuf "$TARGET" "$PORT" "http" "$ffuf_wordlist" "$dir_output" "$WEB_BRUTE_EXTENSIONS" "$WEB_BRUTE_EXCLUDE_CODES"
        fi
    else
        sniper_dir_ffuf "$TARGET" "80" "http" "$ffuf_wordlist" "$dir_output" "$WEB_BRUTE_EXTENSIONS" "$WEB_BRUTE_EXCLUDE_CODES"
        sniper_dir_ffuf "$TARGET" "443" "https" "$ffuf_wordlist" "$dir_output" "$WEB_BRUTE_EXTENSIONS" "$WEB_BRUTE_EXCLUDE_CODES"
    fi

    local combined_file
    if [[ -n "$PORT" ]]; then
        combined_file="$dir_output/dir-ffuf-$TARGET-$PORT.txt"
    else
        combined_file="$dir_output/dir-ffuf-$TARGET.txt"
    fi

    if [[ -f "$combined_file" ]]; then
        local result_count
        result_count=$(grep -v "^Total:" "$combined_file" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "$OKGREEN[+]$RESET ffuf discovered $result_count directories/files"
        cat "$combined_file" >> "$dir_output/dirsearch-$TARGET.txt" 2>/dev/null
    fi

    if [[ $DIR_FUZZ_RECURSIVE == "1" ]]; then
        echo -e "$OKBLUE[*]$RESET Running recursive directory scan..."
        if [[ -n "$PORT" ]]; then
            local protocol="http"
            if echo "$PORT" | grep -q "443"; then
                protocol="https"
            fi
            sniper_dir_ffuf_recursive "$TARGET" "$PORT" "$protocol" "$ffuf_wordlist" "$dir_output" "${DIR_FUZZ_RECURSIVE_DEPTH:-2}"
        else
            sniper_dir_ffuf_recursive "$TARGET" "80" "http" "$ffuf_wordlist" "$dir_output" "${DIR_FUZZ_RECURSIVE_DEPTH:-2}"
            sniper_dir_ffuf_recursive "$TARGET" "443" "https" "$ffuf_wordlist" "$dir_output" "${DIR_FUZZ_RECURSIVE_DEPTH:-2}"
        fi
    fi

    if [[ $DIR_FUZZ_VHOST == "1" ]]; then
        echo -e "$OKBLUE[*]$RESET Running vhost discovery..."
        local vhost_label="$TARGET"
        [[ -n "$PORT" ]] && vhost_label="$TARGET-$PORT"
        sniper_dir_ffuf_vhost "$TARGET" "$ffuf_wordlist" "$dir_output" "$vhost_label"
    fi

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED FFUF DIRECTORY BRUTE FORCE COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
