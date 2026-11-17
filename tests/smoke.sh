#!/usr/bin/env bash
# Uji non-interaktif: syntax, modul, registry, snippet, preview, CLI, isolasi env, wordlist, symlink.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
BIN="$REPO/bin/netlauncher"
CONFIG="$REPO/config"
TOOLS="$CONFIG/tools.tsv"
SNIPPETS="$CONFIG/snippets.tsv"
pass=0
fail=0
skipped=0

ok()      { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
bad()     { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }
skip()    { printf '· %s\n' "$*"; skipped=$((skipped+1)); }
contains(){
  local name="$1" needle="$2" hay clean
  clean="$(sed -E 's/\x1B\[[0-9;]*[mK]//g' <<< "$3")"
  if grep -qF -- "$needle" <<< "$clean"; then ok "$name"; else bad "$name (tidak mengandung: $needle)"; fi
}

echo "== Smoke test =="
echo "Repo: $REPO"
echo

# Syntax dan file dasar
for f in "$BIN" "$REPO"/lib/*.sh "$CONFIG"/automations/*.sh "$REPO"/scripts/*.sh; do
  [ -f "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then ok "bash -n: ${f#$REPO/}"; else bad "bash -n: ${f#$REPO/}"; fi
done
[ -x "$BIN" ] && ok "script executable" || bad "script tidak executable"

for f in "$TOOLS" "$SNIPPETS" "$CONFIG/help.md" "$REPO/MEMORY.md" "$REPO/AGENTS.md"; do
  [ -s "$f" ] && ok "file: ${f#$REPO/}" || bad "file hilang/kosong: ${f#$REPO/}"
done

for m in core.sh ui.sh smart.sh snippets.sh wordlists.sh recipes.sh menu.sh doctor.sh; do
  [ -s "$REPO/lib/$m" ] && ok "modul: lib/$m" || bad "modul hilang: lib/$m"
done

# Registry tools.tsv
count="$(awk -F'|' '!/^#/ && NF>0 {n++} END{print n+0}' "$TOOLS")"
[ "$count" -eq 51 ] && ok "registry: $count entri" || bad "registry: $count entri (harus 51)"

badfields="$(awk -F'|' '!/^#/ && NF!=11 {print NR}' "$TOOLS")"
[ -z "$badfields" ] && ok "semua baris tools.tsv 11 field" || bad "baris dengan field salah: $badfields"

dups="$(awk -F'|' '!/^#/ {print $2}' "$TOOLS" | sort | uniq -d)"
[ -z "$dups" ] && ok "id tool unik" || bad "id duplikat: $dups"

badcat="$(awk -F'|' '!/^#/ && $1 !~ /^(diagnostik|dns|interface|scan|wireless|security|hackingtool)$/ {print $1}' "$TOOLS")"
[ -z "$badcat" ] && ok "kategori dikenal" || bad "kategori tidak dikenal: $badcat"

# Snippets
scount="$(awk -F'\t' '!/^#/ && NF>0 {n++} END{print n+0}' "$SNIPPETS")"
[ "$scount" -ge 100 ] && ok "snippets: $scount entri" || bad "snippets terlalu sedikit: $scount"

sbad="$(awk -F'\t' '!/^#/ && NF!=6 {print NR}' "$SNIPPETS")"
[ -z "$sbad" ] && ok "semua baris snippets.tsv 6 field" || bad "snippets field salah: $sbad"

# Lint & Selftest
out="$("$BIN" lint 2>&1)"
contains "lint" "Lint lolos tanpa error" "$out"

out="$("$BIN" selftest 2>&1)"
contains "selftest" "Selftest selesai tanpa error" "$out"

# CLI
out="$("$BIN" --version 2>&1)"
contains "--version" "netlauncher 2.0.0" "$out"
out="$("$BIN" --help 2>&1)"
contains "--help memuat tool" "tool <id>" "$out"
contains "--help memuat recipe" "recipe <nama>" "$out"
contains "--help memuat examples" "examples [tool_id]" "$out"
contains "--help memuat lint" "lint" "$out"

out="$("$BIN" list --json 2>&1)"
if python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); assert len(d)==51' <<< "$out" 2>/dev/null; then
  ok "list --json valid (51 entri)"
else
  bad "list --json tidak valid"
fi

# Dry-run & isolasi env
tmp_cfg="$(mktemp -d)"
tmp_data="$(mktemp -d)"
cp "$TOOLS" "$SNIPPETS" "$CONFIG/help.md" "$tmp_cfg/"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe cek-koneksi < /dev/null 2>&1)"
contains "dry-run recipe cek-koneksi" "[DRY-RUN]" "$out"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe info-jaringan < /dev/null 2>&1)"
contains "dry-run recipe info-jaringan" "[DRY-RUN]" "$out"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe monitor-port < /dev/null 2>&1)"
contains "dry-run recipe monitor-port" "[DRY-RUN]" "$out"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe discovery-lokal < /dev/null 2>&1)"
contains "dry-run recipe discovery-lokal" "[DRY-RUN]" "$out"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe laporan < /dev/null 2>&1)"
contains "dry-run recipe laporan" "[DRY-RUN]" "$out"
out="$(printf 'example.com\n' | NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe dns 2>&1)"
contains "dry-run recipe dns" "[DRY-RUN]" "$out"
out="$(printf 'https://example.com\n' | NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run recipe audit-web 2>&1)"
contains "dry-run recipe audit-web" "[DRY-RUN]" "$out"
out="$(NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" "$BIN" --no-anim --dry-run tool ip-addr < /dev/null 2>&1)"
contains "dry-run tool ip-addr" "[DRY-RUN]" "$out"
rm -rf "$tmp_cfg" "$tmp_data"

# Preview
out="$("$BIN" --preview-tool ping 2>&1)"
contains "preview tool ping" "Ping" "$out"
contains "preview tool status" "Binary: ping" "$out"
out="$("$BIN" --preview-category diagnostik 2>&1)"
contains "preview kategori" "Diagnostik Jaringan" "$out"
out="$("$BIN" --preview-recipe audit-web 2>&1)"
contains "preview resep audit-web" "Audit Web & TLS" "$out"
out="$("$BIN" --preview-snippet 2 2>&1)"
contains "preview snippet 2" "Contoh Perintah" "$out"
out="$("$BIN" --preview-theme theme:cyber 2>&1)"
contains "preview theme cyber" "Cyber Cyan" "$out"
out="$("$BIN" --preview-global tool:ping 2>&1)"
contains "preview global tool:ping" "Ping" "$out"
out="$("$BIN" --preview-history __LOGS__ 2>&1)"
contains "preview history __LOGS__" "Log Sesi Viewer" "$out"
out="$("$BIN" --preview-automation "$CONFIG/automations/healthcheck-harian.sh" 2>&1)"
contains "preview automation" "Healthcheck Jaringan Harian" "$out"

# Wordlist index
if [ -s "$CONFIG/wordlists.tsv" ]; then
  entries="$(awk -F'|' '!/^#/ && NF>=7 {n++} END{print n+0}' "$CONFIG/wordlists.tsv")"
  [ "$entries" -gt 100 ] && ok "index wordlist: $entries entri" || bad "index wordlist hanya $entries entri"
else
  skip "index wordlist belum ada (jalankan: netlauncher wordlists refresh)"
fi

# Symlink live
check_link() {
  local name="$1" link="$2" target="$3"
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    skip "$name belum dipasang"
  elif [ "$(readlink -f "$link" 2>/dev/null)" = "$target" ]; then
    ok "$name"
  else
    bad "$name (target: $(readlink -f "$link" 2>/dev/null))"
  fi
}
check_link "symlink binary" "$HOME/.local/bin/netlauncher" "$BIN"
check_link "symlink config" "$HOME/.config/netlauncher" "$CONFIG"
check_link "symlink memory" "$HOME/NETLAUNCHER_MEMORY.md" "$REPO/MEMORY.md"

if [ "$(readlink -f "$CONFIG/MEMORY.md" 2>/dev/null)" = "$REPO/MEMORY.md" ]; then
  ok "config/MEMORY.md -> ../MEMORY.md"
else
  bad "config/MEMORY.md bukan symlink ke MEMORY.md"
fi

# Ringkasan
echo
printf 'Hasil: %s lolos, %s gagal, %s dilewati\n' "$pass" "$fail" "$skipped"
[ "$fail" -eq 0 ]
