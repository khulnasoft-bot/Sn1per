SNIPER_TAXONOMY_DIR="$INSTALL_DIR/wordlists"

sniper_taxonomy_extract_paths() {
    local url_list="$1"
    cut -d'?' -f1 "$url_list" 2>/dev/null | \
        grep -oP '/[a-zA-Z0-9_@.-]+(?=/|$)' | \
        tr -d '/' | sort -u
}

sniper_taxonomy_extract_full_paths() {
    local url_list="$1"
    cut -d'?' -f1 "$url_list" 2>/dev/null | \
        grep -oP '/[a-zA-Z0-9_@./-]+' | \
        sort -u
}

sniper_taxonomy_extract_dirs() {
    local url_list="$1"
    cut -d'?' -f1 "$url_list" 2>/dev/null | \
        grep -oP '/[a-zA-Z0-9_@./-]+/' | \
        sort -u
}

sniper_taxonomy_extract_params() {
    local url_list="$1"
    grep -oP '[?&][a-zA-Z0-9_]+(?==)' "$url_list" 2>/dev/null | \
        tr -d '?&' | sort -u
}

sniper_taxonomy_extract_param_values() {
    local url_list="$1"
    local param_name="$2"
    grep -oP "(?<=[?&]$param_name=)[^&#]+" "$url_list" 2>/dev/null | sort -u
}

sniper_taxonomy_extract_extensions() {
    local url_list="$1"
    grep -oP '\.[a-zA-Z0-9]+(?=[?/]|$)' "$url_list" 2>/dev/null | \
        tr '[:upper:]' '[:lower:]' | sort -u
}

sniper_taxonomy_extract_subdomains() {
    local url_list="$1"
    local target="$2"
    grep -oP "[a-zA-Z0-9_.-]+\.$target" "$url_list" 2>/dev/null | sort -u
}

sniper_taxonomy_extract_words() {
    local file="$1"
    local min_len="${2:-3}"
    tr -c '[:alnum:]' '\n' < "$file" 2>/dev/null | \
        grep -vE '^[0-9]+$' | \
        grep -vE '^.{0,'$((min_len-1))'}$' | \
        grep -viE '^(the|and|for|are|but|not|you|all|can|had|her|was|one|our|out|has|have|from|they|this|that|with|have|will|your|which|their|them|would|about|there|could|should|after|then|some|such|than|into|also|more|these|other|very|just|over|only|each|than|those|being|what|when|where|how|who|why|been|have|does|did|done|get|got|make|made|may|might|shall|must|like|same|part|back|still|well|here|there|both|each|few|more|most|other|some|such|than|that|this|these|those|http|https|www|com|org|net|html|php|jsp|asp)$' | \
        sort -u
}

sniper_taxonomy_extract_js_tokens() {
    local file="$1"
    grep -oP '[a-zA-Z_$][a-zA-Z0-9_$]*' "$file" 2>/dev/null | \
        grep -vE '^(var|let|const|function|return|if|else|for|while|do|switch|case|break|continue|new|this|typeof|instanceof|void|delete|in|of|class|extends|super|import|export|default|from|as|try|catch|finally|throw|async|await|yield|true|false|null|undefined|NaN|Infinity|length|name|prototype|constructor|toString|valueOf|hasOwnProperty|isPrototypeOf|propertyIsEnumerable|toLocaleString|call|apply|bind|charAt|charCodeAt|concat|includes|endsWith|indexOf|lastIndexOf|match|repeat|replace|search|slice|split|substring|trim|toLowerCase|toUpperCase|push|pop|shift|unshift|sort|splice|map|filter|reduce|forEach|some|every|find|findIndex|keys|values|entries|then|catch|finally|resolve|reject|all|race|JSON|Math|Date|RegExp|Error|Array|Object|String|Number|Boolean|Symbol|Function|Promise|Set|Map|WeakSet|WeakMap|Proxy|Reflect|Intl|console|window|document|navigator|location|history|localStorage|sessionStorage|fetch|XMLHttpRequest|WebSocket|setTimeout|setInterval|clearTimeout|clearInterval|requestAnimationFrame|cancelAnimationFrame)$' | \
        grep -vE '^[0-9]' | \
        sort -u
}

sniper_taxonomy_extract_routes() {
    local file="$1"
    grep -oP '["'\'']/[a-zA-Z0-9_/{}.:-]*["'\'']' "$file" 2>/dev/null | tr -d '"' | sort -u
    grep -oP '(?:router|route|app)\.[a-zA-Z]+\(["'\'']/[^"'\'']+' "$file" 2>/dev/null | grep -oP '/[^"'\'']+' | sort -u
    grep -oP '(?:path|url|uri)\s*[:=]\s*["'\'']/[^"'\'']+' "$file" 2>/dev/null | grep -oP '/[^"'\'']+' | sort -u
}

