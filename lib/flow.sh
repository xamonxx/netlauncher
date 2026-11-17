# lib/flow.sh - Modern Automation Flow Engine (.flow deklaratif, pipeline runner, variable capture, dashboard)

declare -A FLOW_META=()
declare -a FLOW_INPUT_KEYS=()
declare -A FLOW_INPUT_HINTS=()
declare -a FLOW_STEP_IDS=()
declare -A FLOW_STEP_DATA=()
declare -A FLOW_VARS=()

flow_list_files() {
  local d
  for d in "$FLOWS_DIR" "$FLOWS_LOCAL_DIR"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -type f -name '*.flow' 2>/dev/null | sort
  done
}

flow_find_by_id() {
  local target="$1" f fid
  if [ -f "$target" ]; then
    printf '%s' "$target"
    return 0
  fi
  while IFS= read -r f; do
    fid="$(awk -F'=' '/^id[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$f")"
    if [ "$fid" = "$target" ] || [ "$(basename "$f" .flow)" = "$target" ]; then
      printf '%s' "$f"
      return 0
    fi
  done < <(flow_list_files)
  return 1
}

flow_parse_file() {
  local path="$1" section="" line key val step_id=""
  [ -f "$path" ] || return 1

  FLOW_META=()
  FLOW_INPUT_KEYS=()
  FLOW_INPUT_HINTS=()
  FLOW_STEP_IDS=()
  FLOW_STEP_DATA=()

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      ""|\#*) continue ;;
      \[flow\]) section="flow"; step_id=""; continue ;;
      \[inputs\]) section="inputs"; step_id=""; continue ;;
      \[step:*\])
        section="step"
        step_id="${line#\[step:}"
        step_id="${step_id%\]}"
        FLOW_STEP_IDS+=("$step_id")
        continue
        ;;
    esac

    [[ "$line" == *"="* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    val="$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

    case "$section" in
      flow)
        FLOW_META["$key"]="$val"
        ;;
      inputs)
        FLOW_INPUT_KEYS+=("$key")
        FLOW_INPUT_HINTS["$key"]="$val"
        ;;
      step)
        [ -n "$step_id" ] && FLOW_STEP_DATA["${step_id}:${key}"]="$val"
        ;;
    esac
  done < "$path"
}

