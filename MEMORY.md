# NetLauncher — Memory / Project Context

- **Terakhir diperbarui:** 2026-11-17
- **Versi aktif:** 2.2.0-dev (berbasis rilis 2.1.0)
- **Status:** terpasang dan terverifikasi
- **Repo / lokasi kanonik:** `~/tools/netlauncher/`
- **File ini:** `~/tools/netlauncher/MEMORY.md`
- **Symlink:** `~/NETLAUNCHER_MEMORY.md` dan `~/.config/netlauncher/MEMORY.md`
- **Dokumentasi repo:** `README.md`, `AGENTS.md`, `docs/`
- **Penggunaan:** hanya pada aset/jaringan yang dimiliki atau diizinkan tertulis.

---

## 1. Lingkungan

| Item | Nilai |
| --- | --- |
| OS | Kali GNU/Linux Rolling 2026.3 |
| User / home | `xamonxx` / `/home/xamonxx` |
| Shell utama | zsh (`/usr/bin/zsh`) |
| Python | 3.14.10 |
| pipx | 1.15.0 |
| Go | 1.27.3 |
| Ruby | 3.3.8 |
| fzf | 0.75 (devel), lokal di `~/.local/bin/fzf` |
| sudo | butuh password; tidak tersedia non-interaktif |

Catatan: password sudo tidak disimpan di mana pun. Resep capture meminta password saat runtime.

---

## 2. Komponen yang Dipasang

### fzf

- Binary: `~/.local/bin/fzf` (versi 0.75 dengan dukungan `--style=full:rounded`, `--border-label`, `--ghost`, `--footer`, `--input-label`, `--list-label`, `--header-label`)
- Dipasang tanpa sudo:
  ```bash
  GOBIN="$HOME/.local/bin" go install github.com/junegunn/fzf@latest
  ```
- Tidak ada instalasi fzf system-wide via apt.

### hackingtool

- Versi: **3.1.0**
- Repo: `~/tools/hackingtool`
- Binary: `~/.local/bin/hackingtool`
- Metode: `pipx install .`
- TUI terverifikasi berjalan.
- Update:
  ```bash
  git -C ~/tools/hackingtool pull --ff-only
  pipx install ~/tools/hackingtool --force
  ```
  Atau: `netlauncher update`

### Runtime opsional

- Go 1.27.3 dan Ruby 3.3.8 sudah tersedia.
- `build-essential` sudah terpasang.
- `tmux` tersedia.
- `ruby-dev` tidak dipasang; tambahkan hanya jika gem membutuhkan header native.

---

## 3. Struktur File