sniper_taxonomy_generate() {
    local target="$1"
    local output_dir="$2"
    local sources="$3"
    local min_word_len="${4:-3}"

    local tax_dir="$output_dir/taxonomy-$target"
    mkdir -p "$tax_dir" 2>/dev/null || true

    local combined_wordlist="$tax_dir/wordlist-$target.txt"
    local paths_wordlist="$tax_dir/wordlist-paths-$target.txt"
    local params_wordlist="$tax_dir/wordlist-params-$target.txt"
    local keywords_wordlist="$tax_dir/wordlist-keywords-$target.txt"
    local extensions_wordlist="$tax_dir/wordlist-extensions-$target.txt"
    local tokens_wordlist="$tax_dir/wordlist-js-tokens-$target.txt"
    local combined_taxonomy="$tax_dir/taxonomy-$target.txt"

    echo -e "$OKBLUE[*]$RESET Generating taxonomy wordlist for $target..."

    for source in $sources; do
        case "$source" in
            spider)
                local spider_file="$output_dir/spider-$target.txt"
                if [[ -f "$spider_file" ]]; then
                    echo -e "$OKBLUE[*]$RESET Extracting from spider URLs..."
                    sniper_taxonomy_extract_paths "$spider_file" >> "$paths_wordlist" 2>/dev/null
                    sniper_taxonomy_extract_full_paths "$spider_file" >> "$tax_dir/wordlist-full-paths-$target.txt" 2>/dev/null
                    sniper_taxonomy_extract_params "$spider_file" >> "$params_wordlist" 2>/dev/null
                    sniper_taxonomy_extract_extensions "$spider_file" >> "$extensions_wordlist" 2>/dev/null
                fi
                ;;
            wayback)
                local wayback_file="$output_dir/waybackurls-$target.txt"
                if [[ -f "$wayback_file" ]]; then
                    sniper_taxonomy_extract_paths "$wayback_file" >> "$paths_wordlist" 2>/dev/null
                    sniper_taxonomy_extract_params "$wayback_file" >> "$params_wordlist" 2>/dev/null
                    sniper_taxonomy_extract_extensions "$wayback_file" >> "$extensions_wordlist" 2>/dev/null
                fi
                ;;
            gau)
                local gau_file="$output_dir/gua-$target.txt"
                if [[ -f "$gau_file" ]]; then
                    sniper_taxonomy_extract_paths "$gau_file" >> "$paths_wordlist" 2>/dev/null
                    sniper_taxonomy_extract_params "$gau_file" >> "$params_wordlist" 2>/dev/null
                fi
                ;;
            content)
                local content_dir="$output_dir/fff-output-$target"
                if [[ -d "$content_dir" ]]; then
                    find "$content_dir" -name "*.body" 2>/dev/null | while IFS= read -r body_file; do
                        sniper_taxonomy_extract_words "$body_file" "$min_word_len" >> "$keywords_wordlist" 2>/dev/null
                    done
                fi
                local page_html="$output_dir/analysis-$target/page-html-$target.txt"
                if [[ -f "$page_html" ]]; then
                    sniper_taxonomy_extract_words "$page_html" "$min_word_len" >> "$keywords_wordlist" 2>/dev/null
                fi
                ;;
            js)
                local js_analysis="$output_dir/js-analysis-$target"
                if [[ -d "$js_analysis" ]]; then
                    for js_file in "$js_analysis"/js-endpoints-*.txt; do
                        [[ -f "$js_file" ]] && cat "$js_file" >> "$tax_dir/wordlist-js-endpoints-$target.txt" 2>/dev/null
                    done
                fi
                local js_dir="$output_dir/javascript/$target"
                if [[ -d "$js_dir" ]]; then
                    find "$js_dir" -name "*.js" 2>/dev/null | while IFS= read -r js_file; do
                        sniper_taxonomy_extract_js_tokens "$js_file" >> "$tokens_wordlist" 2>/dev/null
                        sniper_taxonomy_extract_routes "$js_file" >> "$tax_dir/wordlist-js-endpoints-$target.txt" 2>/dev/null
                    done
                fi
                ;;
            headers)
                find "$output_dir" -maxdepth 1 -name "headers-*$target*" -type f 2>/dev/null | while IFS= read -r hfile; do
                    sniper_taxonomy_extract_words "$hfile" "$min_word_len" >> "$keywords_wordlist" 2>/dev/null
                done
                ;;
        esac
    done

    for f in "$paths_wordlist" "$params_wordlist" "$keywords_wordlist" "$extensions_wordlist" "$tokens_wordlist"; do
        [[ -f "$f" ]] && sort -u "$f" -o "$f" 2>/dev/null
    done

    cat "$paths_wordlist" "$params_wordlist" "$keywords_wordlist" "$extensions_wordlist" "$tokens_wordlist" \
        "$tax_dir/wordlist-js-endpoints-$target.txt" \
        "$tax_dir/wordlist-full-paths-$target.txt" 2>/dev/null | \
        sort -u > "$combined_wordlist" 2>/dev/null

    if [[ -f "$SNIPER_TAXONOMY_DIR/taxonomy-paths.txt" ]]; then
        cat "$SNIPER_TAXONOMY_DIR/taxonomy-paths.txt" >> "$combined_wordlist"
    fi
    if [[ -f "$SNIPER_TAXONOMY_DIR/taxonomy-params.txt" ]]; then
        cat "$SNIPER_TAXONOMY_DIR/taxonomy-params.txt" >> "$combined_wordlist"
    fi

    sort -u "$combined_wordlist" -o "$combined_wordlist" 2>/dev/null

    local total
    total=$(wc -l < "$combined_wordlist" 2>/dev/null | tr -d ' ')
    echo -e "$OKGREEN[+]$RESET Taxonomy wordlist generated: $total unique entries"

    {
        echo "=== Taxonomy Wordlist Summary for $target ==="
        echo "Date: $(date)"
        echo "Total entries: $total"
        echo ""
        echo "--- Sources ---"
        for source in $sources; do
            echo "  - $source"
        done
        echo ""
        echo "--- Breakdown ---"
        [[ -f "$paths_wordlist" ]] && echo "Paths: $(wc -l < "$paths_wordlist" | tr -d ' ')"
        [[ -f "$params_wordlist" ]] && echo "Parameters: $(wc -l < "$params_wordlist" | tr -d ' ')"
        [[ -f "$keywords_wordlist" ]] && echo "Keywords: $(wc -l < "$keywords_wordlist" | tr -d ' ')"
        [[ -f "$extensions_wordlist" ]] && echo "Extensions: $(wc -l < "$extensions_wordlist" | tr -d ' ')"
        [[ -f "$tokens_wordlist" ]] && echo "JS Tokens: $(wc -l < "$tokens_wordlist" | tr -d ' ')"
    } > "$combined_taxonomy" 2>/dev/null

    echo -e "$OKGREEN[+]$RESET Taxonomy files in $tax_dir"
}

