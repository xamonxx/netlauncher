# netlauncher.bash - Bash completion untuk NetLauncher v2.1.0
# Pasang: source file ini dari ~/.bashrc, atau salin ke /etc/bash_completion.d/

_netlauncher_complete() {
  local cur prev cmd
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]}"

  local commands="search examples snippets guide flags flow workspace automation wordlists logs theme tool recipe list doctor selftest lint update help"
  local themes="cyber tokyo emerald amber"
  local flow_sub="list show run"
  local ws_sub="show set clear"
  local recipes="cek-koneksi info-jaringan audit-web dns monitor-port discovery-lokal scan-target capture wordlist-stats laporan"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$commands --no-anim --dry-run --theme --version --help" -- "$cur") )
    return 0
  fi

  case "$cmd" in
    theme)
      COMPREPLY=( $(compgen -W "$themes" -- "$cur") )
      ;;
    flow)
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=( $(compgen -W "$flow_sub" -- "$cur") )
      ;;
    workspace)
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=( $(compgen -W "$ws_sub" -- "$cur") )
      ;;
    recipe)
      COMPREPLY=( $(compgen -W "$recipes" -- "$cur") )
      ;;
    tool|guide|flags|examples|snippets)
      local ids
      ids="$(netlauncher list 2>/dev/null | awk 'NR>1{print $2}')"
      COMPREPLY=( $(compgen -W "$ids" -- "$cur") )
      ;;
  esac
  return 0
}

complete -F _netlauncher_complete netlauncher
