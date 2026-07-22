SNIPER_DORK_DIR="$INSTALL_DIR/wordlists"

sniper_dork_run_inurlbr() {
    local dork="$1"
    local target="$2"
    local output_file="$3"

    if ! command -v php &>/dev/null; then
        return
    fi

    if [[ ! -f "$INSTALL_DIR/bin/inurlbr.php" ]]; then
        return
    fi

    local resolved_dork
    resolved_dork=$(echo "$dork" | sed "s/TARGET/$target/g" | sed "s/TARGET/$target/g")

    php "$INSTALL_DIR/bin/inurlbr.php" --dork "$resolved_dork" -s "inurlbr-$target" 2>/dev/null | \
        sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" >> "$output_file" 2>/dev/null
}

sniper_dork_run_all_inurlbr() {
    local target="$1"
    local dork_file="$2"
    local output_dir="$3"
    local max_dorks="${4:-20}"

    if [[ ! -f "$dork_file" ]]; then
        return
    fi

    local dork_count=0
    while IFS= read -r dork; do
        [[ -z "$dork" || "$dork" == "#"* ]] && continue
        dork_count=$((dork_count + 1))
        if [[ $dork_count -gt $max_dorks ]]; then
            break
        fi

        echo -e "$OKBLUE[*]$RESET Running inurlbr dork $dork_count: $dork"
        local output_file="$output_dir/inurlbr-dork-$dork_count-$target.txt"
        sniper_dork_run_inurlbr "$dork" "$target" "$output_file" 2>/dev/null
    done < "$dork_file"
}

sniper_dork_process_goohak() {
    local target="$1"
    local output_dir="$2"

    if ! command -v goohak &>/dev/null; then
        return
    fi

    local goohak_output="$output_dir/goohak-$target"
    mkdir -p "$goohak_output" 2>/dev/null || true

    echo -e "$OKBLUE[*]$RESET Running GooHak against $target..."
    goohak "$target" 2>/dev/null > "$goohak_output/goohak-raw-$target.txt" || true

    local screenshot_dir
    screenshot_dir=$(find /tmp -maxdepth 2 -name "*goohak*" -type d 2>/dev/null | head -n 1)
    if [[ -n "$screenshot_dir" ]]; then
        cp -Rf "$screenshot_dir"/* "$goohak_output/" 2>/dev/null || true
    fi
}

sniper_dork_search_curl() {
    local query="$1"
    local target="$2"
    local output_file="$3"

    local resolved_query
    resolved_query=$(echo "$query" | sed "s/TARGET/$target/g")

    local encoded_query
    encoded_query=$(echo "$resolved_query" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || echo "$resolved_query")

    curl -s -L --connect-timeout 10 --max-time 30 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        -H "Accept: text/html,application/xhtml+xml" \
        "https://www.google.com/search?q=$encoded_query&num=10" 2>/dev/null | \
        grep -oP 'href="/url\?q=\K[^"&]+' 2>/dev/null | \
        sort -u > "$output_file" 2>/dev/null
}

sniper_dork_run_dork_file() {
    local target="$1"
    local dork_file="$2"
    local output_dir="$3"
    local category="$4"
    local max_dorks="${5:-15}"

    if [[ ! -f "$dork_file" ]]; then
        echo -e "$OKORANGE[!]$RESET Dork file not found: $dork_file"
        return
    fi

    local cat_dir="$output_dir/dorks-$category-$target"
    mkdir -p "$cat_dir" 2>/dev/null || true
    local all_results="$cat_dir/all-results-$target.txt"
    touch "$all_results"

    local dork_count=0
    while IFS= read -r dork; do
        [[ -z "$dork" || "$dork" == "#"* || "$dork" == ";"* ]] && continue
        dork_count=$((dork_count + 1))
        [[ $dork_count -gt $max_dorks ]] && break

        local dork_result="$cat_dir/dork-$dork_count-$target.txt"
        sniper_dork_search_curl "$dork" "$target" "$dork_result"

        if [[ -s "$dork_result" ]]; then
            cat "$dork_result" >> "$all_results"
            local url_count
            url_count=$(wc -l < "$dork_result" | tr -d ' ')
            echo -e "$OKGREEN[+]$RESET Dork $dork_count: $url_count results"
        fi
    done < "$dork_file"

    if [[ -f "$all_results" ]]; then
        sort -u "$all_results" -o "$all_results"
        local total
        total=$(wc -l < "$all_results" | tr -d ' ')
        echo -e "$OKGREEN[+]$RESET $category dorks total: $total unique URLs"
        echo "$total" > "$cat_dir/total-$target.txt"
    fi
}

sniper_dork_run_all_categories() {
    local target="$1"
    local output_dir="$2"
    local max_per_category="${3:-15}"

    local categories=("files" "admin" "vulns" "info")
    local dork_files=(
        "$SNIPER_DORK_DIR/dorks-files.txt"
        "$SNIPER_DORK_DIR/dorks-admin.txt"
        "$SNIPER_DORK_DIR/dorks-vulns.txt"
        "$SNIPER_DORK_DIR/dorks-info.txt"
    )

    for i in "${!categories[@]}"; do
        local cat="${categories[$i]}"
        local file="${dork_files[$i]}"

        echo -e "${OKGREEN}====================================================================================${RESET}"
        echo -e "$OKRED RUNNING $cat DORK QUERIES $RESET"
        echo -e "${OKGREEN}====================================================================================${RESET}"

        sniper_dork_run_dork_file "$target" "$file" "$output_dir" "$cat" "$max_per_category"
    done
}

sniper_dork_summary() {
    local target="$1"
    local output_dir="$2"

    local dork_output="$output_dir/dorks-$target"
    mkdir -p "$dork_output" 2>/dev/null || true
    local summary="$dork_output/summary-$target.txt"

    echo "=== Dork Search Summary for $target ===" > "$summary"
    echo "Date: $(date)" >> "$summary"
    echo "" >> "$summary"

    for cat_dir in "$output_dir"/dorks-*-"$target"; do
        [[ ! -d "$cat_dir" ]] && continue
        local cat_name
        cat_name=$(basename "$cat_dir" | sed "s/-$target//" | sed "s/dorks-//")

        local total_file="$cat_dir/total-$target.txt"
        local all_file="$cat_dir/all-results-$target.txt"

        if [[ -f "$total_file" ]]; then
            local total
            total=$(cat "$total_file")
            echo "[$cat_name] $total unique URLs" >> "$summary"
        fi

        if [[ -f "$all_file" ]]; then
            local example_count=0
            while IFS= read -r url; do
                [[ -z "$url" ]] && continue
                example_count=$((example_count + 1))
                [[ $example_count -gt 5 ]] && break
                echo "  -> $url" >> "$summary"
            done < "$all_file"
        fi
        echo "" >> "$summary"
    done

    echo "Summary saved: $summary"
    cat "$summary"
}
