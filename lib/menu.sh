# lib/menu.sh - Menu utama, pencarian global, aksi tool, eksekusi, favorit, riwayat & log

main_header() {
  local count total status_dot
  smart_net_context
  count="$(tool_count_installed)"
  total="$(tool_count_total)"
  if [ "$NET_ONLINE" = "ONLINE" ]; then
    status_dot="${C_OK}● ONLINE${C_RESET}"
  elif [ "$NET_ONLINE" = "LOKAL" ]; then
    status_dot="${C_WARN}◐ LOKAL${C_RESET}"
  else
    status_dot="${C_ERR}○ OFFLINE${C_RESET}"
  fi

  printf '%s◈ NETLAUNCHER v%s%s  %b  %s[%s]%s\n' \
    "$C_PRIMARY$C_BOLD" "$VERSION" "$C_RESET" "$status_dot" "$C_ACCENT" "$THEME" "$C_RESET"
  printf '%sHost:%s %s │ %sIface:%s %s │ %sTool:%s %s/%s\n' \
    "$C_MUTED" "$C_RESET" "$NET_HOST" \
    "$C_MUTED" "$C_RESET" "$NET_IFACE" \
    "$C_MUTED" "$C_RESET" "$count" "$total"
  printf '%sIP:%s %s │ %sGW:%s %s\n' \
    "$C_MUTED" "$C_RESET" "$NET_CIDR" \
    "$C_MUTED" "$C_RESET" "$NET_GW"
}

tool_info() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples status snip_count
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  if have "$binary"; then
    status="$(ui_badge ok "✓ TERPASANG")"
  else
    status="$(ui_badge err "✗ BELUM ADA")"
  fi

  printf '%s%s%s  %b' "$C_PRIMARY$C_BOLD" "$label" "$C_RESET" "$status"
  [ "$sudo" = "1" ] && printf '  %b' "$(ui_badge warn "⚡ SUDO")"
  [ "$mode" = "gui" ] && printf '  %b' "$(ui_badge accent "GUI")"
  is_fav "$id" && printf '  %b' "$(ui_badge info "★ FAVORIT")"
  printf '\n'

  printf '%sKategori:%s %s │ %sBinary:%s %s\n' "$C_MUTED" "$C_RESET" "${CAT_NAMES[$cat]:-$cat}" "$C_MUTED" "$C_RESET" "$binary"
  printf '%sTemplate:%s %s\n' "$C_MUTED" "$C_RESET" "${template:-$binary}"
  printf '%sBantuan :%s %s\n' "$C_MUTED" "$C_RESET" "$help"
  printf '\n%s%s%s\n' "$C_WHITE" "$desc" "$C_RESET"

  if [ -n "$examples" ]; then
    printf '\n%sContoh cepat:%s\n  %s$ %s%s\n' "$C_MUTED" "$C_RESET" "$C_OK" "$examples" "$C_RESET"
  fi

  if [ -f "$SNIPPETS_FILE" ]; then
    snip_count="$(awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {n++} END{print n+0}' "$SNIPPETS_FILE")"
    if [ "$snip_count" -gt 0 ]; then
      printf '\n%sContoh perintah tersedia (%s):%s\n' "$C_ACCENT$C_BOLD" "$snip_count" "$C_RESET"
      awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "  • %s\n    \033[2m$ %s\033[0m\n", $2, $3}' "$SNIPPETS_FILE" | head -n 8
    fi
  fi
  printf '\n%sEnter: buka aksi tool & command builder%s\n' "$C_MUTED" "$C_RESET"
}

preview_tool() {
  tool_info "$1"
}

