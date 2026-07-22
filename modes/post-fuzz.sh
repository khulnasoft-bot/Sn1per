if [[ $POST_FUZZ == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING POST REQUEST FUZZING $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    local post_output="$LOOT_DIR/web/post-fuzz-$TARGET"
    mkdir -p "$post_output" 2>/dev/null || true

    local fff_output_dir="$LOOT_DIR/web/fff-output-$TARGET"
    local forms_found=0

    if [[ -d "$fff_output_dir" ]]; then
        echo -e "$OKBLUE[*]$RESET Searching for HTML forms in fff output..."

        find "$fff_output_dir" -name "*.body" 2>/dev/null | while IFS= read -r body_file; do
            local html_content
            html_content=$(cat "$body_file" 2>/dev/null)

            local forms
            forms=$(echo "$html_content" | grep -oP '<form[^>]*action=["'\'']?\K[^"'\'' >]+' 2>/dev/null)
            if [[ -n "$forms" ]]; then
                echo "$body_file:" >> "$post_output/forms-$TARGET.txt"
                while IFS= read -r form_action; do
                    echo "  action: $form_action" >> "$post_output/forms-$TARGET.txt"
                    forms_found=$((forms_found + 1))
                done <<< "$forms"

                local form_inputs
                form_inputs=$(echo "$html_content" | grep -oP '<input[^>]*name=["'\'' ]?\K[^"'\'' >]+' 2>/dev/null)
                if [[ -n "$form_inputs" ]]; then
                    while IFS= read -r input_name; do
                        echo "    input: $input_name" >> "$post_output/forms-$TARGET.txt"
                    done <<< "$form_inputs"
                fi

                local form_textareas
                form_textareas=$(echo "$html_content" | grep -oP '<textarea[^>]*name=["'\'' ]?\K[^"'\'' >]+' 2>/dev/null)
                if [[ -n "$form_textareas" ]]; then
                    while IFS= read -r ta_name; do
                        echo "    textarea: $ta_name" >> "$post_output/forms-$TARGET.txt"
                    done <<< "$form_textareas"
                fi
            fi
        done

        echo -e "$OKGREEN[+]$RESET Forms found: $forms_found"
    fi

    if command -v ffuf &>/dev/null; then
        local param_list="$LOOT_DIR/web/param-fuzz-$TARGET/param-list-$TARGET.txt"
        if [[ -f "$param_list" ]]; then
            echo -e "$OKBLUE[*]$RESET Running POST parameter fuzzing with ffuf..."

            while IFS= read -r param; do
                [[ -z "$param" ]] && continue
                local sample_url
                sample_url=$(grep -E "[?&]$param=" "$LOOT_DIR/web/spider-$TARGET.txt" 2>/dev/null | head -n 1)
                [[ -z "$sample_url" ]] && continue
                local base_url
                base_url=$(echo "$sample_url" | cut -d'?' -f1)

                ffuf -u "$base_url" -w /dev/stdin -X POST -d "$param=FUZZ" \
                    -fc 400,403,404,405,406,429,500,502,503,504 -t 50 -s \
                    -o "$post_output/ffuf-post-$param-$TARGET.json" -of json 2>/dev/null &
            done < "$param_list"
            wait
        fi
    fi

    local websource_files
    websource_files=$(find "$LOOT_DIR/web" -name "websource-*$TARGET*" 2>/dev/null)
    if [[ -n "$websource_files" ]]; then
        while IFS= read -r ws_file; do
            local ws_forms
            ws_forms=$(grep -oP '<form[^>]*action=["'\'' ]?\K[^"'\'' >]+' "$ws_file" 2>/dev/null)
            if [[ -n "$ws_forms" ]]; then
                echo "$ws_file:" >> "$post_output/forms-$TARGET.txt"
                while IFS= read -r form_action; do
                    echo "  action: $form_action" >> "$post_output/forms-$TARGET.txt"
                done <<< "$ws_forms"
            fi
        done <<< "$websource_files"
    fi

    local form_count
    form_count=$(grep -c "action:" "$post_output/forms-$TARGET.txt" 2>/dev/null | tr -d ' ')
    echo -e "$OKGREEN[+]$RESET Total forms discovered: ${form_count:-0}"
    echo -e "$OKBLUE[*]$RESET POST fuzz results: $post_output"

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED POST REQUEST FUZZING COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
