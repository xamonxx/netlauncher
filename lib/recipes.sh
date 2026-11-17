# lib/recipes.sh - Resep otomasi aman dan pengelola custom automation scripts

recipe_log_init() {
  local name="$1" log
  log="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-$name.log"
  printf '# %s | recipe: %s\n# user: %s | host: %s\n\n' \
    "$(date -Is)" "$name" "${USER:-unknown}" "$(hostname 2>/dev/null || echo '-')" > "$log"
  printf '%s\t%s\t%s\n' "$(date -Is)" "recipe:$name" "netlauncher recipe $name" >> "$HISTORY_FILE"
  printf '%s' "$log"
}

recipe_cek_koneksi() {
  local log gw
  ui_card_header "Resep: Cek Koneksi" "Gateway, Internet, DNS, dan HTTP Latency"
  gw="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: ping -c 4 ${gw:-<gateway>}, ping -c 4 1.1.1.1, dig +short A example.com, curl -IsS https://example.com"
    pause
    return 0
  fi
  log="$(recipe_log_init cek-koneksi)"
  {
    echo "== Cek Koneksi =="
    echo "Gateway: ${gw:--}"
  } | tee -a "$log"

  ui_progress 1 4 "Ping gateway (${gw:--})..."
  if [ -n "$gw" ] && have ping; then
    { echo; echo "-- ping gateway --"; ping -c 4 "$gw"; } 2>&1 | tee -a "$log"
  fi

  ui_progress 2 4 "Ping internet (1.1.1.1)..."
  if have ping; then
    { echo; echo "-- ping 1.1.1.1 --"; ping -c 4 1.1.1.1; } 2>&1 | tee -a "$log"
  fi

  ui_progress 3 4 "Query DNS (example.com)..."
  if have dig; then
    { echo; echo "-- DNS example.com --"; dig +short A example.com; } 2>&1 | tee -a "$log"
  fi

  ui_progress 4 4 "Cek HTTP & timing (https://example.com)..."
  if have curl; then
    {
      echo; echo "-- HTTP example.com --"
      curl -IsS --max-time 8 https://example.com | head -n 5
      curl -o /dev/null -sS --max-time 8 -w "Timing: DNS=%{time_namelookup}s Connect=%{time_connect}s TLS=%{time_appconnect}s Total=%{time_total}s\n" https://example.com
    } 2>&1 | tee -a "$log"
  fi

  echo; ok "Log: $log"; pause
}

recipe_info_jaringan() {
  local log
  smart_net_context
  ui_card_header "Resep: Info Jaringan" "Interface, Subnet, Route, WiFi, Socket, DNS"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: ip -brief addr, ip route, iw dev, ss -tulpn, cat /etc/resolv.conf"
    pause
    return 0
  fi
  log="$(recipe_log_init info-jaringan)"
  {
    echo "== Info Jaringan =="
    echo "Host: $NET_HOST | Iface: $NET_IFACE ($NET_IFACE_TYPE) | IP: $NET_CIDR | GW: $NET_GW | DNS: $NET_DNS"
    [ -n "$NET_SSID" ] && echo "WiFi SSID: $NET_SSID"
    echo; echo "-- ip -brief addr --"; ip -brief addr
    echo; echo "-- ip route --"; ip route
    echo; echo "-- iw dev --"; if have iw; then iw dev; else echo "iw tidak tersedia"; fi
    echo; echo "-- ss -tulpn --"; ss -tulpn
    echo; echo "-- resolv.conf --"; cat /etc/resolv.conf 2>/dev/null
  } 2>&1 | tee -a "$log"
  echo; ok "Log: $log"; pause
}

