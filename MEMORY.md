# NetLauncher — Memory / Project Context

- **Terakhir diperbarui:** 2026-11-17
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

- Binary: `~/.local/bin/fzf`
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
├── Makefile                                # check/test/install/backup
├── bin/netlauncher                         # script utama (Bash, 953 baris)
├── config/
│   ├── tools.tsv                           # registry 35 tool, 11 field
│   ├── help.md                             # panduan pengguna
│   ├── favorites.tsv                       # runtime, tidak di-track
│   ├── wordlists.tsv                       # index 136 wordlist, tidak di-track
│   └── MEMORY.md                           # symlink ke ../MEMORY.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   ├── ROADMAP.md
│   └── CHANGELOG.md
├── tests/smoke.sh
└── scripts/
    ├── install.sh
    └── backup.sh

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
├── logs/                                   # log per sesi, permission 700
└── history.log                             # riwayat perintah

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
- `history.log`, `favorites.tsv`, `wordlists.tsv`, log: `600`

### Alur kerja repo

```bash
cd ~/tools/netlauncher
make check                  # bash -n + smoke test
netlauncher selftest
netlauncher doctor
make backup                 # arsip script + konfigurasi
```

- Semua perubahan dikerjakan di repo, bukan lewat path live.
- Panduan kontribusi lengkap: `AGENTS.md`.
- Detail arsitektur: `docs/ARCHITECTURE.md`.
- Alur pengembangan dan checklist: `docs/DEVELOPMENT.md`.
- Rencana fitur: `docs/ROADMAP.md`; riwayat perubahan: `docs/CHANGELOG.md`.
- `favorites.tsv` dan `wordlists.tsv` bersifat runtime dan tidak di-track git.

---

## 4. Arsitektur Launcher

`bin/netlauncher` adalah script Bash mandiri dengan UI `fzf`. Sumber kanonik ada di
repo; path live `~/.local/bin/netlauncher` adalah symlink, sehingga edit di repo
langsung berlaku tanpa menyalin ulang.

### Registry tool: `tools.tsv`

Format 11 field, delimiter `|`:

```text
category|id|label|binary|template|description|help|sudo|arg_prompt|mode|examples
```

Keterangan:

- `category` — id kategori (`diagnostik`, `dns`, `interface`, `scan`, `wireless`, `security`, `hackingtool`)
- `id` — id unik tool
- `label` — nama tampilan
- `binary` — binary yang dicek via `command -v`
- `template` — perintah; `%s` diganti argumen pengguna
- `description` — deskripsi singkat
- `help` — perintah bantuan (`tool --help` atau `man tool`)
- `sudo` — `1` jika butuh sudo
- `arg_prompt` — label prompt argumen; kosong jika tidak perlu
- `mode` — `term` atau `gui`
- `examples` — contoh singkat

Total: **35 entri**.

### Kategori

- Diagnostik Jaringan — ping, traceroute, curl, wget
- DNS & Web — dig, nslookup, whatweb, nikto, gobuster, ffuf, httpx, nuclei, amass, sqlmap, searchsploit
- Interface & Routing — ip addr, ip route, ss, netstat, iw dev
- Pemindaian & Monitoring — nmap, tcpdump, wireshark
- Wireless (Berizin) — airmon-ng, aircrack-ng, kismet, reaver, wifite
- Tool Keamanan (Berizin) — hydra, john, hashcat, msfconsole
- Hackingtool — TUI, classic REPL, bantuan

### Fitur UI

- Banner `figlet`, header host/IP/interface/jumlah tool/tanggal
- fzf: fuzzy search, preview panel, border rounded, warna ANSI
- Deteksi tool terpasang (`✓`) / belum (`✗`)
- Aksi per tool: Jalankan, Jalankan dengan argumen, Bantuan, Contoh, Favorit
- Prompt argumen otomatis, konfirmasi sudo
- Favorit dan riwayat 100 perintah terakhir
- Log per sesi
- Browser wordlist: preview, salin path, buka di `less`, statistik
- `doctor`, `selftest`, `update`
- Desktop entry dan alias `net`

### Perintah CLI

