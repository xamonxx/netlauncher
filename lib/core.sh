# lib/core.sh - Konfigurasi inti, path, helper, overlay, workspace, dan registry

APP_NAME="netlauncher"
VERSION="2.2.0-dev"

CONFIG_DIR="${NETLAUNCHER_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/netlauncher}"
DATA_DIR="${NETLAUNCHER_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/netlauncher}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/netlauncher"

TOOLS_FILE="$CONFIG_DIR/tools.tsv"
TOOLS_LOCAL_FILE="$CONFIG_DIR/tools.local.tsv"
SNIPPETS_FILE="$CONFIG_DIR/snippets.tsv"
SNIPPETS_LOCAL_FILE="$CONFIG_DIR/snippets.local.tsv"
FLAGS_FILE="$CONFIG_DIR/flags.tsv"
GUIDES_DIR="$CONFIG_DIR/guides"
WORDLISTS_FILE="$CONFIG_DIR/wordlists.tsv"
HELP_FILE="$CONFIG_DIR/help.md"
FAV_FILE="$CONFIG_DIR/favorites.tsv"
THEME_FILE="$CONFIG_DIR/theme.env"
AUTOMATIONS_DIR="$CONFIG_DIR/automations"
FLOWS_DIR="$CONFIG_DIR/flows"
FLOWS_LOCAL_DIR="$CONFIG_DIR/flows.local"

LOG_DIR="$DATA_DIR/logs"
HISTORY_FILE="$DATA_DIR/history.log"
TARGET_HISTORY_FILE="$DATA_DIR/targets.history"
WORKSPACE_FILE="$DATA_DIR/workspace.env"
PROJECTS_DIR="$DATA_DIR/projects"
ACTIVE_PROJECT_FILE="$DATA_DIR/active-project"
FINDINGS_FILE="$DATA_DIR/findings.jsonl"
REPORT_DIR="${NETLAUNCHER_REPORT_DIR:-$HOME/laporan}"

FZF_BIN="${FZF_BIN:-$(command -v fzf 2>/dev/null || true)}"
NO_ANIM="${NETLAUNCHER_NO_ANIM:-0}"
DRY_RUN="${NETLAUNCHER_DRY_RUN:-0}"

WS_TARGET=""
WS_DOMAIN=""
WS_URL=""
WS_SUBNET=""
WS_IFACE=""
WS_NOTE=""

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
  mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$CACHE_DIR" "$LOG_DIR" "$REPORT_DIR" \
    "$AUTOMATIONS_DIR" "$FLOWS_DIR" "$FLOWS_LOCAL_DIR" "$GUIDES_DIR" "$PROJECTS_DIR"
  chmod 700 "$DATA_DIR" "$LOG_DIR" "$PROJECTS_DIR" 2>/dev/null || true
  touch "$FAV_FILE" "$HISTORY_FILE" "$TARGET_HISTORY_FILE" "$WORKSPACE_FILE" "$FINDINGS_FILE" 2>/dev/null || true
  chmod 600 "$FAV_FILE" "$HISTORY_FILE" "$TARGET_HISTORY_FILE" "$WORKSPACE_FILE" "$ACTIVE_PROJECT_FILE" "$FINDINGS_FILE" 2>/dev/null || true
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

tools_files() {
  [ -f "$TOOLS_FILE" ] && printf '%s\n' "$TOOLS_FILE"
  [ -f "$TOOLS_LOCAL_FILE" ] && printf '%s\n' "$TOOLS_LOCAL_FILE"
  return 0
}

snippets_files() {
  [ -f "$SNIPPETS_FILE" ] && printf '%s\n' "$SNIPPETS_FILE"
  [ -f "$SNIPPETS_LOCAL_FILE" ] && printf '%s\n' "$SNIPPETS_LOCAL_FILE"
  return 0
}

