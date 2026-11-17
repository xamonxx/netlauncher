# lib/ui.sh - Tema warna modern, animasi terminal, badge, dan wrapper fzf

THEME="${NETLAUNCHER_THEME:-cyber}"
ANIM="${NETLAUNCHER_ANIM:-1}"

init_ansi_colors() {
  if [ -t 1 ] || [ "${FORCE_COLOR:-0}" = "1" ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_ITALIC=$'\033[3m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_MAGENTA=$'\033[35m'
    C_CYAN=$'\033[36m'
    C_WHITE=$'\033[97m'
  else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_ITALIC=""
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
    C_MAGENTA=""; C_CYAN=""; C_WHITE=""
  fi
}

load_theme() {
  init_ansi_colors
  if [ -f "$THEME_FILE" ]; then
    # shellcheck disable=SC1090
    source "$THEME_FILE" 2>/dev/null || true
  fi
  [ -n "${NETLAUNCHER_THEME:-}" ] && THEME="$NETLAUNCHER_THEME"
  [ -n "${NETLAUNCHER_ANIM:-}" ] && ANIM="$NETLAUNCHER_ANIM"

  case "$THEME" in
    tokyo)
      C_PRIMARY=$'\033[38;2;122;162;247m'
      C_ACCENT=$'\033[38;2;187;154;247m'
      C_OK=$'\033[38;2;158;206;106m'
      C_WARN=$'\033[38;2;224;175;104m'
      C_ERR=$'\033[38;2;247;118;142m'
      C_MUTED=$'\033[38;2;120;124;153m'
      FZF_COLORS='fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7,fg+:#ffffff,bg+:#283457,hl+:#7dcfff,info:#787c99,prompt:#7aa2f7,pointer:#bb9af7,marker:#9ece6a,spinner:#7dcfff,header:#7dcfff,border:#3b4261,label:#7aa2f7,preview-border:#3b4261,preview-label:#bb9af7,list-border:#3b4261,input-border:#7aa2f7,header-border:#3b4261,footer:#787c99,footer-border:#3b4261,ghost:#565f89'
      ;;
    emerald)
      C_PRIMARY=$'\033[38;2;0;255;156m'
      C_ACCENT=$'\033[38;2;38;166;154m'
      C_OK=$'\033[38;2;105;240;174m'
      C_WARN=$'\033[38;2;255;213;79m'
      C_ERR=$'\033[38;2;255;82;82m'
      C_MUTED=$'\033[38;2;107;143;128m'
      FZF_COLORS='fg:#c8e6c9,bg:#0a120e,hl:#00ff9c,fg+:#ffffff,bg+:#12291f,hl+:#69f0ae,info:#6b8f80,prompt:#00ff9c,pointer:#ffd54f,marker:#69f0ae,spinner:#00ff9c,header:#69f0ae,border:#1e3d2f,label:#00ff9c,preview-border:#1e3d2f,preview-label:#26a69a,list-border:#1e3d2f,input-border:#00ff9c,header-border:#1e3d2f,footer:#6b8f80,footer-border:#1e3d2f,ghost:#3d5c4d'
      ;;
    amber)
      C_PRIMARY=$'\033[38;2;255;179;0m'
      C_ACCENT=$'\033[38;2;255;112;67m'
      C_OK=$'\033[38;2;174;213;129m'
      C_WARN=$'\033[38;2;255;213;79m'
      C_ERR=$'\033[38;2;239;83;80m'
      C_MUTED=$'\033[38;2;141;123;104m'
      FZF_COLORS='fg:#ede0d4,bg:#14110d,hl:#ffb300,fg+:#ffffff,bg+:#2b2116,hl+:#ffd54f,info:#8d7b68,prompt:#ffb300,pointer:#ff7043,marker:#aed581,spinner:#ffb300,header:#ffd54f,border:#3e3123,label:#ffb300,preview-border:#3e3123,preview-label:#ff7043,list-border:#3e3123,input-border:#ffb300,header-border:#3e3123,footer:#8d7b68,footer-border:#3e3123,ghost:#5c4d3c'
      ;;
    cyber|*)
      THEME="cyber"
      C_PRIMARY=$'\033[38;2;0;229;255m'
      C_ACCENT=$'\033[38;2;124;77;255m'
      C_OK=$'\033[38;2;0;230;118m'
      C_WARN=$'\033[38;2;255;215;64m'
      C_ERR=$'\033[38;2;255;82;82m'
      C_MUTED=$'\033[38;2;139;148;158m'
      FZF_COLORS='fg:#c9d1d9,bg:#0d1117,hl:#00e5ff,fg+:#ffffff,bg+:#162230,hl+:#5ef2ff,info:#8b949e,prompt:#00e5ff,pointer:#ffd740,marker:#00e676,spinner:#00e5ff,header:#79c0ff,border:#30363d,label:#00e5ff,preview-border:#30363d,preview-label:#7c4dff,list-border:#30363d,input-border:#00e5ff,header-border:#30363d,footer:#8b949e,footer-border:#30363d,ghost:#484f58'
      ;;
  esac

  if [ ! -t 1 ] && [ "${FORCE_COLOR:-0}" != "1" ]; then
    C_PRIMARY=""; C_ACCENT=""; C_OK=""; C_WARN=""; C_ERR=""; C_MUTED=""
  fi
}

