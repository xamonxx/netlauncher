# lib/runner.sh - Modern execution runner, PTY capture, output parser, dan post-run viewer

LAST_RUN_RC=0
LAST_RUN_LOG=""

runner_is_interactive_tool() {
  local id="$1" cmd="$2"
  case "$id" in
    msfconsole|kismet|wifite|hackingtool|hackingtool-classic) return 0 ;;
  esac
  case "$cmd" in
    *"less "*|*"man "*|*"nano "*|*"vi "*|*"vim "*|msfconsole*|kismet*|wifite*|hackingtool|hackingtool\ --classic*)
      return 0 ;;
  esac
  return 1
}

runner_clean_ansi_stream() {
  awk '
    NR==1 && /^Script started on / { next }
    /^Script done on / { next }
    {
      gsub(/\r+$/, "")
      n = split($0, parts, "\r")
      print parts[n]
    }
  '
}

runner_strip_ansi() {
  runner_clean_ansi_stream | sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g; s/\x1B\][^\a\x1B]*(\a|\x1B\\)//g'
}

runner_infer_parser() {
  local id="$1" cmd="$2" hint="${3:-}"
  if [ -n "$hint" ] && [ "$hint" != "auto" ]; then
    printf '%s' "$hint"
    return 0
  fi
  case "$id" in
    ping) printf 'ping' ;;
    nmap|masscan) printf 'nmap' ;;
    curl|wget|httpx) printf 'http_headers' ;;
    openssl) printf 'tls' ;;
    dig|nslookup) printf 'dns' ;;
    ss|netstat|lsof) printf 'sockets' ;;
    ffuf|gobuster|feroxbuster|dirb|wfuzz) printf 'fuzz' ;;
    nuclei|nikto) printf 'vuln' ;;
    ip-addr|ip-route|iw-dev|nmcli|ethtool) printf 'net' ;;
    tcpdump|tshark) printf 'capture' ;;
    *)
      case "$cmd" in
        *nmap\ *) printf 'nmap' ;;
        *openssl\ *s_client*) printf 'tls' ;;
        *curl\ *|*httpx-toolkit*) printf 'http_headers' ;;
        *dig\ *|*nslookup\ *) printf 'dns' ;;
        *ss\ *|*lsof\ *) printf 'sockets' ;;
        *ping\ *) printf 'ping' ;;
        *) printf 'generic' ;;
      esac
      ;;
  esac
}