tool_count_installed() {
  local f
  {
    while IFS= read -r f; do
      awk -F'|' '!/^#/ && NF>=4 {print $4}' "$f"
    done < <(tools_files)
  } | while IFS= read -r b; do have "$b" && echo x; done | wc -l | tr -d ' '
}

tool_count_total() {
  local f total=0 n
  while IFS= read -r f; do
    n="$(awk -F'|' '!/^#/ && NF>=4 {n++} END{print n+0}' "$f")"
    total=$((total + n))
  done < <(tools_files)
  printf '%s\n' "$total"
}

tool_count_category() {
  local cat="$1" total=0 inst=0 f n i
  while IFS= read -r f; do
    n="$(awk -F'|' -v c="$cat" '!/^#/ && $1==c {n++} END{print n+0}' "$f")"
    i="$(awk -F'|' -v c="$cat" '!/^#/ && $1==c {print $4}' "$f" | while IFS= read -r b; do have "$b" && echo x; done | wc -l | tr -d ' ')"
    total=$((total + n))
    inst=$((inst + i))
  done < <(tools_files)
  printf '%s/%s' "$inst" "$total"
}

find_tool_line() {
  local id="$1" f line=""
  while IFS= read -r f; do
    line="$(awk -F'|' -v id="$id" '!/^#/ && $2==id {print; exit}' "$f")"
    if [ -n "$line" ]; then
      printf '%s\n' "$line"
      return 0
    fi
  done < <(tools_files)
  return 1
}

tool_field() {
  find_tool_line "$1" | awk -F'|' -v n="$2" '{print $n}'
}

snippet_line_by_ref() {
  local ref="$1" file="$SNIPPETS_FILE" num="$1"
  case "$ref" in
    main:*) file="$SNIPPETS_FILE"; num="${ref#main:}" ;;
    local:*) file="$SNIPPETS_LOCAL_FILE"; num="${ref#local:}" ;;
  esac
  [ -f "$file" ] || return 1
  [[ "$num" =~ ^[0-9]+$ ]] || return 1
  sed -n "${num}p" "$file"
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

load_workspace() {
  WS_TARGET=""
  WS_DOMAIN=""
  WS_URL=""
  WS_SUBNET=""
  WS_IFACE=""
  WS_NOTE=""
  [ -f "$WORKSPACE_FILE" ] || return 0
  local k v
  while IFS='=' read -r k v; do
    case "$k" in
      WS_TARGET) WS_TARGET="$v" ;;
      WS_DOMAIN) WS_DOMAIN="$v" ;;
      WS_URL) WS_URL="$v" ;;
      WS_SUBNET) WS_SUBNET="$v" ;;
      WS_IFACE) WS_IFACE="$v" ;;
      WS_NOTE) WS_NOTE="$v" ;;
    esac
  done < "$WORKSPACE_FILE"
  load_project_workspace
}

save_workspace() {
  local tmp
  tmp="$(mktemp)"
  {
    printf 'WS_TARGET=%s\n' "${WS_TARGET//$'\n'/}"
    printf 'WS_DOMAIN=%s\n' "${WS_DOMAIN//$'\n'/}"
    printf 'WS_URL=%s\n' "${WS_URL//$'\n'/}"
    printf 'WS_SUBNET=%s\n' "${WS_SUBNET//$'\n'/}"
    printf 'WS_IFACE=%s\n' "${WS_IFACE//$'\n'/}"
    printf 'WS_NOTE=%s\n' "${WS_NOTE//$'\n'/}"
  } > "$tmp"
  mv "$tmp" "$WORKSPACE_FILE"
  chmod 600 "$WORKSPACE_FILE" 2>/dev/null || true
  [ -n "$(active_project_name 2>/dev/null || true)" ] && save_project_workspace
}