```text
~/tools/netlauncher/                        # repo kanonik
├── AGENTS.md                               # aturan kontribusi/agen
├── MEMORY.md                               # file ini
├── README.md                               # dokumentasi pengguna
├── Makefile                                # check/test/lint/install/backup/ui-test
├── bin/netlauncher                         # entrypoint CLI & menu loop (Bash)
├── lib/
│   ├── core.sh                             # path, overlay, workspace, helper, registry, target history
│   ├── ui.sh                               # 4 tema truecolor, animasi, badge, wrapper fzf
│   ├── runner.sh                           # PTY runner, parser output, post-run viewer, ekspor Markdown
│   ├── smart.sh                            # konteks jaringan, smart picker, command builder, advisor
│   ├── snippets.sh                         # browser & runner 104 contoh perintah (overlay-aware)
│   ├── wordlists.sh                        # indexer & browser wordlist
│   ├── knowledge.sh                        # 27 panduan resmi, 205 flag, flag builder, live --help/man
│   ├── flow.sh                             # engine .flow, wizard, pipeline runner, dashboard
│   ├── recipes.sh                          # 10 resep aman & custom automation scripts
│   ├── menu.sh                             # menu utama, workspace/proyek, pencarian global, aksi tool, log
│   ├── workflow.sh                         # findings JSONL, triase, repo scan lokal
│   └── doctor.sh                           # doctor, selftest, lint, list (--json), update, help
├── config/
│   ├── tools.tsv                           # registry 51 tool, 11 field (delimiter |)
│   ├── snippets.tsv                        # 104 contoh perintah, 6 field (delimiter tab)
│   ├── flags.tsv                           # 205 flag resmi, 7 field (delimiter tab)
│   ├── guides/                             # 27 panduan resmi Bahasa Indonesia (*.md)
│   ├── flows/                              # 6 starter automation flow (*.flow)
│   ├── automations/                        # 4 starter script + custom automation (*.sh)
│   ├── help.md                             # panduan pengguna
│   ├── tools.local.tsv                     # overlay lokal, tidak di-track
│   ├── snippets.local.tsv                  # overlay lokal, tidak di-track
│   ├── flows.local/                        # overlay lokal, tidak di-track
│   ├── favorites.tsv                       # runtime, tidak di-track
│   ├── wordlists.tsv                       # index 136 wordlist, tidak di-track
│   ├── theme.env                           # runtime preferensi tema/animasi, tidak di-track
│   └── MEMORY.md                           # symlink ke ../MEMORY.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   ├── ROADMAP.md
│   └── CHANGELOG.md
├── tests/smoke.sh
└── scripts/
    ├── install.sh
    ├── backup.sh
    └── ui-test.sh

# Symlink live -> repo
~/.local/bin/netlauncher -> ~/tools/netlauncher/bin/netlauncher
~/.config/netlauncher    -> ~/tools/netlauncher/config
~/NETLAUNCHER_MEMORY.md  -> ~/tools/netlauncher/MEMORY.md

# Tool lain dan desktop entry
~/.local/bin/fzf                            # fzf lokal
~/.local/bin/hackingtool                    # symlink pipx
~/tools/hackingtool/                        # repo hackingtool
~/.local/share/applications/netlauncher.desktop

# Runtime (di luar repo)
~/.local/share/netlauncher/
├── logs/                                   # log per sesi, permission 700, rotasi > 30 hari
├── history.log                             # riwayat perintah
├── targets.history                         # riwayat target/domain/URL untuk Smart Picker
├── workspace.env                           # Target Workspace legacy
├── projects/*.env + active-project         # profil proyek, workspace & scope
└── findings.jsonl                          # findings lokal terstruktur
├── projects/*.env + active-project         # profil proyek, workspace & scope terpisah
└── findings.jsonl                          # temuan terstruktur lokal

~/wordlists/                                # wordlist lokal
├── README.md                               # sumber, lisensi, SHA256
├── rockyou.txt
└── indonesian/
    ├── geovedi/
    ├── kbbi/
    ├── elliottophellia/
    └── indonesian-pwdb-top150.txt

~/laporan/                                  # laporan Markdown
```

Permission penting:

- `~/.local/share/netlauncher/` dan `logs/`: `700`
- `history.log`, `targets.history`, `workspace.env`, `projects/*.env`, `active-project`, `findings.jsonl`, `favorites.tsv`, `wordlists.tsv`, `theme.env`, log, laporan: `600`

### Alur kerja repo

```bash
cd ~/tools/netlauncher
make check                  # syntax + smoke test
make lint                   # netlauncher lint + shellcheck (jika ada)
make ui-test                # uji UI di tmux
netlauncher selftest
netlauncher doctor
make backup                 # arsip script + konfigurasi
```

- Semua perubahan dikerjakan di repo, bukan lewat path live.
- Panduan kontribusi lengkap: `AGENTS.md`.
- Detail arsitektur: `docs/ARCHITECTURE.md`.
- Alur pengembangan dan checklist: `docs/DEVELOPMENT.md`.
- Rencana fitur: `docs/ROADMAP.md`; riwayat perubahan: `docs/CHANGELOG.md`.
- `favorites.tsv`, `wordlists.tsv`, dan `theme.env` bersifat runtime dan tidak di-track git.

---

## 4. Arsitektur Launcher (v2.1.0)

`bin/netlauncher` adalah entrypoint ringan yang memuat 11 modul di `lib/*.sh`.
Sumber kanonik ada di repo; path live `~/.local/bin/netlauncher` adalah symlink,
sehingga edit di repo langsung berlaku tanpa menyalin ulang.

### Registry tool: `tools.tsv`

Format 11 field, delimiter `|`:

```text
category|id|label|binary|template|description|help|sudo|arg_prompt|mode|examples
```

