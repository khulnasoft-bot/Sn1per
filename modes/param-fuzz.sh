if [[ $PARAM_FUZZ == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING PARAMETER FUZZING $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/param.sh

    local param_input="$LOOT_DIR/web/spider-$TARGET.txt"
    local param_output="$LOOT_DIR/web"

    if [[ -f "$param_input" ]]; then
        local param_list="$param_output/param-fuzz-$TARGET/param-list-$TARGET.txt"
        mkdir -p "$param_output/param-fuzz-$TARGET" 2>/dev/null || true
        sniper_param_extract "$param_input" "$param_list"

        local param_count
        param_count=$(wc -l < "$param_list" 2>/dev/null | tr -d ' ')
        echo -e "$OKBLUE[*]$RESET Found $param_count unique parameters"

        if command -v ffuf &>/dev/null && [[ $param_count -gt 0 ]]; then
            echo -e "$OKBLUE[*]$RESET Running ffuf parameter fuzzing..."
            while IFS= read -r param; do
                [[ -z "$param" ]] && continue
                local sample_url
                sample_url=$(grep -E "[?&]$param=" "$param_input" 2>/dev/null | head -n 1)
                [[ -z "$sample_url" ]] && continue
                local base_url
                base_url=$(echo "$sample_url" | cut -d'?' -f1)
                local ffuf_out="$param_output/param-fuzz-$TARGET/ffuf-$param-$TARGET.txt"
                ffuf -u "$base_url?$param=FUZZ" -w /usr/share/wordlists/dirb/common.txt \
                    -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s 2>/dev/null | \
                    sort -u > "$ffuf_out" 2>/dev/null &
            done < "$param_list"
            wait
            echo -e "$OKGREEN[+]$RESET Parameter fuzzing complete"
        fi

        local xss_params
        xss_params=$(grep -oP '\b(?:q|s|search|lang|keyword|query|page|view|name|callback|jsonp|id|url|redirect|return)\b' "$param_list" | sort -u)
        if [[ -n "$xss_params" ]]; then
            echo "$xss_params" > "$param_output/param-fuzz-$TARGET/param-xss-interesting-$TARGET.txt"
            echo -e "$OKGREEN[+]$RESET XSS-interesting parameters: $(echo "$xss_params" | wc -l | tr -d ' ')"
        fi

        local sqli_params
        sqli_params=$(grep -oP '\b(?:id|select|report|role|query|user|name|sort|order|search|filter|page|view|delete|update)\b' "$param_list" | sort -u)
        if [[ -n "$sqli_params" ]]; then
            echo "$sqli_params" > "$param_output/param-fuzz-$TARGET/param-sqli-interesting-$TARGET.txt"
            echo -e "$OKGREEN[+]$RESET SQLi-interesting parameters: $(echo "$sqli_params" | wc -l | tr -d ' ')"
        fi
    fi

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED PARAMETER FUZZING COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