clear_workspace() {
  WS_TARGET=""
  WS_DOMAIN=""
  WS_URL=""
  WS_SUBNET=""
  WS_IFACE=""
  WS_NOTE=""
  : > "$WORKSPACE_FILE"
  chmod 600 "$WORKSPACE_FILE" 2>/dev/null || true
  [ -n "$(active_project_name 2>/dev/null || true)" ] && save_project_workspace
}

workspace_active_label() {
  local parts=()
  [ -n "$WS_TARGET" ] && parts+=("Target:$WS_TARGET")
  [ -n "$WS_DOMAIN" ] && parts+=("Domain:$WS_DOMAIN")
  [ -n "$WS_URL" ] && parts+=("URL:$WS_URL")
  [ -n "$WS_SUBNET" ] && parts+=("Subnet:$WS_SUBNET")
  [ -n "$WS_IFACE" ] && parts+=("Iface:$WS_IFACE")
  if [ "${#parts[@]}" -eq 0 ]; then
    return 1
  fi
  local out="" p
  for p in "${parts[@]}"; do
    [ -n "$out" ] && out+=" │ "
    out+="$p"
  done
  if [ -n "$(project_name 2>/dev/null || true)" ]; then
    out="$(project_name) │ $out"
  fi
  printf '%s' "$out"
}

is_impactful_tool() {
  local tool_id="$1" cmd="${2:-}"
  case "$tool_id" in
    nmap|masscan|arp-scan|netdiscover|nikto|gobuster|ffuf|feroxbuster|dirb|wfuzz|nuclei|amass|sqlmap|tcpdump|tshark|tcpflow|ngrep|airmon-ng|aircrack-ng|kismet|reaver|wifite|hydra|john|hashcat|msfconsole)
      return 0 ;;
  esac
  case "$cmd" in
    sudo\ *|*\ sudo\ *) return 0 ;;
  esac
  return 1
}

active_project_name() {
  [ -s "$ACTIVE_PROJECT_FILE" ] && head -n 1 "$ACTIVE_PROJECT_FILE"
}

project_slug() {
  local slug
  slug="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+|-+$//g')"
  [ -n "$slug" ] || return 1
  printf '%s' "$slug"
}

project_file() {
  local slug
  slug="$(project_slug "$1")" || return 1
  printf '%s/%s.env' "$PROJECTS_DIR" "$slug"
}

project_create() {
  local name="$1" slug file scope
  [ -n "$name" ] || die "Nama proyek wajib diisi."
  slug="$(project_slug "$name")" || die "Nama proyek tidak valid."
  file="$PROJECTS_DIR/$slug.env"
  [ ! -e "$file" ] || die "Proyek sudah ada: $name"
  printf 'PROJECT_NAME=%s\nPROJECT_SCOPE=\nPROJECT_ENV=lab\nPROJECT_NOTE=\n' "${name//$'\n'/ }" > "$file"
  chmod 600 "$file"
  printf '%s\n' "$slug" > "$ACTIVE_PROJECT_FILE"
  chmod 600 "$ACTIVE_PROJECT_FILE"
  WS_TARGET="" WS_DOMAIN="" WS_URL="" WS_SUBNET="" WS_IFACE="" WS_NOTE=""
  save_project_workspace
  load_workspace
  ok "Proyek dibuat dan diaktifkan: $name"
}

project_use() {
  local slug file
  slug="$(project_slug "$1")" || die "Nama proyek tidak valid."
  file="$PROJECTS_DIR/$slug.env"
  [ -f "$file" ] || die "Proyek tidak ditemukan: $1"
  printf '%s\n' "$slug" > "$ACTIVE_PROJECT_FILE"
  chmod 600 "$ACTIVE_PROJECT_FILE"
  load_workspace
  ok "Proyek aktif: $(project_name)"
}

project_name() {
  local file
  file="$(active_project_file)" || return 1
  sed -n 's/^PROJECT_NAME=//p' "$file" | head -n 1
}

active_project_file() {
  local slug
  slug="$(active_project_name)" || return 1
  [ -f "$PROJECTS_DIR/$slug.env" ] || return 1
  printf '%s/%s.env' "$PROJECTS_DIR" "$slug"
}

