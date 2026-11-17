# lib/smart.sh - Deteksi konteks jaringan, smart prompt, command builder, dan advisor

NET_HOST="-"
NET_IFACE="-"
NET_IFACE_TYPE="-"
NET_IP="-"
NET_CIDR="-"
NET_SUBNET="-"
NET_GW="-"
NET_DNS="-"
NET_SSID=""
NET_ONLINE="OFFLINE"
NET_PORTS="0"

smart_net_context() {
  local route_line cidr ip_part prefix o1 o2 o3 o4 mask
  NET_HOST="$(hostname 2>/dev/null || echo '-')"
  route_line="$(ip -4 route get 1.1.1.1 2>/dev/null | head -n1 || true)"
  NET_IFACE="$(awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' <<< "$route_line")"
  NET_GW="$(ip -4 route 2>/dev/null | awk '/^default/ {print $3; exit}')"

  if [ -n "$NET_IFACE" ]; then
    cidr="$(ip -4 -o addr show dev "$NET_IFACE" scope global 2>/dev/null | awk '{print $4}' | head -n1)"
  else
    cidr="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | head -n1)"
    NET_IFACE="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $2}' | head -n1)"
  fi

  [ -n "$NET_IFACE" ] || NET_IFACE="-"
  [ -n "$NET_GW" ] || NET_GW="-"

  if [ -n "$cidr" ]; then
    NET_CIDR="$cidr"
    NET_IP="${cidr%%/*}"
    prefix="${cidr##*/}"
    if [ "$prefix" = "24" ]; then
      NET_SUBNET="${NET_IP%.*}.0/24"
    elif [ "$prefix" = "16" ]; then
      IFS='.' read -r o1 o2 _ _ <<< "$NET_IP"
      NET_SUBNET="$o1.$o2.0.0/16"
    else
      NET_SUBNET="$cidr"
    fi
  else
    NET_CIDR="-"
    NET_IP="-"
    NET_SUBNET="-"
  fi

  NET_DNS="$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null || echo '-')"
  [ -n "$NET_DNS" ] || NET_DNS="-"

  if [ "$NET_IFACE" != "-" ] && [ -d "/sys/class/net/$NET_IFACE/wireless" ]; then
    NET_IFACE_TYPE="WiFi"
    if have iw; then
      NET_SSID="$(iw dev "$NET_IFACE" link 2>/dev/null | awk -F': ' '/SSID:/ {print $2; exit}')"
    fi
  elif [ "$NET_IFACE" = "lo" ]; then
    NET_IFACE_TYPE="Loopback"
  elif [ "$NET_IFACE" != "-" ]; then
    NET_IFACE_TYPE="Ethernet"
  else
    NET_IFACE_TYPE="-"
  fi

  if [ "$NET_GW" != "-" ] && [ "$NET_IP" != "-" ]; then
    NET_ONLINE="ONLINE"
  elif [ "$NET_IP" != "-" ]; then
    NET_ONLINE="LOKAL"
  else
    NET_ONLINE="OFFLINE"
  fi

  if have ss; then
    NET_PORTS="$(ss -tulnH 2>/dev/null | wc -l | tr -d ' ')"
  else
    NET_PORTS="0"
  fi
}

smart_pick_from_list() {
  local title="$1" prompt="$2" ghost="$3" file="$4" sel val
  sel="$(ui_fzf \
    --prompt="  $prompt ▸ " \
    --ghost="$ghost" \
    --header="$title" \
    --header-first \
    --header-label=' Smart Picker ' \
    --input-label=' Pilih atau ketik ' \
    --list-label=' Saran Kontekstual ' \
    --footer='Enter: Pilih │ Esc: Batal' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  [ -n "$sel" ] || return 1
  val="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  printf '%s' "$val"
}