Total: **51 entri** (seluruh 51 binary terpasang di mesin ini).

### Koleksi Contoh Perintah: `snippets.tsv`

Format 6 field, delimiter **TAB** (`\t`) agar aman terhadap shell pipe `|`:

```text
tool_id	title	command	notes	sudo	placeholders
```

Total: **104 entri** mencakup seluruh 51 tool.

### Kategori

- Diagnostik Jaringan (8) — `ping`, `traceroute`, `curl`, `wget`, `whois`, `openssl`, `nc`, `socat`
- DNS & Web (14) — `dig`, `nslookup`, `whatweb`, `nikto`, `gobuster`, `ffuf`, `feroxbuster`, `dirb`, `wfuzz`, `httpx`, `nuclei`, `amass`, `sqlmap`, `searchsploit`
- Interface & Routing (8) — `ip addr`, `ip route`, `ss`, `netstat`, `iw dev`, `nmcli`, `ethtool`, `lsof`
- Pemindaian & Monitoring (9) — `nmap`, `masscan`, `arp-scan`, `netdiscover`, `tcpdump`, `tshark`, `tcpflow`, `ngrep`, `wireshark`
- Wireless (Berizin) (5) — `airmon-ng`, `aircrack-ng`, `kismet`, `reaver`, `wifite`
- Tool Keamanan (Berizin) (4) — `hydra`, `john`, `hashcat`, `msfconsole`
- Hackingtool (3) — TUI, classic REPL, bantuan

### Fitur UI & Pintar

- Splash screen ASCII animasi + progress bar + spinner murni Bash (`--no-anim` / `NETLAUNCHER_NO_ANIM=1` untuk menonaktifkan)
- `fzf 0.75` `--style=full:rounded --border=rounded --height=100%` dengan panel Status Sistem, Pencarian, Daftar, Inspector Preview, dan Footer
- 4 tema truecolor (`cyber`, `tokyo`, `emerald`, `amber`) dengan pratinjau palet langsung (`Ctrl-T`)
- Shortcut menu utama: `Ctrl-S` (Global Search), `Ctrl-E` (Code Snippets), `Ctrl-K` (Knowledge), `Ctrl-W` (Workspace), `Ctrl-T` (Tema & Animasi), `Ctrl-L` (Riwayat & Log)
- Smart Network Context (`smart_net_context`): deteksi interface aktif, IP/CIDR, subnet, gateway, DNS, SSID WiFi, status `ONLINE`/`LOKAL`/`OFFLINE`
- Smart Placeholder Picker (`smart_prompt_placeholder`): saran kontekstual + riwayat target untuk `{TARGET}`, `{SUBNET}`, `{IFACE}`, `{DOMAIN}`, `{URL}`, `{PORT}`, `{WORDLIST}`, `{FILE}`, `{QUERY}`
- Command Builder (`smart_command_builder`): pilih preset/template, isi parameter pintar, edit perintah, jalankan / salin / dry-run
- Missing Tool Advisor (`smart_missing_advisor`): saran instalasi + alternatif terpasang
- Custom Automation Scripts (`config/automations/*.sh`): 4 starter script + buat/edit/jalankan script kustom
- Browser wordlist: preview, salin path, buka di `less`, statistik
- **Modern Execution Runner** (`lib/runner.sh`): `script -qefc` pada TTY (warna + prompt interaktif + exit code tepat), `tee` + `PIPESTATUS[0]` pada non-TTY, log teks polos, parser `ping`/`nmap`/`http_headers`/`tls`/`dns`/`sockets`/`fuzz`/`vuln`/`net`/`capture`, post-run menu (filter/pager/salin/ekspor/saran/rerun)
- **Knowledge Base** (`lib/knowledge.sh`): 27 panduan resmi, 205 flag di `config/flags.tsv`, `knowledge_flag_builder()` dengan `mapfile` (stdin aman untuk prompt), normalisasi subcommand wajib, dan live extractor `--help`/`man` (khusus `amass` memakai `man` agar tidak memicu unduhan libpostal via sudo)
- **Automation Flow** (`lib/flow.sh`): format INI `[flow]`/`[inputs]`/`[step:N]`, `when` digabung `;`, `capture` variabel, `on_error`, `parser`, `timeout`, dashboard + ekspor Markdown. `flow_resolve_inputs()`turunan `DOMAIN` dari `URL` juga berlaku untuk `--var URL=...`
- **Target Workspace** (`workspace.env`) diprioritaskan di Smart Picker, Flag Builder, dan advisor; shortcut `Ctrl-W` / `netlauncher workspace`
- **Overlay**: `tools.local.tsv`, `snippets.local.tsv`, `flows.local/` digabung otomatis (semua masuk `.gitignore`)
- Completion Bash (`scripts/completions/netlauncher.bash`) dan Zsh (`scripts/completions/_netlauncher`)
- `doctor`, `selftest`, `lint` (juga memvalidasi flags/guides/flow), `list --json`, `update`, `--dry-run`, `--no-anim`, `--theme`
- Desktop entry dan alias `net`

