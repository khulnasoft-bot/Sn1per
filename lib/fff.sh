sniper_fff_install() {
    if ! command -v fff &>/dev/null; then
        echo -e "$OKBLUE[*]$RESET Installing fff (tomnomnom)..."
        GO111MODULE=on go install -v "github.com/tomnomnom/fff@latest" 2>/dev/null || true
        if [[ -f "$HOME/go/bin/fff" ]]; then
            ln -fs "$HOME/go/bin/fff" /usr/local/bin/fff 2>/dev/null || \
                ln -fs "$HOME/go/bin/fff" /usr/bin/fff 2>/dev/null || true
        fi
    fi
}

sniper_fff_fetch() {
    local input_file="$1"
    local output_dir="$2"
    local target="$3"
    local delay="${4:-50}"

    if [[ ! -f "$input_file" ]]; then
        return
    fi

    if ! command -v fff &>/dev/null; then
        echo -e "$OKRED[!]$RESET fff not installed. Skipping bulk fetch."
        return
    fi

    local fff_out="$output_dir/fff-output-$target"
    mkdir -p "$fff_out" 2>/dev/null || true

    echo -e "$OKBLUE[*]$RESET Fetching $(wc -l < "$input_file" | tr -d ' ') URLs with fff..."

    grep '?' "$input_file" 2>/dev/null | fff -o "$fff_out" -S -d "$delay" -k 2>/dev/null | tee "$fff_out/index-$target.txt"

    local total_fetched
    total_fetched=$(find "$fff_out" -name "*.body" 2>/dev/null | wc -l)
    echo -e "$OKGREEN[+]$RESET fff saved $total_fetched responses to $fff_out"
}

sniper_fff_fetch_all() {
    local input_file="$1"
    local output_dir="$2"
    local target="$3"
    local delay="${4:-50}"

    if [[ ! -f "$input_file" ]]; then
        return
    fi

    if ! command -v fff &>/dev/null; then
        echo -e "$OKRED[!]$RESET fff not installed. Skipping bulk fetch."
        return
    fi

    local fff_out="$output_dir/fff-output-$target"
    mkdir -p "$fff_out" 2>/dev/null || true

    fff -o "$fff_out" -S -d "$delay" -k < "$input_file" 2>/dev/null | tee "$fff_out/index-$target.txt"

    local total_fetched
    total_fetched=$(find "$fff_out" -name "*.body" 2>/dev/null | wc -l)
    echo -e "$OKGREEN[+]$RESET fff saved $total_fetched responses to $fff_out"
}

sniper_fff_save_status() {
    local input_file="$1"
    local output_dir="$2"
    local target="$3"
    local status_codes="$4"
    local delay="${5:-50}"

    if [[ ! -f "$input_file" ]]; then
        return
    fi

    if ! command -v fff &>/dev/null; then
        echo -e "$OKRED[!]$RESET fff not installed."
        return
    fi

    local fff_out="$output_dir/fff-status-$target"
    mkdir -p "$fff_out" 2>/dev/null || true

    local save_flags=""
    for code in $status_codes; do
        save_flags="$save_flags -s $code"
    done

    fff -o "$fff_out" $save_flags -d "$delay" < "$input_file" 2>/dev/null | tee "$fff_out/index-$target.txt"

    local total_fetched
    total_fetched=$(find "$fff_out" -name "*.body" 2>/dev/null | wc -l)
    echo -e "$OKGREEN[+]$RESET fff saved $total_fetched status-filtered responses"
}
