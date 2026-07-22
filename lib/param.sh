sniper_param_extract() {
    local input_file="$1"
    local output="$2"
    grep '?' "$input_file" 2>/dev/null | grep -oE '[?&][a-zA-Z0-9_\-]+=' | tr -d '?&=' | sort -u > "$output"
}

sniper_param_extract_full() {
    local input_file="$1"
    local output="$2"
    grep '?' "$input_file" 2>/dev/null | awk -F'?' '{print $2}' | tr '&' '\n' | grep '=' | cut -d'=' -f1 | sort -u > "$output"
}

sniper_param_get_urls_with_param() {
    local input_file="$1"
    local param_name="$2"
    grep -E "[?&]$param_name=" "$input_file" 2>/dev/null | head -n 1
}

sniper_param_fuzz_ffuf() {
    local url_list="$1"
    local output_dir="$2"
    local target="$3"

    if ! command -v ffuf &>/dev/null; then
        echo -e "$OKRED[!]$RESET ffuf not installed. Skipping parameter fuzzing."
        return
    fi

    mkdir -p "$output_dir/param-fuzz-$target" 2>/dev/null || true

    local param_list="$output_dir/param-fuzz-$target/param-list-$target.txt"
    sniper_param_extract "$url_list" "$param_list"

    local param_count
    param_count=$(wc -l < "$param_list" 2>/dev/null | tr -d ' ')
    if [[ -z "$param_count" || "$param_count" -eq 0 ]]; then
        return
    fi

    echo -e "$OKBLUE[*]$RESET Fuzzing $param_count unique parameters with ffuf..."

    while IFS= read -r param; do
        [[ -z "$param" ]] && continue
        local sample_url
        sample_url=$(grep -E "[?&]$param=" "$url_list" 2>/dev/null | head -n 1)
        [[ -z "$sample_url" ]] && continue

        local base_url
        base_url=$(echo "$sample_url" | cut -d'?' -f1)

        local output_file="$output_dir/param-fuzz-$target/ffuf-$param-$target.txt"
        ffuf -u "$base_url?$param=FUZZ" -w /dev/stdin -mr "error|warning|notice|root|admin|select|union|etc/passwd" -o "$output_file" -of json -t 50 -s 2>/dev/null < /dev/null &
    done < "$param_list"
    wait
}

sniper_param_fuzz_injectx() {
    local url_list="$1"
    local output_dir="$2"
    local target="$3"

    local param_list="$output_dir/param-fuzz-$target/param-list-$target.txt"
    sniper_param_extract "$url_list" "$param_list"

    while IFS= read -r param; do
        [[ -z "$param" ]] && continue
        local sample_url
        sample_url=$(grep -E "[?&]$param=" "$url_list" 2>/dev/null | head -n 1)
        [[ -z "$sample_url" ]] && continue

        if command -v injectx.py &>/dev/null; then
            injectx.py -u "$sample_url" -vy 2>/dev/null | tee -a "$output_dir/param-fuzz-$target/injectx-$target-http.raw"
        fi
    done < "$param_list"
}