project_scope() {
  local file
  file="$(active_project_file)" || return 1
  sed -n 's/^PROJECT_SCOPE=//p' "$file" | head -n 1
}

project_set_metadata() {
  local scope="${1:-}" env="${2:-lab}" file tmp name note target domain url subnet iface
  file="$(active_project_file)" || die "Tidak ada proyek aktif."
  case "$env" in lab|staging|produksi) ;; *) die "Lingkungan harus lab, staging, atau produksi." ;; esac
  if [ -n "$scope" ]; then
    local saved_ws_target="$WS_TARGET" saved_ws_domain="$WS_DOMAIN" saved_ws_url="$WS_URL" saved_ws_subnet="$WS_SUBNET"
    WS_TARGET="" WS_DOMAIN="" WS_URL="" WS_SUBNET=""
    if [ -n "$saved_ws_target" ]; then WS_TARGET="$saved_ws_target"; elif [ -n "$saved_ws_domain" ]; then WS_DOMAIN="$saved_ws_domain"; elif [ -n "$saved_ws_url" ]; then WS_URL="$saved_ws_url"; elif [ -n "$saved_ws_subnet" ]; then WS_SUBNET="$saved_ws_subnet"; fi
    SCOPE_VALIDATING=1 PROJECT_SCOPE_OVERRIDE="$scope" confirm_scope || { WS_TARGET="$saved_ws_target"; WS_DOMAIN="$saved_ws_domain"; WS_URL="$saved_ws_url"; WS_SUBNET="$saved_ws_subnet"; die "Cakupan baru tidak mencakup target workspace aktif."; }
    unset SCOPE_VALIDATING PROJECT_SCOPE_OVERRIDE
    WS_TARGET="$saved_ws_target" WS_DOMAIN="$saved_ws_domain" WS_URL="$saved_ws_url" WS_SUBNET="$saved_ws_subnet"
  fi
  name="$(project_name)"
  note="$(sed -n 's/^PROJECT_NOTE=//p' "$file" | head -n 1)"
  target="$(sed -n 's/^PROJECT_TARGET=//p' "$file" | head -n 1)"
  domain="$(sed -n 's/^PROJECT_DOMAIN=//p' "$file" | head -n 1)"
  url="$(sed -n 's/^PROJECT_URL=//p' "$file" | head -n 1)"
  subnet="$(sed -n 's/^PROJECT_SUBNET=//p' "$file" | head -n 1)"
  iface="$(sed -n 's/^PROJECT_IFACE=//p' "$file" | head -n 1)"
  tmp="$(mktemp)"
  printf 'PROJECT_NAME=%s\nPROJECT_SCOPE=%s\nPROJECT_ENV=%s\nPROJECT_NOTE=%s\nPROJECT_TARGET=%s\nPROJECT_DOMAIN=%s\nPROJECT_URL=%s\nPROJECT_SUBNET=%s\nPROJECT_IFACE=%s\n' \
    "${name//$'\n'/ }" "${scope//$'\n'/ }" "$env" "${note//$'\n'/ }" \
    "${target//$'\n'/ }" "${domain//$'\n'/ }" "${url//$'\n'/ }" "${subnet//$'\n'/ }" "${iface//$'\n'/ }" > "$tmp"
  mv "$tmp" "$file"; chmod 600 "$file"
  ok "Metadata proyek diperbarui."
}

project_list() {
  local file slug name active
  active="$(active_project_name 2>/dev/null || true)"
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    slug="$(basename "$file" .env)"
    name="$(sed -n 's/^PROJECT_NAME=//p' "$file" | head -n 1)"
    [ "$slug" = "$active" ] && printf '* ' || printf '  '
    printf '%s\t%s\n' "$slug" "$name"
  done < <(find "$PROJECTS_DIR" -maxdepth 1 -type f -name '*.env' -print 2>/dev/null | sort)
}

