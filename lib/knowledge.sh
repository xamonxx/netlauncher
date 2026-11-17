# lib/knowledge.sh - Knowledge base resmi tool, panduan Bahasa Indonesia, dan Interactive Flag Builder

knowledge_guide_file() {
  local id="$1"
  if [ -f "$GUIDES_DIR/$id.md" ]; then
    printf '%s' "$GUIDES_DIR/$id.md"
    return 0
  fi
  case "$id" in
    ip-route) [ -f "$GUIDES_DIR/ip-addr.md" ] && { printf '%s' "$GUIDES_DIR/ip-addr.md"; return 0; } ;;
    hashcat) [ -f "$GUIDES_DIR/john.md" ] && { printf '%s' "$GUIDES_DIR/john.md"; return 0; } ;;
  esac
  return 1
}

knowledge_flag_count() {
  local id="$1"
  [ -f "$FLAGS_FILE" ] || { printf '0'; return 0; }
  awk -F'\t' -v tid="$id" '!/^#/ && NF>=7 && $1==tid {n++} END{print n+0}' "$FLAGS_FILE"
}

knowledge_render_guide() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples gfile fcount
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { printf 'Tool tidak ditemukan: %s\n' "$id"; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"

  printf '%s◈ Panduan Resmi: %s (%s)%s\n' "$C_PRIMARY$C_BOLD" "$label" "$binary" "$C_RESET"
  printf '%sKategori:%s %s │ %sMode:%s %s │ %sSudo:%s %s\n' \
    "$C_MUTED" "$C_RESET" "${CAT_NAMES[$cat]:-$cat}" \
    "$C_MUTED" "$C_RESET" "$mode" \
    "$C_MUTED" "$C_RESET" "$([ "$sudo" = "1" ] && echo "Ya" || echo "Tidak")"
  printf '%sDeskripsi:%s %s\n\n' "$C_MUTED" "$C_RESET" "$desc"

  if gfile="$(knowledge_guide_file "$id")"; then
    while IFS= read -r gline; do
      case "$gline" in
        "# "*) printf '%s%s%s\n' "$C_PRIMARY$C_BOLD" "${gline#\# }" "$C_RESET" ;;
        "## "*) printf '\n%s▸ %s%s\n' "$C_ACCENT$C_BOLD" "${gline#\#\# }" "$C_RESET" ;;
        "- "*) printf '  %s•%s %s\n' "$C_OK" "$C_RESET" "${gline#- }" ;;
        *) printf '%s\n' "$gline" ;;
      esac
    done < "$gfile"
    printf '\n'
  fi

  fcount="$(knowledge_flag_count "$id")"
  if [ "$fcount" -gt 0 ]; then
    printf '%s▸ Referensi Flag Resmi (%s flag terkurasi)%s\n' "$C_ACCENT$C_BOLD" "$fcount" "$C_RESET"
    awk -F'\t' -v tid="$id" '!/^#/ && NF>=7 && $1==tid {
      printf "  %-18s %-12s [%s/%s]  %s\n", $2, ($3==""?"-":$3), $4, $5, $6
    }' "$FLAGS_FILE"
    printf '\n'
  fi

  local sf scount=0
  while IFS= read -r sf; do
    scount=$((scount + $(awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {n++} END{print n+0}' "$sf")))
  done < <(snippets_files)
  if [ "$scount" -gt 0 ]; then
    printf '%s▸ Contoh Perintah Terverifikasi (%s)%s\n' "$C_OK$C_BOLD" "$scount" "$C_RESET"
    while IFS= read -r sf; do
      awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "  • %s\n    $ %s\n    (%s)\n", $2, $3, $4}' "$sf"
    done < <(snippets_files)
  fi
}

preview_guide() {
  knowledge_render_guide "$1" | head -n 90
}

preview_flag() {
  local id="$1" flag="$2" line tid fl arg cat risk desc ex
  [ -f "$FLAGS_FILE" ] || { printf 'Database flag tidak ditemukan.\n'; return 0; }
  line="$(awk -F'\t' -v tid="$id" -v fl="$flag" '!/^#/ && NF>=7 && $1==tid && $2==fl {print; exit}' "$FLAGS_FILE")"
  if [ -z "$line" ]; then
    printf 'Flag: %s\n' "$flag"
    return 0
  fi
  # Awk menjaga field kosong (read dengan IFS=tab mengabaikan tab berurutan).
  tid="$(awk -F'\t' '{print $1}' <<< "$line")"
  fl="$(awk -F'\t' '{print $2}' <<< "$line")"
  arg="$(awk -F'\t' '{print $3}' <<< "$line")"
  cat="$(awk -F'\t' '{print $4}' <<< "$line")"
  risk="$(awk -F'\t' '{print $5}' <<< "$line")"
  desc="$(awk -F'\t' '{print $6}' <<< "$line")"
  ex="$(awk -F'\t' '{print $7}' <<< "$line")"
  printf '%s%s %s%s\n' "$C_PRIMARY$C_BOLD" "$fl" "$arg" "$C_RESET"
  printf '%sTool:%s %s │ %sKategori:%s %s │ ' "$C_MUTED" "$C_RESET" "$tid" "$C_MUTED" "$C_RESET" "$cat"
  case "$risk" in
    pasif) printf '%b\n\n' "$(ui_badge ok "PASIF")" ;;
    aman)  printf '%b\n\n' "$(ui_badge info "AMAN")" ;;
    aktif) printf '%b\n\n' "$(ui_badge warn "AKTIF BERIZIN")" ;;
    sudo)  printf '%b\n\n' "$(ui_badge err "BUTUH SUDO")" ;;
    *)     printf '%s\n\n' "$risk" ;;
  esac
  printf '%sPenjelasan Resmi:%s\n%s%s%s\n\n' "$C_MUTED" "$C_RESET" "$C_WHITE" "$desc" "$C_RESET"
  printf '%sContoh Penggunaan:%s\n  %s$ %s%s\n' "$C_MUTED" "$C_RESET" "$C_OK" "$ex" "$C_RESET"
}