preview_flow() {
  local target="$1" path fid fname fcat frisk fauth fsudo fdesc ftools t sid stitle stool swhen
  case "$target" in
    __NEW__|__BACK__) printf '%sAksi Flow%s\n\nPilih flow untuk melihat rencana eksekusi, atau gunakan menu aksi untuk membuat/jalankan.\n' "$C_PRIMARY$C_BOLD" "$C_RESET"; return 0 ;;
  esac
  path="$(flow_find_by_id "$target")" || { printf 'Flow tidak ditemukan: %s\n' "$target"; return 0; }
  flow_parse_file "$path" || { printf 'Gagal membaca flow: %s\n' "$path"; return 0; }

  fid="${FLOW_META[id]:-$(basename "$path" .flow)}"
  fname="${FLOW_META[name]:-$fid}"
  fcat="${FLOW_META[category]:-diagnostik}"
  frisk="${FLOW_META[risk]:-pasif}"
  fauth="${FLOW_META[requires_auth]:-false}"
  fsudo="${FLOW_META[sudo]:-false}"
  fdesc="${FLOW_META[description]:-}"
  ftools="${FLOW_META[tools]:-}"

  printf '%s◈ %s%s\n' "$C_PRIMARY$C_BOLD" "$fname" "$C_RESET"
  printf '%sID:%s %s │ %sKategori:%s %s │ ' "$C_MUTED" "$C_RESET" "$fid" "$C_MUTED" "$C_RESET" "${CAT_NAMES[$fcat]:-$fcat}"
  case "$frisk" in
    pasif) printf '%b' "$(ui_badge ok "PASIF")" ;;
    aman)  printf '%b' "$(ui_badge info "AMAN")" ;;
    aktif) printf '%b' "$(ui_badge warn "AKTIF BERIZIN")" ;;
    sudo)  printf '%b' "$(ui_badge err "SUDO")" ;;
    *)     printf '%s' "$frisk" ;;
  esac
  [ "$fsudo" = "true" ] && printf ' %b' "$(ui_badge warn "⚡ SUDO")"
  [ "$fauth" = "true" ] && printf ' %b' "$(ui_badge warn "OTORISASI")"
  printf '\n\n'

  [ -n "$fdesc" ] && printf '%s%s%s\n\n' "$C_WHITE" "$fdesc" "$C_RESET"

  if [ -n "$ftools" ]; then
    printf '%sTool yang digunakan:%s\n  ' "$C_MUTED" "$C_RESET"
    local IFS=','
    for t in $ftools; do
      t="${t// /}"
      if have "$t"; then
        printf '%s✓ %s%s  ' "$C_OK" "$t" "$C_RESET"
      else
        printf '%s✗ %s%s  ' "$C_ERR" "$t" "$C_RESET"
      fi
    done
    printf '\n\n'
  fi

  if [ "${#FLOW_INPUT_KEYS[@]}" -gt 0 ]; then
    printf '%sInput Parameter:%s\n' "$C_ACCENT$C_BOLD" "$C_RESET"
    local k
    for k in "${FLOW_INPUT_KEYS[@]}"; do
      printf '  • %s{%s}%s — %s\n' "$C_PRIMARY" "$k" "$C_RESET" "${FLOW_INPUT_HINTS[$k]}"
    done
    printf '\n'
  fi

  printf '%sAlur Langkah (%s step):%s\n' "$C_ACCENT$C_BOLD" "${#FLOW_STEP_IDS[@]}" "$C_RESET"
  local idx=0
  for sid in "${FLOW_STEP_IDS[@]}"; do
    idx=$((idx + 1))
    stitle="${FLOW_STEP_DATA[${sid}:title]:-Langkah $sid}"
    stool="${FLOW_STEP_DATA[${sid}:tool]:--}"
    swhen="${FLOW_STEP_DATA[${sid}:when]:-always}"
    printf '  %s%d.%s %s %s[%s · %s]%s\n' "$C_PRIMARY" "$idx" "$C_RESET" "$stitle" "$C_MUTED" "$stool" "$swhen" "$C_RESET"
  done
}

flow_substitute_cmd() {
  local cmd="$1" k val qval now_stamp
  now_stamp="$(date +%Y%m%d-%H%M%S)"
  cmd="${cmd//\{DATE\}/$now_stamp}"
  cmd="${cmd//\{REPORT_DIR\}/$REPORT_DIR}"

  for k in "${!FLOW_VARS[@]}"; do
    val="${FLOW_VARS[$k]}"
    if [[ "$cmd" == *"{$k}"* ]]; then
      qval="$(printf '%q' "$val")"
      cmd="${cmd//\{$k\}/$qval}"
    fi
  done
  printf '%s' "$cmd"
}

flow_resolve_inputs() {
  local k hint val
  smart_net_context
  FLOW_VARS[NET_HOST]="$NET_HOST"
  FLOW_VARS[NET_IFACE]="$NET_IFACE"
  FLOW_VARS[NET_IP]="$NET_IP"
  FLOW_VARS[NET_CIDR]="$NET_CIDR"
  FLOW_VARS[NET_SUBNET]="$NET_SUBNET"
  FLOW_VARS[NET_GW]="$NET_GW"
  FLOW_VARS[NET_DNS]="$NET_DNS"

  if [ -n "${FLOW_VARS[URL]:-}" ] && [ -z "${FLOW_VARS[DOMAIN]:-}" ]; then
    local d="${FLOW_VARS[URL]#https://}"; d="${d#http://}"; d="${d%%/*}"; d="${d%%:*}"
    FLOW_VARS[DOMAIN]="$d"
  fi

  for k in "${FLOW_INPUT_KEYS[@]}"; do
    if [ -n "${FLOW_VARS[$k]:-}" ]; then
      continue
    fi
    hint="${FLOW_INPUT_HINTS[$k]:-Isi $k}"
    if [ "$k" = "URL" ] && [ -n "${FLOW_VARS[DOMAIN]:-}" ]; then
      hint="$hint (domain aktif: ${FLOW_VARS[DOMAIN]})"
    fi
    if [ -t 0 ]; then
      val="$(smart_prompt_placeholder "$k" "$hint")" || return 1
    else
      read -r -p "$hint ($k): " val || true
    fi
    [ -n "$val" ] || return 1
    FLOW_VARS["$k"]="$val"
    if [ "$k" = "URL" ] && [ -z "${FLOW_VARS[DOMAIN]:-}" ]; then
      local d="${val#https://}"; d="${d#http://}"; d="${d%%/*}"; d="${d%%:*}"
      FLOW_VARS[DOMAIN]="$d"
    fi
  done
  return 0
}

