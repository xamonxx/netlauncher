# lib/wordlists.sh - Indexer, browser, preview, salin path, dan statistik wordlist

WL_SEEN_FILE=""
WL_TMP=""

add_wordlist() {
  local name="$1" path="$2" category="$3" source="$4" license="$5" real lines size
  [ -f "$path" ] || return 0
  real="$(readlink -f "$path" 2>/dev/null || printf '%s' "$path")"
  grep -qxF "$real" "$WL_SEEN_FILE" 2>/dev/null && return 0
  printf '%s\n' "$real" >> "$WL_SEEN_FILE"
  lines="$(wc -l < "$path" 2>/dev/null || echo 0)"
  lines="${lines//[!0-9]/}"
  [ -n "$lines" ] || lines=0
  size="$(du -h "$path" 2>/dev/null | awk '{print $1}')"
  [ -n "$size" ] || size="?"
  printf '%s|%s|%s|%s|%s|%s|%s\n' "$name" "$path" "$category" "$lines" "$size" "$source" "$license" >> "$WL_TMP"
}

add_dir() {
  local dir="$1" pattern="$2" category="$3" source="$4" license="$5" max="${6:-20}" f
  [ -d "$dir" ] || return 0
  while IFS= read -r f; do
    add_wordlist "$(basename "$f")" "$f" "$category" "$source" "$license"
  done < <(find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | sort | head -n "$max")
}