recipe_dns() {
  local log domain t
  if [ -t 0 ]; then
    domain="$(smart_prompt_placeholder "DOMAIN" "Pilih atau ketik domain untuk audit DNS")" || { warn "Dibatalkan."; return 0; }
  else
    read -r -p "Domain: " domain || true
  fi
  [ -n "$domain" ] || { warn "Dibatalkan."; return 0; }
  have dig || { err "dig belum terpasang."; pause; return 1; }
  ui_card_header "Resep: Audit DNS" "Domain: $domain"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: dig +short {A,AAAA,MX,NS,TXT,SOA} $domain, dig +short TXT _dmarc.$domain, whois $domain"
    pause
    return 0
  fi
  log="$(recipe_log_init dns)"
  {
    echo "== DNS: $domain =="
    for t in A AAAA MX NS TXT SOA; do
      echo; echo "-- $t --"; dig +short "$t" "$domain"
    done
    echo; echo "-- DMARC (_dmarc.$domain) --"; dig +short TXT "_dmarc.$domain"
    if have whois; then
      echo; echo "-- WHOIS Ringkas --"
      whois "$domain" 2>/dev/null | grep -iE 'domain name|registrar|creation|expir|name server' | head -n 15 || true
    fi
  } 2>&1 | tee -a "$log"
  echo; ok "Log: $log"; pause
}

recipe_audit_web() {
  local log url domain
  if [ -t 0 ]; then
    url="$(smart_prompt_placeholder "URL" "Pilih atau ketik URL target berizin")" || { warn "Dibatalkan."; return 0; }
  else
    read -r -p "URL: " url || true
  fi
  [ -n "$url" ] || { warn "Dibatalkan."; return 0; }
  domain="${url#https://}"; domain="${domain#http://}"; domain="${domain%%/*}"; domain="${domain%%:*}"
  ui_card_header "Resep: Audit Web & TLS (Pasif)" "$url"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: curl -sIL $url, openssl s_client -connect $domain:443, dig +short A/AAAA $domain, whatweb -a 1 $url"
    pause
    return 0
  fi
  log="$(recipe_log_init audit-web)"

  ui_progress 1 4 "Memeriksa header HTTP & security headers..."
  if have curl; then
    {
      echo "== Audit Web: $url =="
      echo; echo "-- HTTP Headers & Security Headers --"
      curl -sIL --max-time 10 "$url" | grep -iE '^(http/|server:|location:|strict-transport|content-security|x-frame|x-content-type|referrer-policy|permissions-policy)' || true
      echo; echo "-- Timing --"
      curl -o /dev/null -sS --max-time 10 -w "HTTP=%{http_code} DNS=%{time_namelookup}s Connect=%{time_connect}s TLS=%{time_appconnect}s Total=%{time_total}s\n" "$url" || true
    } 2>&1 | tee -a "$log"
  fi

  ui_progress 2 4 "Memeriksa sertifikat TLS..."
  if have openssl && [[ "$url" == https://* ]]; then
    {
      echo; echo "-- Sertifikat TLS ($domain:443) --"
      echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
        openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null || echo "Tidak dapat membaca sertifikat TLS."
    } 2>&1 | tee -a "$log"
  fi

  ui_progress 3 4 "Memeriksa DNS domain..."
  if have dig; then
    { echo; echo "-- DNS A/AAAA --"; dig +short A "$domain"; dig +short AAAA "$domain"; } 2>&1 | tee -a "$log"
  fi

  ui_progress 4 4 "Fingerprint teknologi (whatweb)..."
  if have whatweb; then
    { echo; echo "-- WhatWeb --"; whatweb -a 1 "$url" 2>/dev/null || true; } 2>&1 | tee -a "$log"
  fi

  echo; ok "Log: $log"; pause
}

recipe_discovery_lokal() {
  local log subnet ans
  smart_net_context
  ui_card_header "Resep: Discovery Subnet Lokal" "ARP Neighbor + Opsional Ping Sweep Berizin"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: ip neigh show, dan opsional nmap -sn $NET_SUBNET (dengan konfirmasi)"
    pause
    return 0
  fi
  log="$(recipe_log_init discovery-lokal)"
  {
    echo "== Discovery Lokal =="
    echo "Interface: $NET_IFACE | IP: $NET_CIDR | Subnet: $NET_SUBNET"
    echo; echo "-- ip neigh show --"
    ip neigh show 2>/dev/null || true
  } 2>&1 | tee -a "$log"

  if [ "$NET_SUBNET" != "-" ] && have nmap; then
    printf '\n%sPerintah opsional:%s nmap -sn %s\n' "$C_MUTED" "$C_RESET" "$NET_SUBNET"
    read -r -p "Saya berwenang memindai subnet lokal ini? (y/N): " ans || true
    if [[ "$ans" =~ ^[yY]$ ]]; then
      { echo; echo "-- nmap -sn $NET_SUBNET --"; nmap -sn "$NET_SUBNET"; } 2>&1 | tee -a "$log"
    fi
  fi
  echo; ok "Log: $log"; pause
}

recipe_monitor_port() {
  local log
  ui_card_header "Resep: Monitor Port & Proses" "Socket listening, koneksi aktif, dan pemilik proses"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan menjalankan: ss -s, ss -tulpn, ss -tunap state established, lsof -i -P -n"
    pause
    return 0
  fi
  log="$(recipe_log_init monitor-port)"
  {
    echo "== Monitor Port & Proses =="
    echo; echo "-- ss -s --"; ss -s 2>/dev/null || true
    echo; echo "-- ss -tulpn --"; ss -tulpn 2>/dev/null || true
    echo; echo "-- Koneksi ESTABLISHED --"; ss -tunap state established 2>/dev/null || true
    if have lsof; then
      echo; echo "-- lsof -i -P -n (top 40) --"; lsof -i -P -n 2>/dev/null | head -n 40 || true
    fi
  } 2>&1 | tee -a "$log"
  echo; ok "Log: $log"; pause
}

recipe_scan_target() {
  local log target qtarget profile cmd ans
  have nmap || { err "nmap belum terpasang."; pause; return 1; }
  if [ -t 0 ]; then
    target="$(smart_prompt_placeholder "TARGET" "Pilih target berizin untuk Nmap")" || { warn "Dibatalkan."; return 0; }
  else
    read -r -p "Target (default 127.0.0.1): " target || true
    target="${target:-127.0.0.1}"
  fi

  if [ -t 0 ]; then
    printf '\n  Profil scan:\n'
    printf '    1) Cepat (Top 100 port + versi)\n'
    printf '    2) Standar (Service + Default NSE scripts)\n'
    printf '    3) Lengkap (Semua 65535 port TCP)\n'
    read -r -p "Pilih profil [1/2/3] (default 1): " profile || true
  else
    profile="1"
  fi

  qtarget="$(printf '%q' "$target")"
  case "${profile:-1}" in
    2) cmd="nmap -sC -sV -T4 $qtarget" ;;
    3) cmd="nmap -p- -T4 --min-rate 1000 $qtarget" ;;
    *) cmd="nmap -sV -T4 --top-ports 100 $qtarget" ;;
  esac

  printf '\n%sTarget:%s %s\n' "$C_MUTED" "$C_RESET" "$target"
  printf '%sPerintah:%s %s\n' "$C_MUTED" "$C_RESET" "$cmd"
  read -r -p "Saya berwenang memindai target ini? (y/N): " ans || true
  [[ "$ans" =~ ^[yY]$ ]] || { warn "Dibatalkan."; return 0; }

  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] $cmd"
    pause
    return 0
  fi

  log="$(recipe_log_init scan-target)"
  {
    echo "== Scan target: $target =="
    echo "# $cmd"
    eval "$cmd"
  } 2>&1 | tee -a "$log"
  echo; ok "Log: $log"; pause
}

