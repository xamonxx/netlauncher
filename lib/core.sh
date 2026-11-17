# lib/core.sh - Konfigurasi inti, path, helper, dan pembaca registry

APP_NAME="netlauncher"
VERSION="2.0.0"

CONFIG_DIR="${NETLAUNCHER_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/netlauncher}"
DATA_DIR="${NETLAUNCHER_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/netlauncher}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/netlauncher"

TOOLS_FILE="$CONFIG_DIR/tools.tsv"
SNIPPETS_FILE="$CONFIG_DIR/snippets.tsv"
WORDLISTS_FILE="$CONFIG_DIR/wordlists.tsv"
HELP_FILE="$CONFIG_DIR/help.md"
FAV_FILE="$CONFIG_DIR/favorites.tsv"
THEME_FILE="$CONFIG_DIR/theme.env"
AUTOMATIONS_DIR="$CONFIG_DIR/automations"

LOG_DIR="$DATA_DIR/logs"
HISTORY_FILE="$DATA_DIR/history.log"
TARGET_HISTORY_FILE="$DATA_DIR/targets.history"
REPORT_DIR="${NETLAUNCHER_REPORT_DIR:-$HOME/laporan}"

FZF_BIN="${FZF_BIN:-$(command -v fzf 2>/dev/null || true)}"
NO_ANIM="${NETLAUNCHER_NO_ANIM:-0}"
DRY_RUN="${NETLAUNCHER_DRY_RUN:-0}"

declare -A CAT_NAMES=(
  [diagnostik]="Diagnostik Jaringan"
  [dns]="DNS & Web"
  [interface]="Interface & Routing"
  [scan]="Pemindaian & Monitoring"
  [wireless]="Wireless (Berizin)"
  [security]="Tool Keamanan (Berizin)"
  [hackingtool]="Hackingtool"
)

declare -A CAT_ICONS=(
  [diagnostik]="⚡"
  [dns]="🌐"
  [interface]="🔌"
  [scan]="📡"
  [wireless]="📶"
  [security]="🛡"
  [hackingtool]="🧰"
)

declare -A CAT_DESC=(
  [diagnostik]="Ping, traceroute, curl, wget, whois, openssl, nc, socat."
  [dns]="Query DNS, fingerprint web, dan audit aplikasi web berizin."
  [interface]="Alamat IP, routing, socket, WiFi link, NMCLI, ethtool, lsof."
  [scan]="Nmap, masscan, arp-scan, netdiscover, tcpdump, tshark, Wireshark."
  [wireless]="Tool wireless terpasang. Gunakan hanya pada jaringan berizin."
  [security]="Hydra, John, Hashcat, Metasploit. Hanya untuk target berizin."
  [hackingtool]="TUI hackingtool: 219 tool dalam 21 kategori."
)

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$*"; }
warn() { printf '%s!%s %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$*"; }
err()  { printf '%s✗%s %s\n' "${C_RED:-}" "${C_RESET:-}" "$*" >&2; }
die()  { err "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
pause(){ [ -t 0 ] || return 0; printf '\n'; read -r -p "Tekan Enter untuk kembali..." _ || true; }

ensure_dirs() {
  mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$CACHE_DIR" "$LOG_DIR" "$REPORT_DIR" "$AUTOMATIONS_DIR"
  chmod 700 "$DATA_DIR" "$LOG_DIR" 2>/dev/null || true
  touch "$FAV_FILE" "$HISTORY_FILE" "$TARGET_HISTORY_FILE" 2>/dev/null || true
  chmod 600 "$FAV_FILE" "$HISTORY_FILE" "$TARGET_HISTORY_FILE" 2>/dev/null || true
  find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime +30 -delete 2>/dev/null || true
}

require_fzf() {
  [ -n "$FZF_BIN" ] && [ -x "$FZF_BIN" ] || die "fzf tidak ditemukan. Pasang: go install github.com/junegunn/fzf@latest"
  [ -f "$TOOLS_FILE" ] || die "Registry tool tidak ditemukan: $TOOLS_FILE"
}

copy_to_clipboard() {
  local text="$1"
  if have wl-copy; then
    printf '%s' "$text" | wl-copy && return 0
  elif have xclip; then
    printf '%s' "$text" | xclip -selection clipboard && return 0
  elif have xsel; then
    printf '%s' "$text" | xsel --clipboard --input && return 0
  elif have pbcopy; then
    printf '%s' "$text" | pbcopy && return 0
  fi
  return 1
}

tool_count_installed() {
  awk -F'|' '!/^#/ && NF>=4 {print $4}' "$TOOLS_FILE" | while read -r b; do have "$b" && echo x; done | wc -l
}

tool_count_total() {
  awk -F'|' '!/^#/ && NF>=4 {n++} END{print n+0}' "$TOOLS_FILE"
}

tool_count_category() {
  local cat="$1" total inst
  total="$(awk -F'|' -v c="$cat" '!/^#/ && $1==c {n++} END{print n+0}' "$TOOLS_FILE")"
  inst="$(awk -F'|' -v c="$cat" '!/^#/ && $1==c {print $4}' "$TOOLS_FILE" | while read -r b; do have "$b" && echo x; done | wc -l)"
  printf '%s/%s' "$inst" "$total"
}

find_tool_line() {
  awk -F'|' -v id="$1" '!/^#/ && $2==id {print; exit}' "$TOOLS_FILE"
}

tool_field() {
  find_tool_line "$1" | awk -F'|' -v n="$2" '{print $n}'
}

is_fav() {
  grep -qxF "$1" "$FAV_FILE" 2>/dev/null
}

toggle_fav() {
  local id="$1" tmp
  tmp="$(mktemp)"
  if is_fav "$id"; then
    grep -vxF "$id" "$FAV_FILE" > "$tmp" || true
    mv "$tmp" "$FAV_FILE"
    ok "Dihapus dari favorit."
  else
    printf '%s\n' "$id" >> "$FAV_FILE"
    rm -f "$tmp"
    ok "Ditambahkan ke favorit."
  fi
  pause
}

record_target_history() {
  local kind="$1" val="$2" tmp
  [ -n "$val" ] || return 0
  case "$val" in
    *" "*|*"password"*|*"token"*) return 0 ;;
  esac
  tmp="$(mktemp)"
  {
    printf '%s\t%s\n' "$kind" "$val"
    grep -vxF "${kind}"$'\t'"${val}" "$TARGET_HISTORY_FILE" 2>/dev/null | head -n 40 || true
  } > "$tmp"
  mv "$tmp" "$TARGET_HISTORY_FILE"
  chmod 600 "$TARGET_HISTORY_FILE" 2>/dev/null || true
}
