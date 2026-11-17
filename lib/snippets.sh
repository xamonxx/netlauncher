# lib/snippets.sh - Browser contoh perintah, code snippet, dan eksekusi pintar

snippet_line_by_num() {
  snippet_line_by_ref "$1"
}

preview_snippet() {
  local ref="$1" line tool_id title cmd notes sudo ph binary status
  line="$(snippet_line_by_ref "$ref")"
  [ -n "$line" ] || { printf 'Snippet tidak ditemukan.\n'; return 0; }
  IFS=$'\t' read -r tool_id title cmd notes sudo ph <<< "$line"
  binary="$(tool_field "$tool_id" 4)"
  [ -n "$binary" ] || binary="$tool_id"
  if have "$binary"; then
    status="$(ui_badge ok "✓ TERPASANG")"
  else
    status="$(ui_badge err "✗ BELUM ADA")"
  fi

  printf '%s%s%s\n' "$C_PRIMARY$C_BOLD" "$title" "$C_RESET"
  printf '%sTool:%s %s (%s)  %b' "$C_MUTED" "$C_RESET" "$tool_id" "$binary" "$status"
  [ "$sudo" = "1" ] && printf '  %b' "$(ui_badge warn "⚡ SUDO")"
  printf '\n\n'

  printf '%sPenjelasan:%s\n%s%s%s\n\n' "$C_MUTED" "$C_RESET" "$C_WHITE" "$notes" "$C_RESET"

  printf '%s╭─ Contoh Perintah ───────────────────────────────────────╮%s\n' "$C_ACCENT" "$C_RESET"
  printf '%s│%s %s$ %s%s\n' "$C_ACCENT" "$C_RESET" "$C_OK$C_BOLD" "$cmd" "$C_RESET"
  printf '%s╰─────────────────────────────────────────────────────────╯%s\n' "$C_ACCENT" "$C_RESET"

  if [ -n "$ph" ]; then
    printf '\n%sParameter otomatis (Smart Fill):%s %s%s%s\n' "$C_MUTED" "$C_RESET" "$C_WARN" "$ph" "$C_RESET"
  fi

  printf '\n%sCuplikan Bash siap pakai:%s\n' "$C_MUTED" "$C_RESET"
  printf '%s#!/usr/bin/env bash\n# %s\n%s%s\n' "$C_DIM" "$title" "$cmd" "$C_RESET"
  printf '\n%sEnter: buka aksi (Jalankan / Edit / Salin / Simpan Automation)%s\n' "$C_MUTED" "$C_RESET"
}

snippets_menu() {
  local filter_tool="${1:-}" file sel ref header sf tag
  [ -f "$SNIPPETS_FILE" ] || { err "File snippet tidak ditemukan: $SNIPPETS_FILE"; pause; return 1; }
  file="$(mktemp)"
  while IFS= read -r sf; do
    if [ "$sf" = "$SNIPPETS_LOCAL_FILE" ]; then tag="local"; else tag="main"; fi
    awk -F'\t' -v ft="$filter_tool" -v tg="$tag" '
      !/^#/ && NF>=6 {
        if (ft == "" || $1 == ft) {
          printf "\033[36m⌘\033[0m  %-14s │ %-34s \033[2m%s\033[0m\t%s:%d\n", $1, $2, substr($3,1,45), tg, NR
        }
      }
    ' "$sf"
  done < <(snippets_files) > "$file"

  if [ ! -s "$file" ]; then
    rm -f "$file"
    warn "Belum ada contoh perintah untuk: ${filter_tool:-semua}"
    pause
    return 0
  fi

  if [ -n "$filter_tool" ]; then
    header="Contoh Perintah & Code: $filter_tool"
  else
    header="Koleksi Contoh Perintah & Automation ($(wc -l < "$file" | tr -d ' ') snippet)"
  fi

  sel="$(ui_fzf \
    --prompt='  Snippet ▸ ' \
    --ghost='Cari contoh perintah (nmap, tls, dns, curl, tcpdump, wordlist)...' \
    --header="$header" \
    --header-first \
    --header-label=' Code & Command Examples ' \
    --input-label=' Filter Snippet ' \
    --list-label=' Daftar Contoh ' \
    --preview="$SELF --preview-snippet {2}" \
    --preview-window='right:54%:wrap' \
    --preview-label=' Detail & Kode Bash ' \
    --footer='Enter: Aksi │ Ctrl-/: Preview │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  ref="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  snippet_action_menu "$ref"
}