recipe_capture() {
  local log iface dur out ans input filter_choice bpf=""
  have tcpdump || { err "tcpdump belum terpasang."; pause; return 1; }
  have sudo || { err "sudo tidak tersedia."; pause; return 1; }

  if [ -t 0 ]; then
    iface="$(smart_prompt_placeholder "IFACE" "Pilih interface untuk capture")" || { warn "Dibatalkan."; return 0; }
  else
    echo "Interface tersedia:"
    ip -brief link 2>/dev/null | awk '{print "  - " $1}'
    iface="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
    read -r -p "Interface (default ${iface:--}): " input || true
    iface="${input:-$iface}"
  fi
  [ -n "$iface" ] || { warn "Interface tidak ditentukan."; return 0; }

  read -r -p "Durasi detik (default 30): " dur || true
  dur="${dur:-30}"
  [[ "$dur" =~ ^[0-9]+$ ]] || { err "Durasi harus angka."; return 1; }

  printf '  Filter BPF: [1] Semua trafik  [2] DNS & HTTP/HTTPS  [3] ICMP saja\n'
  read -r -p "Pilih filter [1/2/3] (default 1): " filter_choice || true
  case "${filter_choice:-1}" in
    2) bpf="port 53 or port 80 or port 443" ;;
    3) bpf="icmp" ;;
    *) bpf="" ;;
  esac

  out="$HOME/capture-$(date +%Y%m%d-%H%M%S).pcap"
  if [ -n "$bpf" ]; then
    printf '%sPerintah:%s sudo timeout %s tcpdump -i %s -w %s "%s"\n' "$C_MUTED" "$C_RESET" "$dur" "$iface" "$out" "$bpf"
  else
    printf '%sPerintah:%s sudo timeout %s tcpdump -i %s -w %s\n' "$C_MUTED" "$C_RESET" "$dur" "$iface" "$out"
  fi
  read -r -p "Mulai capture? (y/N): " ans || true
  [[ "$ans" =~ ^[yY]$ ]] || { warn "Dibatalkan."; return 0; }

  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Capture tidak dijalankan."
    pause
    return 0
  fi

  log="$(recipe_log_init capture)"
  printf '# sudo timeout %s tcpdump -i %s -w %s %s\n' "$dur" "$iface" "$out" "$bpf" >> "$log"
  if [ -n "$bpf" ]; then
    sudo timeout "$dur" tcpdump -i "$iface" -w "$out" "$bpf" 2>&1 | tee -a "$log"
  else
    sudo timeout "$dur" tcpdump -i "$iface" -w "$out" 2>&1 | tee -a "$log"
  fi
  [ -f "$out" ] && ok "Capture disimpan: $out"
  ok "Log: $log"; pause
}