preview_category() {
  local id="$1" cat
  smart_net_context
  case "$id" in
    search)
      printf '%s🔍 Cari Semua Tool & Contoh%s\n\nPencarian fuzzy lintas %s tool dan 100+ contoh perintah sekaligus.\n\nShortcut dari menu utama: %sCtrl-S%s\n' \
        "$C_PRIMARY$C_BOLD" "$C_RESET" "$(tool_count_total)" "$C_WARN" "$C_RESET" ;;
    snippets)
      printf '%s⌘ Contoh Perintah & Code%s\n\nKoleksi 100+ contoh perintah siap pakai dengan Smart Fill parameter, edit sebelum jalan, salin clipboard, dan simpan ke automation.\n\nShortcut: %sCtrl-E%s\n' \
        "$C_ACCENT$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET" ;;
    automation)
      printf '%s🤖 Custom Automation Scripts%s\n\nJalankan, edit, atau buat script Bash otomasi Anda sendiri di:\n%s\n' \
        "$C_PRIMARY$C_BOLD" "$C_RESET" "$AUTOMATIONS_DIR" ;;
    favorit)
      printf '%s★ Favorit%s\n\nTool yang Anda tandai bintang untuk akses cepat.\n' "$C_MAGENTA$C_BOLD" "$C_RESET" ;;
    riwayat)
      printf '%s↺ Riwayat & Log%s\n\nLihat 100 perintah terakhir, inspeksi log sesi, atau jalankan ulang perintah.\n\nShortcut: %sCtrl-L%s\n' \
        "$C_BLUE$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET" ;;
    wordlist)
      printf '%s▤ Wordlist Browser%s\n\nrockyou, SecLists, dan 4 koleksi wordlist Indonesia.\nAksi: salin path, buka di less, statistik.\n' \
        "$C_CYAN$C_BOLD" "$C_RESET" ;;
    resep)
      printf '%s⚡ Resep Otomasi Aman%s\n\n10 alur kerja terpandu: cek koneksi, info jaringan, audit web/TLS, DNS, monitor port, discovery lokal, scan berizin, capture, statistik wordlist, laporan.\n' \
        "$C_WARN$C_BOLD" "$C_RESET" ;;
    theme)
      printf '%s🎨 Tema & Animasi%s\n\nTema aktif: %s%s%s\nAnimasi: %s\n\nPilihan tema: cyber, tokyo, emerald, amber.\nShortcut: %sCtrl-T%s\n' \
        "$C_ACCENT$C_BOLD" "$C_RESET" "$C_PRIMARY" "$THEME" "$C_RESET" "$([ "${ANIM:-1}" = "1" ] && echo AKTIF || echo NONAKTIF)" "$C_WARN" "$C_RESET" ;;
    doctor)
      printf '%s✚ Doctor%s\n\nCek dependensi, tool, wordlist, hackingtool, terminal truecolor, dan akses sudo.\n' "$C_OK$C_BOLD" "$C_RESET" ;;
    update)
      printf '%s↑ Update%s\n\nUpdate hackingtool via git + pipx dan refresh index wordlist.\n' "$C_OK$C_BOLD" "$C_RESET" ;;
    help)
      printf '%s? Bantuan%s\n\nPanduan lengkap penggunaan NetLauncher v%s.\n' "$C_WARN$C_BOLD" "$C_RESET" "$VERSION" ;;
    quit)
      printf '%s× Keluar%s\n\nTutup NetLauncher.\n' "$C_ERR$C_BOLD" "$C_RESET" ;;
    *)
      cat="${CAT_NAMES[$id]:-$id}"
      printf '%s%s %s%s\n\n%s\n\n' "$C_PRIMARY$C_BOLD" "${CAT_ICONS[$id]:-▸}" "$cat" "$C_RESET" "${CAT_DESC[$id]:-}"
      awk -F'|' -v c="$id" '!/^#/ && $1==c {print $3 "|" $4 "|" $6}' "$TOOLS_FILE" |
      while IFS='|' read -r label binary desc; do
        if have "$binary"; then
          printf '%s✓%s %-22s %s%s%s\n' "$C_OK" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET"
        else
          printf '%s✗%s %-22s %s%s%s\n' "$C_ERR" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET"
        fi
      done
      printf '\n%sKonteks aktif:%s Iface %s │ Subnet %s │ GW %s\n' "$C_MUTED" "$C_RESET" "$NET_IFACE" "$NET_SUBNET" "$NET_GW"
      printf '%sEnter: buka kategori%s\n' "$C_MUTED" "$C_RESET"
      ;;
  esac
}

