sniper_analyze_fetch_page() {
    local url="$1"
    curl -s -L --connect-timeout 10 --max-time 30 --insecure -D "$url.headers.tmp" "$url" 2>/dev/null
    local rc=$?
    cat "$url.headers.tmp" 2>/dev/null
    rm -f "$url.headers.tmp" 2>/dev/null
    return $rc
}

sniper_analyze_extract_title() {
    local html="$1"
    echo "$html" | grep -oP '<title[^>]*>\K[^<]+' 2>/dev/null | head -n 1
}

sniper_analyze_extract_meta_tags() {
    local html="$1"
    echo "$html" | grep -oP '<meta[^>]+>' 2>/dev/null
}

sniper_analyze_extract_keywords() {
    local file="$1"
    local min_len="${2:-4}"
    tr -c '[:alnum:]' '\n' < "$file" 2>/dev/null | \
        grep -vE '^[0-9]+$' | \
        grep -vE '^.{0,3}$' | \
        grep -viE '^(the|and|for|are|but|not|you|all|can|had|her|was|one|our|out|has|have|from|they|this|that|with|have|will|your|which|their|them|would|about|there|could|should|after|then|some|such|than|into|also|more|these|other|very|just|over|only|each|than|those|being|what|when|where|how|who|why|been|have|does|did|done|get|got|make|made|may|might|shall|must|like|same|part|back|still|well|here|there|both|each|few|more|most|other|some|such|than|that|this|these|those)$' | \
        sort | uniq -c | sort -rn | head -n 200 | awk '{print $2}'
}

sniper_analyze_extract_emails() {
    local file="$1"
    grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null | sort -u
}

sniper_analyze_extract_phones() {
    local file="$1"
    grep -oP '(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}' "$file" 2>/dev/null | sort -u
}

sniper_analyze_extract_urls() {
    local file="$1"
    grep -oE 'https?://[a-zA-Z0-9./?=_,:@&%~#-]+' "$file" 2>/dev/null | sort -u
}

sniper_analyze_extract_social() {
    local file="$1"
    local social="$2"
    case "$social" in
        twitter)
            grep -oP '(?:https?://)?(?:www\.)?twitter\.com/[a-zA-Z0-9_]+' "$file" 2>/dev/null
            ;;
        linkedin)
            grep -oP '(?:https?://)?(?:www\.)?linkedin\.com/(?:company|in)/[a-zA-Z0-9_-]+' "$file" 2>/dev/null
            ;;
        facebook)
            grep -oP '(?:https?://)?(?:www\.)?facebook\.com/[a-zA-Z0-9.]+' "$file" 2>/dev/null
            ;;
        github)
            grep -oP '(?:https?://)?(?:www\.)?github\.com/[a-zA-Z0-9_-]+' "$file" 2>/dev/null
            ;;
        instagram)
            grep -oP '(?:https?://)?(?:www\.)?instagram\.com/[a-zA-Z0-9_.]+' "$file" 2>/dev/null
            ;;
        youtube)
            grep -oP '(?:https?://)?(?:www\.)?youtube\.com/(?:user|channel|c)/[a-zA-Z0-9_-]+' "$file" 2>/dev/null
            ;;
        all)
            sniper_analyze_extract_social "$file" "twitter"
            sniper_analyze_extract_social "$file" "linkedin"
            sniper_analyze_extract_social "$file" "facebook"
            sniper_analyze_extract_social "$file" "github"
            sniper_analyze_extract_social "$file" "instagram"
            sniper_analyze_extract_social "$file" "youtube"
            ;;
    esac | sort -u
}

sniper_analyze_extract_js_vars() {
    local file="$1"
    grep -oP '(?:var|let|const)\s+[a-zA-Z_$][a-zA-Z0-9_$]*' "$file" 2>/dev/null | awk '{print $2}' | sort -u
}

sniper_analyze_extract_js_funcs() {
    local file="$1"
    grep -oP '(?:function\s+[a-zA-Z_$][a-zA-Z0-9_$]*|[a-zA-Z_$][a-zA-Z0-9_$]*\s*[:=]\s*function|async\s+function\s+[a-zA-Z_$][a-zA-Z0-9_$]*|[a-zA-Z_$][a-zA-Z0-9_$]*\s*\([^)]*\)\s*\{)' "$file" 2>/dev/null | \
        grep -oP '[a-zA-Z_$][a-zA-Z0-9_$]*(?=\s*[:=]\s*function|(?=\())' | sort -u
}