knowledge_live_flags() {
  local id="$1" line binary help raw_tmp sel
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || return 1
  binary="$(printf '%s' "$line" | awk -F'|' '{print $4}')"
  help="$(printf '%s' "$line" | awk -F'|' '{print $7}')"
  have "$binary" || { smart_missing_advisor "$binary" "$id"; return 1; }

  raw_tmp="$(mktemp)"
  if [ "$id" = "amass" ]; then
    man -P cat amass 2>/dev/null > "$raw_tmp" || true
  elif [[ "$help" == man\ * ]]; then
    man -P cat "${help#man }" 2>/dev/null > "$raw_tmp" || true
  else
    timeout 4 bash -c "$help" </dev/null > "$raw_tmp" 2>&1 || true
  fi

  if [ ! -s "$raw_tmp" ]; then
    man -P cat "$binary" 2>/dev/null > "$raw_tmp" || true
  fi

  if [ ! -s "$raw_tmp" ]; then
    rm -f "$raw_tmp"
    warn "Manual lokal untuk $binary tidak menghasilkan teks."
    pause
    return 0
  fi

  sel="$(grep -E '^[[:space:]]*(-[a-zA-Z0-9]|--[a-zA-Z0-9]|[A-Z_]+:)' "$raw_tmp" | head -n 400 | \
    ui_fzf \
      --prompt="  Manual $binary ▸ " \
      --ghost="Cari flag atau kata kunci di manual lokal $binary..." \
      --header="Ekstrak Flag Lokal: $binary ($help)" \
      --header-first \
      --header-label=' Live Manual Extractor ' \
      --footer='Enter: Salin baris │ Esc: Kembali' \
      --footer-border=line || true)"
  rm -f "$raw_tmp"
  if [ -n "$sel" ]; then
    if copy_to_clipboard "$sel"; then
      ok "Baris manual disalin ke clipboard."
    else
      printf '%s\n' "$sel"
    fi
    pause
  fi
}

