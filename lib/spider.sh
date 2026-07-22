sniper_spider_extract_links() {
    local url="$1"
    curl -s -L --connect-timeout 5 --max-time 10 --insecure "$url" 2>/dev/null | \
        grep -oP '(?:href|src|action)=["'\'']?\K[^"'\'' >]+' 2>/dev/null | \
        sort -u
}

sniper_spider_extract_links_from_file() {
    local html_file="$1"
    grep -oP '(?:href|src|action)=["'\'']?\K[^"'\'' >]+' "$html_file" 2>/dev/null | sort -u
}

sniper_spider_normalize_url() {
    local base_url="$1"
    local link="$2"

    case "$link" in
        http://*|https://*)
            echo "$link"
            ;;
        //*)
            echo "https:$link"
            ;;
        /*)
            local base_protocol
            base_protocol=$(echo "$base_url" | cut -d: -f1)
            local base_host
            base_host=$(echo "$base_url" | cut -d/ -f3)
            echo "$base_protocol://$base_host$link"
            ;;
        *)
            echo "$base_url/$link"
            ;;
    esac
}

sniper_spider_crawl() {
    local seed_url="$1"
    local target="$2"
    local output_dir="$3"
    local max_depth="${4:-2}"
    local max_urls="${5:-500}"

    local temp_dir="$output_dir/spider-crawl-$target"
    local all_urls="$temp_dir/all-urls-$target.txt"
    local visited="$temp_dir/visited-$target.txt"

    mkdir -p "$temp_dir" 2>/dev/null || true
    touch "$all_urls" "$visited"

    local domain
    domain=$(echo "$seed_url" | cut -d/ -f3 | cut -d: -f1)

    local to_visit=("$seed_url")
    local depth=0

    while [[ $depth -lt $max_depth ]]; do
        local current_batch=("${to_visit[@]}")
        to_visit=()

        for url in "${current_batch[@]}"; do
            [[ -z "$url" ]] && continue

            if grep -qF "$url" "$visited" 2>/dev/null; then
                continue
            fi
            echo "$url" >> "$visited"

            local url_count
            url_count=$(wc -l < "$all_urls" 2>/dev/null | tr -d ' ')
            if [[ "${url_count:-0}" -ge "$max_urls" ]]; then
                break 2
            fi

            echo "$url" >> "$all_urls"

            local page_links
            page_links=$(sniper_spider_extract_links "$url" 2>/dev/null)

            while IFS= read -r link; do
                [[ -z "$link" ]] && continue

                local full_url
                full_url=$(sniper_spider_normalize_url "$url" "$link")

                if echo "$full_url" | grep -q "$domain" 2>/dev/null; then
                    if ! grep -qF "$full_url" "$visited" 2>/dev/null; then
                        to_visit+=("$full_url")
                    fi
                fi
            done <<< "$page_links"
        done

        depth=$((depth + 1))
    done

    sort -u "$all_urls" > "$output_dir/spider-$target-crawl-$depth.txt"
    echo -e "$OKGREEN[+]$RESET Crawl complete: $(wc -l < "$output_dir/spider-$target-crawl-$depth.txt" | tr -d ' ') urls found at depth $depth"
}

sniper_spider_crawl_fff() {
    local seed_url="$1"
    local target="$2"
    local output_dir="$3"
    local max_depth="${4:-2}"

    if ! command -v fff &>/dev/null; then
        echo -e "$OKRED[!]$RESET fff not installed for spidering. Falling back to curl."
        sniper_spider_crawl "$seed_url" "$target" "$output_dir" "$max_depth"
        return
    fi

    local temp_dir="$output_dir/spider-crawl-$target"
    local all_urls="$temp_dir/all-urls-$target.txt"
    mkdir -p "$temp_dir" 2>/dev/null || true

    echo "$seed_url" > "$temp_dir/seeds-$target.txt"
    local depth=0

    while [[ $depth -lt $max_depth ]]; do
        if [[ ! -f "$temp_dir/seeds-$target.txt" ]]; then
            break
        fi

        local fff_out="$temp_dir/fff-output-depth-$depth"
        fff -o "$fff_out" -S -d 20 -k < "$temp_dir/seeds-$target.txt" 2>/dev/null > /dev/null

        rm -f "$temp_dir/seeds-$target.txt"

        find "$fff_out" -name "*.body" 2>/dev/null | while IFS= read -r body_file; do
            local domain
            domain=$(echo "$seed_url" | cut -d/ -f3 | cut -d: -f1)
            sniper_spider_extract_links_from_file "$body_file" 2>/dev/null | while IFS= read -r link; do
                local full_url
                full_url=$(sniper_spider_normalize_url "$seed_url" "$link")
                if echo "$full_url" | grep -q "$domain" 2>/dev/null; then
                    if ! grep -qF "$full_url" "$all_urls" 2>/dev/null; then
                        echo "$full_url" >> "$all_urls"
                        echo "$full_url" >> "$temp_dir/seeds-$target.txt"
                    fi
                fi
            done
        done

        depth=$((depth + 1))
    done

    sort -u "$all_urls" > "$output_dir/spider-$target-crawl-$depth.txt"
    echo -e "$OKGREEN[+]$RESET fff-crawl complete: $(wc -l < "$output_dir/spider-$target-crawl-$depth.txt" | tr -d ' ') urls at depth $depth"
}

sniper_spider_realpath() {
    local path="$1"
    local base_url="$2"
    if [[ "$path" == "/"* ]]; then
        local base_host
        base_host=$(echo "$base_url" | cut -d/ -f3)
        local base_proto
        base_proto=$(echo "$base_url" | cut -d: -f1)
        echo "$base_proto://$base_host$path"
    else
        echo "$base_url/$path"
    fi
}

sniper_spider_extract_internal() {
    local url="$1"
    local domain="$2"
    sniper_spider_extract_links "$url" 2>/dev/null | while IFS= read -r link; do
        local full_url
        full_url=$(sniper_spider_normalize_url "$url" "$link")
        if echo "$full_url" | grep -qi "$domain" 2>/dev/null; then
            echo "$full_url"
        fi
    done | sort -u
}