flow_check_when() {
  local cond="$1" prev_rc="$2" part
  [ -z "$cond" ] || [ "$cond" = "always" ] && return 0
  local IFS=';'
  for part in $cond; do
    part="$(printf '%s' "$part" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$part" ] && continue
    case "$part" in
      always) ;;
      have:*)
        have "${part#have:}" || return 1
        ;;
      var:*)
        local vname="${part#var:}"
        local vval="${FLOW_VARS[$vname]:-}"
        [ -n "$vval" ] && [ "$vval" != "-" ] || return 1
        ;;
      prev_ok)
        [ "$prev_rc" -eq 0 ] || return 1
        ;;
      confirm:*)
        local msg="${part#confirm:}" ans
        if [ -t 0 ]; then
          read -r -p "$msg (y/N): " ans || true
          [[ "$ans" =~ ^[yY]$ ]] || return 1
        else
          return 1
        fi
        ;;
    esac
  done
  return 0
}

flow_export_markdown() {
  local fid="$1" fname="$2" total_dur="$3" flow_log="$4" summary_file="$5" plain_all="$6"
  local out
  mkdir -p "$REPORT_DIR"
  out="$REPORT_DIR/flow-${fid}-$(date +%Y%m%d-%H%M%S).md"
  {
    echo "# Laporan Automation Flow: $fname"
    echo
    echo "- **Flow ID:** \`$fid\`"
    echo "- **Tanggal:** $(date -Is)"
    echo "- **Total Durasi:** ${total_dur}s"
    echo "- **Log Sesi:** \`$flow_log\`"
    echo
    echo "## Ringkasan Langkah"
    echo
    echo '```text'
    sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g' "$summary_file"
    echo '```'
    echo
    echo "## Output Lengkap"
    echo
    echo '```text'
    cat "$plain_all"
    echo '```'
  } > "$out"
  chmod 600 "$out" 2>/dev/null || true
  ok "Laporan flow dibuat: $out"
}

