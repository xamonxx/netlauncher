# lib/workflow.sh - Findings store and local repository security checks

finding_add() {
  local severity="$1" title="$2" asset="$3" source="$4" evidence="${5:-}" status="baru" id ts project
  id="$(printf '%s\0%s\0%s\0%s' "$severity" "$title" "$asset" "$source" | sha256sum | awk '{print $1}')"
  ts="$(date -Is)"
  project="$(project_name 2>/dev/null || true)"
  python3 - "$FINDINGS_FILE" "$id" "$ts" "$severity" "$title" "$asset" "$source" "$status" "$evidence" "$project" <<'PY'
import json, os, sys, tempfile
path, fid, ts, severity, title, asset, source, status, evidence, project = sys.argv[1:]
os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
rows=[]
try:
    with open(path, encoding='utf-8') as f:
        rows=[json.loads(line) for line in f if line.strip()]
except FileNotFoundError:
    pass
row={'id':fid,'created':ts,'updated':ts,'severity':severity,'title':title,'asset':asset,'source':source,'status':status,'evidence':evidence[:2000],'project':project}
for old in rows:
    if old.get('id')==fid:
        old.update(row); row=old; break
else:
    rows.append(row)
fd,tmp=tempfile.mkstemp(dir=os.path.dirname(path))
with os.fdopen(fd,'w',encoding='utf-8') as f:
    for item in rows: f.write(json.dumps(item,ensure_ascii=False)+'\n')
os.chmod(tmp,0o600); os.replace(tmp,path); os.chmod(path,0o600)
PY
}

findings_list() {
  local filter="${1:-all}"
  python3 - "$FINDINGS_FILE" "$filter" "$(project_name 2>/dev/null || true)" <<'PY'
import json, os, sys
path, filt, project=sys.argv[1:]
if not os.path.exists(path): raise SystemExit(0)
with open(path,encoding='utf-8') as f:
    for line in f:
        try: x=json.loads(line)
        except json.JSONDecodeError: continue
        if project and x.get('project') not in ('',project): continue
        if filt!='all' and x.get('status')!=filt and x.get('severity')!=filt: continue
        print(f"{x.get('severity','?').upper():8} [{x.get('status','?')}] {x.get('title','')} — {x.get('asset','')} ({x.get('source','')})")
PY
}

findings_update_status() {
  local id="$1" status="$2"
  python3 - "$FINDINGS_FILE" "$id" "$status" <<'PY'
import json, os, sys, tempfile
path,fid,status=sys.argv[1:]
rows=[]; changed=False
if os.path.exists(path):
    with open(path,encoding='utf-8') as f:
        for line in f:
            try: x=json.loads(line)
            except json.JSONDecodeError: continue
            if x.get('id','').startswith(fid): x['status']=status; x['updated']=__import__('datetime').datetime.now().astimezone().isoformat(); changed=True
            rows.append(x)
if changed:
    fd,tmp=tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd,'w',encoding='utf-8') as f:
        for x in rows: f.write(json.dumps(x,ensure_ascii=False)+'\n')
    os.chmod(tmp,0o600); os.replace(tmp,path); os.chmod(path,0o600)
print('updated' if changed else 'not-found')
PY
}

findings_menu() {
  require_fzf
  local file sel action id status
  while true; do
    file="$(mktemp)"
    {
      printf '↻  Ekspor temuan ke JSON\t__EXPORT__\n'
      python3 - "$FINDINGS_FILE" "$(project_name 2>/dev/null || true)" <<'PY'
import json,os,sys
p,project=sys.argv[1:]
if not os.path.exists(p): raise SystemExit(0)
with open(p,encoding='utf-8') as f:
 for line in f:
  try:x=json.loads(line)
  except json.JSONDecodeError:continue
  if project and x.get('project') not in ('',project):continue
  title=x.get('title','').replace('\\t',' ').replace('\\n',' ')
  print(f"[{x.get('severity','?').upper()}] {title} — {x.get('asset','')} ({x.get('status','?')})\t{x.get('id','')}")
PY
    } > "$file"
    sel="$(ui_fzf --prompt='  Temuan ▸ ' --header="Temuan Keamanan — $(project_name 2>/dev/null || echo 'semua proyek')" --header-first --delimiter=$'\t' --with-nth=1 --footer='Enter: Ubah status │ e: Ekspor │ Esc: Kembali' < "$file")"
    rm -f "$file"
    [ -n "$sel" ] || return 0
    action="$(awk -F'\t' '{print $2}' <<< "$sel")"
    if [ "$action" = '__EXPORT__' ]; then findings_export; continue; fi
    [ -n "$action" ] || continue
    id="${action:0:12}"
    status="$(ui_fzf --prompt='  Status ▸ ' --header='Pilih status temuan' < <(printf 'baru\nditinjau\nperlu-diperbaiki\nditerima-risikonya\nselesai\n'))"
    [ -n "$status" ] && findings_update_status "$id" "$status"
  done
}