runner_parse_highlights() {
  local id="$1" plain_file="$2" cmd="$3" hint="${4:-}" parser
  [ -s "$plain_file" ] || { printf '  %s(tidak ada output teks)%s\n' "$C_MUTED" "$C_RESET"; return 0; }
  parser="$(runner_infer_parser "$id" "$cmd" "$hint")"

  case "$parser" in
    ping)
      local stats rtt
      stats="$(grep -E 'packets transmitted|packet loss' "$plain_file" | tail -n 1 || true)"
      rtt="$(grep -E 'rtt min/avg/max|round-trip' "$plain_file" | tail -n 1 || true)"
      [ -n "$stats" ] && printf '  %s• Paket:%s %s\n' "$C_PRIMARY" "$C_RESET" "$stats"
      [ -n "$rtt" ] && printf '  %s• Latensi:%s %s\n' "$C_PRIMARY" "$C_RESET" "$rtt"
      if [ -z "$stats" ] && [ -z "$rtt" ]; then
        head -n 5 "$plain_file" | sed 's/^/  /'
      fi
      ;;

    nmap)
      local hosts open_ports
      hosts="$(grep -E 'Nmap scan report for ' "$plain_file" || true)"
      open_ports="$(grep -E '^[0-9]+/(tcp|udp)[[:space:]]+open' "$plain_file" || true)"
      if [ -n "$hosts" ]; then
        printf '  %s• Host terdeteksi:%s %s\n' "$C_PRIMARY" "$C_RESET" "$(printf '%s\n' "$hosts" | wc -l | tr -d ' ')"
      fi
      if [ -n "$open_ports" ]; then
        printf '  %s• Port terbuka (%s):%s\n' "$C_OK" "$(printf '%s\n' "$open_ports" | wc -l | tr -d ' ')" "$C_RESET"
        printf '%s\n' "$open_ports" | head -n 15 | sed 's/^/    /'
      else
        printf '  %s• Tidak ada port open yang tercatat di output.%s\n' "$C_MUTED" "$C_RESET"
      fi
      ;;

    http_headers)
      local statuses server loc h val
      statuses="$(grep -iE '^HTTP/[0-9.]+' "$plain_file" | tr -d '\r' || true)"
      server="$(grep -iE '^server:' "$plain_file" | head -n 1 | tr -d '\r' || true)"
      loc="$(grep -iE '^location:' "$plain_file" | head -n 1 | tr -d '\r' || true)"
      [ -n "$statuses" ] && printf '  %s• Status HTTP:%s %s\n' "$C_PRIMARY" "$C_RESET" "$(printf '%s' "$statuses" | tr '\n' ' ')"
      [ -n "$server" ] && printf '  %s• %s%s\n' "$C_MUTED" "$server" "$C_RESET"
      [ -n "$loc" ] && printf '  %s• %s%s\n' "$C_MUTED" "$loc" "$C_RESET"
      if grep -qiE '^HTTP/[0-9.]+' "$plain_file"; then
        printf '  %s• Checklist Security Headers:%s\n' "$C_ACCENT" "$C_RESET"
        for h in Strict-Transport-Security Content-Security-Policy X-Frame-Options X-Content-Type-Options Referrer-Policy Permissions-Policy; do
          val="$(grep -iE "^${h}:" "$plain_file" | head -n 1 | cut -d: -f2- | sed 's/^[[:space:]]*//' || true)"
          if [ -n "$val" ]; then
            printf '    %s✓%s %-26s %s%s%s\n' "$C_OK" "$C_RESET" "$h" "$C_MUTED" "${val:0:55}" "$C_RESET"
          else
            printf '    %s!%s %-26s %s(tidak ditemukan)%s\n' "$C_WARN" "$C_RESET" "$h" "$C_MUTED" "$C_RESET"
          fi
        done
      else
        head -n 8 "$plain_file" | sed 's/^/  /'
      fi
      ;;

    tls)
      local subj issuer not_after san proto cipher exp_epoch now_epoch days_left
      subj="$(grep -E '^[[:space:]]*subject=' "$plain_file" | head -n 1 || true)"
      issuer="$(grep -E '^[[:space:]]*issuer=' "$plain_file" | head -n 1 || true)"
      not_after="$(grep -E '^[[:space:]]*notAfter=' "$plain_file" | head -n 1 | cut -d= -f2- || true)"
      san="$(grep -A1 'Subject Alternative Name' "$plain_file" | tail -n 1 | sed 's/^[[:space:]]*//' || true)"
      proto="$(grep -E 'Protocol[[:space:]]*:' "$plain_file" | head -n 1 || true)"
      cipher="$(grep -E 'Cipher[[:space:]]*:' "$plain_file" | head -n 1 || true)"
      [ -n "$subj" ] && printf '  %s• %s%s\n' "$C_PRIMARY" "$subj" "$C_RESET"
      [ -n "$issuer" ] && printf '  %s• %s%s\n' "$C_MUTED" "$issuer" "$C_RESET"
      if [ -n "$not_after" ]; then
        exp_epoch="$(date -d "$not_after" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date +%s)"
        if [ "$exp_epoch" -gt 0 ]; then
          days_left=$(( (exp_epoch - now_epoch) / 86400 ))
          if [ "$days_left" -lt 0 ]; then
            printf '  %s✗ Kedaluwarsa:%s %s (%s hari lalu)\n' "$C_ERR" "$C_RESET" "$not_after" "$((-days_left))"
          elif [ "$days_left" -le 30 ]; then
            printf '  %s! Masa berlaku:%s %s (sisa %s hari)\n' "$C_WARN" "$C_RESET" "$not_after" "$days_left"
          else
            printf '  %s✓ Masa berlaku:%s %s (sisa %s hari)\n' "$C_OK" "$C_RESET" "$not_after" "$days_left"
          fi
        else
          printf '  %s• notAfter:%s %s\n' "$C_PRIMARY" "$C_RESET" "$not_after"
        fi
      fi
      [ -n "$san" ] && [ "$san" != "X509v3 Subject Alternative Name:" ] && printf '  %s• SAN:%s %s\n' "$C_MUTED" "$C_RESET" "${san:0:90}"
      [ -n "$proto" ] && printf '  %s• %s%s\n' "$C_MUTED" "$proto" "$C_RESET"
      [ -n "$cipher" ] && printf '  %s• %s%s\n' "$C_MUTED" "$cipher" "$C_RESET"
      ;;

    dns)
      local rec_count
      rec_count="$(grep -cvE '^(;|#|$)' "$plain_file" 2>/dev/null || echo 0)"
      printf '  %s• Baris record DNS:%s %s\n' "$C_PRIMARY" "$C_RESET" "$rec_count"
      grep -vE '^(;|#|$)' "$plain_file" | head -n 12 | sed 's/^/    /' || true
      ;;

    sockets)
      local listen_n exposed
      listen_n="$(grep -cE 'LISTEN|UNCONN' "$plain_file" 2>/dev/null || echo 0)"
      exposed="$(grep -E 'LISTEN' "$plain_file" | grep -E '0\.0\.0\.0:|\[::\]:|\*:' | head -n 10 || true)"
      printf '  %s• Socket LISTEN/UNCONN:%s %s\n' "$C_PRIMARY" "$C_RESET" "$listen_n"
      if [ -n "$exposed" ]; then
        printf '  %s! Port listen di semua interface (0.0.0.0 / ::):%s\n' "$C_WARN" "$C_RESET"
        printf '%s\n' "$exposed" | sed 's/^/    /'
      fi
      ;;

    fuzz)
      local hits
      hits="$(grep -E 'Status:|200|204|301|302|307|403|Found' "$plain_file" | head -n 12 || true)"
      if [ -n "$hits" ]; then
        printf '  %s• Cuplikan temuan:%s\n' "$C_OK" "$C_RESET"
        printf '%s\n' "$hits" | sed 's/^/    /'
      else
        tail -n 8 "$plain_file" | sed 's/^/  /'
      fi
      ;;

    vuln)
      local findings
      findings="$(grep -iE '\[(critical|high|medium|low|info)\]|\+ ' "$plain_file" | head -n 12 || true)"
      if [ -n "$findings" ]; then
        printf '  %s• Temuan terdeteksi:%s\n' "$C_WARN" "$C_RESET"
        printf '%s\n' "$findings" | sed 's/^/    /'
      else
        tail -n 8 "$plain_file" | sed 's/^/  /'
      fi
      ;;

    net)
      grep -vE '^[[:space:]]*$' "$plain_file" | head -n 12 | sed 's/^/  /' || true
      ;;

    capture)
      local pkt_line
      pkt_line="$(grep -E 'packets captured|packets received|^[[:space:]]*[0-9]+' "$plain_file" | tail -n 5 || true)"
      [ -n "$pkt_line" ] && printf '%s\n' "$pkt_line" | sed 's/^/  /'
      ;;

    *)
      local err_n
      err_n="$(grep -ciE 'error|failed|denied|refused|timeout|fatal|invalid' "$plain_file" 2>/dev/null || echo 0)"
      if [ "$err_n" -gt 0 ]; then
        printf '  %s! Baris indikasi error/peringatan:%s %s\n' "$C_WARN" "$C_RESET" "$err_n"
        grep -iE 'error|failed|denied|refused|timeout|fatal|invalid' "$plain_file" | head -n 5 | sed 's/^/    /' || true
      else
        printf '  %s• Cuplikan output:%s\n' "$C_MUTED" "$C_RESET"
        grep -vE '^[[:space:]]*$' "$plain_file" | head -n 6 | sed 's/^/    /' || true
      fi
      ;;
  esac
}