load_project_workspace() {
  local file k v line
  file="$(active_project_file 2>/dev/null)" || return 0
  WS_TARGET="" WS_DOMAIN="" WS_URL="" WS_SUBNET="" WS_IFACE="" WS_NOTE=""
  while IFS='=' read -r k v; do
    case "$k" in
      PROJECT_TARGET) WS_TARGET="$v" ;;
      PROJECT_DOMAIN) WS_DOMAIN="$v" ;;
      PROJECT_URL) WS_URL="$v" ;;
      PROJECT_SUBNET) WS_SUBNET="$v" ;;
      PROJECT_IFACE) WS_IFACE="$v" ;;
      PROJECT_NOTE) WS_NOTE="$v" ;;
    esac
  done < "$file"
}

save_project_workspace() {
  local file tmp scope env note
  file="$(active_project_file 2>/dev/null)" || return 0
  scope="$(project_scope 2>/dev/null || true)"
  env="$(sed -n 's/^PROJECT_ENV=//p' "$file" | head -n 1)"
  note="${WS_NOTE//$'\n'/ }"
  tmp="$(mktemp)"
  {
    printf 'PROJECT_NAME=%s\nPROJECT_SCOPE=%s\nPROJECT_ENV=%s\nPROJECT_NOTE=%s\n' \
      "$(project_name)" "${scope//$'\n'/ }" "${env:-lab}" "$note"
    printf 'PROJECT_TARGET=%s\nPROJECT_DOMAIN=%s\nPROJECT_URL=%s\nPROJECT_SUBNET=%s\nPROJECT_IFACE=%s\n' \
      "${WS_TARGET//$'\n'/ }" "${WS_DOMAIN//$'\n'/ }" "${WS_URL//$'\n'/ }" \
      "${WS_SUBNET//$'\n'/ }" "${WS_IFACE//$'\n'/ }"
  } > "$tmp"
  mv "$tmp" "$file"
  chmod 600 "$file"
}

confirm_scope() {
  local scope target token host allowed=0
  [ -n "$(active_project_name 2>/dev/null || true)" ] || return 0
  scope="${PROJECT_SCOPE_OVERRIDE:-$(project_scope 2>/dev/null || true)}"
  [ -z "$scope" ] && return 0
  target="${WS_TARGET:-${WS_DOMAIN:-${WS_URL:-${WS_SUBNET:-}}}}"
  [ -n "$target" ] || { [ -n "${SCOPE_VALIDATING:-}" ] && return 0; err "Proyek memiliki cakupan; isi target sebelum menjalankan aksi berdampak."; return 1; }
  host="${target#*://}"; host="${host%%/*}"; host="${host%%:*}"
  while IFS= read -r token; do
    token="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$token")"
    [ -n "$token" ] || continue
    case "$host" in
      "$token"|*.$token) allowed=1 ;;
      "$token"/*|"$token":*) allowed=1 ;;
    esac
    [ "$target" = "$token" ] && allowed=1
  done < <(tr ', ' '\n\n' <<< "$scope")
  if [ "$allowed" -ne 1 ]; then
    err "Target '$target' tidak cocok dengan cakupan proyek: $scope"
    return 1
  fi
}

confirm_authorized_action() {
  local tool_id="$1" cmd="$2" sudo_flag="${3:-0}" ans
  [ "$DRY_RUN" = "1" ] && return 0
  confirm_scope || return 1
  if [ "$sudo_flag" = "1" ] || is_impactful_tool "$tool_id" "$cmd"; then
    printf '\n%sPerintah:%s %s\n' "${C_MUTED:-}" "${C_RESET:-}" "$cmd"
    read -r -p "Saya berwenang menjalankan perintah ini pada target? (y/N): " ans || true
    [[ "$ans" =~ ^[yY]$ ]] || return 1
  fi
  return 0
}
