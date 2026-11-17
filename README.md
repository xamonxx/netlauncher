# NetLauncher

Smart Network & Security Command Center berbasis terminal (`Bash + fzf 0.75`)
untuk Kali Linux. UI modern berbahasa Indonesia dengan tema truecolor, animasi
terminal, deteksi konteks jaringan otomatis, 104 contoh perintah siap pakai,
Command Builder, Custom Automation Scripts, dan 10 resep otomasi aman.

> **Authorized use only.** Gunakan hanya pada aset/jaringan milik sendiri atau
> yang ada izin tertulis. Launcher ini membuka tool yang sudah terpasang dan tidak
> menyediakan otomasi serangan (deauth, handshake capture, brute-force).

## Fitur Utama (v2.0.0)

- **UI Terminal Modern & Animasi**: `fzf 0.75` `--style=full:rounded` dengan
  outer frame, panel status sistem real-time, inspector preview, splash screen
  ASCII, progress bar, dan spinner murni Bash (`--no-anim` untuk menonaktifkan).
- **4 Tema Truecolor**: `cyber` (default), `tokyo`, `emerald`, dan `amber`
  dengan pratinjau palet langsung (`Ctrl-T` atau `netlauncher theme`).
- **51 Tool dalam 7 Kategori**: Diagnostik Jaringan (8), DNS & Web (14),
  Interface & Routing (8), Pemindaian & Monitoring (9), Wireless Berizin (5),
  Tool Keamanan Berizin (4), dan Hackingtool (3).
- **Pencarian Global (`Ctrl-S`)**: cari lintas 51 tool dan 104 contoh perintah
  sekaligus dalam satu layar.
- **104 Contoh Perintah & Code Snippets (`Ctrl-E`)**: lengkap dengan penjelasan,
  cuplikan Bash, Smart Fill parameter, edit sebelum jalan, salin clipboard,
  `--dry-run`, dan simpan ke Custom Automation.
- **Smart Context & Command Builder**: deteksi otomatis interface aktif, IP/CIDR,
  subnet, gateway, DNS, dan SSID WiFi; saran target/interface/domain/wordlist
  kontekstual; serta Missing Tool Advisor.
- **Custom Automation Scripts**: kelola, buat, edit, dan jalankan script Bash
  otomasi di `config/automations/` (termasuk 4 starter script siap pakai).
- **10 Resep Otomasi Aman**: `cek-koneksi`, `info-jaringan`, `audit-web`, `dns`,
  `monitor-port`, `discovery-lokal`, `scan-target`, `capture`, `wordlist-stats`,
  dan `laporan` (semua mendukung `--dry-run`).
- **Wordlist Browser (136 entri)**: `rockyou.txt`, SecLists, dan 4 koleksi
  wordlist Indonesia (`geovedi`, `KBBI v6.1.0`, `REI`, `SecLists ID`).
- **Riwayat, Log Viewer (`Ctrl-L`), & CLI Lengkap**: `lint`, `selftest`,
  `doctor`, `list --json`, `update`, rotasi log > 30 hari, desktop entry, dan
  alias `net`.

## Instalasi di mesin ini

Sumber kanonik ada di repo ini; lokasi live sudah berupa symlink:

```text
~/.local/bin/netlauncher   -> ~/tools/netlauncher/bin/netlauncher
~/.config/netlauncher      -> ~/tools/netlauncher/config
~/NETLAUNCHER_MEMORY.md    -> ~/tools/netlauncher/MEMORY.md
```

Pasang ulang symlink (idempoten):

```bash
make install
# atau
./scripts/install.sh
```

Prasyarat: `fzf` (disarankan 0.60+, terpasang `0.75`), `bash` 4+, dan tool yang
ingin dipakai. Verifikasi dengan:

```bash
netlauncher doctor
netlauncher lint
netlauncher selftest
```

## Penggunaan

```bash
net                               # alias untuk netlauncher
netlauncher                       # menu utama interaktif
netlauncher search                # pencarian global tool & contoh perintah
netlauncher examples [tool_id]    # browser contoh perintah & code snippets
netlauncher automation            # kelola & jalankan custom automation scripts
netlauncher wordlists [refresh]   # browser / refresh index wordlist
netlauncher logs                  # buka viewer log sesi
netlauncher theme [nama]          # ubah tema (cyber|tokyo|emerald|amber)
netlauncher tool <id>             # jalankan tool langsung
netlauncher recipe <nama>         # jalankan resep otomasi aman
netlauncher list [--json]         # daftar semua tool (tabel atau JSON)
netlauncher doctor                # cek dependensi & terminal
netlauncher selftest              # validasi registry & snippet
netlauncher lint                  # validasi ketat format TSV & syntax
netlauncher update                # update hackingtool + index wordlist
netlauncher help                  # panduan lengkap
netlauncher --version
```

Opsi global: `--no-anim`, `--dry-run`, `--theme <nama>`.

Shortcut di menu utama:

- `Enter` membuka, `Esc` kembali, `Ctrl-/` toggle preview
- `Ctrl-S` pencarian global, `Ctrl-E` contoh perintah, `Ctrl-T` tema & animasi, `Ctrl-L` riwayat & log

Resep yang tersedia:

```text
cek-koneksi, info-jaringan, audit-web, dns, monitor-port,
discovery-lokal, scan-target, capture, wordlist-stats, laporan
```

## Wordlist

Wordlist Indonesia dan umum sudah diindeks (136 entri):

- `~/wordlists/rockyou.txt`
- `~/wordlists/indonesian/geovedi/*.lst` — public domain
- `~/wordlists/indonesian/kbbi/all_entries_v6.1.0.txt`
- `~/wordlists/indonesian/elliottophellia/rei-indonesia-wordlist.txt` — CC BY-SA 4.0
- `~/wordlists/indonesian/indonesian-pwdb-top150.txt` — SecLists
- SecLists, dirb, dirbuster, john, nmap, sqlmap, wfuzz, metasploit, fern-wifi

Detail sumber, lisensi, dan SHA256: `~/wordlists/README.md`.

## Pengembangan

```bash
cd ~/tools/netlauncher
make check        # syntax + smoke test
make lint         # netlauncher lint + shellcheck (jika ada)
make test         # sama dengan check
make ui-test      # uji UI di tmux
make backup       # arsip konfigurasi + script
```

Baca:

- `AGENTS.md` — aturan kontribusi dan checklist definition of done
- `MEMORY.md` — konteks proyek, arsitektur, wordlist, troubleshooting
- `docs/ARCHITECTURE.md` — detail internal
- `docs/DEVELOPMENT.md` — alur kerja pengembangan
- `docs/ROADMAP.md` — rencana pengembangan
- `docs/CHANGELOG.md` — riwayat perubahan

## Struktur

```text
bin/netlauncher       entrypoint CLI & loop menu utama
lib/*.sh              8 modul (core, ui, smart, snippets, wordlists, recipes, menu, doctor)
config/tools.tsv      registry 51 tool (11 field)
config/snippets.tsv   104 contoh perintah & code snippets (6 field tab-delimited)
config/automations/   starter & custom automation scripts (*.sh)
config/help.md        panduan di dalam TUI
config/               runtime favorites/wordlists/theme.env (tidak di-track)
docs/                 dokumentasi teknis
tests/smoke.sh        uji non-interaktif
scripts/              install, backup, dan ui-test
```

## Lisensi dan batasan

Proyek internal, tanpa lisensi publik. Wordlist pihak ketiga mengikuti lisensi
masing-masing. Jangan redistribusikan `rockyou.txt` atau wordlist tanpa memeriksa
lisensinya.