runner_suggest_next_steps() {
  local id="$1" plain_file="$2" cmd="$3" target="" domain=""
  [ -s "$plain_file" ] || return 0

  if [ -n "${WS_DOMAIN:-}" ]; then domain="$WS_DOMAIN"; fi
  if [ -n "${WS_TARGET:-}" ]; then target="$WS_TARGET"; fi

  case "$id" in
    nmap)
      local host
      host="$(awk '/Nmap scan report for /{print $NF; exit}' "$plain_file" | tr -d '()')"
      [ -n "$host" ] || host="$target"
      if grep -qE '^(80|8080)/tcp[[:space:]]+open' "$plain_file"; then
        printf 'Audit HTTP Headers (curl)\tcurl\tcurl -ILsS --max-time 10 http://%s\n' "${host:-127.0.0.1}"
      fi
      if grep -qE '^(443|8443)/tcp[[:space:]]+open' "$plain_file"; then
        printf 'Audit HTTPS Headers (curl)\tcurl\tcurl -ILsS --max-time 10 https://%s\n' "${host:-127.0.0.1}"
        printf 'Inspeksi Sertifikat TLS (openssl)\topenssl\techo | openssl s_client -servername %s -connect %s:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName\n' "${host:-example.com}" "${host:-example.com}"
      fi
      if grep -qE '^53/(tcp|udp)[[:space:]]+open' "$plain_file"; then
        printf 'Cek versi DNS server (dig)\tdig\tdig @%s version.bind chaos txt +short\n' "${host:-127.0.0.1}"
      fi
      ;;
    dig|nslookup)
      local ip
      ip="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$plain_file" | head -n 1 || true)"
      if [ -n "$ip" ]; then
        printf 'Reverse DNS (PTR) untuk %s\tdig\tdig -x %s +short\n' "$ip" "$ip"
        printf 'WHOIS IP %s\twhois\twhois %s | head -n 30\n' "$ip" "$ip"
      fi
      if [ -n "$domain" ]; then
        printf 'Inspeksi Sertifikat TLS %s\topenssl\techo | openssl s_client -servername %s -connect %s:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates\n' "$domain" "$domain" "$domain"
      fi
      ;;
    ss|netstat)
      printf 'Lihat proses pemilik socket (lsof)\tlsof\tlsof -i -P -n | head -n 40\n'
      ;;
    openssl)
      if [ -n "$domain" ]; then
        printf 'Audit HTTP Security Headers %s\tcurl\tcurl -sIL --max-time 10 https://%s\n' "$domain" "$domain"
      fi
      ;;
    curl|httpx)
      if [ -n "$domain" ]; then
        printf 'Inspeksi Sertifikat TLS %s\topenssl\techo | openssl s_client -servername %s -connect %s:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates\n' "$domain" "$domain" "$domain"
      fi
      ;;
  esac
}