recipe_wordlist_stats() {
  local path
  [ -s "$WORDLISTS_FILE" ] || wordlist_refresh
  path="$(awk -F'|' '!/^#/ && NF>=7 {printf "%s  [%s · %s]\t%s\n", $1, $3, $5, $2}' "$WORDLISTS_FILE" | \
    ui_fzf \
      --prompt='  Wordlist ▸ ' \
      --ghost='Pilih wordlist untuk statistik...' \
      --header='Pilih wordlist untuk statistik | Esc: batal' \
      --header-first \
      --preview="$SELF --preview-wordlist {2}" \
      --preview-window='right:52%:wrap' \
      --delimiter=$'\t' --with-nth=1 | awk -F'\t' '{print $2}')"
  [ -n "$path" ] || { warn "Dibatalkan."; return 0; }
  wordlist_stats "$path"
}

recipe_laporan() {
  local out count f tmpl tfile tsel days
  out="$REPORT_DIR/laporan-$(date +%Y%m%d-%H%M%S).md"
  tmpl="${1:-}"
  if [ -z "$tmpl" ] && [ -t 0 ] && [ -t 1 ]; then
    tfile="$(mktemp)"
    {
      printf '%s📄%s  Ringkas   %s(metadata + log 24 jam terakhir)%s\tringkas\n' "$C_PRIMARY" "$C_RESET" "$C_MUTED" "$C_RESET"
      printf '%s📚%s  Lengkap   %s(semua log 7 hari + indeks per tool + flow)%s\tlengkap\n' "$C_ACCENT" "$C_RESET" "$C_MUTED" "$C_RESET"
      printf '%s✅%s  Audit     %s(checklist temuan + rekomendasi tindak lanjut)%s\taudit\n' "$C_OK" "$C_RESET" "$C_MUTED" "$C_RESET"
    } > "$tfile"
    tsel="$(ui_fzf --prompt='  Template Laporan ▸ ' --header='Pilih template laporan Markdown' \
      --footer='Enter: Pilih │ Esc: Ringkas' --delimiter=$'\t' --with-nth=1 < "$tfile")"
    rm -f "$tfile"
    tmpl="$(printf '%s\n' "$tsel" | awk -F'\t' '{print $2}')"
  fi
  tmpl="${tmpl:-ringkas}"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Akan membuat laporan Markdown (template: $tmpl) di: $out"
    pause
    return 0
  fi
  mkdir -p "$REPORT_DIR"
  smart_net_context
  case "$tmpl" in
    lengkap) days=7 ;;
    audit) days=30 ;;
    *) days=1 ;;
  esac
  {
    echo "# Laporan NetLauncher — ${tmpl^^}"
    echo
    echo "- Tanggal: $(date -Is)"
    echo "- Host: $NET_HOST"
    echo "- User: ${USER:-unknown}"
    echo "- Interface: $NET_IFACE ($NET_IFACE_TYPE)"
    echo "- IP / Subnet: $NET_CIDR ($NET_SUBNET)"
    echo "- Gateway: $NET_GW"
    echo "- Target Workspace: $(workspace_active_label 2>/dev/null || echo '-')"
    echo

    if [ "$tmpl" = "audit" ]; then
      echo "## Checklist Audit & Rekomendasi"
      echo
      echo "| Item | Status | Catatan |"
      echo "| --- | --- | --- |"
      echo "| Otorisasi target | ☐ | Pastikan izin tertulis masih berlaku |"
      echo "| Log eksekusi | $([ -n "$(find "$LOG_DIR" -type f -name '*.log' -mtime -$days 2>/dev/null | head -n 1)" ] && echo ☑ || echo ☐) | $(find "$LOG_DIR" -type f -name '*.log' -mtime -$days 2>/dev/null | wc -l | tr -d ' ') log dalam $days hari |"
      echo "| Temuan error | ☐ | Tinjau baris error/denied pada log di bawah |"
      echo "| Tindak lanjut | ☐ | Catat owner & tenggat perbaikan |"
      echo
      echo "### Baris Indikatif Error / Peringatan"
      echo
      echo '```text'
      grep -riE 'error|failed|denied|refused|expired|warning|critical' "$LOG_DIR" --include='*.log' -m 3 2>/dev/null | head -n 60 || echo '(tidak ada)'
      echo '```'
      echo
    fi

    if [ "$tmpl" = "lengkap" ]; then
      echo "## Indeks Log"
      echo
      echo '```text'
      find "$LOG_DIR" -type f -name '*.log' -mtime -$days 2>/dev/null | sort -r | wc -l
      echo '```'
      echo
    fi

    echo "## Log $days Hari Terakhir"
    echo
    count=0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      count=$((count+1))
      echo "### $(basename "$f")"
      echo
      echo '```text'
      cat "$f"
      echo '```'
      echo
    done < <(find "$LOG_DIR" -type f -name '*.log' -mtime -$days 2>/dev/null | sort -r | head -n 60)
    echo "Total log: $count"
  } > "$out"
  chmod 600 "$out" 2>/dev/null || true
  ok "Laporan dibuat: $out (template: $tmpl)"
  pause
}