sniper_analyze_extract_js_objects() {
    local file="$1"
    grep -oP '[a-zA-Z_$][a-zA-Z0-9_$]*\s*[:=]\s*\{' "$file" 2>/dev/null | sed 's/[=:{ ]//g' | sort -u
}

sniper_analyze_extract_js_props() {
    local file="$1"
    grep -oP '["'\'']?[a-zA-Z_$][a-zA-Z0-9_$]*["'\'']?\s*:' "$file" 2>/dev/null | sed 's/["'\'': ]//g' | sort -u
}

sniper_analyze_extract_api_endpoints() {
    local file="$1"
    grep -oP '["'\'']/[a-zA-Z0-9_/{}.-]+["'\'']' "$file" 2>/dev/null | tr -d '"' | sort -u
    grep -oP '["'\''](?:https?://[^"'\'']+)["'\'']' "$file" 2>/dev/null | tr -d '"' | sort -u
}

sniper_analyze_extract_forms() {
    local html="$1"
    echo "$html" | grep -oP '<form[^>]*>' 2>/dev/null
    echo "$html" | grep -oP '<input[^>]*>' 2>/dev/null
    echo "$html" | grep -oP '<select[^>]*>' 2>/dev/null
    echo "$html" | grep -oP '<textarea[^>]*>' 2>/dev/null
    echo "$html" | grep -oP '<button[^>]*>' 2>/dev/null
}

sniper_analyze_extract_form_actions() {
    local html="$1"
    echo "$html" | grep -oP 'action=["'\'']?\K[^"'\'' >]+' 2>/dev/null | sort -u
}

sniper_analyze_extract_form_inputs() {
    local html="$1"
    echo "$html" | grep -oP '<input[^>]*name=["'\'']?\K[^"'\'' >]+' 2>/dev/null | sort -u
}

sniper_analyze_extract_headings() {
    local html="$1"
    for tag in h1 h2 h3 h4 h5 h6; do
        echo "$html" | grep -oP "<$tag[^>]*>\K[^<]+" 2>/dev/null
    done | sort -u
}

sniper_analyze_extract_json_keys() {
    local file="$1"
    grep -oP '["'\'']?[a-zA-Z_$][a-zA-Z0-9_$]*["'\'']?\s*:' "$file" 2>/dev/null | \
        sed 's/["'\'': ]//g' | sort -u
}

sniper_analyze_extract_json_strings() {
    local file="$1"
    grep -oP '"[^"\\]*(?:\\.[^"\\]*)*"' "$file" 2>/dev/null | \
        grep -vE '^"[0-9]+"$' | \
        grep -vE '^"https?://' | \
        tr -d '"' | sort -u
}

sniper_analyze_detect_tech() {
    local html="$1"
    local headers_file="$2"
    local output=""

    if echo "$html" | grep -qi 'wp-content\|wp-includes\|WordPress'; then
        output="$output WordPress"
    fi
    if echo "$html" | grep -qi 'Joomla\|joomla'; then
        output="$output Joomla"
    fi
    if echo "$html" | grep -qi 'Drupal\|drupal'; then
        output="$output Drupal"
    fi
    if echo "$html" | grep -qi 'Magento\|mage\b'; then
        output="$output Magento"
    fi
    if echo "$html" | grep -qi 'Shopify\|shopify'; then
        output="$output Shopify"
    fi
    if echo "$html" | grep -qi 'react\.js\|react-dom\|React\.createElement\|__NEXT_DATA__'; then
        output="$output React"
    fi
    if echo "$html" | grep -qi 'angular\.js\|ng-app\|ng-app="[^"]*"'; then
        output="$output Angular"
    fi
    if echo "$html" | grep -qi 'vue\.js\|vuejs\|Vue\.'; then
        output="$output Vue"
    fi
    if echo "$html" | grep -qi 'jquery'; then
        output="$output jQuery"
    fi
    if echo "$html" | grep -qi 'bootstrap\.css\|bootstrap\.min\.css'; then
        output="$output Bootstrap"
    fi
    if echo "$html" | grep -qi 'ajax\.googleapis\.com\|cdnjs\.cloudflare\.com\|unpkg\.com\|jsdelivr\.net'; then
        output="$output CDN"
    fi
    if [[ -f "$headers_file" ]]; then
        if grep -qi 'PHP/' "$headers_file"; then
            output="$output PHP"
        fi
        if grep -qi 'ASP\.NET\|X-AspNet\|__VIEWSTATE' "$html"; then
            output="$output ASP.NET"
        fi
        if grep -qi 'nginx/' "$headers_file"; then
            output="$output Nginx"
        fi
        if grep -qi 'Apache/' "$headers_file"; then
            output="$output Apache"
        fi
        if grep -qi 'IIS/' "$headers_file"; then
            output="$output IIS"
        fi
        if grep -qi 'X-Powered-By: Express' "$headers_file" 2>/dev/null; then
            output="$output Express"
        fi
    fi
    echo "$output" | xargs
}

