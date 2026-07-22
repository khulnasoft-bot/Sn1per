log_info()    { printf "${OKBLUE}[*]${RESET} %s\n" "$*"; }
log_ok()      { printf "${OKBLUE}[*]${RESET} %s ${OKBLUE}[${OKGREEN}OK${OKBLUE}]${RESET}\n" "$*"; }
log_fail()    { printf "${OKBLUE}[*]${RESET} %s ${OKBLUE}[${OKRED}FAIL${OKBLUE}]${RESET}\n" "$*"; }
log_warn()    { printf "${OKBLUE}[${OKRED}i${OKBLUE}]${RESET} %s\n" "$*"; }

section_banner() {
  printf "${OKGREEN}%s${RESET}•x${OKGREEN}[%s]${RESET}x•\n" \
    "====================================================================================" \
    "$(date +"%Y-%m-%d](%H:%M)")"
}

section_header() {
  printf "${OKRED} %s ${RESET}\n" "$*"
}

notify_slack() {
  [[ "$SLACK_NOTIFICATIONS" != "1" ]] && return
  /bin/bash "$INSTALL_DIR/bin/slack.sh" "$1"
}

notify_slack_file() {
  [[ "$SLACK_NOTIFICATIONS" != "1" ]] && return
  /bin/bash "$INSTALL_DIR/bin/slack.sh" postfile "$1"
}