save_theme() {
  local new_theme="${1:-$THEME}" new_anim="${2:-$ANIM}"
  THEME="$new_theme"
  ANIM="$new_anim"
  cat > "$THEME_FILE" <<EOF
THEME="$THEME"
ANIM="$ANIM"
EOF
  chmod 600 "$THEME_FILE" 2>/dev/null || true
  load_theme
}

anim_enabled() {
  [ "${NO_ANIM:-0}" != "1" ] && \
  [ "${ANIM:-1}" = "1" ] && \
  [ -t 1 ] && \
  [ "${TERM:-dumb}" != "dumb" ]
}

ui_cleanup() {
  if [ -t 1 ]; then
    printf '\033[?25h' 2>/dev/null || true
    stty sane 2>/dev/null || true
  fi
}

ui_badge() {
  local kind="$1" text="$2"
  case "$kind" in
    ok)     printf '%s[%s]%s' "$C_OK$C_BOLD" "$text" "$C_RESET" ;;
    warn)   printf '%s[%s]%s' "$C_WARN$C_BOLD" "$text" "$C_RESET" ;;
    err)    printf '%s[%s]%s' "$C_ERR$C_BOLD" "$text" "$C_RESET" ;;
    accent) printf '%s[%s]%s' "$C_ACCENT$C_BOLD" "$text" "$C_RESET" ;;
    info)   printf '%s[%s]%s' "$C_PRIMARY$C_BOLD" "$text" "$C_RESET" ;;
    *)      printf '%s[%s]%s' "$C_MUTED" "$text" "$C_RESET" ;;
  esac
}

ui_card_header() {
  local title="$1" subtitle="${2:-}"
  printf '%s╭──────────────────────────────────────────────────────────────╮%s\n' "$C_PRIMARY" "$C_RESET"
  printf '%s│%s  %s◈ %s%s\n' "$C_PRIMARY" "$C_RESET" "$C_BOLD$C_WHITE" "$title" "$C_RESET"
  if [ -n "$subtitle" ]; then
    printf '%s│%s  %s%s%s\n' "$C_PRIMARY" "$C_RESET" "$C_MUTED" "$subtitle" "$C_RESET"
  fi
  printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_PRIMARY" "$C_RESET"
}

ui_progress() {
  local cur="$1" total="$2" label="${3:-Memproses...}" width=26 pct filled empty bar i
  [ "$total" -gt 0 ] || total=1
  pct=$(( cur * 100 / total ))
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  if anim_enabled; then
    printf '\r\033[K  %s[%s%s%s]%s %s%3d%%%s  %s%s%s' \
      "$C_MUTED" "$C_PRIMARY" "$bar" "$C_MUTED" "$C_RESET" \
      "$C_BOLD" "$pct" "$C_RESET" "$C_WHITE" "$label" "$C_RESET"
    [ "$cur" -ge "$total" ] && printf '\n'
  else
    printf '  [%3d%%] %s\n' "$pct" "$label"
  fi
}

ui_spin() {
  local label="$1"
  shift
  if ! anim_enabled; then
    printf '  %s... ' "$label"
    "$@"
    local rc=$?
    if [ "$rc" -eq 0 ]; then printf 'OK\n'; else printf 'gagal (%s)\n' "$rc"; fi
    return "$rc"
  fi

  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local pid i=0 start_ts now_ts elapsed rc
  start_ts="$(date +%s)"
  printf '\033[?25l'
  "$@" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    now_ts="$(date +%s)"
    elapsed=$((now_ts - start_ts))
    printf '\r\033[K  %s%s%s %s %s(%ss)%s' \
      "$C_PRIMARY" "${frames[$((i % 10))]}" "$C_RESET" \
      "$label" "$C_MUTED" "$elapsed" "$C_RESET"
    i=$((i + 1))
    sleep 0.07
  done
  wait "$pid"
  rc=$?
  printf '\033[?25h'
  if [ "$rc" -eq 0 ]; then
    printf '\r\033[K  %s✓%s %s\n' "$C_OK" "$C_RESET" "$label"
  else
    printf '\r\033[K  %s✗%s %s %s(exit %s)%s\n' "$C_ERR" "$C_RESET" "$label" "$C_MUTED" "$rc" "$C_RESET"
  fi
  return "$rc"
}

