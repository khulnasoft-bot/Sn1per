sniper_usage() {
  logo
  local star
  printf -v star "$OKBLUE[*]$RESET"
  cat <<EOHELP

$star NORMAL MODE
 sniper -t <TARGET>

$star SPECIFY CUSTOM CONFIG FILE
 sniper -c /full/path/to/sniper.conf -t <TARGET> -m <MODE> -w <WORKSPACE>

$star NORMAL MODE + OSINT + RECON
 sniper -t <TARGET> -o -re

$star STEALTH MODE + OSINT + RECON
 sniper -t <TARGET> -m stealth -o -re

$star DISCOVER MODE
 sniper -t <CIDR> -m discover -w <WORKSPACE_ALIAS>

$star SCAN ONLY SPECIFIC PORT
 sniper -t <TARGET> -m port -p <portnum>

$star FULLPORTONLY SCAN MODE
 sniper -t <TARGET> -fp

$star WEB MODE - PORT 80 + 443 ONLY!
 sniper -t <TARGET> -m web

$star HTTP WEB PORT MODE
 sniper -t <TARGET> -m webporthttp -p <port>

$star HTTPS WEB PORT MODE
 sniper -t <TARGET> -m webporthttps -p <port>

$star HTTP WEBSCAN MODE
 sniper -t <TARGET> -m webscan

$star ENABLE BRUTEFORCE
 sniper -t <TARGET> -b

$star AIRSTRIKE MODE
 sniper -f targets.txt -m airstrike

$star NUKE MODE WITH TARGET LIST, BRUTEFORCE ENABLED, FULLPORTSCAN ENABLED, OSINT ENABLED, RECON ENABLED, WORKSPACE & LOOT ENABLED
 sniper -f targets.txt -m nuke -w <WORKSPACE_ALIAS>

$star MASS PORT SCAN MODE
 sniper -f targets.txt -m massportscan -w <WORKSPACE_ALIAS>

$star MASS WEB SCAN MODE
 sniper -f targets.txt -m massweb -w <WORKSPACE_ALIAS>

$star MASS WEBSCAN SCAN MODE
 sniper -f targets.txt -m masswebscan -w <WORKSPACE_ALIAS>

$star MASS VULN SCAN MODE
 sniper -f targets.txt -m massvulnscan -w <WORKSPACE_ALIAS>

$star PORT SCAN MODE
 sniper -t <TARGET> -m port -p <PORT_NUM>

$star LIST WORKSPACES
 sniper --list

$star DELETE WORKSPACE
 sniper -w <WORKSPACE_ALIAS> -d

$star DELETE HOST FROM WORKSPACE
 sniper -w <WORKSPACE_ALIAS> -t <TARGET> -dh

$star DELETE TASKS FROM WORKSPACE
 sniper -w <WORKSPACE_ALIAS> -t <TARGET> -dt

$star GET SNIPER SCAN STATUS
 sniper --status

$star LOOT REIMPORT FUNCTION
 sniper -w <WORKSPACE_ALIAS> --reimport

$star LOOT REIMPORTALL FUNCTION
 sniper -w <WORKSPACE_ALIAS> --reimportall

$star LOOT REIMPORT FUNCTION
 sniper -w <WORKSPACE_ALIAS> --reload

$star LOOT EXPORT FUNCTION
 sniper -w <WORKSPACE_ALIAS> --export

$star SCHEDULED SCANS
 sniper -w <WORKSPACE_ALIAS> -s daily|weekly|monthly

$star USE A CUSTOM CONFIG
 sniper -c /path/to/sniper.conf -t <TARGET> -w <WORKSPACE_ALIAS>

$star UPDATE SNIPER
 sniper -u|--update

$star VERSION
 sniper -v|--version

$star ADD-ONS
 --addon-list                              list installed add-ons
 --addon-install <name>                    install add-on dependencies
 --apk <path>                              reverse APK (requires reverse-apk add-on)
 --threat-intel                            enable threat intel enrichment
 --bruteforce                              enable enhanced brute-force scan
 --nessus                                  launch Nessus scan
 --api                                     start REST API server
 --api-port <port>                         API server port (default: 8080)
 sniper -m command-inject -t <TARGET>      command injection scan
 sniper -m threat-intel -t <TARGET>        threat intel enrichment
 sniper -m portscan-massive -t <TARGET>    masscan all ports
 sniper -m portscan-quick -t <TARGET>      quick port scan
 sniper -m fuzz-directory -t <TARGET>      directory fuzzing
 sniper -m fuzz-parameters -t <TARGET>     parameter fuzzing
 sniper -m fuzz-vhost -t <TARGET>          vhost fuzzing
 sniper -m nessus-scan -t <TARGET>         Nessus scan
 sniper -m masspwn -f targets.txt          mass exploitation
 sniper --apk app.apk                      reverse APK
 sniper --api                              start API server

EOHELP
  exit
}

