if [[ $GF_SEARCH == "1" ]]; then
    if command -v gf &>/dev/null; then
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
        echo -e "$OKRED RUNNING GF STATIC ANALYSIS $RESET"
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

        source $INSTALL_DIR/lib/gf.sh

        local gf_input="$LOOT_DIR/web/spider-$TARGET.txt"
        local gf_output="$LOOT_DIR/web"

        if [[ -f "$gf_input" ]]; then
            sniper_gf_run_all "$gf_input" "$gf_output" "$TARGET"
        fi

        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
        echo -e "$OKRED GF STATIC ANALYSIS COMPLETE $RESET"
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    fi
fi