### Perintah CLI

```bash
netlauncher                       # menu utama
netlauncher search                # pencarian global tool & contoh perintah
netlauncher examples [tool_id]    # browser contoh perintah & code snippets
netlauncher snippets [tool_id]    # alias untuk examples
netlauncher guide [tool_id]       # panduan resmi (stdout bila non-TTY)
netlauncher flags [tool_id]       # Interactive Flag Builder
netlauncher flow [ui|list|show|run]
netlauncher workspace [show|set|clear]
netlauncher automation            # kelola & jalankan custom automation scripts
netlauncher wordlists [refresh]   # browser / refresh wordlist
netlauncher logs                  # viewer log sesi
netlauncher theme [nama]          # ubah tema (cyber|tokyo|emerald|amber)
netlauncher tool <id>             # jalankan tool langsung
netlauncher recipe <nama>         # jalankan resep otomasi aman
netlauncher list [--json]         # daftar tool (tabel atau JSON)
netlauncher doctor                # cek dependensi & terminal
netlauncher selftest              # validasi registry & snippet
netlauncher lint                  # validasi ketat TSV & syntax
netlauncher update                # update hackingtool + index wordlist
netlauncher help                  # panduan lengkap
netlauncher --version
netlauncher --help
```

### Alias

`~/.zshrc` dan `~/.bashrc` berisi:

```bash
# >>> netlauncher >>>
alias net='netlauncher'
# <<< netlauncher <<<
```

Aktifkan dengan membuka terminal baru atau `source ~/.zshrc`.

### Desktop entry

`~/.local/share/applications/netlauncher.desktop`

```ini
[Desktop Entry]
Type=Application
Name=NetLauncher
Exec=/home/xamonxx/.local/bin/netlauncher
Icon=utilities-terminal
Terminal=true
Categories=Network;
```

---

## 5. Resep Otomasi (10 Resep)

Semua resep menampilkan perintah sebelum eksekusi, mendukung `--dry-run`, dan menyimpan log.

| Nama | Fungsi | Sudo |
| --- | --- | --- |
| `cek-koneksi` | Ping gateway/internet, DNS, HTTP timing | tidak |
| `info-jaringan` | IP, subnet, route, `iw dev`, `ss`, resolver | tidak |
| `audit-web` | HTTP security headers, timing, sertifikat TLS, DNS, WhatWeb | tidak |
| `dns` | Query A, AAAA, MX, NS, TXT, SOA, DMARC, WHOIS | tidak |
| `monitor-port` | Ringkasan socket, port listening, koneksi aktif, `lsof` | tidak |
| `discovery-lokal` | Tabel ARP lokal + opsional ping sweep berizin | tidak |
| `scan-target` | Nmap (Top 100 / Service+NSE / Full TCP) + konfirmasi otorisasi | tidak |
| `capture` | `tcpdump` pada interface + filter BPF + durasi | ya |
| `wordlist-stats` | Baris, ukuran, cuplikan, unik | tidak |
| `laporan` | Gabungkan log 24 jam ke Markdown | tidak |

Batasan:

- Tidak ada otomasi deauth, handshake capture, atau brute-force.
- Scan/capture meminta konfirmasi.
- Resep hanya untuk target berizin.
- `recipe_laporan` menyediakan 3 template: `ringkas` (log 24 jam), `lengkap` (7 hari + indeks), `audit` (checklist temuan + baris error).

