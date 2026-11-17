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
  local ws_lbl
  if ws_lbl="$(workspace_active_label 2>/dev/null)" && [ -n "$ws_lbl" ]; then
    printf '%s◎ Workspace:%s %s%s%s\n' "$C_ACCENT" "$C_RESET" "$C_ACCENT" "$ws_lbl" "$C_RESET"
  fi
}

tool_info() {
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples status snip_count=0
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

  local sf
  while IFS= read -r sf; do
    [ -f "$sf" ] || continue
    snip_count=$((snip_count + $(awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {n++} END{print n+0}' "$sf")))
  done < <(snippets_files)
  if [ "$snip_count" -gt 0 ]; then
    printf '\n%sContoh perintah tersedia (%s):%s\n' "$C_ACCENT$C_BOLD" "$snip_count" "$C_RESET"
    while IFS= read -r sf; do
      awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "  • %s\n    \033[2m$ %s\033[0m\n", $2, $3}' "$sf"
    done < <(snippets_files) | head -n 8
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
    knowledge)
      printf '%s📖 Knowledge Base Resmi Tool%s\n\nPanduan resmi Bahasa Indonesia untuk %s tool, referensi flag terkurasi, Interactive Flag Builder, dan ekstrak flag langsung dari --help/man lokal.\n\nShortcut: %sCtrl-K%s\n' \
        "$C_OK$C_BOLD" "$C_RESET" "$(tool_count_total)" "$C_WARN" "$C_RESET" ;;
    workspace)
      printf '%s◎ Target Workspace%s\n\nSimpan TARGET, DOMAIN, URL, SUBNET, dan IFACE aktif agar dipakai otomatis oleh Smart Prompt, Flag Builder, dan Automation Flow.\n\nShortcut: %sCtrl-W%s\n' \
        "$C_ACCENT$C_BOLD" "$C_RESET" "$C_WARN" "$C_RESET"
      printf '\n%sWorkspace saat ini:%s\n' "$C_MUTED" "$C_RESET"
      workspace_active_label 2>/dev/null | sed 's/^/  /' || printf '  (kosong)\n'
      ;;
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
    flow)
      printf '%s🌊 Automation Flow%s\n\nPipeline otomasi deklaratif dari file .flow: variabel, condition, capture, parser, dan ekspor laporan Markdown.\n\nFlow tersedia: %s\n' \
        "$C_CYAN$C_BOLD" "$C_RESET" "$(flow_list_files 2>/dev/null | wc -l | tr -d ' ')"
      printf '\nShortcut: menu utama → Automation Flow.\n'
      ;;
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
    printf '%s📖%s %-26s %s%s\n' "$C_OK" "$C_RESET" "Knowledge Base Resmi" "$C_MUTED" "panduan & flag builder (^K)"$'\t'"knowledge"
    printf '%s◎%s  %-26s %s%s\n' "$C_ACCENT" "$C_RESET" "Target Workspace" "$C_MUTED" "target aktif (^W)"$'\t'"workspace"
    printf '%s⚙%s  %-26s %s%s\n' "$C_WARN" "$C_RESET" "Resep Otomasi Aman" "$C_MUTED" "10 alur kerja + .flow"$'\t'"resep"
    printf '%s🌊%s %-26s %s%s\n' "$C_CYAN" "$C_RESET" "Automation Flow" "$C_MUTED" "pipeline .flow deklaratif"$'\t'"flow"
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
    --expect=ctrl-s,ctrl-e,ctrl-t,ctrl-l,ctrl-k,ctrl-w \
    --preview="$SELF --preview-category {2}" \
    --preview-window='right:52%:wrap' \
    --preview-label=' Inspector ' \
    --footer='Enter: Buka │ ^S: Cari │ ^E: Contoh │ ^K: Knowledge │ ^W: Workspace' \
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
    ctrl-k) printf 'knowledge\n'; return 0 ;;
    ctrl-w) printf 'workspace\n'; return 0 ;;
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
    local tf sf tag
    while IFS= read -r tf; do
      awk -F'|' '!/^#/ && NF>=11 {printf "tool\t%s\t%s\t%s\t%s\n", $2, $3, $4, $6}' "$tf"
    done < <(tools_files) |
    while IFS=$'\t' read -r _ id label binary desc; do
      if have "$binary"; then
        printf '%s✓%s [TOOL]    %-22s %s%s%s\ttool:%s\n' "$C_OK" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
      else
        printf '%s✗%s [TOOL]    %-22s %s%s%s\ttool:%s\n' "$C_ERR" "$C_RESET" "$label" "$C_MUTED" "$desc" "$C_RESET" "$id"
      fi
    done
    while IFS= read -r sf; do
      if [ "$sf" = "$SNIPPETS_LOCAL_FILE" ]; then tag="local"; else tag="main"; fi
      awk -F'\t' -v tg="$tag" '!/^#/ && NF>=6 {printf "\033[36m⌘\033[0m [CONTOH]  %-12s │ %-24s \033[2m%s\033[0m\tsnip:%s:%d\n", $1, $2, substr($3,1,36), tg, NR}' "$sf"
    done < <(snippets_files)
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
  local cat="$1" file sel id header tf status
  file="$(mktemp)"
  while IFS= read -r tf; do
    awk -F'|' -v c="$cat" '!/^#/ && $1==c {print}' "$tf"
  done < <(tools_files) |
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
  local sf_sc
  while IFS= read -r sf_sc; do
    [ -f "$sf_sc" ] && snip_count=$((snip_count + $(awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {n++} END{print n+0}' "$sf_sc")))
  done < <(snippets_files)

  file="$(mktemp)"
  {
    printf '%s▶%s  Jalankan (Smart Prompt)\trun\n' "$C_OK" "$C_RESET"
    printf '%s🧩%s  Flag Builder Resmi (%s flag)\tbuilder-flags\n' "$C_OK" "$C_RESET" "$(knowledge_flag_count "$id" 2>/dev/null || echo 0)"
    printf '%s🛠%s  Command Builder & Preset\tbuilder\n' "$C_PRIMARY" "$C_RESET"
    printf '%s⌘%s  Contoh Perintah (%s snippet)\tsnippets\n' "$C_ACCENT" "$C_RESET" "$snip_count"
    printf '%s📖%s  Panduan Resmi Tool\tknowledge\n' "$C_ACCENT" "$C_RESET"
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
    builder-flags) knowledge_flag_builder "$id" ;;
    knowledge) knowledge_menu "$id" ;;
    snippets) snippets_menu "$id" ;;
    args) run_tool_args "$id" ;;
    help) tool_help "$id" ;;
    examples) show_examples "$id" ;;
    fav) toggle_fav "$id" ;;
    *) return 0 ;;
  esac
}

