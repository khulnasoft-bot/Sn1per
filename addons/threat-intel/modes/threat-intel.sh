MODE_NAME="threat-intel"
MODE_DESCRIPTION="Enrich target with external threat intelligence feeds"
MODE_REQUIRED_VARS=(TARGET LOOT_DIR)
MODE_REQUIRED_TOOLS=(curl)

THREAT_INTEL_SOURCES="${THREAT_INTEL_SOURCES:-otx,virustotal,threatfox}"

mode_validate() {
  [[ -n "$TARGET" ]] || { log_fail "TARGET not set"; return 1; }
}

mode_init() {
  mkdir -p "$LOOT_DIR/osint/threat-intel"
}

mode_run() {
  local outdir="$LOOT_DIR/osint/threat-intel"
  local target="$TARGET"

  section_banner
  section_header "THREAT INTELLIGENCE ENRICHMENT: $target"

  IFS=',' read -ra sources <<< "$THREAT_INTEL_SOURCES"
  for src in "${sources[@]}"; do
    case "$src" in
      otx)
        section_header "Querying AlienVault OTX..."
        if [[ -n "${OTX_API_KEY:-}" ]]; then
          curl -s -H "X-OTX-API-KEY: $OTX_API_KEY" "https://otx.alienvault.com/api/v1/indicators/domain/$target" > "$outdir/otx-$target.json" 2>/dev/null
          sniper_json_gron_grep "$outdir/otx-$target.json" "pulse" > "$outdir/otx-$target-pulses.txt" 2>/dev/null
        else
          log_warn "OTX_API_KEY not set — skipping AlienVault OTX"
        fi
        ;;
      virustotal)
        section_header "Querying VirusTotal..."
        if [[ -n "${VIRUSTOTAL_API_KEY:-}" ]]; then
          curl -s "https://www.virustotal.com/api/v3/domains/$target" -H "x-apikey: $VIRUSTOTAL_API_KEY" > "$outdir/virustotal-$target.json" 2>/dev/null
          python3 -c "
import json,sys
try:
    with open('$outdir/virustotal-$target.json') as f:
        d=json.load(f)
    stats=d.get('data',{}).get('attributes',{}).get('last_analysis_stats',{})
    malicious=stats.get('malicious',0)
    if malicious>0:
        print(f'VT: {malicious} malicious detections for $target')
except: pass
" 2>/dev/null | tee "$outdir/virustotal-$target-summary.txt"
        else
          log_warn "VIRUSTOTAL_API_KEY not set — skipping VirusTotal"
        fi
        ;;
      threatfox)
        section_header "Querying ThreatFox..."
        if [[ -n "${THREATFOX_API_KEY:-}" ]]; then
          curl -s -X POST "https://threatfox-api.abuse.ch/api/v1/" -d "{\"query\":\"search_ioc\",\"search_term\":\"$target\"}" > "$outdir/threatfox-$target.json" 2>/dev/null
        else
          log_warn "THREATFOX_API_KEY not set — skipping ThreatFox"
        fi
        ;;
    esac
  done

  section_header "Threat intelligence enrichment complete for $target"
}

mode_cleanup() {
  log_info "Threat intel scan complete for $TARGET"
}

mode_execute