smart_prompt_placeholder() {
  local kind="$1" hint="${2:-}" file val custom
  smart_net_context
  file="$(mktemp)"

  case "$kind" in
    TARGET)
      {
        printf '%s127.0.0.1%s  %s(localhost · aman untuk uji lokal)%s\t127.0.0.1\n' "$C_OK" "$C_RESET" "$C_MUTED" "$C_RESET"
        [ "$NET_GW" != "-" ] && printf '%s%s%s  %s(default gateway terdeteksi)%s\t%s\n' "$C_PRIMARY" "$NET_GW" "$C_RESET" "$C_MUTED" "$C_RESET" "$NET_GW"
        [ "$NET_IP" != "-" ] && printf '%s%s%s  %s(IP lokal mesin ini)%s\t%s\n' "$C_PRIMARY" "$NET_IP" "$C_RESET" "$C_MUTED" "$C_RESET" "$NET_IP"
        [ "$NET_SUBNET" != "-" ] && printf '%s%s%s  %s(subnet lokal terdeteksi)%s\t%s\n' "$C_WARN" "$NET_SUBNET" "$C_RESET" "$C_MUTED" "$C_RESET" "$NET_SUBNET"
        printf '%s1.1.1.1%s  %s(Cloudflare DNS · uji ping/route)%s\t1.1.1.1\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
        printf '%sexample.com%s  %s(domain uji standar)%s\texample.com\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
        if [ -s "$TARGET_HISTORY_FILE" ]; then
          awk -F'\t' '$1=="TARGET" {printf "\033[35m↺ %s\033[0m  \033[2m(riwayat target)\033[0m\t%s\n", $2, $2}' "$TARGET_HISTORY_FILE" | head -n 6
        fi
        printf '%s✎ Ketik target manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih Target Berizin}" "Target" "Pilih saran atau ketik manual..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan target (IP/host/CIDR): " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      record_target_history "TARGET" "$val"
      printf '%s' "$val"
      ;;

    SUBNET)
      {
        [ "$NET_SUBNET" != "-" ] && printf '%s%s%s  %s(subnet aktif terdeteksi)%s\t%s\n' "$C_OK" "$NET_SUBNET" "$C_RESET" "$C_MUTED" "$C_RESET" "$NET_SUBNET"
        printf '%s127.0.0.0/24%s  %s(loopback)%s\t127.0.0.0/24\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
        printf '%s✎ Ketik subnet CIDR manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih Subnet CIDR}" "Subnet" "Pilih subnet..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan subnet CIDR (mis. 192.168.1.0/24): " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    IFACE)
      {
        [ "$NET_IFACE" != "-" ] && printf '%s%s%s  %s(interface aktif · %s · %s)%s\t%s\n' "$C_OK" "$NET_IFACE" "$C_RESET" "$C_MUTED" "$NET_IFACE_TYPE" "$NET_IP" "$C_RESET" "$NET_IFACE"
        ip -brief link 2>/dev/null | awk -v act="$NET_IFACE" '{
          if ($1 != act) printf "%s  [%s]\t%s\n", $1, $2, $1
        }'
        printf '%s✎ Ketik nama interface manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih Interface Jaringan}" "Iface" "Pilih interface..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan nama interface: " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    DOMAIN)
      {
        printf '%sexample.com%s  %s(domain uji standar)%s\texample.com\n' "$C_OK" "$C_RESET" "$C_MUTED" "$C_RESET"
        printf '%scloudflare.com%s  %s(uji DNS/TLS)%s\tcloudflare.com\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
        if [ -s "$TARGET_HISTORY_FILE" ]; then
          awk -F'\t' '$1=="DOMAIN" {printf "\033[35m↺ %s\033[0m  \033[2m(riwayat domain)\033[0m\t%s\n", $2, $2}' "$TARGET_HISTORY_FILE" | head -n 6
        fi
        printf '%s✎ Ketik domain manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih Domain}" "Domain" "Pilih atau ketik domain..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan domain (mis. example.com): " custom || true
        val="$custom"
      fi
      val="${val#https://}"; val="${val#http://}"; val="${val%%/*}"
      [ -n "$val" ] || return 1
      record_target_history "DOMAIN" "$val"
      printf '%s' "$val"
      ;;

    URL)
      {
        printf '%shttps://example.com%s  %s(URL uji standar)%s\thttps://example.com\n' "$C_OK" "$C_RESET" "$C_MUTED" "$C_RESET"
        printf '%shttp://127.0.0.1%s  %s(server lokal)%s\thttp://127.0.0.1\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
        if [ -s "$TARGET_HISTORY_FILE" ]; then
          awk -F'\t' '$1=="URL" {printf "\033[35m↺ %s\033[0m  \033[2m(riwayat URL)\033[0m\t%s\n", $2, $2}' "$TARGET_HISTORY_FILE" | head -n 6
        fi
        printf '%s✎ Ketik URL manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih URL Target}" "URL" "Pilih atau ketik URL..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan URL (mis. https://example.com): " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      record_target_history "URL" "$val"
      printf '%s' "$val"
      ;;

    PORT)
      {
        printf '80    (HTTP)\t80\n'
        printf '443   (HTTPS)\t443\n'
        printf '22    (SSH)\t22\n'
        printf '53    (DNS)\t53\n'
        printf '8080  (HTTP Alt)\t8080\n'
        printf '3306  (MySQL)\t3306\n'
        printf '%s✎ Ketik port manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih Port}" "Port" "Pilih port..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -p "Masukkan port (mis. 8443): " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    WORDLIST)
      rm -f "$file"
      [ -s "$WORDLISTS_FILE" ] || wordlist_refresh >/dev/null
      val="$(awk -F'|' '!/^#/ && NF>=7 {printf "%s  [%s · %s baris · %s]\t%s\n", $1, $3, $4, $5, $2}' "$WORDLISTS_FILE" | \
        ui_fzf \
          --prompt='  Wordlist ▸ ' \
          --ghost='Cari wordlist (indonesia, rockyou, common, dirb)...' \
          --header='Pilih Wordlist untuk Perintah' \
          --header-first \
          --header-label=' Smart Wordlist Picker ' \
          --preview="$SELF --preview-wordlist {2}" \
          --preview-window='right:52%:wrap' \
          --preview-label=' Cuplikan Wordlist ' \
          --footer='Enter: Pilih │ Esc: Batal' \
          --footer-border=line \
          --delimiter=$'\t' --with-nth=1 | awk -F'\t' '{print $2}')"
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    FILE)
      {
        find "$HOME" "$LOG_DIR" "$REPORT_DIR" -maxdepth 2 -type f \( -name '*.pcap' -o -name '*.pcapng' -o -name '*.txt' -o -name '*.log' \) 2>/dev/null | \
          sort -r | head -n 20 | awk '{printf "%s\t%s\n", $0, $0}'
        printf '%s✎ Ketik path file manual...%s\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      } > "$file"
      val="$(smart_pick_from_list "${hint:-Pilih File}" "File" "Pilih file atau ketik manual..." "$file")" || { rm -f "$file"; return 1; }
      rm -f "$file"
      if [ "$val" = "__CUSTOM__" ]; then
        read -r -e -p "Masukkan path file: " custom || true
        val="$custom"
      fi
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    QUERY)
      rm -f "$file"
      read -r -p "${hint:-Kata kunci pencarian}: " val || true
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;

    *)
      rm -f "$file"
      read -r -p "${hint:-Nilai $kind}: " val || true
      [ -n "$val" ] || return 1
      printf '%s' "$val"
      ;;
  esac
}