# Kompatibilitas: semua pemanggil lama kini lewat runner modern (PTY + parser + post-menu).
execute_command() {
  runner_exec "$@"
}

run_tool() {
  local id="$1" extra="${2:-}" line cat label binary template desc help sudo arg_prompt mode examples cmd arg quoted kind="TARGET"
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || { err "Tool tidak ditemukan: $id"; pause; return 1; }
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  have "$binary" || { smart_missing_advisor "$binary" "$label" "$cat"; return 1; }
  cmd="${template:-$binary}"
  if [ -n "$extra" ]; then
    if [[ "$cmd" == *"%s"* ]]; then
      cmd="${cmd//%s/$(printf '%q' "$extra")}"
    else
      cmd="$cmd $extra"
    fi
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
  if confirm_authorized_action "$id" "$cmd" "$sudo"; then
    execute_command "$id" "$label" "$mode" "$sudo" "$cmd"
  else
    warn "Dibatalkan."
    pause
  fi
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
  if confirm_authorized_action "$id" "$cmd" "$sudo"; then
    execute_command "$id" "$label" "$mode" "$sudo" "$cmd"
  else
    warn "Dibatalkan."
    pause
  fi
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
  local id="$1" line cat label binary template desc help sudo arg_prompt mode examples sf
  line="$(find_tool_line "$id")"
  [ -n "$line" ] || return 1
  IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
  ui_card_header "$label" "Kategori: ${CAT_NAMES[$cat]:-$cat} │ Binary: $binary"
  printf '\n  %sTemplate:%s %s\n' "$C_MUTED" "$C_RESET" "${template:-$binary}"
  printf '  %sBantuan :%s %s\n' "$C_MUTED" "$C_RESET" "$help"
  printf '\n  %sContoh utama:%s\n    %s$ %s%s\n' "$C_MUTED" "$C_RESET" "$C_OK" "${examples:-(lihat bantuan tool)}" "$C_RESET"
  printf '\n  %sSemua contoh perintah:%s\n' "$C_ACCENT$C_BOLD" "$C_RESET"
  while IFS= read -r sf; do
    [ -f "$sf" ] && awk -F'\t' -v tid="$id" '!/^#/ && $1==tid {printf "    • %s\n      $ %s\n      (%s)\n\n", $2, $3, $4}' "$sf"
  done < <(snippets_files)
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
  local file sel path action n total report_n
  total="$(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' 2>/dev/null | wc -l | tr -d ' ')"
  report_n="$(find "$REPORT_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  file="$(mktemp)"
  {
    printf '%s📝%s  Ekspor Ringkasan Log ke Markdown\t__EXPORT__\n' "$C_GREEN" "$C_RESET"
    printf '%s🗂%s  Buka Folder Laporan (~/laporan, %s file)\t__REPORT__\n' "$C_ACCENT" "$C_RESET" "$report_n"
    printf '%s🌊%s  Filter Hanya Log Automation Flow\t__FLOWS__\n' "$C_CYAN" "$C_RESET"
    find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' 2>/dev/null | sort -r | head -n 100 | while IFS= read -r path; do
      case "$(basename "$path")" in
        *-flow-*) tag="flow" ;;
        *-recipe-*) tag="resep" ;;
        *) tag="tool" ;;
      esac
      printf '%s📄%s [%s] %-36s %s(%s)%s\t%s\n' "$C_CYAN" "$C_RESET" "$tag" "$(basename "$path")" "$C_MUTED" "$(du -h "$path" | awk '{print $1}')" "$C_RESET" "$path"
    done
  } > "$file"
  if [ "$(wc -l < "$file" | tr -d ' ')" -le 3 ]; then
    rm -f "$file"
    warn "Belum ada log sesi."
    pause
    return 0
  fi
  sel="$(ui_fzf \
    --prompt='  Log Sesi ▸ ' \
    --ghost='Cari log sesi, tool, flow, atau resep...' \
    --header="Log Sesi: $total file │ $LOG_DIR" \
    --header-first \
    --header-label=' Log & Report Viewer ' \
    --preview="$SELF --preview-log {2}" \
    --preview-window='right:58%:wrap' \
    --preview-label=' Isi Log ' \
    --footer='Enter: Buka │ Ctrl-/: Preview │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$action" in
    __EXPORT__)
      recipe_laporan
      ;;
    __REPORT__)
      if [ -d "$REPORT_DIR" ]; then
        if have fzf; then
          find "$REPORT_DIR" -maxdepth 1 -type f -name '*.md' -printf '%f\t%p\n' 2>/dev/null | \
            ui_fzf --prompt='  Laporan ▸ ' --header="Laporan Markdown ($REPORT_DIR)" \
            --delimiter=$'\t' --with-nth=1 | awk -F'\t' '{print $2}' | while IFS= read -r rp; do
              [ -n "$rp" ] && { have less && less -R "$rp" || cat "$rp"; }
            done
        else
          ls -la "$REPORT_DIR" | head -n 40
          pause
        fi
      fi
      ;;
    __FLOWS__)
      find "$LOG_DIR" -maxdepth 1 -type f -name '*-flow-*.log' 2>/dev/null | sort -r | head -n 50 | while IFS= read -r path; do
        printf '%s🌊%s %-40s\t%s\n' "$C_CYAN" "$C_RESET" "$(basename "$path")" "$path"
      done > "$file"
      sel="$(ui_fzf --prompt='  Log Flow ▸ ' --header='Log Automation Flow' --delimiter=$'\t' --with-nth=1 \
        --preview="$SELF --preview-log {2}" --preview-window='right:58%:wrap' < "$file")"
      rm -f "$file"
      [ -n "$sel" ] || return 0
      path="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
      have less && less -R "$path" || cat "$path"
      ;;
    *)
      path="$action"
      [ -f "$path" ] || return 0
      if have less; then less -R "$path"; else cat "$path"; pause; fi
      ;;
  esac
}