sniper_taxonomy_generate_full() {
    local target="$1"
    local output_dir="$2"
    sniper_taxonomy_generate "$target" "$output_dir" "spider wayback gau content js headers" 3
}

sniper_taxonomy_apply_wordlist() {
    local target="$1"
    local output_dir="$2"
    local wordlist="$output_dir/taxonomy-$target/wordlist-$target.txt"

    if [[ ! -f "$wordlist" ]]; then
        return
    fi

    if command -v ffuf &>/dev/null; then
        if [[ -f "$output_dir/headers-http-$target.txt" ]]; then
            local port
            port=$(grep -m 1 "http://" "$output_dir/spider-$target.txt" 2>/dev/null | awk -F/ '{print $3}' | awk -F: '{print $2}')
            port="${port:-80}"

            echo -e "$OKBLUE[*]$RESET Running ffuf with taxonomy wordlist against http://$target..."
            ffuf -u "http://$target:$port/FUZZ" -w "$wordlist" \
                -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
                sort -u > "$output_dir/taxonomy-$target/ffuf-results-$target.txt" 2>/dev/null
            echo -e "$OKGREEN[+]$RESET ffuf results: $(wc -l < "$output_dir/taxonomy-$target/ffuf-results-$target.txt" | tr -d ' ')"
        fi
        if [[ -f "$output_dir/headers-https-$target.txt" ]]; then
            local port
            port=$(grep -m 1 "https://" "$output_dir/spider-$target.txt" 2>/dev/null | awk -F/ '{print $3}' | awk -F: '{print $2}')
            port="${port:-443}"

            echo -e "$OKBLUE[*]$RESET Running ffuf with taxonomy wordlist against https://$target..."
            ffuf -u "https://$target:$port/FUZZ" -w "$wordlist" \
                -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
                sort -u >> "$output_dir/taxonomy-$target/ffuf-results-$target.txt" 2>/dev/null
        fi
    fi
}