```bash
netlauncher                  # menu utama
netlauncher --help
netlauncher help             # panduan lengkap
netlauncher doctor           # cek dependensi
netlauncher selftest         # validasi registry
netlauncher wordlists        # browser wordlist
netlauncher wordlists refresh
netlauncher update
netlauncher tool <id>
netlauncher recipe <nama>
netlauncher --version
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

## 5. Resep Otomasi

Semua resep menampilkan perintah sebelum eksekusi dan menyimpan log.

| Nama | Fungsi | Sudo |
| --- | --- | --- |
| `cek-koneksi` | Ping gateway/internet, DNS, HTTP | tidak |
| `info-jaringan` | IP, route, `iw dev`, `ss`, resolver | tidak |
| `scan-target` | `nmap -sV -T4 --top-ports 100` + konfirmasi otorisasi | tidak |
| `capture` | `tcpdump` pada interface + durasi | ya |
| `dns` | Query A, MX, NS, TXT | tidak |
| `wordlist-stats` | Baris, ukuran, cuplikan, unik | tidak |
| `laporan` | Gabungkan log 24 jam ke Markdown | tidak |

Batasan:

- Tidak ada otomasi deauth, handshake capture, atau brute-force.
- Scan/capture meminta konfirmasi.
- Resep hanya untuk target berizin.

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

### Menambah wordlist

1. Letakkan file di `~/wordlists/` atau subdirektori.
2. Tambahkan entri ke `wordlist_refresh()` di script, atau edit `wordlists.tsv` manual.
3. Jalankan `netlauncher wordlists refresh`.

---

## 7. Verifikasi yang Sudah Dilakukan

- `bash -n bin/netlauncher` → OK
- `make check` / `tests/smoke.sh` → lolos setelah restrukturisasi repo
- Symlink live (`~/.local/bin/netlauncher`, `~/.config/netlauncher`, `~/NETLAUNCHER_MEMORY.md`) → resolve ke repo
- `netlauncher selftest` → 35 entri, tanpa error
- `netlauncher doctor` → komponen utama siap
- UI tmux → menu utama, kategori, aksi tool, wordlist, preview tampil
- Eksekusi `ping 127.0.0.1` via menu → exit 0
- Browser wordlist → preview `rockyou` tampil
- Resep `cek-koneksi` → berhasil, log dibuat
- Resep `info-jaringan` → berhasil, log dibuat
- Resep `laporan` → laporan Markdown dibuat
- TUI `hackingtool` → berhasil terbuka
- `desktop-file-validate` → valid

Artefak uji (boleh dihapus):

- `~/.local/share/netlauncher/logs/20261117-160049-ping.log`
- `~/.local/share/netlauncher/logs/20261117-160115-cek-koneksi.log`
- `~/.local/share/netlauncher/logs/20261117-160205-info-jaringan.log`
- `~/laporan/laporan-20261117-160115.md`
- Entri riwayat uji di `history.log`

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

Pastikan `TERM` mendukung ANSI, misalnya `xterm-256color`.

---

## 9. Maintenance

### Menambah tool baru

1. Tambahkan baris 11-field ke `config/tools.tsv` di repo.
2. Pastikan `binary` sesuai `command -v`.
3. Jalankan `netlauncher selftest`.
4. Uji preview: `netlauncher --preview-tool <id>`.

### Menambah kategori

1. Tambahkan nama di `CAT_NAMES` dan `CAT_DESC` pada script.
2. Tambahkan entri menu di `main_menu()`.
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

# atau manual:
tar czf ~/netlauncher-backup-$(date +%F).tar.gz \
  -C ~/tools netlauncher \
  ~/.local/share/applications/netlauncher.desktop
```

### Reset log/riwayat

```bash
rm -f ~/.local/share/netlauncher/logs/*.log
: > ~/.local/share/netlauncher/history.log
```

---

## 10. Batasan Keamanan

- Hanya untuk aset/jaringan milik sendiri atau dengan izin tertulis.
- Launcher membuka tool yang sudah terpasang; tidak menambahkan otomasi serangan.
- Tidak menyimpan kredensial atau password sudo.
- Log dapat berisi data sensitif; disimpan dengan permission `600` di direktori `700`.
- Wordlist password dapat berisi data nyata; jangan redistribusikan tanpa memeriksa lisensi.

---

## 11. Changelog

- **2026-11-17** — Restrukturisasi menjadi repo pengembangan di `~/tools/netlauncher` (`bin/`, `config/`, `docs/`, `tests/`, `scripts/`), tambah `AGENTS.md`, `README.md`, `MEMORY.md` kanonik, `Makefile`, dan symlink live. Backup konfigurasi lama: `~/.config/netlauncher.backup-20261117-160508`.
- **2026-11-17** — Instalasi fzf lokal, hackingtool 3.1.0 via pipx, 3 wordlist Indonesia + rockyou/SecLists, launcher `netlauncher`, alias `net`, desktop entry, resep otomasi, dokumentasi memory ini.