flow_run() {
  local target="$1"
  shift || true
  local path fid fname frisk fauth fsudo ftools
  local kv k v ans flow_log flow_start flow_end total_dur
  local total_steps idx=0 prev_rc=0 overall_rc=0
  local summary_tmp plain_all ansi_all step_raw step_ansi step_plain

  path="$(flow_find_by_id "$target")" || { err "Flow tidak ditemukan: $target"; pause; return 1; }
  flow_parse_file "$path" || { err "Gagal mem-parse flow: $path"; pause; return 1; }

  FLOW_VARS=()
  for kv in "$@"; do
    if [[ "$kv" == *=* ]]; then
      k="${kv%%=*}"
      v="${kv#*=}"
      FLOW_VARS["$k"]="$v"
    fi
  done

  fid="${FLOW_META[id]:-$(basename "$path" .flow)}"
  fname="${FLOW_META[name]:-$fid}"
  frisk="${FLOW_META[risk]:-pasif}"
  fauth="${FLOW_META[requires_auth]:-false}"
  fsudo="${FLOW_META[sudo]:-false}"
  ftools="${FLOW_META[tools]:-}"

  if ! flow_resolve_inputs; then
    warn "Input flow dibatalkan."
    return 0
  fi

  ui_card_header "Automation Flow: $fname" "ID: $fid │ Risiko: ${frisk^^} │ ${#FLOW_STEP_IDS[@]} langkah"
  if [ -n "$ftools" ]; then
    printf '  %sPre-flight tool:%s ' "$C_MUTED" "$C_RESET"
    local IFS=',' t
    for t in $ftools; do
      t="${t// /}"
      if have "$t"; then
        printf '%s✓ %s%s  ' "$C_OK" "$t" "$C_RESET"
      else
        printf '%s✗ %s%s  ' "$C_WARN" "$t" "$C_RESET"
      fi
    done
    printf '\n'
  fi

  printf '\n  %sRencana Eksekusi:%s\n' "$C_ACCENT$C_BOLD" "$C_RESET"
  local sid stitle scmd resolved_preview
  idx=0
  for sid in "${FLOW_STEP_IDS[@]}"; do
    idx=$((idx + 1))
    stitle="${FLOW_STEP_DATA[${sid}:title]:-Langkah $sid}"
    scmd="${FLOW_STEP_DATA[${sid}:cmd]:-}"
    resolved_preview="$(flow_substitute_cmd "$scmd")"
    printf '    %s%d.%s %s\n       %s$ %s%s\n' "$C_PRIMARY" "$idx" "$C_RESET" "$stitle" "$C_MUTED" "$resolved_preview" "$C_RESET"
  done

  if [ "$DRY_RUN" = "1" ]; then
    printf '\n'
    warn "[DRY-RUN] Flow tidak dijalankan."
    pause
    return 0
  fi

  if [ "$fauth" = "true" ] || [ "$fsudo" = "true" ]; then
    printf '\n'
    read -r -p "Saya berwenang menjalankan flow ini pada target? (y/N): " ans || true
    [[ "$ans" =~ ^[yY]$ ]] || { warn "Dibatalkan."; return 0; }
  fi

  flow_log="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-flow-${fid}.log"
  printf '%s\t%s\t%s\n' "$(date -Is)" "flow:$fid" "netlauncher flow run $fid" >> "$HISTORY_FILE"
  {
    printf '# %s\n# flow: %s (%s)\n# user: %s\n# host: %s\n\n' \
      "$(date -Is)" "$fname" "$fid" "${USER:-unknown}" "$(hostname 2>/dev/null || echo '-')"
  } > "$flow_log"
  chmod 600 "$flow_log" 2>/dev/null || true

  summary_tmp="$(mktemp)"
  plain_all="$(mktemp)"
  ansi_all="$(mktemp)"
  total_steps="${#FLOW_STEP_IDS[@]}"
  flow_start="$(date +%s)"
  idx=0

  for sid in "${FLOW_STEP_IDS[@]}"; do
    idx=$((idx + 1))
    local stool swhen sparser son_err stimeout scap
    stitle="${FLOW_STEP_DATA[${sid}:title]:-Langkah $sid}"
    stool="${FLOW_STEP_DATA[${sid}:tool]:-flow}"
    swhen="${FLOW_STEP_DATA[${sid}:when]:-always}"
    sparser="${FLOW_STEP_DATA[${sid}:parser]:-auto}"
    son_err="${FLOW_STEP_DATA[${sid}:on_error]:-continue}"
    stimeout="${FLOW_STEP_DATA[${sid}:timeout]:-0}"
    scap="${FLOW_STEP_DATA[${sid}:capture]:-}"
    scmd="${FLOW_STEP_DATA[${sid}:cmd]:-}"

    printf '\n'
    ui_progress "$idx" "$total_steps" "Langkah $idx/$total_steps: $stitle"

    if ! flow_check_when "$swhen" "$prev_rc"; then
      printf '  %s⏭%s Dilewati (%s)\n' "$C_MUTED" "$C_RESET" "$swhen"
      printf '⏭ [%d/%d] %-38s (dilewati: %s)\n' "$idx" "$total_steps" "$stitle" "$swhen" >> "$summary_tmp"
      printf '\n== [%d/%d] %s (SKIPPED: %s) ==\n' "$idx" "$total_steps" "$stitle" "$swhen" >> "$flow_log"
      continue
    fi

    local final_cmd run_cmd s_start s_end s_dur s_rc
    final_cmd="$(flow_substitute_cmd "$scmd")"
    run_cmd="$final_cmd"
    if [[ "$stimeout" =~ ^[0-9]+$ ]] && [ "$stimeout" -gt 0 ] && have timeout; then
      run_cmd="timeout $stimeout bash -c $(printf '%q' "$final_cmd")"
    fi

    printf '  %s$ %s%s\n' "$C_MUTED" "$final_cmd" "$C_RESET"
    step_raw="$(mktemp)"
    step_ansi="$(mktemp)"
    step_plain="$(mktemp)"
    s_start="$(date +%s)"

    if [ -t 0 ] && [ -t 1 ] && have script; then
      (
        export NETLAUNCHER_RUN_CMD="$run_cmd"
        script -qefc 'bash -c "$NETLAUNCHER_RUN_CMD"' "$step_raw"
      )
      s_rc=$?
    else
      bash -c "$run_cmd" 2>&1 | tee "$step_raw"
      s_rc=${PIPESTATUS[0]}
    fi
    stty sane 2>/dev/null || true
    s_end="$(date +%s)"
    s_dur=$((s_end - s_start))
    prev_rc="$s_rc"

    runner_clean_ansi_stream < "$step_raw" > "$step_ansi"
    runner_strip_ansi < "$step_raw" > "$step_plain"

    {
      printf '\n== [%d/%d] %s ==\n# cmd: %s\n# exit=%s duration=%ss\n' "$idx" "$total_steps" "$stitle" "$final_cmd" "$s_rc" "$s_dur"
      cat "$step_plain"
    } >> "$flow_log"
    {
      printf '\n== [%d/%d] %s ==\n' "$idx" "$total_steps" "$stitle"
      cat "$step_plain"
    } >> "$plain_all"
    {
      printf '\n%s== [%d/%d] %s ==%s\n' "$C_PRIMARY$C_BOLD" "$idx" "$total_steps" "$stitle" "$C_RESET"
      cat "$step_ansi"
    } >> "$ansi_all"

    if [ "$s_rc" -eq 0 ]; then
      printf '✓ [%d/%d] %-38s (%ss · exit 0)\n' "$idx" "$total_steps" "$stitle" "$s_dur" >> "$summary_tmp"
      if [ -n "$scap" ] && [[ "$scap" == *=* ]]; then
        local cap_var="${scap%%=*}" cap_cmd="${scap#*=}" cap_val
        cap_val="$(bash -c "$cap_cmd" < "$step_plain" 2>/dev/null | head -n 1 | tr -d '\r\n' || true)"
        if [ -n "$cap_val" ]; then
          FLOW_VARS["$cap_var"]="$cap_val"
          printf '  %s↳ Captured %s=%s%s\n' "$C_ACCENT" "$cap_var" "$cap_val" "$C_RESET"
        fi
      fi
    else
      overall_rc=1
      printf '✗ [%d/%d] %-38s (%ss · exit %s)\n' "$idx" "$total_steps" "$stitle" "$s_dur" "$s_rc" >> "$summary_tmp"
    fi

    if [ "$sparser" != "none" ] && [ -s "$step_plain" ]; then
      printf '  %sRingkasan langkah:%s\n' "$C_ACCENT" "$C_RESET"
      runner_parse_highlights "$stool" "$step_plain" "$final_cmd" "$sparser"
    fi

    rm -f "$step_raw" "$step_ansi" "$step_plain"

    if [ "$s_rc" -ne 0 ]; then
      case "$son_err" in
        stop)
          err "Flow dihentikan karena langkah gagal (on_error=stop)."
          break
          ;;
        ask)
          if [ -t 0 ]; then
            read -r -p "Langkah gagal (exit $s_rc). Lanjutkan flow? (y/N): " ans || true
            [[ "$ans" =~ ^[yY]$ ]] || break
          fi
          ;;
      esac
    fi
  done

  flow_end="$(date +%s)"
  total_dur=$((flow_end - flow_start))
  printf '\n# flow_exit=%s total_duration=%ss\n' "$overall_rc" "$total_dur" >> "$flow_log"

  printf '\n%s╭─ Dashboard Hasil Flow ───────────────────────────────────────╮%s\n' "$C_PRIMARY" "$C_RESET"
  printf '%s│%s  %s%s%s  (%ss total)\n' "$C_PRIMARY" "$C_RESET" "$C_BOLD$C_WHITE" "$fname" "$C_RESET" "$total_dur"
  printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_PRIMARY" "$C_RESET"
  cat "$summary_tmp"
  printf '\n%sLog Flow:%s %s\n' "$C_MUTED" "$C_RESET" "$flow_log"

  if [ -t 0 ] && [ -t 1 ] && [ "${NETLAUNCHER_NO_POST_MENU:-0}" != "1" ]; then
    local pfile psel paction
    while true; do
      pfile="$(mktemp)"
      {
        printf '%s✓%s  Selesai & Kembali\tdone\n' "$C_OK" "$C_RESET"
        printf '%s🔍%s Filter Output Flow (fzf)\tfilter\n' "$C_PRIMARY" "$C_RESET"
        printf '%s📄%s Buka Log Flow Lengkap (less -R)\tpager\n' "$C_CYAN" "$C_RESET"
        printf '%s📝%s Ekspor Laporan Flow Markdown (~/laporan/)\texport\n' "$C_GREEN" "$C_RESET"
        printf '%s↻%s  Jalankan Ulang Flow\trerun\n' "$C_YELLOW" "$C_RESET"
      } > "$pfile"
      psel="$(ui_fzf \
        --prompt='  Hasil Flow ▸ ' \
        --header="$fname │ ${total_dur}s │ $(basename "$flow_log")" \
        --header-first \
        --preview="$SELF --preview-log $(printf '%q' "$flow_log")" \
        --preview-window='right:56%:wrap' \
        --delimiter=$'\t' --with-nth=1 < "$pfile")"
      rm -f "$pfile"
      [ -n "$psel" ] || break
      paction="$(printf '%s\n' "$psel" | awk -F'\t' '{print $2}')"
      case "$paction" in
        done|"") break ;;
        filter) runner_filter_output_fzf "$ansi_all" "$fname" ;;
        pager) if have less; then less -R "$ansi_all"; else cat "$plain_all"; pause; fi ;;
        export) flow_export_markdown "$fid" "$fname" "$total_dur" "$flow_log" "$summary_tmp" "$plain_all"; pause ;;
        rerun)
          rm -f "$summary_tmp" "$plain_all" "$ansi_all"
          flow_run "$target" "$@"
          return $?
          ;;
      esac
    done
  fi

  rm -f "$summary_tmp" "$plain_all" "$ansi_all"
  return "$overall_rc"
}