---

## 5b. Knowledge, Flag Builder & Automation Flow (v2.1.0)

## 5c. Profil Proyek, Temuan & Repo Scan (v2.2.0-dev)

- Profil proyek di `$DATA_DIR/projects/<slug>.env`; `$DATA_DIR/active-project` memilih proyek.
- `workspace create|use|projects|scope|set|show|clear|delete`; scope domain/IP/path dicocokkan sebelum aksi berdampak.
- `FINDINGS_FILE=$DATA_DIR/findings.jsonl`: JSONL lokal mode 600, deduplikasi via SHA-256, status triase, `findings list|export`, menu Temuan.
- `repo-scan <dir>` menjalankan scanner lokal terpasang (Gitleaks/Trivy/Semgrep) setelah konfirmasi; tidak menginstal tool otomatis. Temuan scanner disimpan sebagai rujukan laporan (jangan menaruh secret mentah di terminal/log).
- Semgrep JSON memakai `--json-output`; Gitleaks memakai `--redact`; output laporan berada di `REPORT_DIR` dengan mode 600.



### `config/flags.tsv` (205 entri, delimiter TAB, 7 field)

```text
tool_id	flag	arg_spec	category	risk	description_id	example
```

`risk` hanya `pasif|aman|aktif|sudo`. Field `arg_spec` boleh kosong; parser
memakai `awk -F'\t'` karena `read` dengan `IFS=$'\t'` mengabaikan tab berurutan.
Panduan ada di `config/guides/<id>.md` (fallback `ip-route`→`ip-addr`,
`hashcat`→`john`).

### Starter flow di `config/flows/`

| ID | Risiko | Fungsi |
| --- | --- | --- |
| `healthcheck-harian` | aman | interface, ping GW/internet, DNS, HTTP timing |
| `audit-web-lengkap` | pasif | headers, timing, TLS, DNS, PTR, WhatWeb, HTTPX |
| `inventaris-port-lokal` | pasif | `ss` + `lsof` |
| `discovery-subnet-aman` | aktif | ARP lokal + `nmap -sn` dengan `confirm:` |
| `audit-dns-mendalam` | pasif | A/AAAA/MX/NS/TXT/SOA, SPF/DMARC, PTR, DNSSEC, WHOIS |
| `diagnostik-wifi-link` | pasif | `ip`, `iw dev`, `nmcli`, `ethtool` |

### Perbaikan kompatibilitas Kali yang sudah diterapkan

- `httpx` di registry memakai binary **`httpx-toolkit`** (`/usr/bin/httpx` adalah `python3-httpx`).
- `traceroute --help`, `nikto -H`, `man airmon-ng` sebagai perintah bantuan.
- `nc` adalah `nc.traditional v1.10`: argumen host + port wajib dipisah (Flag Builder menambah keduanya).
- `amass -h` memicu `sudo` untuk libpostal → live extractor memakai `man amass`.

### Overlay & Workspace

- Overlay: `tools.local.tsv`, `snippets.local.tsv`, `flows.local/*.flow` (di-`.gitignore`).
- Workspace: `~/.local/share/netlauncher/workspace.env`, diisi via `Ctrl-W` atau `netlauncher workspace set K=V`.
- Snippet ref kini `main:<baris>` / `local:<baris>` agar preview & aksi tidak tertukar saat overlay aktif.

---

## 6. Wordlist

### Indonesia

| Nama | Path | Baris | Ukuran | Lisensi |
| --- | --- | ---: | ---: | --- |
| geovedi (utama) | `~/wordlists/indonesian/geovedi/00-indonesian-wordlist.lst` | 79.898 | 704K | Public Domain |
| KBBI v6.1.0 | `~/wordlists/indonesian/kbbi/all_entries_v6.1.0.txt` | 194.691 | 2.3M | Tidak dinyatakan |
| REI Indonesia Password | `~/wordlists/indonesian/elliottophellia/rei-indonesia-wordlist.txt` | 10.064.096 | 98M | CC BY-SA 4.0 |
| Indonesian Pwdb Top 150 | `~/wordlists/indonesian/indonesian-pwdb-top150.txt` | 150 | 4K | MIT (SecLists) |

