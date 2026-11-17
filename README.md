# NetLauncher

Smart Network & Security Command Center berbasis terminal (`Bash + fzf 0.75`)
untuk Kali Linux. UI modern berbahasa Indonesia dengan tema truecolor, animasi,
deteksi konteks jaringan otomatis, 104 contoh perintah, Knowledge Base resmi +
Interactive Flag Builder, Automation Flow (`.flow`), Target Workspace, Modern
Execution Runner, dan 10 resep otomasi aman.

> **Authorized use only.** Gunakan hanya pada aset/jaringan milik sendiri atau
> yang ada izin tertulis. Launcher ini membuka tool yang sudah terpasang dan tidak
> menyediakan otomasi serangan (deauth, handshake capture, brute-force).

## Fitur Utama (v2.1.0)

- **UI Terminal Modern & Animasi**: `fzf 0.75` `--style=full:rounded`, outer frame,
  panel status sistem real-time (termasuk workspace aktif), inspector preview,
  splash ASCII, progress bar, dan spinner murni Bash (`--no-anim`).
- **4 Tema Truecolor**: `cyber`, `tokyo`, `emerald`, `amber` dengan pratinjau
  palet (`Ctrl-T` / `netlauncher theme`).
- **51 Tool dalam 7 Kategori**: Diagnostik (8), DNS & Web (14), Interface &
  Routing (8), Pemindaian & Monitoring (9), Wireless berizin (5), Keamanan
  berizin (4), Hackingtool (3).
- **Pencarian Global (`Ctrl-S`)**: cari lintas tool, snippet, dan flow.
- **104 Contoh Perintah (`Ctrl-E`)**: Smart Fill, edit, salin, dry-run, simpan
  ke automation.
- **Knowledge Base Resmi (`Ctrl-K`)**: 27 panduan Bahasa Indonesia, 205 flag
  terkurasi untuk 51 tool, dan ekstrak flag langsung dari `--help`/`man` lokal.
- **Interactive Flag Builder** (`netlauncher flags <id>`): pilih banyak flag
  dengan `Tab`, isi argumen, normalisasi subcommand wajib, lalu
  jalankan/salin/dry-run/simpan.
- **Modern Execution Runner**: PTY (`script -qefc`) menjaga warna & prompt
  interaktif, `PIPESTATUS[0]` menjaga exit code di non-TTY, log tetap teks
  polos. Ringkasan temuan tool-aware, filter output, saran langkah berikutnya,
  ekspor Markdown, dan jalankan ulang.
- **Automation Flow**: 6 starter `.flow` deklaratif dengan variabel, kondisi
  (`have:`, `var:`, `prev_ok`, `confirm:`), capture, parser, timeout, `on_error`,
  dashboard hasil, dan ekspor laporan.
- **Target Workspace** (`Ctrl-W`): `TARGET`, `DOMAIN`, `URL`, `SUBNET`, `IFACE`
  aktif dipakai otomatis oleh smart picker, builder, dan flow.
- **Overlay Lokal**: `tools.local.tsv`, `snippets.local.tsv`, `flows.local/`
  (tidak di-track).
- **Custom Automation & 10 Resep Aman**: semua mendukung `--dry-run` dan
  konfirmasi sebelum aksi berdampak.
- **Wordlist Browser (136 entri)**, Riwayat, Log Viewer (`Ctrl-L`),
  `lint`, `selftest`, `doctor`, `list --json`, Bash/Zsh completion.

## Instalasi di mesin ini

Sumber kanonik ada di repo ini; lokasi live sudah berupa symlink:

```text
~/.local/bin/netlauncher   -> ~/tools/netlauncher/bin/netlauncher
~/.config/netlauncher      -> ~/tools/netlauncher/config
~/NETLAUNCHER_MEMORY.md    -> ~/tools/netlauncher/MEMORY.md
```

Pasang ulang symlink (idempoten): `make install` atau `./scripts/install.sh`.

Prasyarat: `bash` 4+, `fzf` 0.60+ (terpasang `0.75`), `jq`, `script` (util-linux),
`python3`, `tmux` (opsional). Verifikasi:

```bash
netlauncher doctor
netlauncher lint
netlauncher selftest
```

## Penggunaan

```bash
net                                  # alias
netlauncher                          # menu utama interaktif
netlauncher search                   # pencarian global
netlauncher examples [tool_id]       # browser contoh perintah
netlauncher guide [tool_id]          # panduan resmi tool
netlauncher flags [tool_id]          # Interactive Flag Builder
netlauncher flow [ui|list|show|run]  # Automation Flow
netlauncher workspace [show|set|clear]
netlauncher automation               # custom automation scripts
netlauncher wordlists [refresh]
netlauncher logs                     # log sesi & laporan
netlauncher theme [nama]
netlauncher tool <id> [argumen]
netlauncher recipe <nama>
netlauncher list [--json]
netlauncher doctor | selftest | lint | update | help
netlauncher --version | --help
```

Opsi global: `--no-anim`, `--dry-run`, `--theme <nama>`.

Shortcut menu utama: `Enter` buka, `Esc` kembali, `Ctrl-/` preview,
`Ctrl-S` cari, `Ctrl-E` contoh, `Ctrl-K` knowledge, `Ctrl-W` workspace,
`Ctrl-T` tema, `Ctrl-L` riwayat/log.

Contoh flow:

```bash
netlauncher flow list
netlauncher flow show audit-web-lengkap
netlauncher --dry-run flow run audit-web-lengkap --var URL=https://example.com
netlauncher flow run healthcheck-harian
netlauncher workspace set DOMAIN=example.com SUBNET=192.168.1.0/24
```

Completion:

```bash
source scripts/completions/netlauncher.bash      # Bash
# atau salin scripts/completions/_netlauncher ke fpath Zsh
```

## Pengembangan

```bash
cd ~/tools/netlauncher
make check        # syntax + smoke test
make lint         # netlauncher lint + shellcheck (jika ada)
make test         # sama dengan check
make ui-test      # uji UI di tmux
make backup
```

Baca `AGENTS.md`, `MEMORY.md`, dan `docs/`.

## Struktur

```text
bin/netlauncher       entrypoint CLI & loop menu utama
lib/*.sh              11 modul (core, ui, runner, smart, snippets,
                      wordlists, knowledge, flow, recipes, menu, doctor)
config/tools.tsv      registry 51 tool (11 field)
config/snippets.tsv   104 contoh perintah (6 field tab)
config/flags.tsv      205 flag resmi (7 field tab)
config/guides/        27 panduan resmi Bahasa Indonesia
config/flows/         6 starter automation flow (.flow)
config/automations/   starter & custom automation scripts (*.sh)
config/help.md        panduan di dalam TUI
scripts/completions/  Bash & Zsh completion
tests/smoke.sh        uji non-interaktif
scripts/              install, backup, ui-test
```

Runtime: `~/.local/share/netlauncher/` (logs, history, targets.history,
workspace.env), `~/.local/share/netlauncher/logs/`, `~/laporan/`.

## Lisensi dan batasan

Proyek internal, tanpa lisensi publik. Wordlist pihak ketiga mengikuti lisensi
masing-masing. Jangan redistribusikan `rockyou.txt` atau wordlist tanpa
memeriksa lisensinya. Tidak ada password, token, atau kredensial yang disimpan.