preview_recipe() {
  case "$1" in
    cek-koneksi)
      printf '%sCek Koneksi%s\n\nPing gateway, ping internet, query DNS, dan cek HTTP timing.\n\n%sTidak membutuhkan sudo.%s\n' "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$C_RESET" ;;
    info-jaringan)
      printf '%sInfo Jaringan%s\n\nTampilkan IP, subnet, route, interface wireless, socket listening, dan resolver.\n\n%sTidak membutuhkan sudo.%s\n' "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$C_RESET" ;;
    audit-web)
      printf '%sAudit Web & TLS (Pasif)%s\n\nCek HTTP security headers, timing, sertifikat TLS (OpenSSL), DNS, dan WhatWeb.\n\n%sTidak membutuhkan sudo.%s\n' "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$C_RESET" ;;
    discovery-lokal)
      printf '%sDiscovery Subnet Lokal%s\n\nTampilkan tabel ARP lokal dan opsional ping sweep subnet dengan konfirmasi.\n\n%sKonfirmasi otorisasi wajib.%s\n' "$C_WARN$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET" ;;
    monitor-port)
      printf '%sMonitor Port & Proses%s\n\nRingkasan socket, port listening, koneksi aktif, dan proses pemilik (ss + lsof).\n\n%sTidak membutuhkan sudo.%s\n' "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$C_RESET" ;;
    scan-target)
      printf '%sScan Target (Berizin)%s\n\nPilih profil Nmap (Top 100 / Service+NSE / Full TCP) ke target berizin.\n\n%sWajib konfirmasi otorisasi sebelum scan.%s\n' "$C_WARN$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET" ;;
    capture)
      printf '%sCapture Trafik%s\n\ntcpdump dengan smart interface picker, filter BPF, dan durasi pilihan Anda.\n\n%sMembutuhkan sudo dan konfirmasi.%s\n' "$C_WARN$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET" ;;
    dns)
      printf '%sAudit DNS & WHOIS%s\n\nQuery A, AAAA, MX, NS, TXT, SOA, DMARC, dan ringkasan WHOIS.\n\n%sTidak membutuhkan sudo.%s\n' "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$C_RESET" ;;
    wordlist-stats)
      printf '%sStatistik Wordlist%s\n\nPilih wordlist, lalu lihat jumlah baris, ukuran, cuplikan, dan baris unik.\n' "$C_OK$C_BOLD" "$C_RESET" ;;
    laporan)
      printf '%sBuat Laporan Markdown%s\n\nGabungkan log 24 jam terakhir menjadi laporan Markdown di ~/laporan/.\n' "$C_OK$C_BOLD" "$C_RESET" ;;
    *) printf 'Resep tidak dikenal.\n' ;;
  esac
}