runner_render_summary() {
  local id="$1" label="$2" cmd="$3" rc="$4" dur="$5" plain_file="$6" log_file="$7" hint="${8:-}"
  local lines size badge
  lines="$(wc -l < "$plain_file" 2>/dev/null | tr -d ' ')"
  size="$(du -h "$plain_file" 2>/dev/null | awk '{print $1}')"
  [ -n "$size" ] || size="0B"
  if [ "$rc" -eq 0 ]; then
    badge="$(ui_badge ok "✓ BERHASIL (exit 0)")"
  else
    badge="$(ui_badge err "✗ GAGAL (exit $rc)")"
  fi

  printf '\n%s╭─ Ringkasan Eksekusi ─────────────────────────────────────────╮%s\n' "$C_PRIMARY" "$C_RESET"
  printf '%s│%s  %s%s%s  %b\n' "$C_PRIMARY" "$C_RESET" "$C_BOLD$C_WHITE" "$label" "$C_RESET" "$badge"
  printf '%s│%s  %sDurasi:%s %ss │ %sOutput:%s %s baris (%s) │ %sLog:%s %s\n' \
    "$C_PRIMARY" "$C_RESET" "$C_MUTED" "$C_RESET" "$dur" \
    "$C_MUTED" "$C_RESET" "$lines" "$size" \
    "$C_MUTED" "$C_RESET" "$(basename "$log_file")"
  printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_PRIMARY" "$C_RESET"
  runner_parse_highlights "$id" "$plain_file" "$cmd" "$hint"
}