flow_create_wizard() {
  local slug name desc risk req_auth="false" out step_n=0
  local inputs_list=() steps_block="" tools_used=()
  read -r -p "ID flow (tanpa spasi, mis. audit-server-lokal): " slug || true
  [ -n "$slug" ] || { warn "Dibatalkan."; return 0; }
  slug="${slug//[^a-zA-Z0-9_-]/-}"
  read -r -p "Nama flow: " name || true
  read -r -p "Deskripsi singkat: " desc || true
  read -r -p "Tingkat risiko [pasif/aman/aktif] (default pasif): " risk || true
  risk="${risk:-pasif}"
  [ "$risk" = "aktif" ] && req_auth="true"

  local in_choice
  read -r -p "Input placeholder (pisahkan koma, mis. DOMAIN,URL atau kosong): " in_choice || true

  while true; do
    local sfile ssel sline tid stitle scmd snotes ssudo sph stool
    sfile="$(mktemp)"
    {
      printf '%s✓%s  Selesai menambah langkah (%s langkah)\t__DONE__\n' "$C_OK" "$C_RESET" "$step_n"
      printf '%s✎%s  Tulis perintah langkah kustom\t__CUSTOM__\n' "$C_ACCENT" "$C_RESET"
      while IFS= read -r sf; do
        awk -F'\t' -v f="$sf" '!/^#/ && NF>=6 {printf "⌘ %-12s │ %-28s \033[2m%s\033[0m\t%s:%d\n", $1, $2, substr($3,1,36), f, NR}' "$sf"
      done < <(snippets_files)
    } > "$sfile"
    ssel="$(ui_fzf \
      --prompt="  Tambah Langkah $((step_n+1)) ▸ " \
      --header="Flow Builder: ${name:-$slug} ($step_n langkah)" \
      --header-first \
      --delimiter=$'\t' --with-nth=1 < "$sfile")"
    rm -f "$sfile"
    [ -n "$ssel" ] || break
    local ref
    ref="$(printf '%s\n' "$ssel" | awk -F'\t' '{print $2}')"
    [ "$ref" = "__DONE__" ] && break
    step_n=$((step_n + 1))
    if [ "$ref" = "__CUSTOM__" ]; then
      read -r -p "Judul langkah $step_n: " stitle || true
      read -r -p "Perintah bash: " scmd || true
      stool="bash"
    else
      local sfile_path="${ref%:*}" sline_num="${ref##*:}"
      sline="$(sed -n "${sline_num}p" "$sfile_path")"
      IFS=$'\t' read -r tid stitle scmd snotes ssudo sph <<< "$sline"
      stool="$(tool_field "$tid" 4)"
      [ -n "$stool" ] || stool="$tid"
    fi
    [ -n "$scmd" ] || { step_n=$((step_n - 1)); continue; }
    tools_used+=("$stool")
    steps_block+=$'\n'"[step:$step_n]"$'\n'
    steps_block+="title = ${stitle:-Langkah $step_n}"$'\n'
    steps_block+="tool = $stool"$'\n'
    steps_block+="when = have:$stool"$'\n'
    steps_block+="parser = auto"$'\n'
    steps_block+="on_error = continue"$'\n'
    steps_block+="cmd = $scmd"$'\n'
  done

  if [ "$step_n" -eq 0 ]; then
    warn "Tidak ada langkah ditambahkan. Dibatalkan."
    pause
    return 0
  fi

  mkdir -p "$FLOWS_LOCAL_DIR"
  out="$FLOWS_LOCAL_DIR/$slug.flow"
  local unique_tools
  unique_tools="$(printf '%s\n' "${tools_used[@]}" | awk '!seen[$0]++' | paste -sd, -)"
  {
    echo "[flow]"
    echo "id = $slug"
    echo "name = ${name:-$slug}"
    echo "category = diagnostik"
    echo "risk = $risk"
    echo "requires_auth = $req_auth"
    echo "sudo = false"
    echo "description = ${desc:-Flow otomasi kustom}"
    echo "tools = $unique_tools"
    echo
    echo "[inputs]"
    if [ -n "$in_choice" ]; then
      local IFS=',' ik
      for ik in $in_choice; do
        ik="${ik// /}"
        [ -n "$ik" ] && echo "$ik = Nilai untuk $ik"
      done
    fi
    printf '%s' "$steps_block"
  } > "$out"
  chmod 600 "$out" 2>/dev/null || true
  ok "Flow modern dibuat: $out"
  pause
}

