if [[ $FFF_FETCH == "1" ]]; then
    if command -v fff &>/dev/null; then
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
        echo -e "$OKRED RUNNING FFF BULK URL FETCH $RESET"
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"

        source $INSTALL_DIR/lib/fff.sh

        local fff_input="$LOOT_DIR/web/spider-$TARGET.txt"
        local fff_output="$LOOT_DIR/web"

        if [[ -f "$fff_input" ]]; then
            sniper_fff_fetch_all "$fff_input" "$fff_output" "$TARGET"
        fi

        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
        echo -e "$OKRED FFF BULK URL FETCH COMPLETE $RESET"
        echo -e "${OKGREEN}====================================================================================${RESET}•x${OKGREEN}[`date +"%Y-%m-%d](%H:%M)"`${RESET}x•"
    fi
fi