runner_export_markdown() {
  local id="$1" label="$2" cmd="$3" rc="$4" dur="$5" plain_file="$6" hint="${7:-}"
  local safe_id out
  safe_id="${id//[^a-zA-Z0-9._-]/_}"
  mkdir -p "$REPORT_DIR"
  out="$REPORT_DIR/hasil-$(date +%Y%m%d-%H%M%S)-${safe_id}.md"
  {
    echo "# Laporan Eksekusi: $label"
    echo
    echo "- **Tanggal:** $(date -Is)"
    echo "- **Tool ID:** \`$id\`"
    echo "- **Perintah:** \`$cmd\`"
    echo "- **Exit Code:** $rc"
    echo "- **Durasi:** ${dur}s"
    echo
    echo "## Ringkasan Temuan"
    echo
    echo '```text'
    FORCE_COLOR=0 runner_parse_highlights "$id" "$plain_file" "$cmd" "$hint" | sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g'
    echo '```'
    echo
    echo "## Output Lengkap"
    echo
    echo '```text'
    cat "$plain_file"
    echo '```'
  } > "$out"
  chmod 600 "$out" 2>/dev/null || true
  ok "Laporan diekspor ke: $out"
}

runner_filter_output_fzf() {
  local ansi_file="$1" label="$2"
  [ -s "$ansi_file" ] || { warn "Output kosong."; pause; return 0; }
  nl -ba "$ansi_file" | ui_fzf \
    --prompt='  Filter Output ▸ ' \
    --ghost='Ketik kata kunci (open, 200, error, TLS, IP)...' \
    --header="Filter Output: $label" \
    --header-first \
    --header-label=' Output Inspector ' \
    --footer='Ketik untuk filter │ Esc: Kembali' \
    --footer-border=line >/dev/null || true
}

