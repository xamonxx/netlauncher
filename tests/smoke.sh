#!/usr/bin/env bash
# Uji non-interaktif: syntax, registry, preview, CLI, wordlist, symlink.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
BIN="$REPO/bin/netlauncher"
CONFIG="$REPO/config"
TOOLS="$CONFIG/tools.tsv"
pass=0
fail=0
skipped=0

ok()      { printf '✓ %s\n' "$*"; pass=$((pass+1)); }
bad()     { printf '✗ %s\n' "$*" >&2; fail=$((fail+1)); }
skip()    { printf '· %s\n' "$*"; skipped=$((skipped+1)); }
contains(){ local name="$1" needle="$2" hay="$3"; if grep -qF -- "$needle" <<< "$hay"; then ok "$name"; else bad "$name (tidak mengandung: $needle)"; fi; }

echo "== Smoke test =="
echo "Repo: $REPO"
echo

# Syntax dan file dasar
if bash -n "$BIN" 2>/dev/null; then ok "bash -n"; else bad "bash -n"; fi
[ -x "$BIN" ] && ok "script executable" || bad "script tidak executable"
for f in "$TOOLS" "$CONFIG/help.md" "$REPO/MEMORY.md" "$REPO/AGENTS.md"; do
  [ -s "$f" ] && ok "file: ${f#$REPO/}" || bad "file hilang/kosong: ${f#$REPO/}"
done

# Registry
count="$(awk -F'|' '!/^#/ && NF>0 {n++} END{print n+0}' "$TOOLS")"
[ "$count" -eq 35 ] && ok "registry: $count entri" || bad "registry: $count entri (harus 35)"

badfields="$(awk -F'|' '!/^#/ && NF!=11 {print NR}' "$TOOLS")"
[ -z "$badfields" ] && ok "semua baris 11 field" || bad "baris dengan field salah: $badfields"

dups="$(awk -F'|' '!/^#/ {print $2}' "$TOOLS" | sort | uniq -d)"
[ -z "$dups" ] && ok "id tool unik" || bad "id duplikat: $dups"

badcat="$(awk -F'|' '!/^#/ && $1 !~ /^(diagnostik|dns|interface|scan|wireless|security|hackingtool)$/ {print $1}' "$TOOLS")"
[ -z "$badcat" ] && ok "kategori dikenal" || bad "kategori tidak dikenal: $badcat"

# CLI
out="$("$BIN" --version 2>&1)"
contains "--version" "netlauncher" "$out"
out="$("$BIN" --help 2>&1)"
contains "--help memuat tool" "tool <id>" "$out"
contains "--help memuat recipe" "recipe <nama>" "$out"

# Preview
out="$("$BIN" --preview-tool ping 2>&1)"
contains "preview tool ping" "Ping" "$out"
contains "preview tool status" "Binary: ping" "$out"
out="$("$BIN" --preview-category diagnostik 2>&1)"
contains "preview kategori" "Diagnostik Jaringan" "$out"
out="$("$BIN" --preview-recipe cek-koneksi 2>&1)"
contains "preview resep" "Cek Koneksi" "$out"

# Selftest
out="$("$BIN" selftest 2>&1)"
contains "selftest" "Selftest selesai tanpa error" "$out"

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
