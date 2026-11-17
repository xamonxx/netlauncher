#!/usr/bin/env bash
# Arsipkan repo, konfigurasi runtime, dan desktop entry.
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
OUT="$HOME/netlauncher-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
DESKTOP="$HOME/.local/share/applications/netlauncher.desktop"
targets=(-C "$HOME/tools" --exclude='netlauncher/.git' netlauncher)

[ -f "$DESKTOP" ] && targets+=(-C "$HOME" .local/share/applications/netlauncher.desktop)

echo "== Backup NetLauncher =="
echo "Repo: $REPO"

tar czf "$OUT" "${targets[@]}" || { echo "✗ Gagal membuat arsip" >&2; exit 1; }

if tar tzf "$OUT" >/dev/null 2>&1; then
  printf '✓ Backup dibuat: %s\n' "$OUT"
  du -h "$OUT" | awk '{print "  Ukuran: " $1}'
  printf '  Entri: %s\n' "$(tar tzf "$OUT" | wc -l)"
else
  echo "✗ Arsip rusak" >&2
  exit 1
fi

echo
echo "Backup lama (boleh dihapus manual):"
ls -1t "$HOME"/netlauncher-backup-*.tar.gz 2>/dev/null | tail -n +6 | sed 's/^/  /' || true