smart_resolve_template() {
  local cmd="$1" ph val qval now_stamp
  now_stamp="$(date +%Y%m%d-%H%M%S)"
  cmd="${cmd//\{DATE\}/$now_stamp}"
  cmd="${cmd//\{REPORT_DIR\}/$REPORT_DIR}"

  for ph in TARGET SUBNET IFACE DOMAIN URL PORT WORDLIST FILE QUERY; do
    if [[ "$cmd" == *"{$ph}"* ]]; then
      val="$(smart_prompt_placeholder "$ph" "Isi {$ph} untuk perintah")" || return 1
      qval="$(printf '%q' "$val")"
      cmd="${cmd//\{$ph\}/$qval}"
    fi
  done
  printf '%s' "$cmd"
}

smart_missing_advisor() {
  local binary="$1" label="$2" cat="${3:-}" pkg="$binary" hint=""
  case "$binary" in
    ip) pkg="iproute2" ;;
    ss) pkg="iproute2" ;;
    dig|nslookup) pkg="dnsutils" ;;
    nc) pkg="netcat-openbsd" ;;
    airmon-ng|aircrack-ng) pkg="aircrack-ng" ;;
    hackingtool) hint="pipx install ~/tools/hackingtool --force" ;;
    fzf) hint="GOBIN=\"\$HOME/.local/bin\" go install github.com/junegunn/fzf@latest" ;;
  esac
  [ -n "$hint" ] || hint="sudo apt update && sudo apt install -y $pkg"

  ui_card_header "$label belum terpasang" "Binary '$binary' tidak ditemukan di PATH"
  printf '\n  %sSaran instalasi:%s\n' "$C_WARN$C_BOLD" "$C_RESET"
  printf '  %s%s%s\n\n' "$C_PRIMARY" "$hint" "$C_RESET"
  if [ -n "$cat" ]; then
    printf '  %sAlternatif terpasang di kategori %s:%s\n' "$C_MUTED" "${CAT_NAMES[$cat]:-$cat}" "$C_RESET"
    awk -F'|' -v c="$cat" '!/^#/ && $1==c {print $3 "|" $4}' "$TOOLS_FILE" | while IFS='|' read -r l b; do
      have "$b" && printf '    %s✓%s %s (%s)\n' "$C_OK" "$C_RESET" "$l" "$b"
    done
  fi
  if copy_to_clipboard "$hint"; then
    printf '\n'
    ok "Perintah instalasi disalin ke clipboard."
  fi
  pause
}

