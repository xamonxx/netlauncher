# AGENTS.md — Panduan Pengembangan NetLauncher

Dokumen ini adalah instruksi utama untuk manusia maupun agen AI yang mengerjakan
repo ini. Baca `MEMORY.md` untuk konteks lengkap dan `docs/ARCHITECTURE.md` untuk
detail internal.

## Ringkasan proyek

NetLauncher adalah launcher terminal berbasis Bash + fzf untuk tool jaringan dan
keamanan yang sudah terpasang di Kali Linux. UI berbahasa Indonesia, registry tool
berbasis TSV, dan seluruh aksi berjalan lokal tanpa server.

Repo ini adalah **sumber kanonik**. Lokasi live hanyalah symlink:

| Lokasi live | Menunjuk ke |
| --- | --- |
| `~/.local/bin/netlauncher` | `~/tools/netlauncher/bin/netlauncher` |
| `~/.config/netlauncher` | `~/tools/netlauncher/config` |
| `~/NETLAUNCHER_MEMORY.md` | `~/tools/netlauncher/MEMORY.md` |

Jangan mengedit file lewat path live; edit file di repo. Perubahan langsung aktif
karena symlink.

## Aturan keamanan (wajib)

1. **Authorized use only.** Semua fitur hanya untuk aset/jaringan milik sendiri
   atau yang ada izin tertulis.
2. **Tidak ada otomasi ofensif.** Jangan menambahkan deauth, handshake capture,
   brute-force otomatis, atau payload. Registry boleh membuka tool yang sudah
   terpasang, tetapi resep tidak boleh mengotomasi serangan.
3. **Konfirmasi sebelum aksi berdampak.** Scan dan capture wajib menampilkan
   perintah dan meminta konfirmasi otorisasi.
4. **Jangan menyimpan rahasia.** Tidak ada password sudo, token, API key, atau
   kredensial di repo, log, memory, maupun contoh.
5. **Log bisa sensitif.** Tetap simpan di `~/.local/share/netlauncher/` dengan
   permission `600` di direktori `700`.

## Struktur repo

```text
~/tools/netlauncher/
├── AGENTS.md              # panduan ini
├── MEMORY.md              # konteks proyek (sumber kanonik)
├── README.md              # dokumentasi pengguna
├── Makefile               # target check/test/install/backup
├── .gitignore
├── bin/
│   └── netlauncher        # script utama (Bash)
├── config/
│   ├── tools.tsv          # registry 35 tool, 11 field
│   ├── help.md            # panduan pengguna di dalam TUI
│   ├── favorites.tsv      # runtime, tidak di-track
│   ├── wordlists.tsv      # hasil generate, tidak di-track
│   └── MEMORY.md          # symlink ke ../MEMORY.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   ├── ROADMAP.md
│   └── CHANGELOG.md
├── tests/
│   └── smoke.sh
└── scripts/
    ├── install.sh
    └── backup.sh
```

Data runtime tetap di luar repo:

- `~/.local/share/netlauncher/logs/`
- `~/.local/share/netlauncher/history.log`
- `~/.cache/netlauncher/`
- `~/wordlists/`, `~/laporan/`

## Konvensi kode

- Bash 4+, `set -uo pipefail`, `umask 077`.
- String UI: **Bahasa Indonesia**. Identifier, nama fungsi, dan field TSV: Inggris.
- Semua path memakai variabel (`CONFIG_DIR`, `DATA_DIR`, dst.), jangan hardcode
  `/home/xamonxx` di script.
- Gunakan `have <binary>` untuk deteksi tool, `find_tool_line`/`tool_field` untuk
  registry, dan helper `ok`/`warn`/`err` untuk output.
- Jangan menambah dependensi baru tanpa memperbarui `doctor` dan dokumentasi.
- Jaga kompatibilitas dengan `fzf` yang terpasang lokal di `~/.local/bin/fzf`.

## Registry tool (`config/tools.tsv`)

Format wajib 11 field dengan delimiter `|`:

```text
category|id|label|binary|template|description|help|sudo|arg_prompt|mode|examples
```

Aturan:

- `id` unik dan stabil (dipakai favorit, riwayat, `tool <id>`).
- `%s` hanya dipakai untuk satu argumen pengguna.
- `sudo=1` hanya jika tool memang memerlukan sudo.
- `mode` hanya `term` atau `gui`.
- Baris komentar diawali `#`.
- Setelah menambah tool: `netlauncher selftest` dan cek
  `netlauncher --preview-tool <id>`.

## Alur pengembangan

```bash
cd ~/tools/netlauncher

# 1. Edit sumber
$EDITOR bin/netlauncher          # atau config/tools.tsv, config/help.md

# 2. Cek cepat
make check                       # bash -n + smoke test

# 3. Uji manual
netlauncher selftest
netlauncher doctor
netlauncher --preview-tool ping
netlauncher --preview-category diagnostik

# 4. Uji UI (butuh tmux)
tmux new -d -s nl-dev -x 120 -y 40 "netlauncher"
tmux capture-pane -pt nl-dev -S -40
tmux send-keys -t nl-dev Escape
tmux kill-session -t nl-dev
```

Jika mengubah UI atau navigasi, uji minimal: menu utama → kategori → aksi tool →
kembali, serta browser wordlist dan menu resep.

## Definition of done

Sebuah perubahan dianggap selesai jika:

- [ ] `bash -n bin/netlauncher` lolos.
- [ ] `make test` (atau `tests/smoke.sh`) lolos.
- [ ] `netlauncher selftest` tanpa error.
- [ ] `netlauncher doctor` tidak memunculkan masalah baru.
- [ ] UI masih tampil normal jika ada perubahan tampilan.
- [ ] Fitur baru punya entri di `config/help.md` dan `docs/CHANGELOG.md`.
- [ ] Perubahan arsitektur/path dicatat di `MEMORY.md`.
- [ ] Tidak ada rahasia atau otomasi ofensif yang masuk.

## Menambah tool

1. Pastikan binary terpasang (`command -v <binary>`).
2. Tambahkan baris 11-field ke `config/tools.tsv`.
3. Tambahkan ke kategori yang sesuai; jika kategori baru, ubah `CAT_NAMES`,
   `CAT_DESC`, dan entri di `main_menu()`.
4. Perbarui `config/help.md` bila relevan.
5. Jalankan `make check` dan uji preview.

## Menambah resep

1. Tulis fungsi `recipe_<nama>()` di `bin/netlauncher`; tampilkan perintah lebih
   dulu, minta konfirmasi untuk aksi berdampak, dan catat log.
2. Daftarkan di `preview_recipe()`, `recipes_menu()`, dan `run_recipe()`.
3. Tambahkan ke `print_cli_help()` dan `config/help.md`.
4. Uji non-interaktif: `netlauncher recipe <nama> < /dev/null`.

## Git

Repo memakai commit kecil dan pesan imperatif, contoh:

```text
tambah resep cek-ip-publik
perbaiki preview wordlist untuk file besar
dokumentasi: perbarui MEMORY.md
```

Jangan commit `config/favorites.tsv`, `config/wordlists.tsv`, log, atau file
rahasia. Keduanya sudah ada di `.gitignore`.