flow_ui() {
  local file sel f fid fname frisk fdesc path action
  while true; do
    file="$(mktemp)"
    {
      printf '%s+%s   Buat Flow Baru (Wizard)\t__NEW__\n' "$C_OK" "$C_RESET"
      while IFS= read -r f; do
        flow_parse_file "$f" 2>/dev/null || continue
        fid="${FLOW_META[id]:-$(basename "$f" .flow)}"
        fname="${FLOW_META[name]:-$fid}"
        frisk="${FLOW_META[risk]:-pasif}"
        fdesc="${FLOW_META[description]:-}"
        printf '%s🌊%s %-26s %s[%-5s]%s  %s%s%s\t%s\n' \
          "$C_CYAN" "$C_RESET" "$fname" "$C_MUTED" "$frisk" "$C_RESET" \
          "$C_MUTED" "${fdesc:0:46}" "$C_RESET" "$f"
      done < <(flow_list_files)
      printf '%s←%s   Kembali\t__BACK__\n' "$C_MUTED" "$C_RESET"
    } > "$file"
    sel="$(ui_fzf \
      --prompt='  Flow ▸ ' \
      --ghost='Pilih automation flow...' \
      --header="Automation Flow (${FLOWS_DIR})" \
      --header-first \
      --header-label=' Automation Flow Engine ' \
      --list-label=' Daftar Flow ' \
      --preview="$SELF --preview-flow {2}" \
      --preview-window='right:56%:wrap' \
      --preview-label=' Rencana Flow ' \
      --footer='Enter: Jalankan │ Esc: Kembali' \
      --footer-border=line \
      --delimiter=$'\t' --with-nth=1 < "$file")"
    rm -f "$file"
    [ -n "$sel" ] || return 0
    path="$(printf '%s\n' "$sel" | awk -F'\t' '{print $2}')"
    case "$path" in
      __BACK__) return 0 ;;
      __NEW__) flow_create_wizard; continue ;;
    esac
    flow_parse_file "$path" || continue
    fid="${FLOW_META[id]:-$(basename "$path" .flow)}"
    fname="${FLOW_META[name]:-$fid}"

    action_file="$(mktemp)"
    {
      printf '%s▶%s  Jalankan Flow\t__RUN__\n' "$C_OK" "$C_RESET"
      printf '%s👁%s  Dry-run (pratinjau tanpa eksekusi)\t__DRY__\n' "$C_ACCENT" "$C_RESET"
      printf '%s📖%s  Lihat Rencana Detail\t__SHOW__\n' "$C_CYAN" "$C_RESET"
      printf '%s←%s  Kembali\t__BACK__\n' "$C_MUTED" "$C_RESET"
    } > "$action_file"
    action="$(ui_fzf \
      --prompt='  Aksi Flow ▸ ' \
      --header="$fname ($fid)" \
      --header-first \
      --preview="$SELF --preview-flow $(printf '%q' "$path")" \
      --preview-window='right:56%:wrap' \
      --delimiter=$'\t' --with-nth=1 < "$action_file")"
    rm -f "$action_file"
    case "$(printf '%s\n' "$action" | awk -F'\t' '{print $2}')" in
      __RUN__) flow_run "$path" ;;
      __DRY__) DRY_RUN=1 flow_run "$path" ;;
      __SHOW__) FORCE_COLOR=1 preview_flow "$path" | less -R 2>/dev/null || preview_flow "$path"; pause ;;
    esac
  done
}