ui_splash() {
  anim_enabled || return 0
  [ "${NETLAUNCHER_SPLASH_DONE:-0}" = "1" ] && return 0
  export NETLAUNCHER_SPLASH_DONE=1

  local lines=(
    "  ███╗   ██╗███████╗████████╗██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗███████╗██████╗ "
    "  ████╗  ██║██╔════╝╚══██╔══╝██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝██╔══██╗"
    "  ██╔██╗ ██║█████╗     ██║   ██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║█████╗  ██████╔╝"
    "  ██║╚██╗██║██╔══╝     ██║   ██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██╔══╝  ██╔══██╗"
    "  ██║ ╚████║███████╗   ██║   ███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║███████╗██║  ██║"
    "  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
  )
  local cols
  cols="$(tput cols 2>/dev/null || echo 80)"
  printf '\033[2J\033[H\033[?25l'
  printf '\n'
  if [ "$cols" -ge 100 ]; then
    local idx=0
    for l in "${lines[@]}"; do
      if [ $((idx % 2)) -eq 0 ]; then
        printf '%s%s%s\n' "$C_PRIMARY" "$l" "$C_RESET"
      else
        printf '%s%s%s\n' "$C_ACCENT" "$l" "$C_RESET"
      fi
      idx=$((idx + 1))
      sleep 0.03
    done
  else
    printf '  %s◈ NETLAUNCHER v%s%s\n' "$C_PRIMARY$C_BOLD" "$VERSION" "$C_RESET"
  fi
  printf '\n  %sSmart Network & Security Command Center · Kali Linux · Authorized Use Only%s\n\n' "$C_MUTED" "$C_RESET"

  ui_progress 1 4 "Memuat tema ($THEME) & registry..."
  sleep 0.06
  ui_progress 2 4 "Mendeteksi interface & konteks jaringan..."
  smart_net_context >/dev/null 2>&1 || true
  sleep 0.06
  ui_progress 3 4 "Memeriksa tool & index wordlist..."
  sleep 0.06
  ui_progress 4 4 "Siap! Membuka antarmuka..."
  sleep 0.08
  printf '\033[?25h'
}

ui_fzf() {
  "$FZF_BIN" \
    --ansi \
    --style=full:rounded \
    --border=rounded \
    --height=100% \
    --layout=reverse \
    --info=inline-right \
    --pointer='▶' \
    --marker='✓' \
    --scrollbar='┃' \
    --highlight-line \
    --border-label=" ◈ NETLAUNCHER v$VERSION · ${THEME^^} ◈ " \
    --border-label-pos=3 \
    --color="$FZF_COLORS" \
    "$@"
}

