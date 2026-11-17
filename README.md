# NetLauncher

Launcher terminal modern untuk tool jaringan dan keamanan di Kali Linux.
UI berbasis `fzf`, berbahasa Indonesia, dengan registry tool yang mudah dikembangkan.

> **Authorized use only.** Gunakan hanya pada aset/jaringan milik sendiri atau
> yang ada izin tertulis. Launcher ini membuka tool yang sudah terpasang dan tidak
> menyediakan otomasi serangan (deauth, handshake capture, brute-force).

## Fitur

- Menu kategori: Diagnostik, DNS & Web, Interface & Routing, Pemindaian &
  Monitoring, Wireless (berizin), Tool Keamanan, dan Hackingtool.
- Pencarian fuzzy + panel preview untuk setiap tool, kategori, wordlist, dan resep.
- Deteksi otomatis tool terpasang (`✓`) atau belum (`✗`).
- Aksi per tool: jalankan, jalankan dengan argumen, bantuan, contoh, favorit.
- Browser wordlist: preview, salin path, buka di `less`, statistik.
- Resep aman: cek koneksi, info jaringan, scan target berizin, capture, DNS,
  statistik wordlist, laporan Markdown.
- Riwayat 100 perintah, favorit, dan log per sesi.
- `doctor`, `selftest`, `update`, serta integrasi desktop entry dan alias `net`.
- Integrasi `hackingtool 3.1.0` (TUI 219 tool).

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

Prasyarat: `fzf`, `bash`, dan tool yang ingin dipakai. Verifikasi dengan:

```bash
netlauncher doctor
netlauncher selftest
```

## Penggunaan

```bash
net                          # alias untuk netlauncher
netlauncher                  # menu utama
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

Navigasi: ketik untuk mencari, `Enter` membuka, `Esc` kembali,
`Ctrl-/` menampilkan/menyembunyikan preview.

Resep yang tersedia:

```text
cek-koneksi, info-jaringan, scan-target, capture, dns, wordlist-stats, laporan
```

Contoh:

```bash
netlauncher tool ping
netlauncher recipe cek-koneksi
netlauncher recipe laporan
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
make test         # smoke test lengkap
make ui-test      # buka UI di tmux (jika ada tmux)
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
bin/netlauncher       script utama
config/tools.tsv      registry tool (11 field)
config/help.md        panduan di dalam TUI
config/               runtime favorites/wordlists (tidak di-track)
docs/                 dokumentasi teknis
tests/smoke.sh        uji non-interaktif
scripts/              install dan backup
```

## Lisensi dan batasan

Proyek internal, tanpa lisensi publik. Wordlist pihak ketiga mengikuti lisensi
masing-masing. Jangan redistribusikan `rockyou.txt` atau wordlist tanpa memeriksa
lisensinya.