runner_post_menu() {
  local id="$1" label="$2" mode="$3" sudo_flag="$4" cmd="$5" rc="$6" dur="$7"
  local ansi_file="$8" plain_file="$9" log_file="${10}" hint="${11:-}"
  local next_file menu_file sel action next_sel next_id next_cmd next_label

  next_file="$(mktemp)"
  runner_suggest_next_steps "$id" "$plain_file" "$cmd" > "$next_file" || true

  while true; do
    menu_file="$(mktemp)"
    {
      printf '%s✓%s  Selesai & Kembali\tdone\n' "$C_OK" "$C_RESET"
      printf '%s🔍%s Filter & Cari Baris Output (fzf)\tfilter\n' "$C_PRIMARY" "$C_RESET"
      printf '%s📄%s Buka Output Lengkap di Pager (less -R)\tpager\n' "$C_CYAN" "$C_RESET"
      printf '%s📊%s Lihat Ringkasan & Temuan Lengkap\tsummary\n' "$C_ACCENT" "$C_RESET"
      if [ -s "$next_file" ]; then
        printf '%s⚡%s Saran Langkah Berikutnya (%s opsi)\tnext\n' "$C_WARN" "$C_RESET" "$(wc -l < "$next_file" | tr -d ' ')"
      fi
      printf '%s⧉%s  Salin Output ke Clipboard\tcopy\n' "$C_CYAN" "$C_RESET"
      printf '%s📝%s Ekspor ke Laporan Markdown (~/laporan/)\texport\n' "$C_GREEN" "$C_RESET"
      printf '%s↻%s  Jalankan Ulang Perintah\trerun\n' "$C_YELLOW" "$C_RESET"
    } > "$menu_file"

    sel="$(ui_fzf \
      --prompt='  Pasca-Eksekusi ▸ ' \
      --ghost='Pilih aksi untuk hasil eksekusi...' \
      --header="$label │ exit=$rc │ ${dur}s │ $(basename "$log_file")" \
      --header-first \
      --header-label=' Hasil Eksekusi ' \
      --list-label=' Aksi Output ' \
      --preview="$SELF --preview-log $(printf '%q' "$log_file")" \
      --preview-window='right:58%:wrap' \
      --preview-label=' Pratinjau Log ' \
      --footer='Enter: Pilih │ Esc: Kembali' \
      --footer-border=line \
      --delimiter=$'\t' --with-nth=1 < "$menu_file")"
    rm -f "$menu_file"
    [ -n "$sel" ] || break
    action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"

    case "$action" in
      done|"") break ;;
      filter) runner_filter_output_fzf "$ansi_file" "$label" ;;
      pager)
        if have less; then less -R "$ansi_file"; else cat "$plain_file"; pause; fi
        ;;
      summary)
        clear 2>/dev/null || true
        runner_render_summary "$id" "$label" "$cmd" "$rc" "$dur" "$plain_file" "$log_file" "$hint"
        pause
        ;;
      next)
        next_sel="$(awk -F'\t' '{printf "⚡ %-36s \033[2m$ %s\033[0m\t%s\t%s\t%s\n", $1, $3, $2, $3, $1}' "$next_file" | \
          ui_fzf \
            --prompt='  Langkah Berikutnya ▸ ' \
            --header="Rekomendasi lanjutan dari hasil $label" \
            --header-first \
            --delimiter=$'\t' --with-nth=1)"
        if [ -n "$next_sel" ]; then
          next_id="$(printf '%s\n' "$next_sel" | awk -F'\t' '{print $2}')"
          next_cmd="$(printf '%s\n' "$next_sel" | awk -F'\t' '{print $3}')"
          next_label="$(printf '%s\n' "$next_sel" | awk -F'\t' '{print $4}')"
          if confirm_authorized_action "$next_id" "$next_cmd" "0"; then
            runner_exec "$next_id" "$next_label" "term" "0" "$next_cmd"
          fi
        fi
        ;;
      copy)
        local clip_text
        clip_text="$(head -c 524288 "$plain_file")"
        if copy_to_clipboard "$clip_text"; then
          ok "Output disalin ke clipboard."
        else
          warn "Clipboard tidak tersedia. Log tersimpan di: $log_file"
        fi
        pause
        ;;
      export)
        runner_export_markdown "$id" "$label" "$cmd" "$rc" "$dur" "$plain_file" "$hint"
        pause
        ;;
      rerun)
        rm -f "$next_file"
        runner_exec "$id" "$label" "$mode" "$sudo_flag" "$cmd" "$hint"
        return $?
        ;;
    esac
  done
  rm -f "$next_file"
}

