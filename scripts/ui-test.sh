#!/usr/bin/env bash
# Uji UI dasar di tmux: menu tampil, kategori terbuka, Esc keluar.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SESSION="nl-ui-test-$$"
cleanup() { tmux kill-session -t "$SESSION" 2>/dev/null || true; }
trap cleanup EXIT

command -v tmux >/dev/null 2>&1 || { echo "✗ tmux tidak tersedia" >&2; exit 1; }
[ -x "$REPO/bin/netlauncher" ] || { echo "✗ Script tidak executable" >&2; exit 1; }

tmux new-session -d -s "$SESSION" -x 120 -y 40 "$REPO/bin/netlauncher"
sleep 1

screen="$(tmux capture-pane -pt "$SESSION" -S -40)"
if grep -qF "Diagnostik Jaringan" <<< "$screen"; then
  echo "✓ Menu utama tampil"
else
  echo "✗ Menu utama tidak terdeteksi" >&2
  printf '%s\n' "$screen" >&2
  exit 1
fi

tmux send-keys -t "$SESSION" Enter
sleep 0.7
screen="$(tmux capture-pane -pt "$SESSION" -S -40)"
if grep -qF "Ping" <<< "$screen"; then
  echo "✓ Kategori dapat dibuka"
else
  echo "✗ Kategori tidak terbuka" >&2
  printf '%s\n' "$screen" >&2
  exit 1
fi

tmux send-keys -t "$SESSION" Escape
sleep 0.3
tmux send-keys -t "$SESSION" Escape
sleep 0.3
echo "✓ UI test selesai"