sniper_analyze_page() {
    local url="$1"
    local output_file="$2"
    local html
    html=$(sniper_analyze_fetch_page "$url" 2>/dev/null)

    if [[ -z "$html" ]]; then
        return
    fi

    {
        echo "=== URL Analysis: $url ==="
        echo "Date: $(date)"
        echo ""
        echo "--- Title ---"
        sniper_analyze_extract_title "$html"
        echo ""
        echo "--- Meta Tags ---"
        sniper_analyze_extract_meta_tags "$html"
        echo ""
        echo "--- Headings ---"
        sniper_analyze_extract_headings "$html"
        echo ""
        echo "--- Forms ---"
        sniper_analyze_extract_forms "$html"
        echo ""
        echo "--- Form Actions ---"
        sniper_analyze_extract_form_actions "$html"
        echo ""
        echo "--- Form Inputs ---"
        sniper_analyze_extract_form_inputs "$html"
    } > "$output_file" 2>/dev/null

    echo "$html"
}

sniper_analyze_site() {
    local url="$1"
    local output_dir="$2"
    local target="$3"

    mkdir -p "$output_dir/analysis-$target" 2>/dev/null || true

    local analysis_dir="$output_dir/analysis-$target"
    local html
    html=$(sniper_analyze_fetch_page "$url" 2>/dev/null)

    if [[ -z "$html" ]]; then
        echo -e "$OKORANGE[!]$RESET Failed to fetch $url"
        return
    fi

    echo "$html" > "$analysis_dir/page-html-$target.txt"

    echo -e "$OKBLUE[*]$RESET Extracting metadata..."
    {
        echo "=== Meta Tags ==="
        sniper_analyze_extract_meta_tags "$html"
    } > "$analysis_dir/meta-$target.txt"
    echo -e "$OKGREEN[+]$RESET Meta tags: $(wc -l < "$analysis_dir/meta-$target.txt" | tr -d ' ')"

    echo -e "$OKBLUE[*]$RESET Extracting title..."
    local title
    title=$(sniper_analyze_extract_title "$html")
    echo "$title" > "$analysis_dir/title-$target.txt"
    echo -e "$OKGREEN[+]$RESET Title: $title"

    echo -e "$OKBLUE[*]$RESET Extracting headings..."
    sniper_analyze_extract_headings "$html" > "$analysis_dir/headings-$target.txt" 2>/dev/null
    echo -e "$OKGREEN[+]$RESET Headings: $(wc -l < "$analysis_dir/headings-$target.txt" | tr -d ' ')"

    echo -e "$OKBLUE[*]$RESET Extracting keywords..."
    sniper_analyze_extract_keywords "$analysis_dir/page-html-$target.txt" > "$analysis_dir/keywords-$target.txt" 2>/dev/null
    echo -e "$OKGREEN[+]$RESET Keywords: $(wc -l < "$analysis_dir/keywords-$target.txt" | tr -d ' ')"

    echo -e "$OKBLUE[*]$RESET Extracting emails..."
    sniper_analyze_extract_emails "$analysis_dir/page-html-$target.txt" > "$analysis_dir/emails-$target.txt" 2>/dev/null
    local email_count
    email_count=$(wc -l < "$analysis_dir/emails-$target.txt" | tr -d ' ')
    echo -e "$OKGREEN[+]$RESET Emails: $email_count"

    echo -e "$OKBLUE[*]$RESET Extracting phone numbers..."
    sniper_analyze_extract_phones "$analysis_dir/page-html-$target.txt" > "$analysis_dir/phones-$target.txt" 2>/dev/null

    echo -e "$OKBLUE[*]$RESET Extracting forms..."
    sniper_analyze_extract_forms "$html" > "$analysis_dir/forms-$target.txt" 2>/dev/null
    echo -e "$OKGREEN[+]$RESET Form elements: $(wc -l < "$analysis_dir/forms-$target.txt" | tr -d ' ')"

    echo -e "$OKBLUE[*]$RESET Extracting form inputs..."
    sniper_analyze_extract_form_inputs "$html" > "$analysis_dir/inputs-$target.txt" 2>/dev/null
    echo -e "$OKGREEN[+]$RESET Form inputs: $(wc -l < "$analysis_dir/inputs-$target.txt" | tr -d ' ')"

    echo -e "$OKBLUE[*]$RESET Detecting technologies..."
    local tech
    tech=$(sniper_analyze_detect_tech "$html" "/dev/null")
    echo "$tech" > "$analysis_dir/tech-$target.txt"
    echo -e "$OKGREEN[+]$RESET Technologies: $tech"

    echo -e "$OKBLUE[*]$RESET Extracting social media links..."
    sniper_analyze_extract_social "$analysis_dir/page-html-$target.txt" "all" > "$analysis_dir/social-$target.txt" 2>/dev/null
    echo -e "$OKGREEN[+]$RESET Social links: $(wc -l < "$analysis_dir/social-$target.txt" | tr -d ' ')"

    echo -e "$OKGREEN[+]$RESET Analysis saved to $analysis_dir"
}