main_menu() {
  local file out key sel header
  file="$(mktemp)"
  header="$(main_header)"
  {
    printf '%s⚡%s %-26s %s(%s)%s\tdiagnostik\n' "$C_PRIMARY" "$C_RESET" "Diagnostik Jaringan" "$C_MUTED" "$(tool_count_category diagnostik)" "$C_RESET"
    printf '%s🌐%s %-26s %s(%s)%s\tdns\n' "$C_PRIMARY" "$C_RESET" "DNS & Web" "$C_MUTED" "$(tool_count_category dns)" "$C_RESET"
    printf '%s🔌%s %-26s %s(%s)%s\tinterface\n' "$C_PRIMARY" "$C_RESET" "Interface & Routing" "$C_MUTED" "$(tool_count_category interface)" "$C_RESET"
    printf '%s📡%s %-26s %s(%s)%s\tscan\n' "$C_PRIMARY" "$C_RESET" "Pemindaian & Monitoring" "$C_MUTED" "$(tool_count_category scan)" "$C_RESET"
    printf '%s📶%s %-26s %s(%s)%s\twireless\n' "$C_WARN" "$C_RESET" "Wireless (Berizin)" "$C_MUTED" "$(tool_count_category wireless)" "$C_RESET"
    printf '%s🛡%s  %-26s %s(%s)%s\tsecurity\n' "$C_WARN" "$C_RESET" "Tool Keamanan (Berizin)" "$C_MUTED" "$(tool_count_category security)" "$C_RESET"
    printf '%s🧰%s %-26s %s(%s)%s\thackingtool\n' "$C_ACCENT" "$C_RESET" "Hackingtool" "$C_MUTED" "$(tool_count_category hackingtool)" "$C_RESET"
    printf '%s🔍%s %-26s %s%s\n' "$C_PRIMARY" "$C_RESET" "Cari Semua Tool & Contoh" "$C_MUTED" "lintas kategori (^S)"$'\t'"search"
    printf '%s⌘%s  %-26s %s%s\n' "$C_ACCENT" "$C_RESET" "Contoh Perintah & Code" "$C_MUTED" "100+ snippet siap pakai (^E)"$'\t'"snippets"
    printf '%s⚙%s  %-26s %s%s\n' "$C_WARN" "$C_RESET" "Resep Otomasi Aman" "$C_MUTED" "10 alur kerja terpandu"$'\t'"resep"
    printf '%s🤖%s %-26s %s%s\n' "$C_PRIMARY" "$C_RESET" "Custom Automation" "$C_MUTED" "script bash kustom"$'\t'"automation"
    printf '%s▤%s  %-26s %s%s\n' "$C_CYAN" "$C_RESET" "Wordlist Browser" "$C_MUTED" "rockyou, SecLists, ID"$'\t'"wordlist"
    printf '%s★%s  %-26s %s%s\n' "$C_MAGENTA" "$C_RESET" "Favorit" "$C_MUTED" "tool yang ditandai"$'\t'"favorit"
    printf '%s↺%s  %-26s %s%s\n' "$C_BLUE" "$C_RESET" "Riwayat & Log" "$C_MUTED" "perintah & log sesi (^L)"$'\t'"riwayat"
    printf '%s🎨%s %-26s %s%s\n' "$C_ACCENT" "$C_RESET" "Tema & Animasi" "$C_MUTED" "tema: $THEME (^T)"$'\t'"theme"
    printf '%s✚%s  %-26s %s%s\n' "$C_OK" "$C_RESET" "Doctor" "$C_MUTED" "cek dependensi"$'\t'"doctor"
    printf '%s↑%s  %-26s %s%s\n' "$C_OK" "$C_RESET" "Update" "$C_MUTED" "hackingtool + wordlist"$'\t'"update"
    printf '%s?%s  %-26s %s%s\n' "$C_WARN" "$C_RESET" "Bantuan" "$C_MUTED" "panduan lengkap"$'\t'"help"
    printf '%s×%s  %-26s %s%s\n' "$C_ERR" "$C_RESET" "Keluar" "$C_MUTED" "tutup launcher"$'\t'"quit"
  } > "$file"

  out="$(ui_fzf \
    --prompt='  Pilih ▸ ' \
    --ghost='Ketik kategori, tool, atau fitur...' \
    --header="$header" \
    --header-first \
    --header-label=' Status Sistem ' \
    --input-label=' Pencarian ' \
    --list-label=' Menu Utama ' \
    --no-sort \
    --expect=ctrl-s,ctrl-e,ctrl-t,ctrl-l \
    --preview="$SELF --preview-category {2}" \
    --preview-window='right:52%:wrap' \
    --preview-label=' Inspector ' \
    --footer='Enter: Buka │ ^S: Cari │ ^E: Contoh │ ^T: Tema' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$out" ] || return 1

  key="$(printf '%s\n' "$out" | sed -n '1p')"
  sel="$(printf '%s\n' "$out" | sed -n '2p')"
  case "$key" in
    ctrl-s) printf 'search\n'; return 0 ;;
    ctrl-e) printf 'snippets\n'; return 0 ;;
    ctrl-t) printf 'theme\n'; return 0 ;;
    ctrl-l) printf 'riwayat\n'; return 0 ;;
  esac
  [ -n "$sel" ] || return 1
  printf '%s\n' "$sel" | awk -F'\t' '{print $2}'
}