recipes_menu() {
  local file sel recipe
  file="$(mktemp)"
  {
    printf '%s⚡%s  Cek Koneksi              %s(gateway, internet, DNS, HTTP)%s\tcek-koneksi\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s🔌%s  Info Jaringan            %s(IP, subnet, route, WiFi, port)%s\tinfo-jaringan\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s🌐%s  Audit Web & TLS          %s(security headers, sertifikat, DNS)%s\taudit-web\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s🔍%s  Audit DNS & WHOIS        %s(A, AAAA, MX, NS, TXT, DMARC)%s\tdns\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s📊%s  Monitor Port & Proses    %s(ss + lsof socket aktif)%s\tmonitor-port\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s📡%s  Discovery Subnet Lokal   %s(ARP neighbor + ping sweep berizin)%s\tdiscovery-lokal\n' "$C_YELLOW" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s🎯%s  Scan Target (Berizin)    %s(Nmap profil cepat/standar/lengkap)%s\tscan-target\n' "$C_YELLOW" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s📦%s  Capture Trafik           %s(tcpdump + filter BPF + sudo)%s\tcapture\n' "$C_YELLOW" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%sΣ%s   Statistik Wordlist       %s(baris, ukuran, unik, cuplikan)%s\twordlist-stats\n' "$C_GREEN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s📝%s  Buat Laporan Markdown    %s(ekspor log 24 jam ke ~/laporan/)%s\tlaporan\n' "$C_GREEN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s←%s   Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"
  sel="$(ui_fzf \
    --prompt='  Resep ▸ ' \
    --ghost='Pilih resep otomasi aman...' \
    --header='Alur Kerja Otomasi Aman (Authorized Use Only)' \
    --header-first \
    --header-label=' Resep Otomasi ' \
    --list-label=' Daftar Resep ' \
    --preview="$SELF --preview-recipe {2}" \
    --preview-window='right:52%:wrap' \
    --preview-label=' Detail Resep ' \
    --footer='Enter: Jalankan │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  recipe="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  [ "$recipe" = "back" ] && return 0
  run_recipe "$recipe"
}

run_recipe() {
  case "$1" in
    cek-koneksi) recipe_cek_koneksi ;;
    info-jaringan) recipe_info_jaringan ;;
    audit-web) recipe_audit_web ;;
    discovery-lokal) recipe_discovery_lokal ;;
    monitor-port) recipe_monitor_port ;;
    scan-target) recipe_scan_target ;;
    capture) recipe_capture ;;
    dns) recipe_dns ;;
    wordlist-stats) recipe_wordlist_stats ;;
    laporan) recipe_laporan ;;
    *) err "Resep tidak dikenal: $1"; pause; return 1 ;;
  esac
}

preview_automation() {
  local path="$1"
  [ -f "$path" ] || { printf 'File tidak ditemukan.\n'; return 0; }
  printf '%s%s%s\n' "$C_PRIMARY$C_BOLD" "$(basename "$path")" "$C_RESET"
  printf '%sPath:%s %s\n\n' "$C_MUTED" "$C_RESET" "$path"
  sed -n '1,60p' "$path"
}

