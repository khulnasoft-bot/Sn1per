sniper_dir_ffuf() {
    local target="$1"
    local port="$2"
    local protocol="$3"
    local wordlist="$4"
    local output_dir="$5"
    local extensions="${6:-htm,html,asp,aspx,php,jsp,js,txt}"
    local exclude_codes="${7:-400,403,404,405,406,429,500,502,503,504}"

    if ! command -v ffuf &>/dev/null; then
        echo -e "$OKRED[!]$RESET ffuf not installed."
        return
    fi

    local url="$protocol://$target"
    if [[ -n "$port" ]]; then
        url="$protocol://$target:$port"
    fi

    local label
    if [[ -n "$port" ]]; then
        label="$target-$port"
    else
        label="$target"
    fi

    local output_file="$output_dir/dir-ffuf-$label.txt"
    local json_output="$output_dir/dir-ffuf-$label.json"

    echo -e "$OKBLUE[*]$RESET Running ffuf directory scan against $url ..."

    ffuf -u "$url/FUZZ" -w "$wordlist" -e ".$extensions" -fc "$exclude_codes" \
        -t 100 -o "$json_output" -of json -s 2>/dev/null > /dev/null

    if [[ -f "$json_output" ]]; then
        python3 -c "
import json,sys
try:
    with open('$json_output') as f:
        data = json.load(f)
    results = data.get('results',[])
    for r in results:
        print(f\"{r.get('status','')} {r.get('url','')} [{r.get('length',0)}]\")
    print(f\"Total: {len(results)}\")
except: pass
" 2>/dev/null > "$output_file"
    fi
}

sniper_dir_ffuf_recursive() {
    local target="$1"
    local port="$2"
    local protocol="$3"
    local wordlist="$4"
    local output_dir="$5"
    local depth="${6:-2}"

    if ! command -v ffuf &>/dev/null; then
        echo -e "$OKRED[!]$RESET ffuf not installed."
        return
    fi

    local url="$protocol://$target"
    if [[ -n "$port" ]]; then
        url="$protocol://$target:$port"
    fi

    local label
    if [[ -n "$port" ]]; then
        label="$target-$port"
    else
        label="$target"
    fi

    local output_file="$output_dir/dir-ffuf-recursive-$label.txt"

    echo -e "$OKBLUE[*]$RESET Running recursive ffuf directory scan against $url (depth $depth)..."

    ffuf -u "$url/FUZZ" -w "$wordlist" -recursion -recursion-depth "$depth" \
        -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
        sort -u > "$output_file"
}

sniper_dir_ffuf_vhost() {
    local target="$1"
    local wordlist="$2"
    local output_dir="$3"
    local label="$4"

    if ! command -v ffuf &>/dev/null; then
        return
    fi

    local output_file="$output_dir/vhosts-ffuf-$label.txt"

    echo -e "$OKBLUE[*]$RESET Running ffuf vhost discovery against $target..."

    ffuf -u "http://$target" -w "$wordlist" -H "Host: FUZZ.$target" \
        -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
        sort -u > "$output_file"

    ffuf -u "https://$target" -w "$wordlist" -H "Host: FUZZ.$target" \
        -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
        sort -u >> "$output_file"
}