knowledge_flag_builder() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples
  local file sel_lines cmd_parts=() need_sudo=0 fl arg risk val qval pos_kind="" pos_val=""
  local assembled final_cmd ans

  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; pause; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  have "$binary" || { smart_missing_advisor "$binary" "$label" "$cat"; return 1; }

  if [ "$(knowledge_flag_count "$id")" -eq 0 ]; then
    warn "Belum ada flag terkurasi untuk $label; membuka Command Builder standar."
    smart_command_builder "$id"
    return $?
  fi

  file="$(mktemp)"
  awk -F'\t' -v tid="$id" '!/^#/ && NF>=7 && $1==tid {
    badge = ($5=="sudo" ? "[SUDO]" : ($5=="aktif" ? "[AKTIF]" : ($5=="pasif" ? "[PASIF]" : "[AMAN]")))
    printf "%-16s %-12s %-8s %s\t%s\t%s\t%s\n", $2, ($3==""?"-":$3), badge, $6, $2, ($3==""?"-":$3), $5
  }' "$FLAGS_FILE" > "$file"

  sel_lines="$(ui_fzf \
    --multi \
    --prompt="  Flag $label ▸ " \
    --ghost='Tab: pilih beberapa flag, Enter: rakit perintah...' \
    --header="Interactive Flag Builder: $label ($binary) │ Tab=Pilih Banyak" \
    --header-first \
    --header-label=' Flag Builder Resmi ' \
    --list-label=' Daftar Flag Resmi ' \
    --preview="$SELF --preview-flag $id {2}" \
    --preview-window='right:52%:wrap' \
    --preview-label=' Penjelasan Resmi ' \
    --footer='Tab: Toggle Flag │ Enter: Rakit Perintah │ Esc: Batal' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel_lines" ] || return 0

  [ "$sudo" = "1" ] && need_sudo=1
  cmd_parts=("$binary")

  local sel_arr=() row
  mapfile -t sel_arr <<< "$sel_lines"
  for row in "${sel_arr[@]}"; do
    IFS=$'\t' read -r _ fl arg risk <<< "$row"
    [ "$arg" = "-" ] && arg=""
    [ -n "$fl" ] || continue
    [ "$risk" = "sudo" ] && need_sudo=1
    if [ -z "$arg" ]; then
      cmd_parts+=("$fl")
    else
      case "$arg" in
        "{TARGET}"|"{DOMAIN}"|"{URL}"|"{PORT}"|"{IFACE}"|"{SUBNET}"|"{WORDLIST}"|"{FILE}"|"{QUERY}")
          local ph="${arg#\{}"; ph="${ph%\}}"
          val="$(smart_prompt_placeholder "$ph" "Nilai untuk $fl ($label)")" || { warn "Dibatalkan."; return 0; }
          ;;
        *)
          read -r -p "Nilai untuk $fl $arg: " val || true
          [ -n "$val" ] || { warn "Dibatalkan."; return 0; }
          ;;
      esac
      qval="$(printf '%q' "$val")"
      if [[ "$fl" == *= ]]; then
        cmd_parts+=("${fl}${qval}")
      else
        cmd_parts+=("$fl" "$qval")
      fi
    fi
  done

  # Normalisasi subcommand & flag wajib untuk tool tertentu
  local joined=" ${cmd_parts[*]} " extra_val extra_port
  case "$id" in
    openssl)
      [[ "$joined" == *" s_client "* ]] || cmd_parts=("$binary" "s_client" "${cmd_parts[@]:1}")
      joined=" ${cmd_parts[*]} "
      if [[ "$joined" != *" -connect "* ]]; then
        extra_val="$(smart_prompt_placeholder "DOMAIN" "Domain/host TLS untuk -connect (<host>:443)")" || { warn "Dibatalkan."; return 0; }
        if [[ "$extra_val" == *:* ]]; then
          cmd_parts+=("-connect" "$(printf '%q' "$extra_val")")
          extra_val="${extra_val%%:*}"
        else
          cmd_parts+=("-connect" "$(printf '%q' "${extra_val}:443")")
        fi
        if [[ "$joined" != *" -servername "* ]]; then
          cmd_parts+=("-servername" "$(printf '%q' "$extra_val")")
        fi
      fi
      ;;
    gobuster)
      if [[ "$joined" != *" dir "* ]] && [[ "$joined" != *" dns "* ]]; then
        cmd_parts=("$binary" "dir" "${cmd_parts[@]:1}")
      fi
      joined=" ${cmd_parts[*]} "
      if [[ "$joined" == *" dns "* ]]; then
        if [[ "$joined" != *" --domain "* ]] && [[ "$joined" != *" -d "* ]]; then
          extra_val="$(smart_prompt_placeholder "DOMAIN" "Domain target untuk gobuster dns")" || { warn "Dibatalkan."; return 0; }
          cmd_parts+=("--domain" "$(printf '%q' "$extra_val")")
        fi
      else
        if [[ "$joined" != *" -u "* ]]; then
          extra_val="$(smart_prompt_placeholder "URL" "URL target untuk gobuster dir")" || { warn "Dibatalkan."; return 0; }
          cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
        fi
      fi
      if [[ "$joined" != *" -w "* ]]; then
        extra_val="$(smart_prompt_placeholder "WORDLIST" "Wordlist untuk gobuster")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-w" "$(printf '%q' "$extra_val")")
      fi
      ;;
    ffuf)
      if [[ "$joined" != *" -u "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL target untuk ffuf (FUZZ ditambahkan jika belum ada)")" || { warn "Dibatalkan."; return 0; }
        if [[ "$extra_val" != *"FUZZ"* ]] && [[ "$joined" != *"FUZZ"* ]]; then
          extra_val="${extra_val%/}/FUZZ"
        fi
        cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
      fi
      if [[ "$joined" != *" -w "* ]]; then
        extra_val="$(smart_prompt_placeholder "WORDLIST" "Wordlist untuk ffuf")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-w" "$(printf '%q' "$extra_val")")
      fi
      ;;
    feroxbuster)
      if [[ "$joined" != *" -u "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL target untuk feroxbuster")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
      fi
      ;;
    nikto)
      if [[ "$joined" != *" -h "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL/host target untuk nikto -h")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-h" "$(printf '%q' "$extra_val")")
      fi
      ;;
    httpx)
      if [[ "$joined" != *" -u "* ]] && [[ "$joined" != *" -l "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL target untuk httpx-toolkit -u")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
      fi
      ;;
    nuclei)
      if [[ "$joined" != *" -u "* ]] && [[ "$joined" != *" -l "* ]] && [[ "$joined" != *" -update-templates "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL target untuk nuclei -u")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
      fi
      ;;
    amass)
      [[ "$joined" == *" enum "* ]] || cmd_parts=("$binary" "enum" "${cmd_parts[@]:1}")
      joined=" ${cmd_parts[*]} "
      if [[ "$joined" != *" -d "* ]]; then
        extra_val="$(smart_prompt_placeholder "DOMAIN" "Domain target untuk amass enum")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-d" "$(printf '%q' "$extra_val")")
      fi
      ;;
    sqlmap)
      if [[ "$joined" != *" -u "* ]] && [[ "$joined" != *" -r "* ]]; then
        extra_val="$(smart_prompt_placeholder "URL" "URL target berparameter untuk sqlmap -u")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-u" "$(printf '%q' "$extra_val")")
      fi
      ;;
    wfuzz)
      if [[ "$joined" != *" -z "* ]]; then
        extra_val="$(smart_prompt_placeholder "WORDLIST" "Wordlist untuk wfuzz -z")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-z" "file,$(printf '%q' "$extra_val")")
      fi
      extra_val="$(smart_prompt_placeholder "URL" "URL target untuk wfuzz (FUZZ ditambahkan jika belum ada)")" || { warn "Dibatalkan."; return 0; }
      [[ "$extra_val" == *"FUZZ"* ]] || extra_val="${extra_val%/}/FUZZ"
      cmd_parts+=("$(printf '%q' "$extra_val")")
      ;;
    dirb)
      extra_val="$(smart_prompt_placeholder "URL" "URL target untuk dirb")" || { warn "Dibatalkan."; return 0; }
      extra_port="$(smart_prompt_placeholder "WORDLIST" "Wordlist untuk dirb")" || { warn "Dibatalkan."; return 0; }
      cmd_parts+=("$(printf '%q' "$extra_val")" "$(printf '%q' "$extra_port")")
      ;;
    ip-addr)
      if [[ "$joined" != *" addr"* ]] && [[ "$joined" != *" link"* ]] && [[ "$joined" != *" neigh"* ]]; then
        cmd_parts+=("addr")
      fi
      ;;
    ip-route)
      if [[ "$joined" != *" route"* ]] && [[ "$joined" != *" get "* ]]; then
        cmd_parts+=("route")
      elif [[ "$joined" == *" get "* ]] && [[ "$joined" != *" route "* ]]; then
        cmd_parts=("$binary" "route" "${cmd_parts[@]:1}")
      fi
      ;;
    iw-dev)
      if [[ "$joined" == *" link "* ]]; then
        extra_val="$(smart_prompt_placeholder "IFACE" "Interface wireless untuk iw dev <iface> link")" || { warn "Dibatalkan."; return 0; }
        cmd_parts=("$binary" "dev" "$(printf '%q' "$extra_val")" "link")
      elif [[ "$joined" == *" scan "* ]]; then
        extra_val="$(smart_prompt_placeholder "IFACE" "Interface wireless untuk iw dev <iface> scan")" || { warn "Dibatalkan."; return 0; }
        cmd_parts=("$binary" "dev" "$(printf '%q' "$extra_val")" "scan")
        need_sudo=1
      elif [[ "$joined" != *" dev "* ]]; then
        cmd_parts=("$binary" "dev" "${cmd_parts[@]:1}")
      fi
      ;;
    nc)
      if [[ "$joined" == *" -l "* ]]; then
        if [[ "$joined" != *" -p "* ]]; then
          extra_port="$(smart_prompt_placeholder "PORT" "Port listen untuk nc -l -p")" || { warn "Dibatalkan."; return 0; }
          cmd_parts+=("-p" "$(printf '%q' "$extra_port")")
        fi
      else
        extra_val="$(smart_prompt_placeholder "TARGET" "Host/IP tujuan untuk Netcat")" || { warn "Dibatalkan."; return 0; }
        extra_port="$(smart_prompt_placeholder "PORT" "Port tujuan untuk Netcat")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("$(printf '%q' "$extra_val")" "$(printf '%q' "$extra_port")")
      fi
      ;;
    masscan)
      if [[ "$joined" != *" -p "* ]] && [[ "$joined" != *" -p"* ]]; then
        extra_port="$(smart_prompt_placeholder "PORT" "Port target untuk masscan -p")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-p" "$(printf '%q' "$extra_port")")
      fi
      pos_kind="TARGET"
      ;;
    arp-scan)
      [[ "$joined" == *" --localnet "* ]] || cmd_parts+=("--localnet")
      ;;
    socat)
      if [[ "$joined" != *" -V "* ]]; then
        extra_val="$(smart_prompt_placeholder "TARGET" "Host tujuan untuk socat TCP")" || { warn "Dibatalkan."; return 0; }
        extra_port="$(smart_prompt_placeholder "PORT" "Port tujuan untuk socat TCP")" || { warn "Dibatalkan."; return 0; }
        cmd_parts+=("-" "TCP:$(printf '%q' "$extra_val"):$(printf '%q' "$extra_port")")
      fi
      ;;
  esac

  # Tambahkan argumen posisional jika tool membutuhkannya dan belum ada di flag
  case "$id" in
    ping|traceroute) pos_kind="TARGET" ;;
    nmap)
      [[ "$joined" == *" -iL "* ]] || pos_kind="TARGET"
      ;;
    whois|nslookup) pos_kind="DOMAIN" ;;
    dig)
      [[ "$joined" == *" -x "* ]] || pos_kind="DOMAIN"
      ;;
    curl|wget|whatweb) pos_kind="URL" ;;
    ethtool)
      if [[ "$joined" != *" -i "* ]] && [[ "$joined" != *" -S "* ]]; then
        pos_kind="IFACE"
      fi
      ;;
    searchsploit)
      [[ "$joined" == *" --cve "* ]] || pos_kind="QUERY"
      ;;
  esac

  if [ -n "$pos_kind" ]; then
    pos_val="$(smart_prompt_placeholder "$pos_kind" "Target/argumen utama untuk $label")" || { warn "Dibatalkan."; return 0; }
    cmd_parts+=("$(printf '%q' "$pos_val")")
  fi

  if [ "$need_sudo" -eq 1 ]; then
    assembled="sudo ${cmd_parts[*]}"
  else
    assembled="${cmd_parts[*]}"
  fi

  printf '\n'
  ui_card_header "Hasil Rakitan Flag Resmi" "$label"
  printf '\n  %s$ %s%s\n\n' "$C_PRIMARY$C_BOLD" "$assembled" "$C_RESET"
  read -r -e -i "$assembled" -p "Edit perintah (Enter untuk lanjut): " final_cmd || true
  [ -n "$final_cmd" ] || { warn "Dibatalkan."; return 0; }

  printf '\n  [r] Jalankan sekarang   [c] Salin ke clipboard   [d] Dry-run   [s] Simpan ke Automation   [b] Batal\n'
  read -r -p "Pilihan (R/c/d/s/b): " ans || true
  case "${ans:-r}" in
    c|C)
      if copy_to_clipboard "$final_cmd"; then ok "Disalin ke clipboard."; else printf '%s\n' "$final_cmd"; fi
      pause
      ;;
    d|D)
      DRY_RUN=1 runner_exec "$id" "$label" "$mode" "$need_sudo" "$final_cmd"
      ;;
    s|S)
      snippet_save_automation "$label (Flag Builder)" "$final_cmd" "Dirakit dari Flag Builder resmi $label" "$need_sudo"
      ;;
    b|B)
      warn "Dibatalkan."
      ;;
    *)
      if confirm_authorized_action "$id" "$final_cmd" "$need_sudo"; then
        runner_exec "$id" "$label" "$mode" "$need_sudo" "$final_cmd"
      else
        warn "Dibatalkan."
        pause
      fi
      ;;
  esac
}

