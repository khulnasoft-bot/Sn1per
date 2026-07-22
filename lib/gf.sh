SNIPER_GF_PATTERNS_DIR="$INSTALL_DIR/gf_patterns"

sniper_gf_install() {
    if ! command -v gf &>/dev/null; then
        echo -e "$OKBLUE[*]$RESET Installing gf (tomnomnom)..."
        GO111MODULE=on go install -v "github.com/tomnomnom/gf@latest" 2>/dev/null || true
        if [[ -f "$HOME/go/bin/gf" ]]; then
            ln -fs "$HOME/go/bin/gf" /usr/local/bin/gf 2>/dev/null || \
                ln -fs "$HOME/go/bin/gf" /usr/bin/gf 2>/dev/null || true
        fi
    fi
}

sniper_gf_setup_patterns() {
    local gf_dir="$HOME/.gf"
    mkdir -p "$gf_dir" 2>/dev/null || true

    if [[ -d "$SNIPER_GF_PATTERNS_DIR" ]]; then
        cp -f "$SNIPER_GF_PATTERNS_DIR"/*.json "$gf_dir/" 2>/dev/null || true
        echo -e "$OKGREEN[✓]$RESET Installed gf patterns to $gf_dir"
    fi
}

sniper_gf_setup_completion() {
    local gf_source_path="$HOME/go/pkg/mod/github.com/tomnomnom/gf@*/gf-completion.bash"
    local gf_completion
    gf_completion=$(compgen -G "$gf_source_path" 2>/dev/null | head -n 1)

    if [[ -z "$gf_completion" ]]; then
        gf_completion="$HOME/go/src/github.com/tomnomnom/gf/gf-completion.bash"
    fi

    if [[ -f "$gf_completion" ]]; then
        if ! grep -q "gf-completion" "$HOME/.bashrc" 2>/dev/null; then
            echo "source $gf_completion" >> "$HOME/.bashrc"
        fi
    fi
}

sniper_gf_run() {
    local pattern_name="$1"
    local input_file="$2"
    local output_file="$3"

    if [[ ! -f "$input_file" ]]; then
        return
    fi

    if ! command -v gf &>/dev/null; then
        echo -e "$OKRED[!]$RESET gf not installed. Skipping gf analysis."
        return
    fi

    if [[ ! -f "$HOME/.gf/$pattern_name.json" ]]; then
        echo -e "$OKORANGE[!]$RESET gf pattern '$pattern_name' not found. Skipping."
        return
    fi

    grep '?' "$input_file" 2>/dev/null | gf "$pattern_name" > "$output_file" 2>/dev/null
}

sniper_gf_run_all() {
    local input_file="$1"
    local output_dir="$2"
    local target="$3"

    if [[ ! -f "$input_file" ]]; then
        return
    fi

    if ! command -v gf &>/dev/null; then
        echo -e "$OKRED[!]$RESET gf not installed. Skipping gf analysis."
        return
    fi

    local patterns=("xss" "ssrf" "redirect" "rce" "idor" "sqli" "lfi" "ssti" "debug" "parameters" "extensions")

    for pattern in "${patterns[@]}"; do
        local outfile="$output_dir/gf-$pattern-$target.txt"
        sniper_gf_run "$pattern" "$input_file" "$outfile"
        if [[ -s "$outfile" ]]; then
            echo -e "$OKGREEN[+]$RESET gf $pattern: $(wc -l < "$outfile" | tr -d ' ') matches"
        fi
    done
}
