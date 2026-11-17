# lib/doctor.sh - Doctor, selftest, lint, list (--json), update, dan bantuan

doctor() {
  local fails=0 c f
  ui_card_header "NetLauncher Doctor" "Pemeriksaan dependensi, tool, terminal, dan konfigurasi"
  echo
  local cmds=(fzf git pipx python3 go ruby tmux hackingtool nmap ip ss dig curl openssl whois tcpdump tshark wireshark aircrack-ng airmon-ng)
  for c in "${cmds[@]}"; do
    if have "$c"; then ok "$c: $(command -v "$c")"; else err "$c: tidak ditemukan"; fails=$((fails+1)); fi
  done
  echo
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ok "PATH berisi ~/.local/bin" ;;
    *) err "PATH tidak berisi ~/.local/bin"; fails=$((fails+1)) ;;
  esac
  for f in "$TOOLS_FILE" "$SNIPPETS_FILE" "$HELP_FILE" "$WORDLISTS_FILE"; do
    if [ -s "$f" ]; then ok "File: $f"; else err "File: $f (belum ada/kosong)"; fails=$((fails+1)); fi
  done
  for f in "$HOME/wordlists" "$HOME/wordlists/indonesian" "$AUTOMATIONS_DIR"; do
    if [ -d "$f" ]; then ok "Direktori: $f"; else err "Direktori: $f tidak ada"; fails=$((fails+1)); fi
  done
  echo
  ok "Terminal: TERM=${TERM:-?} COLORTERM=${COLORTERM:-?} Tema=$THEME Animasi=$([ "${ANIM:-1}" = "1" ] && echo ON || echo OFF)"
  if have fzf; then ok "fzf versi: $(fzf --version 2>/dev/null | head -n1)"; fi
  if have sudo; then
    if sudo -n true 2>/dev/null; then ok "sudo: sesi aktif tanpa password"; else warn "sudo: akan meminta password saat capture/scan ARP"; fi
  else
    err "sudo tidak tersedia"; fails=$((fails+1))
  fi
  echo
  if [ "$fails" -eq 0 ]; then ok "Semua komponen utama siap."; else warn "$fails komponen perlu perhatian."; fi
  return 0
}

do_update() {
  local repo="$HOME/tools/hackingtool"
  ui_card_header "Update NetLauncher Ecosystem" "Hackingtool + Index Wordlist + Doctor"
  if [ -d "$repo/.git" ]; then
    ui_spin "Menarik pembaruan repo hackingtool..." git -C "$repo" pull --ff-only || warn "git pull gagal (mungkin ada perubahan lokal)."
    ui_spin "Memasang ulang hackingtool via pipx..." pipx install "$repo" --force || warn "pipx install gagal."
  else
    warn "Repo hackingtool tidak ditemukan di $repo."
  fi
  echo
  wordlist_refresh
  echo
  doctor
  pause
}

show_help() {
  if [ -f "$HELP_FILE" ]; then
    if have less; then less -R "$HELP_FILE"; else cat "$HELP_FILE"; fi
  else
    err "File bantuan tidak ditemukan: $HELP_FILE"
  fi
}

print_cli_help() {
  cat <<EOF
NetLauncher $VERSION — smart terminal launcher & automation (authorized use only)

Usage:
  netlauncher [options] [command]

Options:
  --no-anim           Matikan animasi splash/spinner
  --dry-run           Pratinjau perintah tanpa mengeksekusi
  --theme <nama>      Pakai tema sementara (cyber|tokyo|emerald|amber)
  --version, -v       Tampilkan versi
  --help, -h          Tampilkan bantuan ini

Commands:
  (tanpa argumen)     Buka menu utama interaktif
  search              Pencarian global tool & contoh perintah
  examples [tool_id]  Browser contoh perintah & code snippets
  snippets [tool_id]  Alias untuk examples
  automation          Kelola & jalankan custom automation scripts
  wordlists [refresh] Browser/index wordlist
  logs                Buka viewer log sesi
  theme [nama]        Ubah tema warna & animasi
  tool <id>           Jalankan tool berdasarkan id
  recipe <nama>       Jalankan resep otomasi aman
  list [--json]       Daftar semua tool di registry
  doctor              Cek dependensi, terminal, dan tool
  selftest            Validasi registry, snippet, dan file
  lint                Validasi ketat format tools.tsv & snippets.tsv
  update              Update hackingtool + index wordlist
  help                Panduan lengkap

Resep:
  cek-koneksi, info-jaringan, audit-web, dns, monitor-port,
  discovery-lokal, scan-target, capture, wordlist-stats, laporan

Contoh:
  netlauncher
  netlauncher search
  netlauncher examples nmap
  netlauncher recipe audit-web
  netlauncher list --json
  netlauncher --dry-run tool ping
EOF
}

selftest() {
  local fails=0 line n cat id label binary template desc help sudo arg_prompt mode examples snip_n
  echo "== Selftest =="
  echo
  if [ -f "$TOOLS_FILE" ]; then ok "tools.tsv ada"; else err "tools.tsv tidak ada"; fails=$((fails+1)); fi
  if [ -f "$SNIPPETS_FILE" ]; then ok "snippets.tsv ada"; else err "snippets.tsv tidak ada"; fails=$((fails+1)); fi
  n=0
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    n=$((n+1))
    IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
    if [ -z "${id:-}" ] || [ -z "${binary:-}" ]; then
      err "Baris $n tidak lengkap"; fails=$((fails+1)); continue
    fi
    if [ "$(awk -F'|' '{print NF}' <<< "$line")" -ne 11 ]; then
      err "Baris $n tidak punya 11 field: $id"; fails=$((fails+1))
    fi
    if have "$binary"; then ok "$id ($binary)"; else warn "$id ($binary) belum terpasang"; fi
  done < "$TOOLS_FILE"
  snip_n="$(awk -F'\t' '!/^#/ && NF==6 {n++} END{print n+0}' "$SNIPPETS_FILE" 2>/dev/null || echo 0)"
  echo
  ok "$n entri registry dan $snip_n snippet diperiksa."
  if [ "$fails" -eq 0 ]; then ok "Selftest selesai tanpa error."; else warn "$fails masalah ditemukan."; fi
  return "$fails"
}

