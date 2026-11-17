#!/usr/bin/env bash
# Pasang NetLauncher: tautkan repo ke lokasi live. Idempoten, tanpa sudo.
set -uo pipefail
umask 022

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
BIN_REPO="$REPO/bin/netlauncher"
CONFIG_REPO="$REPO/config"
BIN_LINK="$HOME/.local/bin/netlauncher"
CONFIG_LINK="$HOME/.config/netlauncher"
MEMORY_LINK="$HOME/NETLAUNCHER_MEMORY.md"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/netlauncher"
STAMP="$(date +%Y%m%d-%H%M%S)"
fails=0

ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
err()  { printf '✗ %s\n' "$*" >&2; }

[ -f "$BIN_REPO" ] || { err "Script tidak ditemukan: $BIN_REPO"; exit 1; }
[ -f "$CONFIG_REPO/tools.tsv" ] || { err "Registry tidak ditemukan: $CONFIG_REPO/tools.tsv"; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/.config" "$DATA_DIR/logs"
chmod 700 "$DATA_DIR" "$DATA_DIR/logs" 2>/dev/null || true
chmod 755 "$BIN_REPO" 2>/dev/null || true

echo "== NetLauncher install =="
echo "Repo: $REPO"
echo

# --- binary ---
if [ -L "$BIN_LINK" ] && [ "$(readlink -f "$BIN_LINK")" = "$BIN_REPO" ]; then
  ok "binary sudah tertaut"
else
  if [ -e "$BIN_LINK" ] || [ -L "$BIN_LINK" ]; then
    mv "$BIN_LINK" "$BIN_LINK.backup-$STAMP"
    warn "File lama dipindah: $BIN_LINK.backup-$STAMP"
  fi
  ln -s "$BIN_REPO" "$BIN_LINK"
  ok "binary ditautkan: $BIN_LINK"
fi

# --- config ---
if [ -L "$CONFIG_LINK" ] && [ "$(readlink -f "$CONFIG_LINK")" = "$CONFIG_REPO" ]; then
  ok "config sudah tertaut"
else
  if [ -e "$CONFIG_LINK" ] || [ -L "$CONFIG_LINK" ]; then
    BAK="$CONFIG_LINK.backup-$STAMP"
    mv "$CONFIG_LINK" "$BAK"
    warn "Config lama dipindah: $BAK"
    for f in favorites.tsv wordlists.tsv; do
      if [ -f "$BAK/$f" ] && [ ! -f "$CONFIG_REPO/$f" ]; then
        cp -p "$BAK/$f" "$CONFIG_REPO/$f" && ok "state $f disalin ke repo"
      fi
    done
  fi
  ln -s "$CONFIG_REPO" "$CONFIG_LINK"
  ok "config ditautkan: $CONFIG_LINK"
fi

# --- memory ---
ln -sfn ../MEMORY.md "$CONFIG_REPO/MEMORY.md"
ln -sfn "$REPO/MEMORY.md" "$MEMORY_LINK"
ok "memory ditautkan: $MEMORY_LINK"

# --- state runtime ---
touch "$CONFIG_REPO/favorites.tsv" 2>/dev/null || true
touch "$DATA_DIR/history.log" 2>/dev/null || true
chmod 600 "$CONFIG_REPO/favorites.tsv" "$DATA_DIR/history.log" 2>/dev/null || true

# --- verifikasi ---
echo
[ "$(readlink -f "$BIN_LINK")" = "$BIN_REPO" ] || { err "Symlink binary salah"; fails=$((fails+1)); }
[ "$(readlink -f "$CONFIG_LINK")" = "$CONFIG_REPO" ] || { err "Symlink config salah"; fails=$((fails+1)); }
[ "$(readlink -f "$MEMORY_LINK")" = "$REPO/MEMORY.md" ] || { err "Symlink memory salah"; fails=$((fails+1)); }
"$BIN_LINK" --version >/dev/null 2>&1 || { err "Launcher tidak dapat dijalankan"; fails=$((fails+1)); }

if [ "$fails" -eq 0 ]; then
  ok "Instalasi selesai."
  echo
  echo "Langkah berikutnya:"
  echo "  netlauncher doctor"
  echo "  netlauncher selftest"
  echo "  netlauncher"
  exit 0
else
  err "$fails masalah ditemukan."
  exit 1
fi