preview_global() {
  local item="$1"
  case "$item" in
    tool:*) tool_info "${item#tool:}" ;;
    snip:*) preview_snippet "${item#snip:}" ;;
    *) printf 'Item tidak dikenal.\n' ;;
  esac
}

preview_history() {
  local val="$1" log_count
  if [ "$val" = "__LOGS__" ]; then
    log_count="$(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' 2>/dev/null | wc -l | tr -d ' ')"
    printf '%sLog Sesi Viewer%s\n\nDirektori: %s\nTotal log: %s\n\nTekan Enter untuk melihat dan membaca log sesi.\n' \
      "$C_PRIMARY$C_BOLD" "$C_RESET" "$LOG_DIR" "$log_count"
  else
    printf '%sPerintah Lengkap:%s\n\n  %s$ %s%s\n\nTekan Enter untuk menjalankan ulang.\n' \
      "$C_PRIMARY$C_BOLD" "$C_RESET" "$C_OK" "$val" "$C_RESET"
  fi
}

global_search_menu() {
  local file sel kind target
  file="$(mktemp)"
  {
    awk -F'|' '!/^#/ && NF>=11 {printf "tool\t%s\t%s\t%s\t%s\n", $2, $3, $4, $6}' "$TOOLS_FILE" |
    while IFS=$'\t' read -r _ id label binary desc; do
      if have "$binary"; then
        printf '%s✓%s [TOOL]    %-22s %s%s%s\ttool:%s\n' "$C_OK" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
      else
        printf '%s✗%s [TOOL]    %-22s %s%s%s\ttool:%s\n' "$C_ERR" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
      fi
    done
    if [ -f "$SNIPPETS_FILE" ]; then
      awk -F'\t' '!/^#/ && NF>=6 {printf "\033[36m⌘\033[0m [CONTOH]  %-12s │ %-24s \033[2m%s\033[0m\tsnip:%d\n", $1, $2, substr($3,1,36), NR}' "$SNIPPETS_FILE"
    fi
  } > "$file"

  sel="$(ui_fzf \
    --prompt='  Cari Global ▸ ' \
    --ghost='Ketik nama tool, protokol, atau contoh perintah...' \
    --header="Pencarian Global: $(tool_count_total) tool + contoh perintah" \
    --header-first \
    --header-label=' Global Smart Search ' \
    --input-label=' Kata Kunci ' \
    --list-label=' Hasil ' \
    --preview="$SELF --preview-global {2}" \
    --preview-window='right:54%:wrap' \
    --preview-label=' Inspector ' \
    --footer='Enter: Buka │ Ctrl-/: Preview │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  target="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$target" in
    tool:*) tool_action_menu "${target#tool:}" ;;
    snip:*) snippet_action_menu "${target#snip:}" ;;
  esac
}

category_menu() {
  local cat="$1" file sel id header
  file="$(mktemp)"
  awk -F'|' -v c="$cat" '!/^#/ && $1==c {print}' "$TOOLS_FILE" |
  while IFS='|' read -r category id label binary template desc help sudo arg_prompt mode examples; do
    if have "$binary"; then status="${C_OK}✓${C_RESET}"; else status="${C_ERR}✗${C_RESET}"; fi
    printf '%s  %-24s %s%s%s\t%s\n' "$status" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
  done > "$file"
  header="$(printf '%s%s %s%s  (%s)' "$C_PRIMARY$C_BOLD" "${CAT_ICONS[$cat]:-▸}" "${CAT_NAMES[$cat]:-$cat}" "$C_RESET" "$(tool_count_category "$cat")")"
  sel="$(ui_fzf \
    --prompt='  Tool ▸ ' \
    --ghost='Ketik nama tool untuk filter...' \
    --header="$header" \
    --header-first \
    --header-label=' Kategori ' \
    --input-label=' Filter Tool ' \
    --list-label=' Daftar Tool ' \
    --preview="$SELF --preview-tool {2}" \
    --preview-window='right:54%:wrap' \
    --preview-label=' Detail & Contoh ' \
    --footer='Enter: Aksi Tool │ Ctrl-/: Preview │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  id="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  tool_action_menu "$id"
}