smart_command_builder() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples
  local file sel choice cmd final_cmd ans
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; pause; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  have "$binary" || { smart_missing_advisor "$binary" "$label" "$cat"; return 1; }

  file="$(mktemp)"
  {
    if [ -s "$SNIPPETS_FILE" ]; then
      awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "\033[36m⌘\033[0m  %-34s \033[2m%s\033[0m\t%s\n", $2, $3, $3}' "$SNIPPETS_FILE"
    fi
    printf '%s⚙%s  Template bawaan: %s\t%s\n' "$C_YELLOW" "$C_RESET" "${template:-$binary}" "${template:-$binary}"
    printf '%s✎%s  Tulis perintah kustom dari awal\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
  } > "$file"

  sel="$(ui_fzf \
    --prompt='  Builder ▸ ' \
    --ghost='Pilih preset perintah atau tulis kustom...' \
    --header="Command Builder: $label ($binary)" \
    --header-first \
    --header-label=' Smart Command Builder ' \
    --list-label=' Preset & Template ' \
    --footer='Enter: Pilih & Isi Parameter │ Esc: Batal' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0

  cmd="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  if [ "$cmd" = "__CUSTOM__" ]; then
    read -r -e -i "$binary " -p "Perintah: " cmd || true
    [ -n "$cmd" ] || { warn "Dibatalkan."; return 0; }
  else
    if [[ "$cmd" == *"%s"* ]]; then
      local val qval
      val="$(smart_prompt_placeholder "TARGET" "${arg_prompt:-Argumen untuk $label}")" || { warn "Dibatalkan."; return 0; }
      qval="$(printf '%q' "$val")"
      cmd="${cmd//%s/$qval}"
    fi
    cmd="$(smart_resolve_template "$cmd")" || { warn "Dibatalkan."; return 0; }
  fi

  printf '\n'
  ui_card_header "Pratinjau Perintah" "$label"
  printf '\n  %s$ %s%s\n\n' "$C_PRIMARY$C_BOLD" "$cmd" "$C_RESET"
  read -r -e -i "$cmd" -p "Edit perintah (Enter untuk lanjut): " final_cmd || true
  [ -n "$final_cmd" ] || { warn "Dibatalkan."; return 0; }

  printf '\n  [r] Jalankan sekarang   [c] Salin ke clipboard   [d] Dry-run   [b] Batal\n'
  read -r -p "Pilihan (R/c/d/b): " ans || true
  case "${ans:-r}" in
    c|C)
      if copy_to_clipboard "$final_cmd"; then ok "Disalin ke clipboard."; else printf '%s\n' "$final_cmd"; fi
      pause
      ;;
    d|D)
      DRY_RUN=1 execute_command "$id" "$label" "$mode" "$sudo" "$final_cmd"
      ;;
    b|B)
      warn "Dibatalkan."
      ;;
    *)
      execute_command "$id" "$label" "$mode" "$sudo" "$final_cmd"
      ;;
  esac
}