### Lainnya

- `~/wordlists/rockyou.txt` — 14.344.392 baris, 134M
- SecLists — `/usr/share/seclists/`
- dirb, dirbuster, john, nmap, sqlmap, wfuzz, metasploit, fern-wifi — mengikuti paket Kali

### Index

- File: `~/.config/netlauncher/wordlists.tsv` → `~/tools/netlauncher/config/wordlists.tsv`
- Jumlah: **136 entri**
- Regenerate: `netlauncher wordlists refresh`
- Detail sumber, lisensi, dan SHA256: `~/wordlists/README.md`

---

## 7. Verifikasi yang Sudah Dilakukan

- `make check` (`bash -n` semua script + `tests/smoke.sh`) → lolos (107 asersi)
- `netlauncher lint` → 51 tool, 104 snippet, 205 flag, 27 panduan, 6 flow, 11 modul syntax OK
- `netlauncher selftest` → 51 entri & 104 snippet tanpa error
- `netlauncher doctor` → komponen utama siap (flag/guide/flow terhitung)
- `netlauncher list --json` → JSON valid 51 entri (overlay-aware)
- Eksekusi `netlauncher tool ping 127.0.0.1` → exit 0, parser ping menampilkan packet loss & RTT
- `netlauncher flow run healthcheck-harian` → 5/5 langkah exit 0, log flow dibuat
- `netlauncher --dry-run flow run audit-web-lengkap --var URL=https://example.com` → `DOMAIN` terderivasi otomatis
- `make ui-test` & tmux capture → menu utama, knowledge, workspace, flow, kategori, `Ctrl-E`, `Ctrl-T` tampil normal (11 asersi)
- `NETLAUNCHER_CONFIG_DIR` / `NETLAUNCHER_DATA_DIR` + `--dry-run` → terisolasi tanpa menyentuh data pengguna
- Symlink live (`~/.local/bin/netlauncher`, `~/.config/netlauncher`, `~/NETLAUNCHER_MEMORY.md`) → resolve ke repo
- `desktop-file-validate` → valid

---

## 8. Troubleshooting

### fzf tidak ditemukan

```bash
GOBIN="$HOME/.local/bin" go install github.com/junegunn/fzf@latest
```

### hackingtool tidak ditemukan

```bash
pipx install ~/tools/hackingtool --force
pipx ensurepath
```

### Tool belum terpasang

```bash
netlauncher doctor
```

Pasang tool via apt/package manager Kali, lalu buka launcher lagi.

### Capture gagal

- Pastikan `tcpdump` terpasang.
- Capture membutuhkan sudo; masukkan password saat diminta.
- Pastikan interface benar: `ip -brief link`.

### Alias `net` belum aktif

```bash
source ~/.zshrc
# atau buka terminal baru
```

### Warna/UI tidak normal

Pastikan `TERM` mendukung ANSI dan truecolor (`TERM=xterm-256color`, `COLORTERM=truecolor`).
Untuk menonaktifkan animasi: `netlauncher --no-anim` atau ubah di menu `Tema & Animasi` (`Ctrl-T`).

---

## 9. Maintenance

### Menambah tool baru

1. Tambahkan baris 11-field ke `config/tools.tsv` di repo.
2. Tambahkan contoh perintah ke `config/snippets.tsv`.
3. Pastikan `binary` sesuai `command -v`.
4. Jalankan `netlauncher lint` dan `netlauncher selftest`.
5. Uji preview: `netlauncher --preview-tool <id>`.

### Menambah kategori

1. Tambahkan nama di `CAT_NAMES`, `CAT_ICONS`, dan `CAT_DESC` pada `lib/core.sh`.
2. Tambahkan entri menu di `main_menu()` pada `lib/menu.sh`.
3. Tambahkan tool dengan `category` yang sesuai di `tools.tsv`.

### Update hackingtool

```bash
netlauncher update
```

atau manual:

```bash
git -C ~/tools/hackingtool pull --ff-only
pipx install ~/tools/hackingtool --force
```

### Backup konfigurasi

```bash
cd ~/tools/netlauncher
make backup
```