lint() {
  local fails=0 line ln=0 cat id label binary template desc help sudo arg_prompt mode examples
  local tool_id title cmd notes ph
  declare -A seen_ids=()
  echo "== Lint =="
  echo

  while IFS= read -r line; do
    ln=$((ln+1))
    case "$line" in ''|'#'*) continue ;; esac
    if [ "$(awk -F'|' '{print NF}' <<< "$line")" -ne 11 ]; then
      err "tools.tsv:$ln jumlah field bukan 11"; fails=$((fails+1)); continue
    fi
    IFS='|' read -r cat id label binary template desc help sudo arg_prompt mode examples <<< "$line"
    if [[ ! "$cat" =~ ^(diagnostik|dns|interface|scan|wireless|security|hackingtool)$ ]]; then
      err "tools.tsv:$ln kategori tidak dikenal: $cat"; fails=$((fails+1))
    fi
    if [ -z "$id" ] || [ -z "$label" ] || [ -z "$binary" ] || [ -z "$desc" ]; then
      err "tools.tsv:$ln field wajib kosong ($id)"; fails=$((fails+1))
    fi
    if [ -n "${seen_ids[$id]:-}" ]; then
      err "tools.tsv:$ln id duplikat: $id"; fails=$((fails+1))
    fi
    seen_ids["$id"]=1
    if [[ ! "$sudo" =~ ^[01]$ ]]; then
      err "tools.tsv:$ln sudo harus 0 atau 1 ($id: $sudo)"; fails=$((fails+1))
    fi
    if [[ ! "$mode" =~ ^(term|gui)$ ]]; then
      err "tools.tsv:$ln mode harus term atau gui ($id: $mode)"; fails=$((fails+1))
    fi
  done < "$TOOLS_FILE"
  ok "tools.tsv diperiksa (${#seen_ids[@]} id unik)"

  if [ -f "$SNIPPETS_FILE" ]; then
    ln=0
    local scount=0
    while IFS= read -r line; do
      ln=$((ln+1))
      case "$line" in ''|'#'*) continue ;; esac
      if [ "$(awk -F'\t' '{print NF}' <<< "$line")" -ne 6 ]; then
        err "snippets.tsv:$ln jumlah field bukan 6"; fails=$((fails+1)); continue
      fi
      IFS=$'\t' read -r tool_id title cmd notes sudo ph <<< "$line"
      if [ -z "${seen_ids[$tool_id]:-}" ]; then
        err "snippets.tsv:$ln tool_id tidak ada di tools.tsv: $tool_id"; fails=$((fails+1))
      fi
      if [ -z "$title" ] || [ -z "$cmd" ] || [ -z "$notes" ]; then
        err "snippets.tsv:$ln field wajib kosong"; fails=$((fails+1))
      fi
      if [[ ! "$sudo" =~ ^[01]$ ]]; then
        err "snippets.tsv:$ln sudo harus 0 atau 1 ($sudo)"; fails=$((fails+1))
      fi
      scount=$((scount+1))
    done < "$SNIPPETS_FILE"
    ok "snippets.tsv diperiksa ($scount snippet)"
  fi

  local f
  for f in "$REPO_DIR/bin/netlauncher" "$LIB_DIR"/*.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then
      ok "syntax: ${f#$REPO_DIR/}"
    else
      err "syntax error: ${f#$REPO_DIR/}"; fails=$((fails+1))
    fi
  done

  echo
  if [ "$fails" -eq 0 ]; then ok "Lint lolos tanpa error."; return 0; else err "Lint gagal ($fails error)."; return 1; fi
}

list_tools() {
  local fmt="${1:-table}"
  if [ "$fmt" = "--json" ]; then
    python3 - "$TOOLS_FILE" <<'PY'
import json, shutil, sys
items = []
with open(sys.argv[1], encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 11:
            continue
        cat, tid, label, binary, template, desc, help_cmd, sudo, arg_prompt, mode, examples = parts
        items.append({
            "category": cat,
            "id": tid,
            "label": label,
            "binary": binary,
            "installed": shutil.which(binary) is not None,
            "template": template,
            "description": desc,
            "help": help_cmd,
            "sudo": sudo == "1",
            "arg_prompt": arg_prompt,
            "mode": mode,
            "examples": examples,
        })
print(json.dumps(items, indent=2, ensure_ascii=False))
PY
  else
    printf '%-12s %-20s %-22s %-10s %s\n' "KATEGORI" "ID" "LABEL" "STATUS" "DESKRIPSI"
    awk -F'|' '!/^#/ && NF==11 {print $1 "|" $2 "|" $3 "|" $4 "|" $6}' "$TOOLS_FILE" |
    while IFS='|' read -r cat id label binary desc; do
      local st="belum"
      have "$binary" && st="terpasang"
      printf '%-12s %-20s %-22s %-10s %s\n' "$cat" "$id" "$label" "$st" "$desc"
    done
  fi
}
