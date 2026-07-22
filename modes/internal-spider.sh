if [[ $INTERNAL_SPIDER == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING INTERNAL LINK AUTO SPIDER $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/spider.sh

    local spider_seeds="$LOOT_DIR/web/spider-$TARGET.txt"
    local spider_output="$LOOT_DIR/web"
    local temp_dir="$spider_output/spider-crawl-$TARGET"
    local new_urls="$temp_dir/new-urls-$TARGET.txt"
    local all_crawled="$temp_dir/all-crawled-$TARGET.txt"
    local depth=0
    local max_depth="${INTERNAL_SPIDER_DEPTH:-2}"

    mkdir -p "$temp_dir" 2>/dev/null || true
    touch "$all_crawled"

    if [[ -f "$spider_seeds" ]]; then
        head -n 50 "$spider_seeds" > "$temp_dir/seeds-$TARGET.txt"
    fi

    if [[ ! -f "$temp_dir/seeds-$TARGET.txt" ]]; then
        echo "$TARGET" > "$temp_dir/seeds-$TARGET.txt"
    fi

    echo -e "$OKBLUE[*]$RESET Starting internal spider (max depth: $max_depth)..."

    if command -v fff &>/dev/null; then
        while [[ $depth -lt $max_depth ]]; do
            if [[ ! -f "$temp_dir/seeds-$TARGET.txt" ]]; then
                break
            fi

            local seed_count
            seed_count=$(wc -l < "$temp_dir/seeds-$TARGET.txt" 2>/dev/null | tr -d ' ')
            echo -e "$OKBLUE[*]$RESET Depth $depth: fetching $seed_count seed URLs..."

            local fff_out="$temp_dir/fff-depth-$depth"
            fff -o "$fff_out" -S -d 50 -k < "$temp_dir/seeds-$TARGET.txt" 2>/dev/null > /dev/null
            rm -f "$temp_dir/seeds-$TARGET.txt"

            find "$fff_out" -name "*.body" 2>/dev/null | while IFS= read -r body_file; do
                sniper_spider_extract_links_from_file "$body_file" 2>/dev/null | while IFS= read -r link; do
                    local full_url
                    full_url=$(sniper_spider_normalize_url "http://$TARGET" "$link")
                    if echo "$full_url" | grep -qi "$TARGET" 2>/dev/null; then
                        if ! grep -qF "$full_url" "$all_crawled" 2>/dev/null; then
                            echo "$full_url" >> "$all_crawled"
                            echo "$full_url" >> "$temp_dir/seeds-$TARGET.txt"
                            echo "$full_url" >> "$new_urls"
                        fi
                    fi
                done
            done

            depth=$((depth + 1))
        done
    else
        local domain
        domain=$(echo "$TARGET" | cut -d: -f1)
        local to_visit
        to_visit=($(cat "$temp_dir/seeds-$TARGET.txt" 2>/dev/null))

        while [[ $depth -lt $max_depth && ${#to_visit[@]} -gt 0 ]]; do
            local current_batch=("${to_visit[@]}")
            to_visit=()

            for url in "${current_batch[@]}"; do
                [[ -z "$url" ]] && continue

                if grep -qF "$url" "$all_crawled" 2>/dev/null; then
                    continue
                fi
                echo "$url" >> "$all_crawled"

                local links
                links=$(sniper_spider_extract_links "$url" 2>/dev/null)
                while IFS= read -r link; do
                    [[ -z "$link" ]] && continue
                    local full_url
                    full_url=$(sniper_spider_normalize_url "$url" "$link")
                    if echo "$full_url" | grep -qi "$TARGET" 2>/dev/null; then
                        if ! grep -qF "$full_url" "$all_crawled" 2>/dev/null; then
                            to_visit+=("$full_url")
                            echo "$full_url" >> "$new_urls"
                        fi
                    fi
                done <<< "$links"
            done
            depth=$((depth + 1))
        done
    fi

    if [[ -f "$new_urls" ]]; then
        local new_count
        new_count=$(wc -l < "$new_urls" 2>/dev/null | tr -d ' ')
        echo -e "$OKGREEN[+]$RESET New internal URLs discovered: ${new_count:-0}"

        if [[ -f "$spider_seeds" ]]; then
            cat "$new_urls" >> "$spider_seeds"
        fi

        sort -u "$new_urls" > "$spider_output/spider-internal-$TARGET.txt"
    else
        echo -e "$OKORANGE[!]$RESET No new internal URLs discovered"
    fi

    local total
    total=$(wc -l < "$all_crawled" 2>/dev/null | tr -d ' ')
    echo -e "$OKGREEN[+]$RESET Total URLs crawled: ${total:-0}"

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED INTERNAL LINK AUTO SPIDER COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