tool_action_menu() {
  local id="$1" file sel action label binary status fav_label snip_count
  label="$(tool_field "$id" 3)"
  binary="$(tool_field "$id" 4)"
  if have "$binary"; then status="✓ terpasang"; else status="✗ belum terpasang"; fi
  if is_fav "$id"; then fav_label="★ Hapus dari favorit"; else fav_label="★ Tambah ke favorit"; fi
  snip_count=0
  [ -f "$SNIPPETS_FILE" ] && snip_count="$(awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {n++} END{print n+0}' "$SNIPPETS_FILE")"

  file="$(mktemp)"
  {
    printf '%s▶%s  Jalankan (Smart Prompt)\trun\n' "$C_OK" "$C_RESET"
    printf '%s🛠%s  Command Builder & Preset\tbuilder\n' "$C_PRIMARY" "$C_RESET"
    printf '%s⌘%s  Contoh Perintah (%s snippet)\tsnippets\n' "$C_ACCENT" "$C_RESET" "$snip_count"
    printf '%s⌨%s  Jalankan dengan argumen manual\targs\n' "$C_CYAN" "$C_RESET"
    printf '%s?%s  Bantuan tool\thelp\n' "$C_WARN" "$C_RESET"
    printf '%s▤%s  Ringkasan contoh\texamples\n' "$C_BLUE" "$C_RESET"
    printf '%s%s%s\tfav\n' "$C_MAGENTA" "$fav_label" "$C_RESET"
    printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"
  sel="$(ui_fzf \
    --prompt='  Aksi ▸ ' \
    --ghost='Pilih aksi untuk tool ini...' \
    --header="$label ($binary)  │  $status" \
    --header-first \
    --header-label=' Aksi Tool ' \
    --list-label=' Pilihan ' \
    --preview="$SELF --preview-tool $id" \
    --preview-window='right:56%:wrap' \
    --preview-label=' Inspector Tool ' \
    --footer='Enter: Pilih │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$action" in
    run) run_tool "$id" ;;
    builder) smart_command_builder "$id" ;;
    snippets) snippets_menu "$id" ;;
    args) run_tool_args "$id" ;;
    help) tool_help "$id" ;;
    examples) show_examples "$id" ;;
    fav) toggle_fav "$id" ;;
    *) return 0 ;;
  esac
}

execute_command() {
  local id="$1" label="$2" mode="$3" sudo_flag="$4" cmd="$5" log_file rc start_ts end_ts dur
  ui_card_header "Eksekusi: $label" "$cmd"
  if [ "$DRY_RUN" = "1" ]; then
    warn "[DRY-RUN] Perintah tidak dijalankan."
    pause
    return 0
  fi
  if [ "$sudo_flag" = "1" ]; then
    warn "Tool ini meminta sudo; Anda akan diminta password di terminal."
  fi
  printf '%s\t%s\t%s\n' "$(date -Is)" "$id" "$cmd" >> "$HISTORY_FILE"
  log_file="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-$id.log"
  {
    printf '# %s\n# tool: %s\n# command: %s\n# user: %s\n# host: %s\n\n' \
      "$(date -Is)" "$label" "$cmd" "${USER:-unknown}" "$(hostname 2>/dev/null || echo '-')"
  } > "$log_file"

  start_ts="$(date +%s)"
  if [ "$mode" = "gui" ]; then
    if have setsid; then
      setsid bash -c "$cmd" >/dev/null 2>&1 &
    else
      nohup bash -c "$cmd" >/dev/null 2>&1 &
    fi
    ok "Dijalankan di background (GUI)."
  else
    eval "$cmd"
    rc=$?
    end_ts="$(date +%s)"
    dur=$((end_ts - start_ts))
    printf '\n# exit=%s duration=%ss\n' "$rc" "$dur" >> "$log_file"
    stty sane 2>/dev/null || true
    printf '\n'
    if [ "$rc" -eq 0 ]; then
      ok "Selesai (exit 0 · ${dur}s)"
    else
      warn "Selesai dengan exit code $rc (${dur}s)"
    fi
  fi
  printf '%sLog:%s %s\n' "$C_MUTED" "$C_RESET" "$log_file"
  pause
}

