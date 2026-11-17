#!/usr/bin/env bash
# Uji UI di tmux: menu utama, knowledge, workspace, flow, kategori, snippet & tema.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SESSION="nl-ui-test-$$"
PASS=0
FAIL=0
cleanup() { tmux kill-session -t "$SESSION" 2>/dev/null || true; }
trap cleanup EXIT

screen() { tmux capture-pane -pt "$SESSION" -S -200 2>/dev/null || true; }
cur_screen() { tmux capture-pane -pt "$SESSION" 2>/dev/null || true; }

check() {
  local label="$1" needle="$2" sc="" i
  for i in 1 2 3 4 5 6 7 8; do
    sleep 0.35
    sc="$(cur_screen)"
    grep -qF -- "$needle" <<< "$sc" && break
    sc="$(screen)"
    grep -qF -- "$needle" <<< "$sc" && break
  done
  if grep -qF -- "$needle" <<< "$sc"; then
    printf '✓ %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '✗ %s (tidak menemukan: %s)\n' "$label" "$needle" >&2
    FAIL=$((FAIL+1))
  fi
}

goto_main() {
  local i
  for i in 1 2 3 4 5; do
    if grep -qF "Cari Semua Tool & Contoh" <<< "$(cur_screen)"; then return 0; fi
    tmux send-keys -t "$SESSION" Escape
    sleep 0.5
  done
}

open() {
  goto_main
  tmux send-keys -t "$SESSION" "$1"
  sleep 0.25
  tmux send-keys -t "$SESSION" Enter
}

command -v tmux >/dev/null 2>&1 || { echo "✗ tmux tidak tersedia" >&2; exit 1; }
[ -x "$REPO/bin/netlauncher" ] || { echo "✗ Script tidak executable" >&2; exit 1; }

tmux new-session -d -s "$SESSION" -x 130 -y 42 "NETLAUNCHER_NO_ANIM=1 $REPO/bin/netlauncher"
sleep 1.2

check "menu utama tampil" "Diagnostik Jaringan"
check "entri knowledge tersedia" "Knowledge Base Resmi"
check "entri workspace tersedia" "Target Workspace"
check "entri flow tersedia" "Automation Flow"

open "Knowledge"
check "knowledge base terbuka" "Knowledge Base Resmi Tool"

open "Workspace"
check "workspace terbuka" "Target Workspace"
check "field workspace tampil" "Subnet"

open "Automation Flow"
check "flow terbuka" "Buat Flow Baru"

goto_main
tmux send-keys -t "$SESSION" Enter
check "kategori dapat dibuka" "Ping"

goto_main
tmux send-keys -t "$SESSION" C-e
check "browser snippet terbuka" "Snippet"

goto_main
tmux send-keys -t "$SESSION" C-t
check "menu tema terbuka" "Cyber Cyan"

printf 'UI test: %s lolos, %s gagal\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
