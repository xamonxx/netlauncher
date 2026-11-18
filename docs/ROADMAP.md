# Roadmap

Status: `[x]` selesai, `[ ]` direncanakan, `[~]` sedang dipertimbangkan.

## v2.0.0 (Selesai)

- [x] Pecah `bin/netlauncher` menjadi modul di `lib/` (`core`, `ui`, `smart`, `snippets`, `wordlists`, `recipes`, `menu`, `doctor`).
- [x] UI modern `fzf 0.75` (`--style=full:rounded`, panel status, footer, ghost text) + animasi terminal (`ui_splash`, `ui_progress`, `ui_spin`, `--no-anim`).
- [x] 4 tema truecolor (`cyber`, `tokyo`, `emerald`, `amber`) + pratinjau palet.
- [x] Smart Network Context, Smart Placeholder Picker, Command Builder, Missing Tool Advisor.
- [x] 104 contoh perintah + Custom Automation Scripts (`config/automations/`).
- [x] Pencarian global (`Ctrl-S`), shortcut `Ctrl-E`/`Ctrl-T`/`Ctrl-L`, registry 51 tool.
- [x] `netlauncher lint` untuk `tools.tsv`, `snippets.tsv`, dan syntax.
- [x] Perluasan `tests/smoke.sh`, isolasi `NETLAUNCHER_CONFIG_DIR`/`NETLAUNCHER_DATA_DIR`, rotasi log, `list --json`, `--dry-run`.

## v2.1.0 (Selesai)

- [x] **Modern Execution Runner** (`lib/runner.sh`): PTY via `script -qefc`,
      `PIPESTATUS[0]` untuk non-TTY, ANSI dipertahankan di terminal dan dihapus di log,
      parser output per tool (ping, nmap, HTTP, TLS, DNS, socket, fuzz, vuln, capture),
      post-run menu (filter fzf, pager, ringkasan, saran langkah, salin, ekspor Markdown, rerun).
- [x] **Knowledge Base resmi** (`lib/knowledge.sh`): 27 panduan Bahasa Indonesia,
      205 flag terkurasi di `config/flags.tsv`, pratinjau flag, dan live extractor
      `--help`/`man` (aman untuk `amass`).
- [x] **Interactive Flag Builder** dengan `fzf --multi` (`Tab`), placeholder cerdas,
      normalisasi subcommand wajib, dropdown integrasi di `smart_command_builder()`,
      dan aksi jalankan/salin/dry-run/simpan automation.
- [x] **Automation Flow Engine** (`lib/flow.sh`): format `.flow` deklaratif,
      `when`/`capture`/`on_error`/`parser`/`timeout`, wizard pembuat flow, UI browser,
      CLI `flow ui|list|show|run`, dashboard hasil, dan ekspor laporan Markdown.
- [x] 6 starter flow: `healthcheck-harian`, `audit-web-lengkap`,
      `inventaris-port-lokal`, `discovery-subnet-aman`, `audit-dns-mendalam`,
      `diagnostik-wifi-link`.
- [x] **Target Workspace** (`Ctrl-W` / `netlauncher workspace`): `TARGET`, `DOMAIN`,
      `URL`, `SUBNET`, `IFACE`, `NOTE`; diprioritaskan di Smart Picker, Flag Builder, dan advisor.
- [x] Overlay lokal: `tools.local.tsv`, `snippets.local.tsv`, `flows.local/` (di-`.gitignore`).
- [x] Konfirmasi otorisasi terpusat (`confirm_authorized_action()`) untuk tool berdampak.
- [x] `recipe_laporan()` dengan 3 template (ringkas, lengkap, audit) dan `logs_menu()` yang ditingkatkan.
- [x] Bash & Zsh completion di `scripts/completions/`.
- [x] `lint` memvalidasi flags, panduan, dan flow; `make check`/`ui-test` diperluas
      (runner, knowledge, flow, workspace, overlay; 11 asersi UI).
- [x] Perbaikan binary/flag Kali: `httpx-toolkit`, `traceroute --help`, `nikto -H`, `man airmon-ng`, penanganan `nc.traditional v1.10`.

## v2.2.0 (Sedang dikerjakan)

- [x] Profil proyek multiproject: workspace per proyek, environment lab/staging/produksi, scope host/domain/subnet, switching CLI.
- [x] Temuan terstruktur JSONL dengan deduplikasi, triase status, dan ekspor JSON.
- [x] Integrasi repo scan lokal opsional untuk Gitleaks, Trivy, dan Semgrep; tidak ada instalasi otomatis.
- [ ] Redaksi PII/secret configurable untuk seluruh format laporan.
- [ ] Import/export favorit, riwayat, workspace, dan custom automation.
- [ ] Pemeriksa update wordlist (tanpa mengunduh otomatis).
- [ ] Flow scheduler / trigger berbasis event (tetap lokal, tanpa daemon).

## Eksplorasi

- [ ] Paket instalasi `.deb` atau rilis tarball.
- [ ] UI alternatif selain fzf (mis. `gum`) sebagai backend opsional.
- [ ] Hook pra/pasca eksekusi untuk logging eksternal.
- [ ] Dukungan locale (ID/EN) dengan file pesan terpisah.

## Non-goals

- Otomasi deauth, handshake capture, brute-force, atau eksploitasi otomatis.
- Penyimpanan password, token, atau kredensial apa pun.
- Server pusat, telemetry, atau pengiriman log ke pihak ketiga.
- Menjalankan tool yang belum terpasang secara diam-diam.

## Prinsip

1. Aman secara default dan hanya untuk penggunaan berizin.
2. Transparan: tampilkan perintah sebelum eksekusi.
3. Lokal: tidak ada dependensi cloud.
4. Sederhana: Bash + fzf, mudah dibaca dan dipatch.