findings_export() {
  local out="$REPORT_DIR/findings-$(date +%Y%m%d-%H%M%S).json" project
  project="$(project_name 2>/dev/null || true)"
  python3 - "$FINDINGS_FILE" "$out" "$project" <<'PY'
import json, os, sys
src,dst,project=sys.argv[1:]
rows=[]
if os.path.exists(src):
    with open(src,encoding='utf-8') as f:
        for line in f:
            try: x=json.loads(line)
            except json.JSONDecodeError: continue
            if not project or x.get('project') in ('',project): rows.append(x)
with open(dst,'w',encoding='utf-8') as f: json.dump({'project':project,'findings':rows},f,ensure_ascii=False,indent=2)
os.chmod(dst,0o600)
PY
  ok "Temuan diekspor: $out"
}

repo_scan() {
  local root="${1:-.}" tool out rc=0 json_file findings=0 saved_target="${WS_TARGET:-}" did_scan=0 scanned=0
  [ -d "$root" ] || die "Direktori tidak ditemukan: $root"
  root="$(cd "$root" && pwd -P)"
  [ -d "$root/.git" ] || [ -f "$root/.git" ] || warn "Direktori bukan checkout Git: $root"
  if [ -n "$(active_project_name 2>/dev/null || true)" ]; then
    WS_TARGET="$root"
    confirm_scope || { WS_TARGET="$saved_target"; die "Repo lokal tidak cocok dengan cakupan proyek."; }
    WS_TARGET="$saved_target"
  fi
  if [ -n "$(active_project_name 2>/dev/null || true)" ]; then
    local saved_target="$WS_TARGET"
    WS_TARGET="$root"
    confirm_scope || { WS_TARGET="$saved_target"; die "Repo lokal tidak cocok dengan cakupan proyek."; }
    WS_TARGET="$saved_target"
  fi
  for tool in gitleaks trivy semgrep; do
    have "$tool" || { warn "$tool belum terpasang; lewati."; continue; }
    confirm_authorized_action "$tool" "$tool local scan: $root" 0 || { warn "$tool dibatalkan."; continue; }
    did_scan=1
    scanned=$((scanned+1))
    json_file="$(mktemp)"
    case "$tool" in
      gitleaks) "$tool" git --no-banner --redact --report-format json --report-path "$json_file" "$root" >/dev/null 2>&1; rc=$? ;;
      trivy) "$tool" fs --scanners vuln,misconfig,secret --format json --output "$json_file" "$root" >/dev/null 2>&1; rc=$? ;;
      semgrep) "$tool" scan --config auto --json --json-output="$json_file" "$root" >/dev/null 2>&1; rc=$? ;;
    esac
    out="$REPORT_DIR/${tool}-$(date +%Y%m%d-%H%M%S).json"
    if [ -s "$json_file" ]; then
      cp "$json_file" "$out"; chmod 600 "$out"
      findings="$(python3 - "$tool" "$json_file" <<'PY'
import json,sys
kind,path=sys.argv[1:]
try:
 x=json.load(open(path,encoding='utf-8'))
 if kind=='gitleaks': print(len(x) if isinstance(x,list) else 0)
 elif kind=='trivy': print(sum(len(r.get('Vulnerabilities') or [])+len(r.get('Misconfigurations') or [])+len(r.get('Secrets') or []) for r in x.get('Results',[])))
 else: print(len(x.get('results',[])))
except Exception: print(0)
PY
)"
      ok "$tool selesai (exit $rc, temuan $findings); JSON: $out"
      finding_add info "$tool: $findings temuan; tinjau laporan JSON" "$root" "$tool" "Laporan: $out"
    else
      warn "$tool selesai tanpa JSON (exit $rc)."
      finding_add info "$tool selesai; JSON tidak tersedia (exit $rc)" "$root" "$tool" "Tinjau log/perintah manual."
    fi
    rm -f "$json_file"
  done
  [ "$scanned" -gt 0 ] || warn "Tidak ada scanner yang selesai dijalankan. Pasang tool dari sumber resminya lalu ulangi."
}