knowledge_menu() {
  local id="${1:-}" file sel action
  if [ -z "$id" ]; then
    file="$(mktemp)"
    while IFS= read -r tf; do
      awk -F'|' '!/^#/ && NF>=11 {printf "%s\t%s\t%s\t%s\n", $2, $3, $4, $6}' "$tf"
    done < <(tools_files) | while IFS=$'\t' read -r tid label binary desc; do
      local fc
      fc="$(knowledge_flag_count "$tid")"
      printf '%-22s %s[%s flag]%s  %s%s%s\t%s\n' "$label" "$C_ACCENT" "$fc" "$C_RESET" "$C_MUTED" "$desc" "$C_RESET" "$tid"
    done > "$file"
    sel="$(ui_fzf \
      --prompt='  Panduan Tool ▸ ' \
      --ghost='Pilih tool untuk membaca panduan resmi & flag...' \
      --header="Knowledge Base Resmi Tool ($(tool_count_total) Tool)" \
      --header-first \
      --header-label=' Panduan Resmi ' \
      --preview="$SELF --preview-guide {2}" \
      --preview-window='right:58%:wrap' \
      --preview-label=' Ringkasan Panduan ' \
      --footer='Enter: Buka Panduan │ Esc: Kembali' \
      --footer-border=line \
      --delimiter=$'\t' --with-nth=1 < "$file")"
    rm -f "$file"
    [ -n "$sel" ] || return 0
    id="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  fi

  while true; do
    file="$(mktemp)"
    {
      printf '%s📖%s Baca Panduan Resmi (Bahasa Indonesia)\tguide\n' "$C_PRIMARY" "$C_RESET"
      printf '%s🧩%s Rakit Perintah dari Flag Resmi (Flag Builder)\tbuilder\n' "$C_OK" "$C_RESET"
      printf '%s🔎%s Cari Flag di Manual Lokal (--help / man)\tlive\n' "$C_CYAN" "$C_RESET"
      printf '%s⌘%s  Lihat Contoh Perintah (Snippets)\tsnippets\n' "$C_ACCENT" "$C_RESET"
      printf '%s📜%s Buka Manual Sistem Mentah (man / --help)\traw\n' "$C_MUTED" "$C_RESET"
      printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
    } > "$file"
    sel="$(ui_fzf \
      --prompt='  Knowledge ▸ ' \
      --header="Panduan Resmi: $(tool_field "$id" 3) ($id)" \
      --header-first \
      --header-label=' Knowledge Base ' \
      --preview="$SELF --preview-guide $id" \
      --preview-window='right:58%:wrap' \
      --preview-label=' Pratinjau Panduan ' \
      --footer='Enter: Pilih │ Esc: Kembali' \
      --footer-border=line \
      --delimiter=$'\t' --with-nth=1 < "$file")"
    rm -f "$file"
    [ -n "$sel" ] || return 0
    action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
    case "$action" in
      guide)
        if have less; then
          FORCE_COLOR=1 knowledge_render_guide "$id" | less -R
        else
          knowledge_render_guide "$id"
          pause
        fi
        ;;
      builder) knowledge_flag_builder "$id" ;;
      live) knowledge_live_flags "$id" ;;
      snippets) snippets_menu "$id" ;;
      raw) tool_help "$id" ;;
      *) return 0 ;;
    esac
  done
}