runner_exec() {
  local id="$1" label="$2" mode="$3" sudo_flag="$4" cmd="$5" hint="${6:-}" no_post="${7:-0}"
  local safe_id log_file start_ts end_ts dur rc raw_tmp ansi_tmp plain_tmp lines ws_lbl

  safe_id="${id//[^a-zA-Z0-9._-]/_}"
  LAST_RUN_RC=0
  LAST_RUN_LOG=""

  ui_card_header "Eksekusi: $label" "$cmd"
  ws_lbl="$(workspace_active_label 2>/dev/null || true)"
  [ -n "$ws_lbl" ] && printf '  %sWorkspace:%s %s\n' "$C_ACCENT" "$C_RESET" "$ws_lbl"

  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Perintah tidak dijalankan."
    [ "$no_post" = "1" ] || pause
    return 0
  fi

  if [ "$sudo_flag" = "1" ]; then
    warn "Tool ini meminta sudo; Anda akan diminta password di terminal."
  fi

  printf '%s\t%s\t%s\n' "$(date -Is)" "$id" "$cmd" >> "$HISTORY_FILE"
  log_file="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-${safe_id}.log"
  LAST_RUN_LOG="$log_file"
  {
    printf '# %s\n# tool: %s\n# id: %s\n# command: %s\n# user: %s\n# host: %s\n' \
      "$(date -Is)" "$label" "$id" "$cmd" "${USER:-unknown}" "$(hostname 2>/dev/null || echo '-')"
    [ -n "$ws_lbl" ] && printf '# workspace: %s\n' "$ws_lbl"
    printf '\n'
  } > "$log_file"
  chmod 600 "$log_file" 2>/dev/null || true

  start_ts="$(date +%s)"
  if [ "$mode" = "gui" ]; then
    if have setsid; then
      setsid bash -c "$cmd" >/dev/null 2>&1 &
    else
      nohup bash -c "$cmd" >/dev/null 2>&1 &
    fi
    printf '# mode=gui\n' >> "$log_file"
    ok "Dijalankan di background (GUI)."
    printf '%sLog:%s %s\n' "$C_MUTED" "$C_RESET" "$log_file"
    [ "$no_post" = "1" ] || pause
    return 0
  fi

  if runner_is_interactive_tool "$id" "$cmd"; then
    bash -c "$cmd"
    rc=$?
    end_ts="$(date +%s)"
    dur=$((end_ts - start_ts))
    printf '# interactive=1\n# exit=%s duration=%ss\n' "$rc" "$dur" >> "$log_file"
    stty sane 2>/dev/null || true
    LAST_RUN_RC="$rc"
    printf '\n'
    if [ "$rc" -eq 0 ]; then
      ok "Selesai (exit 0 · ${dur}s)"
    else
      warn "Selesai dengan exit code $rc (${dur}s)"
    fi
    printf '%sLog:%s %s\n' "$C_MUTED" "$C_RESET" "$log_file"
    [ "$no_post" = "1" ] || pause
    return "$rc"
  fi

  raw_tmp="$(mktemp)"
  ansi_tmp="$(mktemp)"
  plain_tmp="$(mktemp)"

  printf '\n%s╭─ Output Langsung ────────────────────────────────────────────╮%s\n' "$C_MUTED" "$C_RESET"
  if [ -t 0 ] && [ -t 1 ] && have script; then
    (
      export NETLAUNCHER_RUN_CMD="$cmd"
      script -qefc 'bash -c "$NETLAUNCHER_RUN_CMD"' "$raw_tmp"
    )
    rc=$?
  else
    bash -c "$cmd" 2>&1 | tee "$raw_tmp"
    rc=${PIPESTATUS[0]}
  fi
  stty sane 2>/dev/null || true
  printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_MUTED" "$C_RESET"

  end_ts="$(date +%s)"
  dur=$((end_ts - start_ts))
  LAST_RUN_RC="$rc"

  runner_clean_ansi_stream < "$raw_tmp" > "$ansi_tmp"
  runner_strip_ansi < "$raw_tmp" > "$plain_tmp"
  lines="$(wc -l < "$plain_tmp" 2>/dev/null | tr -d ' ')"

  {
    cat "$plain_tmp"
    printf '\n# exit=%s duration=%ss lines=%s\n' "$rc" "$dur" "$lines"
  } >> "$log_file"
  chmod 600 "$log_file" 2>/dev/null || true

  runner_render_summary "$id" "$label" "$cmd" "$rc" "$dur" "$plain_tmp" "$log_file" "$hint"

  if [ -t 0 ] && [ -t 1 ] && [ "$no_post" != "1" ] && [ "${NETLAUNCHER_NO_POST_MENU:-0}" != "1" ]; then
    runner_post_menu "$id" "$label" "$mode" "$sudo_flag" "$cmd" "$rc" "$dur" "$ansi_tmp" "$plain_tmp" "$log_file" "$hint"
  fi

  rm -f "$raw_tmp" "$ansi_tmp" "$plain_tmp"
  return "$rc"
}