snippet_save_automation() {
  local title="$1" cmd="$2" notes="$3" sudo="$4" slug out
  read -r -p "Nama file automation (tanpa .sh, mis. cek-tls): " slug || true
  [ -n "$slug" ] || { warn "Dibatalkan."; return 0; }
  slug="${slug//[^a-zA-Z0-9_-]/-}"
  out="$AUTOMATIONS_DIR/$slug.sh"
  cat > "$out" <<EOF
#!/usr/bin/env bash
# Automation: $title
# Deskripsi: $notes
# Sudo: $([ "$sudo" = "1" ] && echo ya || echo tidak)
set -uo pipefail

echo "== $title =="
echo "Waktu: \$(date -Is)"
echo

$cmd
EOF
  chmod 700 "$out"
  ok "Automation disimpan: $out"
  pause
}

snippet_action_menu() {
  local ref="$1" line tool_id title cmd notes sudo ph binary mode file sel action resolved edited
  line="$(snippet_line_by_ref "$ref")"
  [ -n "$line" ] || return 1
  IFS=$'\t' read -r tool_id title cmd notes sudo ph <<< "$line"
  binary="$(tool_field "$tool_id" 4)"
  [ -n "$binary" ] || binary="$tool_id"
  mode="$(tool_field "$tool_id" 10)"
  [ -n "$mode" ] || mode="term"

  file="$(mktemp)"
  {
    printf '%s▶%s  Jalankan (Smart Fill parameter)\trun\n' "$C_OK" "$C_RESET"
    printf '%s✎%s  Edit perintah sebelum jalankan\tedit\n' "$C_PRIMARY" "$C_RESET"
    printf '%s⧉%s  Salin perintah ke clipboard\tcopy\n' "$C_CYAN" "$C_RESET"
    printf '%s⚙%s  Simpan sebagai Custom Automation\tsave\n' "$C_WARN" "$C_RESET"
    printf '%s👁%s  Dry-run (pratinjau tanpa eksekusi)\tdry\n' "$C_ACCENT" "$C_RESET"
    printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"

  sel="$(ui_fzf \
    --prompt='  Aksi Snippet ▸ ' \
    --ghost='Pilih aksi untuk contoh perintah ini...' \
    --header="$title ($tool_id)" \
    --header-first \
    --header-label=' Aksi Snippet ' \
    --list-label=' Pilihan ' \
    --preview="$SELF --preview-snippet $(printf '%q' "$ref")" \
    --preview-window='right:56%:wrap' \
    --preview-label=' Detail Perintah ' \
    --footer='Enter: Pilih │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"

  case "$action" in
    run|dry)
      have "$binary" || { smart_missing_advisor "$binary" "$tool_id" "$(tool_field "$tool_id" 1)"; return 1; }
      resolved="$(smart_resolve_template "$cmd")" || { warn "Dibatalkan."; return 0; }
      if [ "$action" = "dry" ]; then
        DRY_RUN=1 runner_exec "$tool_id" "$title" "$mode" "$sudo" "$resolved"
      else
        if confirm_authorized_action "$tool_id" "$resolved" "$sudo"; then
          runner_exec "$tool_id" "$title" "$mode" "$sudo" "$resolved"
        else
          warn "Dibatalkan."
          pause
        fi
      fi
      ;;
    edit)
      have "$binary" || { smart_missing_advisor "$binary" "$tool_id" "$(tool_field "$tool_id" 1)"; return 1; }
      resolved="$(smart_resolve_template "$cmd")" || resolved="$cmd"
      read -r -e -i "$resolved" -p "Edit perintah: " edited || true
      [ -n "$edited" ] || { warn "Dibatalkan."; return 0; }
      if confirm_authorized_action "$tool_id" "$edited" "$sudo"; then
        runner_exec "$tool_id" "$title" "$mode" "$sudo" "$edited"
      else
        warn "Dibatalkan."
        pause
      fi
      ;;
    copy)
      if copy_to_clipboard "$cmd"; then
        ok "Perintah disalin ke clipboard:"
      else
        warn "Clipboard tidak tersedia. Salin manual:"
      fi
      printf '  %s%s%s\n' "$C_PRIMARY" "$cmd" "$C_RESET"
      pause
      ;;
    save)
      snippet_save_automation "$title" "$cmd" "$notes" "$sudo"
      ;;
    *) return 0 ;;
  esac
}