run_tool() {
  local id="$1" extra="${2:-}" line cat label binary template desc help sudo arg_prompt mode examples cmd arg quoted kind="TARGET"
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; pause; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  have "$binary" || { smart_missing_advisor "$binary" "$label" "$cat"; return 1; }
  cmd="${template:-$binary}"
  if [ -n "$extra" ]; then
    cmd="$cmd $extra"
  elif [ -n "$arg_prompt" ] && [[ "$cmd" == *"%s"* ]]; then
    case "$arg_prompt" in
      *URL*) kind="URL" ;;
      *Domain*) kind="DOMAIN" ;;
      *Interface*) kind="IFACE" ;;
      *Subnet*) kind="SUBNET" ;;
      *Kata*) kind="QUERY" ;;
      *) kind="TARGET" ;;
    esac
    if [ -t 0 ]; then
      arg="$(smart_prompt_placeholder "$kind" "$label — $arg_prompt")" || { warn "Dibatalkan."; return 0; }
    else
      printf '%s%s%s\n' "$C_CYAN" "$desc" "$C_RESET"
      read -r -p "$arg_prompt: " arg || true
    fi
    [ -n "$arg" ] || { warn "Dibatalkan."; return 0; }
    quoted="$(printf '%q' "$arg")"
    cmd="${cmd//%s/$quoted}"
  fi
  execute_command "$id" "$label" "$mode" "$sudo" "$cmd"
}

run_tool_args() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples cmd args
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; pause; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  have "$binary" || { smart_missing_advisor "$binary" "$label" "$cat"; return 1; }
  printf '%s%s%s\n' "$C_PRIMARY" "$desc" "$C_RESET"
  printf '%sBantuan cepat:%s %s\n' "$C_MUTED" "$C_RESET" "$help"
  read -r -p "Argumen tambahan: " args || true
  [ -n "$args" ] || { warn "Dibatalkan."; return 0; }
  cmd="${template:-$binary}"
  if [[ "$cmd" == *"%s"* ]]; then
    cmd="${cmd//%s/$args}"
  else
    cmd="$cmd $args"
  fi
  execute_command "$id" "$label" "$mode" "$sudo" "$cmd"
}

tool_help() {
  local id="$1" help
  help="$(tool_field "$id" 7)"
  [ -n "$help" ] || { warn "Bantuan tidak tersedia."; pause; return 0; }
  printf '%sMenjalankan bantuan:%s %s\n' "$C_MUTED" "$C_RESET" "$help"
  if [[ "$help" == man\ * ]]; then
    eval "$help"
  elif have less; then
    eval "$help" 2>&1 | less -R
  else
    eval "$help" 2>&1
  fi
  pause
}

show_examples() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || return 1
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  ui_card_header "$label" "Kategori: ${CAT_NAMES[$cat]:-$cat} │ Binary: $binary"
  printf '\n  %sTemplate:%s %s\n' "$C_MUTED" "$C_RESET" "${template:-$binary}"
  printf '  %sBantuan :%s %s\n' "$C_MUTED" "$C_RESET" "$help"
  printf '\n  %sContoh utama:%s\n    %s$ %s%s\n' "$C_MUTED" "$C_RESET" "$C_OK" "${examples:-(lihat bantuan tool)}" "$C_RESET"
  if [ -f "$SNIPPETS_FILE" ]; then
    printf '\n  %sSemua contoh perintah:%s\n' "$C_ACCENT$C_BOLD" "$C_RESET"
    awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "    • %s\n      $ %s\n      (%s)\n\n", $2, $3, $4}' "$SNIPPETS_FILE"
  fi
  pause
}