workspace_menu() {
  local file sel key val target domain url subnet iface note
  while true; do
    file="$(mktemp)"
    {
      printf '%s%s  Target    :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_TARGET:-(kosong)}" "$C_RESET" "edit:WS_TARGET"
      printf '%s%s  Domain    :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_DOMAIN:-(kosong)}" "$C_RESET" "edit:WS_DOMAIN"
      printf '%s%s  URL       :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_URL:-(kosong)}" "$C_RESET" "edit:WS_URL"
      printf '%s%s  Subnet    :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_SUBNET:-(kosong)}" "$C_RESET" "edit:WS_SUBNET"
      printf '%s%s  Interface :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_IFACE:-(kosong)}" "$C_RESET" "edit:WS_IFACE"
      printf '%s%s  Catatan   :%s %s%s\t%s\n' "$C_PRIMARY" "◎" "$C_MUTED" "${WS_NOTE:-(kosong)}" "$C_RESET" "edit:WS_NOTE"
      printf '%s✓%s  Simpan Workspace\t__SAVE__\n' "$C_OK" "$C_RESET"
      printf '%s✎%s  Isi dari Konteks Jaringan Terdeteksi\t__AUTO__\n' "$C_ACCENT" "$C_RESET"
      printf '%s✗%s  Kosongkan Workspace\t__CLEAR__\n' "$C_WARN" "$C_RESET"
      printf '%s←%s  Kembali (tanpa simpan)\t__BACK__\n' "$C_MUTED" "$C_RESET"
    } > "$file"
    sel="$(ui_fzf \
      --prompt='  Workspace ▸ ' \
      --ghost='Pilih field atau aksi workspace...' \
      --header="Target Workspace ($WORKSPACE_FILE)" \
      --header-first \
      --header-label=' Target Workspace ' \
      --list-label=' Atribut Target ' \
      --footer='Enter: Edit / Simpan │ Esc: Kembali' \
      --footer-border=line \
      --delimiter=$'\t' --with-nth=1 < "$file")"
    rm -f "$file"
    [ -n "$sel" ] || break
    key="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
    case "$key" in
      edit:*)
        val="${key#edit:}"
        read -r -p "Nilai baru untuk $val (kosongkan untuk hapus): " val || true
        case "${key#edit:}" in
          WS_TARGET) WS_TARGET="$val" ;;
          WS_DOMAIN) WS_DOMAIN="$val" ;;
          WS_URL) WS_URL="$val" ;;
          WS_SUBNET) WS_SUBNET="$val" ;;
          WS_IFACE) WS_IFACE="$val" ;;
          WS_NOTE) WS_NOTE="$val" ;;
        esac
        ;;
      __SAVE__)
        save_workspace
        ok "Workspace disimpan: $WORKSPACE_FILE"
        break
        ;;
      __AUTO__)
        smart_net_context
        [ -n "$NET_IFACE" ] && [ "$NET_IFACE" != "-" ] && WS_IFACE="$NET_IFACE"
        [ -n "$NET_SUBNET" ] && [ "$NET_SUBNET" != "-" ] && WS_SUBNET="$NET_SUBNET"
        [ -n "$NET_IP" ] && [ "$NET_IP" != "-" ] && WS_TARGET="$NET_IP"
        ok "Workspace diisi dari konteks jaringan. Simpan untuk menyimpan perubahan."
        ;;
      __CLEAR__)
        clear_workspace
        warn "Workspace dikosongkan."
        break
        ;;
      *) break ;;
    esac
  done
}

workspace_cli() {
  local sub="${1:-show}" k v
  shift || true
  case "$sub" in
    show)
      if ! workspace_active_label; then
        printf '(workspace kosong)\n'
      else
        printf '\n'
      fi
      printf '%sFile:%s %s\n' "$C_MUTED" "$C_RESET" "$WORKSPACE_FILE"
      ;;
    set)
      [ -n "${1:-}" ] || die "Gunakan: netlauncher workspace set KEY=NILAI [KEY=NILAI ...]"
      for k in "$@"; do
        [[ "$k" == *=* ]] || continue
        v="${k#*=}"
        case "${k%%=*}" in
          TARGET) WS_TARGET="$v" ;;
          DOMAIN) WS_DOMAIN="$v" ;;
          URL) WS_URL="$v" ;;
          SUBNET) WS_SUBNET="$v" ;;
          IFACE) WS_IFACE="$v" ;;
          NOTE) WS_NOTE="$v" ;;
          *) err "Kunci workspace tidak dikenal: ${k%%=*}" ;;
        esac
      done
      save_workspace
      ok "Workspace disimpan."
      ;;
    clear)
      clear_workspace
      ok "Workspace dikosongkan."
      ;;
    *)
      require_fzf
      workspace_menu
      ;;
  esac
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
