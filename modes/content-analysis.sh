if [[ $CONTENT_ANALYSIS == "1" ]]; then
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED RUNNING SITE CONTENT ANALYSIS $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

    source $INSTALL_DIR/lib/analyze.sh

    local analysis_output="$LOOT_DIR/web"

    if [[ -n "$TARGET" ]]; then
        mkdir -p "$analysis_output" 2>/dev/null || true
        sniper_analyze_all_content "$TARGET" "$analysis_output"

        local analysis_dir="$analysis_output/analysis-$TARGET"
        if [[ -d "$analysis_dir" ]]; then
            echo -e "${OKGREEN}====================================================================================${RESET}"
            echo -e "$OKRED ANALYSIS SUMMARY $RESET"
            echo -e "${OKGREEN}====================================================================================${RESET}"
            for f in "$analysis_dir"/*.txt; do
                [[ ! -f "$f" ]] && continue
                local name
                name=$(basename "$f" .txt | sed "s/-$TARGET//")
                local count
                count=$(wc -l < "$f" | tr -d ' ')
                echo -e "$OKGREEN[+]$RESET $name: $count entries"
            done

            local analysis_spider="$analysis_output/spider-$TARGET.txt"
            local analysis_wayback="$analysis_output/waybackurls-$TARGET.txt"

            local tech_file="$analysis_dir/tech-$TARGET.txt"
            if [[ -f "$tech_file" ]]; then
                local tech
                tech=$(cat "$tech_file")
                echo -e "$OKGREEN[+]$RESET Detected tech: $tech"
            fi
        fi
    fi

    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    echo -e "$OKRED SITE CONTENT ANALYSIS COMPLETE $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
fi