sniper_analyze_js_files() {
    local js_dir="$1"
    local output_dir="$2"
    local target="$3"

    if [[ ! -d "$js_dir" ]]; then
        return
    fi

    local js_analysis_dir="$output_dir/js-analysis-$target"
    mkdir -p "$js_analysis_dir" 2>/dev/null || true

    find "$js_dir" -name "*.js" 2>/dev/null | while IFS= read -r js_file; do
        echo -e "$OKBLUE[*]$RESET Analyzing $(basename "$js_file")..."

        sniper_analyze_extract_js_vars "$js_file" >> "$js_analysis_dir/js-vars-$target.txt" 2>/dev/null
        sniper_analyze_extract_js_funcs "$js_file" >> "$js_analysis_dir/js-funcs-$target.txt" 2>/dev/null
        sniper_analyze_extract_js_objects "$js_file" >> "$js_analysis_dir/js-objects-$target.txt" 2>/dev/null
        sniper_analyze_extract_js_props "$js_file" >> "$js_analysis_dir/js-props-$target.txt" 2>/dev/null
        sniper_analyze_extract_api_endpoints "$js_file" >> "$js_analysis_dir/js-endpoints-$target.txt" 2>/dev/null
    done

    for f in "$js_analysis_dir"/js-*-"$target.txt"; do
        [[ -f "$f" ]] && sort -u "$f" -o "$f"
    done

    echo -e "$OKGREEN[+]$RESET JS analysis saved to $js_analysis_dir"
}

sniper_analyze_all_content() {
    local target="$1"
    local output_dir="$2"

    local analysis_dir="$output_dir/analysis-$target"
    mkdir -p "$analysis_dir" 2>/dev/null || true

    local url_list="$output_dir/spider-$target.txt"
    if [[ ! -f "$url_list" ]]; then
        url_list="$output_dir/waybackurls-$target.txt"
    fi
    if [[ ! -f "$url_list" ]]; then
        echo -e "$OKORANGE[!]$RESET No URL list found for content analysis"
        return
    fi

    echo -e "$OKBLUE[*]$RESET Analyzing site content for $target..."
    local head_url
    head_url=$(head -n 1 "$url_list" 2>/dev/null)
    if [[ -n "$head_url" ]]; then
        sniper_analyze_site "$head_url" "$output_dir" "$target"
    fi

    local js_dir="$output_dir/javascript/$target"
    if [[ -d "$js_dir" ]]; then
        sniper_analyze_js_files "$js_dir" "$output_dir" "$target"
    fi

    local fff_dir="$output_dir/fff-output-$target"
    if [[ -d "$fff_dir" ]]; then
        echo -e "$OKBLUE[*]$RESET Analyzing fff-fetched content..."
        find "$fff_dir" -name "*.body" 2>/dev/null | while IFS= read -r body_file; do
            sniper_analyze_extract_emails "$body_file" >> "$analysis_dir/emails-$target.txt" 2>/dev/null
            sniper_analyze_extract_phones "$body_file" >> "$analysis_dir/phones-$target.txt" 2>/dev/null
            sniper_analyze_extract_social "$body_file" "all" >> "$analysis_dir/social-$target.txt" 2>/dev/null
            sniper_analyze_extract_keywords "$body_file" >> "$analysis_dir/keywords-all-$target.txt" 2>/dev/null
        done

        for f in "$analysis_dir"/emails-*.txt "$analysis_dir"/phones-*.txt "$analysis_dir"/social-*.txt "$analysis_dir"/keywords-all-*.txt; do
            [[ -f "$f" ]] && sort -u "$f" -o "$f" 2>/dev/null
        done
    fi

    echo -e "$OKGREEN[+]$RESET Content analysis complete for $target"
}