automation_create() {
  local slug title desc out
  read -r -p "Nama script (tanpa .sh, mis. cek-gateway): " slug || true
  [ -n "$slug" ] || { warn "Dibatalkan."; return 0; }
  slug="${slug//[^a-zA-Z0-9_-]/-}"
  read -r -p "Judul singkat: " title || true
  read -r -p "Deskripsi: " desc || true
  out="$AUTOMATIONS_DIR/$slug.sh"
  cat > "$out" <<EOF
#!/usr/bin/env bash
# Automation: ${title:-$slug}
# Deskripsi: ${desc:-Script otomasi kustom}
set -uo pipefail

echo "== ${title:-$slug} =="
echo "Waktu: \$(date -Is)"
echo

# Tambahkan perintah Anda di bawah ini:
ip -brief addr
EOF
  chmod 700 "$out"
  ok "Template dibuat: $out"
  if [ -n "${EDITOR:-}" ] && have "${EDITOR%% *}"; then
    "$EDITOR" "$out"
  elif have nano; then
    nano "$out"
  fi
}

automation_menu() {
  local file sel choice action path
  mkdir -p "$AUTOMATIONS_DIR"
  file="$(mktemp)"
  {
    while IFS= read -r path; do
      [ -f "$path" ] || continue
      local desc
      desc="$(awk -F': ' '/^# Deskripsi:/ {print $2; exit}' "$path")"
      printf '%s🤖%s  %-28s %s%s%s\t%s\n' "$C_PRIMARY" "$C_RESET" "$(basename "$path")" "$C_MUTED" "${desc:-Script automation}" "$C_RESET" "$path"
    done < <(find "$AUTOMATIONS_DIR" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)
    printf '%s+%s   Buat Script Automation Baru\t__NEW__\n' "$C_OK" "$C_RESET"
    printf '%s←%s   Kembali\t__BACK__\n' "$C_MUTED" "$C_RESET"
  } > "$file"

  printf '%s🌊%s  Kelola Automation Flow (.flow)\t__FLOW__\n' "$C_CYAN" "$C_RESET" >> "$file"

  sel="$(ui_fzf \
    --prompt='  Automation ▸ ' \
    --ghost='Pilih script automation, flow, atau buat baru...' \
    --header="Direktori: $AUTOMATIONS_DIR │ Flow: $FLOWS_DIR" \
    --header-first \
    --header-label=' Custom Automation Scripts ' \
    --list-label=' Daftar Script & Flow ' \
    --preview="$SELF --preview-automation {2}" \
    --preview-window='right:56%:wrap' \
    --preview-label=' Isi Script ' \
    --footer='Enter: Pilih │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  choice="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$choice" in
    __BACK__) return 0 ;;
    __NEW__) automation_create; return 0 ;;
    __FLOW__) flow_ui; return 0 ;;
  esac

  file="$(mktemp)"
  {
    printf '%s▶%s  Jalankan script\trun\n' "$C_OK" "$C_RESET"
    printf '%s✎%s  Edit script\tedit\n' "$C_PRIMARY" "$C_RESET"
    printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"
  sel="$(ui_fzf \
    --prompt='  Aksi Script ▸ ' \
    --header="$(basename "$choice")" \
    --header-first \
    --preview="$SELF --preview-automation $(printf '%q' "$choice")" \
    --preview-window='right:56%:wrap' \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$action" in
    run)
      chmod +x "$choice" 2>/dev/null || true
      execute_command "auto:$(basename "$choice" .sh)" "$(basename "$choice")" "term" "0" "bash $(printf '%q' "$choice")"
      ;;
    edit)
      if [ -n "${EDITOR:-}" ] && have "${EDITOR%% *}"; then
        "$EDITOR" "$choice"
      elif have nano; then
        nano "$choice"
      elif have vi; then
        vi "$choice"
      else
        warn "Editor tidak ditemukan. Edit manual: $choice"
        pause
      fi
      ;;
    *) return 0 ;;
  esac
}