favorites_menu() {
  local file sel id line label binary desc status
  [ -s "$FAV_FILE" ] || { warn "Belum ada favorit. Tambahkan dari menu aksi tool."; pause; return 0; }
  file="$(mktemp)"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    line="$(find_tool_line "$id")"
    [ -n "$line" ] || continue
    IFS='|' read -r _ _ label binary _ desc _ _ _ _ _ <<< "$line"
    if have "$binary"; then status="${C_OK}✓${C_RESET}"; else status="${C_ERR}✗${C_RESET}"; fi
    printf '%s  %-24s %s%s%s\t%s\n' "$status" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
  done < "$FAV_FILE" > "$file"
  sel="$(ui_fzf \
    --prompt='  Favorit ▸ ' \
    --ghost='Cari tool favorit...' \
    --header='Tool Favorit Anda' \
    --header-first \
    --header-label=' Favorit ' \
    --preview="$SELF --preview-tool {2}" \
    --preview-window='right:56%:wrap' \
    --preview-label=' Detail Tool ' \
    --footer='Enter: Aksi Tool │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  id="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  tool_action_menu "$id"
}

preview_log() {
  local path="$1"
  [ -f "$path" ] || { printf 'Log tidak ditemukan.\n'; return 0; }
  printf '%s%s%s\n' "$C_PRIMARY$C_BOLD" "$(basename "$path")" "$C_RESET"
  printf '%sUkuran:%s %s\n\n' "$C_MUTED" "$C_RESET" "$(du -h "$path" 2>/dev/null | awk '{print $1}')"
  head -n 80 "$path" 2>/dev/null
}

logs_menu() {
  local file sel path
  file="$(mktemp)"
  find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' 2>/dev/null | sort -r | head -n 100 | while IFS= read -r path; do
    printf '%s📄%s %-36s %s(%s)%s\t%s\n' "$C_CYAN" "$C_RESET" "$(basename "$path")" "$C_MUTED" "$(du -h "$path" | awk '{print $1}')" "$C_RESET" "$path"
  done > "$file"
  if [ ! -s "$file" ]; then
    rm -f "$file"
    warn "Belum ada log sesi."
    pause
    return 0
  fi
  sel="$(ui_fzf \
    --prompt='  Log Sesi ▸ ' \
    --ghost='Cari file log...' \
    --header="Log Sesi ($LOG_DIR)" \
    --header-first \
    --header-label=' Log Viewer ' \
    --preview="$SELF --preview-log {2}" \
    --preview-window='right:58%:wrap' \
    --preview-label=' Isi Log ' \
    --footer='Enter: Buka di less │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  path="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  if have less; then less -R "$path"; else cat "$path"; pause; fi
}

history_menu() {
  local file sel cmd ans log_count
  log_count="$(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' 2>/dev/null | wc -l | tr -d ' ')"
  file="$(mktemp)"
  {
    printf '%s📄%s  Buka Log Sesi Viewer (%s log)\t__LOGS__\n' "$C_CYAN" "$C_RESET" "$log_count"
    if [ -s "$HISTORY_FILE" ]; then
      if have tac; then
        tail -n 100 "$HISTORY_FILE" | tac | awk -F'\t' '{printf "%s  %-16s %s\t%s\n", $1, $2, substr($3,1,55), $3}'
      else
        tail -n 100 "$HISTORY_FILE" | awk -F'\t' '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}' | awk -F'\t' '{printf "%s  %-16s %s\t%s\n", $1, $2, substr($3,1,55), $3}'
      fi
    fi
  } > "$file"
  sel="$(ui_fzf \
    --prompt='  Riwayat ▸ ' \
    --ghost='Cari riwayat perintah atau buka log sesi...' \
    --header='Riwayat Perintah & Log Sesi' \
    --header-first \
    --header-label=' Riwayat & Log ' \
    --preview="$SELF --preview-history {2}" \
    --preview-window='right:48%:wrap' \
    --preview-label=' Detail Riwayat ' \
    --footer='Enter: Jalankan Ulang / Buka Log │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  cmd="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  [ -n "$cmd" ] || return 0
  if [ "$cmd" = "__LOGS__" ]; then
    logs_menu
    return 0
  fi
  printf '%sPerintah:%s %s\n' "$C_MUTED" "$C_RESET" "$cmd"
  read -r -p "Jalankan ulang? (y/N): " ans || true
  if [[ "$ans" =~ ^[yY]$ ]]; then
    execute_command "history" "Riwayat" "term" "0" "$cmd"
  fi
}