preview_theme() {
  local item="$1" tname p a o w e
  case "$item" in
    theme:tokyo)
      tname="Tokyo Night"
      p=$'\033[38;2;122;162;247m'; a=$'\033[38;2;187;154;247m'; o=$'\033[38;2;158;206;106m'; w=$'\033[38;2;224;175;104m'; e=$'\033[38;2;247;118;142m'
      ;;
    theme:emerald)
      tname="Matrix Emerald"
      p=$'\033[38;2;0;255;156m'; a=$'\033[38;2;38;166;154m'; o=$'\033[38;2;105;240;174m'; w=$'\033[38;2;255;213;79m'; e=$'\033[38;2;255;82;82m'
      ;;
    theme:amber)
      tname="Tactical Amber"
      p=$'\033[38;2;255;179;0m'; a=$'\033[38;2;255;112;67m'; o=$'\033[38;2;174;213;129m'; w=$'\033[38;2;255;213;79m'; e=$'\033[38;2;239;83;80m'
      ;;
    theme:cyber)
      tname="Cyber Cyan"
      p=$'\033[38;2;0;229;255m'; a=$'\033[38;2;124;77;255m'; o=$'\033[38;2;0;230;118m'; w=$'\033[38;2;255;215;64m'; e=$'\033[38;2;255;82;82m'
      ;;
    anim:*)
      printf '%sAnimasi Terminal%s\n\nMengatur splash screen ASCII, progress bar, dan spinner.\n\nStatus saat ini: %s\n' \
        "$C_PRIMARY$C_BOLD" "$C_RESET" "$([ "${ANIM:-1}" = "1" ] && echo AKTIF || echo NONAKTIF)"
      printf '\nDapat juga dimatikan sementara dengan:\n  netlauncher --no-anim\n'
      return 0
      ;;
    *)
      printf 'Kembali ke menu utama.\n'
      return 0
      ;;
  esac

  printf '%s◈ %s%s\n\n' "$p$C_BOLD" "$tname" "$C_RESET"
  printf 'Palet Truecolor:\n'
  printf '  %s████%s Primary   %s████%s Accent\n' "$p" "$C_RESET" "$a" "$C_RESET"
  printf '  %s████%s Sukses    %s████%s Peringatan   %s████%s Error\n\n' "$o" "$C_RESET" "$w" "$C_RESET" "$e" "$C_RESET"
  printf '%s╭─ Contoh Kartu ─────────────────────────╮%s\n' "$p" "$C_RESET"
  printf '%s│%s %s✓%s Ping       %s127.0.0.1 (0.04 ms)%s       %s│%s\n' "$p" "$C_RESET" "$o" "$C_RESET" "$a" "$C_RESET" "$p" "$C_RESET"
  printf '%s│%s %s⚡%s Nmap      %s[SUDO / KONFIRMASI]%s       %s│%s\n' "$p" "$C_RESET" "$w" "$C_RESET" "$w" "$C_RESET" "$p" "$C_RESET"
  printf '%s╰────────────────────────────────────────╯%s\n' "$p" "$C_RESET"
  printf '\nDisimpan ke: %s\n' "$THEME_FILE"
}

theme_menu() {
  local file sel choice new_anim
  file="$(mktemp)"
  {
    printf '%s◈%s  Cyber Cyan       %s(default · biru elektrik & ungu)%s\ttheme:cyber\n' "$C_CYAN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s◈%s  Tokyo Night      %s(biru lembut & lavender)%s\ttheme:tokyo\n' "$C_BLUE" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s◈%s  Matrix Emerald   %s(hijau terminal klasik modern)%s\ttheme:emerald\n' "$C_GREEN" "$C_RESET" "$C_MUTED" "$C_RESET"
    printf '%s◈%s  Tactical Amber   %s(oranye taktis kontras tinggi)%s\ttheme:amber\n' "$C_YELLOW" "$C_RESET" "$C_MUTED" "$C_RESET"
    if [ "${ANIM:-1}" = "1" ]; then
      printf '%s✦%s  Animasi Terminal %s[AKTIF — klik untuk matikan]%s\tanim:0\n' "$C_OK" "$C_RESET" "$C_MUTED" "$C_RESET"
    else
      printf '%s✦%s  Animasi Terminal %s[NONAKTIF — klik untuk aktifkan]%s\tanim:1\n' "$C_WARN" "$C_RESET" "$C_MUTED" "$C_RESET"
    fi
    printf '%s←%s  Kembali\tback\n' "$C_MUTED" "$C_RESET"
  } > "$file"

  sel="$(ui_fzf \
    --prompt='  Tema ▸ ' \
    --ghost='Pilih tema warna atau toggle animasi...' \
    --header="Tema aktif: $THEME │ Animasi: $([ "${ANIM:-1}" = "1" ] && echo ON || echo OFF)" \
    --header-first \
    --header-label=' Pengaturan Tampilan ' \
    --input-label=' Filter ' \
    --list-label=' Tema & Animasi ' \
    --preview="$SELF --preview-theme {2}" \
    --preview-window='right:52%:wrap' \
    --preview-label=' Pratinjau Tema ' \
    --footer='Enter: Terapkan │ Esc: Kembali' \
    --footer-border=line \
    --delimiter=$'\t' --with-nth=1 < "$file")"
  rm -f "$file"
  [ -n "$sel" ] || return 0
  choice="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
  case "$choice" in
    theme:*)
      save_theme "${choice#theme:}" "$ANIM"
      ok "Tema diubah ke: $THEME"
      sleep 0.4
      ;;
    anim:*)
      new_anim="${choice#anim:}"
      save_theme "$THEME" "$new_anim"
      ok "Animasi diatur ke: $([ "$ANIM" = "1" ] && echo AKTIF || echo NONAKTIF)"
      sleep 0.4
      ;;
    *) return 0 ;;
  esac
}