logo() {
  echo -e "$OKRED                ____               $RESET"
  echo -e "$OKRED    _________  /  _/___  ___  _____$RESET"
  echo -e "$OKRED   / ___/ __ \ / // __ \/ _ \/ ___/$RESET"
  echo -e "$OKRED  (__  ) / / // // /_/ /  __/ /    $RESET"
  echo -e "$OKRED /____/_/ /_/___/ .___/\___/_/     $RESET"
  echo -e "$OKRED               /_/                 $RESET"
  echo ""
  echo -e "$OKORANGE + -- --=[ https://sn1persecurity.com$RESET"
  echo -e "$OKORANGE + -- --=[ Sn1per v$VER by @xer0dayz$RESET"
  echo ""
}

sniper_status() {
  watch -n 1 -c 'ps -ef | egrep "sniper|slurp|hydra|ruby|python|dirsearch|amass|nmap|metasploit|curl|wget|nikto" && echo "NETWORK CONNECTIONS..." && netstat -an | egrep "TIME_WAIT|EST"'
}

sniper_detect_scan_type() {
  if [[ ${TARGET:0:1} =~ $REGEX ]]; then
    echo "IP"
  else
    echo "DOMAIN"
  fi
}

sniper_parse_args() {
  CONFIG=""; TARGET=""; MODE=""; PORT=""; FILE=""
  WORKSPACE=""; WORKSPACE_DIR=""
  AUTO_BRUTE="0"; FULLNMAPSCAN="0"; OSINT="0"; RECON="0"
  REIMPORT="0"; REIMPORT_ALL="0"; RELOAD="0"
  REPORT="1"; LOOT="1"; NOLOOT="0"; UPDATE="0"
  APK_PATH=""

  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -h|--help)    sniper_usage ;;
      -v|--version) logo; exit ;;
      -c|--config)  CONFIG="$2"
                    echo -e "$OKBLUE[*]$RESET Creating backup of existing config to /root/.sniper.conf.bak..."
                    cp -f /root/.sniper.conf /root/.sniper.conf.bak
                    echo -e "$OKBLUE[*]$RESET Copying $CONFIG to /root/.sniper.conf..."
                    cp -f "$CONFIG" /root/.sniper.conf 2>/dev/null
                    _sniper_dos2unix /root/.sniper.conf
                    source /root/.sniper.conf
                    sleep 1; shift 2 ;;
      -t)           TARGET="$2"; shift 2 ;;
      -b)           AUTO_BRUTE="1"; shift ;;
      -fp|--fullportscan) FULLNMAPSCAN="1"; shift ;;
      -o|--osint)   OSINT="1"; shift ;;
      -re|--recon)  RECON="1"; shift ;;
      -m)           MODE="$2"; shift 2 ;;
      -p)           PORT="$2"; shift 2 ;;
      -f|--file)    FILE="$(realpath "$2")"; shift 2 ;;
      -ri|--reimport)   REIMPORT="1"; shift ;;
      -ria|--reimportall) REIMPORT_ALL="1"; shift ;;
      -rl|--reload) RELOAD="1"; shift ;;
      -n|--noreport) REPORT="0"; shift ;;
      -nl|--noloot) LOOT="0"; NOLOOT="1"; shift ;;
      -w)           WORKSPACE="$(echo "$2" | tr / -)"
                    WORKSPACE_DIR="$INSTALL_DIR/loot/workspace/$WORKSPACE"; shift 2 ;;
      -s|--schedule)
                    [[ -z "$WORKSPACE" ]] && { echo "Set workspace via -w"; exit 1; }
                    case "$2" in
                      daily|weekly|monthly)
                        vim "$WORKSPACE_DIR/scans/scheduled/$2.sh"
                        cat "$WORKSPACE_DIR/scans/scheduled/"*.sh; exit 0 ;;
                      *) echo "Specify daily, weekly, or monthly"; exit 1 ;;
                    esac; shift 2 ;;
      -d|--delete)  logo
                    echo "Remove $WORKSPACE? (Hit Ctrl+C to exit): $INSTALL_DIR/loot/workspace/$WORKSPACE/"
                    read ANS
                    rm -Rf "$INSTALL_DIR/loot/workspace/$WORKSPACE/"
                    echo "Removed $WORKSPACE."
                    sniper -w default --reimport; exit ;;
      -dh|--delete-host)
                    echo "Removing $TARGET from $WORKSPACE"
                    sed -i "/$TARGET/d" "$WORKSPACE_DIR/domains/"* "$WORKSPACE_DIR/reports/host-table-report.csv" 2>/dev/null
                    rm -f "$WORKSPACE_DIR/screenshots/$TARGET"*.jpg \
                          "$WORKSPACE_DIR/nmap/dns-$TARGET.txt" \
                          "$WORKSPACE_DIR/nmap/ports-$TARGET.txt" \
                          "$WORKSPACE_DIR/web/title-"*-"$TARGET.txt" \
                          "$WORKSPACE_DIR/web/headers-"*-"$TARGET.txt" \
                          "$WORKSPACE_DIR/vulnerabilities/sc0pe-$TARGET-"*.txt \
                          "$WORKSPACE_DIR/vulnerabilities/vulnerability-report-$TARGET.txt" \
                          "$WORKSPACE_DIR/vulnerabilities/vulnerability-risk-$TARGET.txt" 2>/dev/null
                    exit ;;
      -dt|--delete-task)
                    echo "Removing running $TARGET tasks from $WORKSPACE"
                    rm -f "$WORKSPACE_DIR/scans/running_$TARGET"_*.txt
                    ls -lh "$LOOT_DIR/scans/running_"*.txt 2>/dev/null | wc -l > "$WORKSPACE_DIR/scans/tasks-running.txt" 2>/dev/null
                    ps -ef | grep "$TARGET\|sniper"
                    ps -ef | grep "sniper" | awk '{print $2}' | xargs kill -9 2>/dev/null
                    exit ;;
      --list)       logo
                    ls -l "$INSTALL_DIR/loot/workspace/"
                    echo ""
                    echo "cd $INSTALL_DIR/loot/workspace/"
                    if [[ -f "$LOOT_DIR/sniper-report.html" ]]; then
                      ${BROWSER:-firefox} "$INSTALL_DIR/loot/workspace/sniper-report.html" &>/dev/null &
                    else
                      ${BROWSER:-firefox} "$INSTALL_DIR/loot/workspace/" &>/dev/null &
                    fi
                    exit ;;
      --export)     [[ -z "$WORKSPACE" ]] && { echo "Set workspace via -w"; exit 1; }
                    echo "Archiving $WORKSPACE to $INSTALL_DIR/loot/$WORKSPACE.tar"
                    cd "$INSTALL_DIR/loot/workspace/" && tar -cvf "../$WORKSPACE.tar" "$WORKSPACE"
                    cp -Rf "$WORKSPACE" "${WORKSPACE}_$(date +%Y-%m-%d)"
                    echo "Done!"; exit ;;
      --status)     sniper_status; exit ;;
      -u|--update)  UPDATE="1"; sniper_update; exit ;;
      --addon-list)  logo
                     echo -e "$OKBLUE[*]$RESET Installed add-ons:"
                     sniper_addon_list "$INSTALL_DIR/addons"
                     echo ""
                     echo -e "  Disable an add-on: set ${OKGREEN}ADDON_<NAME>_ENABLED=0$RESET in config"
                     exit ;;
      --addon-install)
                     local a_name="$2"
                     if [[ -z "$a_name" ]]; then
                       echo "Usage: sniper --addon-install <name>"
                       echo "Available:"
                       sniper_addon_list "$INSTALL_DIR/addons"
                       exit 1
                     fi
                     sniper_addon_install "$a_name"
                     exit ;;
      --apk)         APK_PATH="$2"; MODE="reverse-apk"; shift 2 ;;
      --threat-intel) THREAT_INTEL_CHECK="1"; MODE="${MODE:-threat-intel}" ;;
      --bruteforce)  MODE="${MODE:-bruteforce-enhanced}" ;;
      --nessus)      MODE="${MODE:-nessus-scan}" ;;
      --api)         MODE="api-server"; shift ;;
      --api-port)    API_PORT="$2"; shift 2 ;;
      *)            echo "Unknown option $1"; exit 1 ;;
    esac
  done
  set -- "${POSITIONAL[@]}"

  [[ -n "$TARGET" && -z "$WORKSPACE" ]] && WORKSPACE="$TARGET"
  if [[ -z "$TARGET" && -z "$WORKSPACE" ]]; then
    logo
    echo "You need to specify a target or workspace to use. Type sniper --help for command usage."
    exit 1
  fi
}