_wordlist_build_index() {
  local f
  WL_TMP="$(mktemp)"
  WL_SEEN_FILE="$(mktemp)"
  printf '# name|path|category|lines|size|source|license\n' > "$WL_TMP"
  add_wordlist "rockyou" "$HOME/wordlists/rockyou.txt" "Password" "Kali wordlists" "Tidak jelas"
  add_wordlist "Indonesian Pwdb Top 150" "$HOME/wordlists/indonesian/indonesian-pwdb-top150.txt" "Password ID" "SecLists" "MIT"
  for f in "$HOME"/wordlists/indonesian/geovedi/*.lst; do
    [ -f "$f" ] || continue
    add_wordlist "$(basename "$f")" "$f" "Bahasa ID" "geovedi/indonesian-wordlist" "Public Domain"
  done
  add_wordlist "KBBI v6.1.0" "$HOME/wordlists/indonesian/kbbi/all_entries_v6.1.0.txt" "Bahasa ID" "aryakdaniswara/kbbi-v6-wordlist" "Tidak dinyatakan"
  add_wordlist "REI Indonesia Password" "$HOME/wordlists/indonesian/elliottophellia/rei-indonesia-wordlist.txt" "Password ID" "elliottophellia/wordlist" "CC BY-SA 4.0"
  add_wordlist "John password.lst" "/usr/share/john/password.lst" "Password" "John the Ripper" "Ikuti paket"
  add_wordlist "Nmap passwords.lst" "/usr/share/nmap/nselib/data/passwords.lst" "Password" "Nmap" "Ikuti paket"
  add_wordlist "SQLMap wordlist" "/usr/share/sqlmap/data/txt/wordlist.txt" "Web" "SQLMap" "Ikuti paket"
  add_wordlist "SecLists names" "/usr/share/seclists/Usernames/Names/names.txt" "Username" "SecLists" "MIT"
  add_wordlist "SecLists top usernames" "/usr/share/seclists/Usernames/top-usernames-shortlist.txt" "Username" "SecLists" "MIT"
  add_dir "/usr/share/seclists/Passwords/Common-Credentials" "*.txt" "Password" "SecLists" "MIT" 40
  add_dir "/usr/share/seclists/Passwords/Common-Credentials/Language-Specific" "*.txt" "Password" "SecLists" "MIT" 20
  add_dir "/usr/share/seclists/Discovery/Web-Content" "*.txt" "Web Content" "SecLists" "MIT" 25
  add_dir "/usr/share/seclists/Usernames" "*.txt" "Username" "SecLists" "MIT" 15
  add_dir "/usr/share/dirb/wordlists" "*.txt" "Web Content" "dirb" "Ikuti paket" 10
  add_dir "/usr/share/dirbuster/wordlists" "*.txt" "Web Content" "DirBuster" "Ikuti paket" 10
  add_dir "/usr/share/wfuzz/wordlist" "*.txt" "Web Content" "Wfuzz" "Ikuti paket" 10
  add_dir "/usr/share/metasploit-framework/data/wordlists" "*.txt" "Password/Umum" "Metasploit" "Ikuti paket" 15
  add_dir "/usr/share/fern-wifi-cracker/extras/wordlists" "*.txt" "Wireless" "Fern WiFi" "Ikuti paket" 10
  mv "$WL_TMP" "$WORDLISTS_FILE"
  chmod 600 "$WORDLISTS_FILE"
  rm -f "$WL_SEEN_FILE"
}

wordlist_refresh() {
  local n
  ui_spin "Mengindeks wordlist lokal & SecLists..." _wordlist_build_index
  n="$(awk -F'|' '!/^#/ && NF>1 {n++} END{print n+0}' "$WORDLISTS_FILE")"
  ok "Index wordlist diperbarui: $n entri."
}

wordlist_menu() {
  local mode="${1:-}" file sel path
  if [ "$mode" = "refresh" ]; then wordlist_refresh; return 0; fi
  [ -s "$WORDLISTS_FILE" ] || wordlist_refresh
  file="$(mktemp)"
  awk -F'|' '!/^#/ && NF>=7 {printf "%s  \033[2m[%s · %s baris · %s]\033[0m\t%s\n", $1, $3, $4, $5, $2}' "$WORDLISTS_FILE" > "$file"
  sel="$(ui_fzf \
    --prompt='  Wordlist ▸ ' \
    --ghost='Cari wordlist (indonesia, rockyou, seclists, dirb)...' \
    --header="Total: $(wc -l < "$file" | tr -d ' ') wordlist terindeks" \
    --header-first \
    --header-label=' Browser Wordlist ' \
    --input-label=' Filter Wordlist ' \
    --list-label=' Daftar Wordlist ' \
    --preview="$SELF --preview-wordlist {2}" \
    --preview-window='right:54%:wrap' \
    --preview-label=' Info & Cuplikan ' \
    --footer='Enter: Aksi │ Ctrl-/: Preview │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  path="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  wordlist_action_menu "$path"
}

preview_wordlist() {
  local path="$1" line name category lines size source license
  line="$(awk -F'|' -v p="$path" '!/^#/ && $2==p {print; exit}' "$WORDLISTS_FILE")"
  if [ -n "$line" ]; then
    IFS='|' read -r name _ category lines size source license <<< "$line"
    printf '%s%s%s\n' "$C_PRIMARY$C_BOLD" "$name" "$C_RESET"
    printf '%sPath:%s %s\n' "$C_MUTED" "$C_RESET" "$path"
    printf '%sKategori:%s %s │ %sBaris:%s %s │ %sUkuran:%s %s\n' \
      "$C_MUTED" "$C_RESET" "$category" "$C_MUTED" "$C_RESET" "$lines" "$C_MUTED" "$C_RESET" "$size"
    printf '%sSumber:%s %s │ %sLisensi:%s %s\n\n' "$C_MUTED" "$C_RESET" "$source" "$C_MUTED" "$C_RESET" "$license"
  else
    printf '%s\n\n' "$path"
  fi
  printf '%s--- 20 baris pertama ---%s\n' "$C_MUTED" "$C_RESET"
  head -n 20 "$path" 2>/dev/null
}

wordlist_action_menu() {
  local path="$1" file sel action qpath
  [ -f "$path" ] || { err "File tidak ditemukan: $path"; pause; return 1; }
  qpath="$(printf '%q' "$path")"
  file="$(mktemp)"
  {
    printf '%s⧉%s  Salin path ke clipboard\tcopy\n' "$C_CYAN" "$C_RESET"
    printf '%s▤%s  Buka di less\topen\n' "$C_BLUE" "$C_RESET"
    printf '%sΣ%s  Statistik lengkap\tstats\n' "$C_GREEN" "$C_RESET"
    printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"
  sel="$(ui_fzf \
    --prompt='  Aksi Wordlist ▸ ' \
    --ghost='Pilih aksi...' \
    --header="$(basename "$path")" \
    --header-first \
    --header-label=' Aksi Wordlist ' \
    --list-label=' Pilihan ' \
    --preview="$SELF --preview-wordlist $qpath" \
    --preview-window='right:56%:wrap' \
    --preview-label=' Info & Cuplikan ' \
    --footer='Enter: Pilih │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  action="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$action" in
    copy) wordlist_copy "$path" ;;
    open) wordlist_open "$path" ;;
    stats) wordlist_stats "$path" ;;
    *) return 0 ;;
  esac
}

wordlist_copy() {
  local path="$1"
  if copy_to_clipboard "$path"; then
    ok "Path disalin ke clipboard: $path"
  else
    warn "Clipboard tidak tersedia. Path:"
    printf '%s\n' "$path"
  fi
  pause
}

wordlist_open() {
  local path="$1"
  if have less; then less -R "$path"; else cat "$path"; fi
}

wordlist_stats() {
  local path="$1" lines size bytes uniq
  lines="$(wc -l < "$path" 2>/dev/null || echo 0)"
  size="$(du -h "$path" 2>/dev/null | awk '{print $1}')"
  bytes="$(stat -c%s "$path" 2>/dev/null || echo 0)"
  ui_card_header "$(basename "$path")" "$path"
  printf '  Baris  : %s\n  Ukuran : %s (%s bytes)\n' "$lines" "$size" "$bytes"
  printf '\n  %s5 baris pertama:%s\n' "$C_MUTED" "$C_RESET"
  head -n 5 "$path" 2>/dev/null | sed 's/^/    /'
  printf '\n  %s5 baris terakhir:%s\n' "$C_MUTED" "$C_RESET"
  tail -n 5 "$path" 2>/dev/null | sed 's/^/    /'
  if [ "$bytes" -lt 52428800 ]; then
    uniq="$(LC_ALL=C sort -u "$path" | wc -l)"
    printf '\n  Baris unik: %s\n' "$uniq"
  else
    printf '\n  Baris unik: dilewati (file > 50 MB)\n'
  fi
  pause
}