flow_cli() {
  local sub="${1:-list}"
  shift || true
  case "$sub" in
    ui)
      flow_ui
      ;;
    list)
      local f fid fname frisk
      while IFS= read -r f; do
        fid="$(awk -F'=' '/^id[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$f")"
        fname="$(awk -F'=' '/^name[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$f")"
        frisk="$(awk -F'=' '/^risk[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$f")"
        printf '%-24s [%-5s] %s\n' "${fid:-$(basename "$f" .flow)}" "${frisk:-pasif}" "${fname:-}"
      done < <(flow_list_files)
      ;;
    show)
      [ -n "${1:-}" ] || die "Gunakan: netlauncher flow show <id>"
      preview_flow "$1"
      ;;
    run)
      [ -n "${1:-}" ] || die "Gunakan: netlauncher flow run <id> [--var KEY=VAL ...]"
      local fid="$1" vars=()
      shift
      while [ $# -gt 0 ]; do
        case "$1" in
          --var)
            [ -n "${2:-}" ] || die "Gunakan: --var KEY=VAL"
            vars+=("$2")
            shift 2
            ;;
          *)
            vars+=("$1")
            shift
            ;;
        esac
      done
      flow_run "$fid" "${vars[@]}"
      ;;
    *)
      die "Subcommand flow tidak dikenal: $sub (gunakan: ui | list | show <id> | run <id>)"
      ;;
  esac
}
