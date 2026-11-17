# AGENTS.md — Panduan Pengembangan NetLauncher

Dokumen ini adalah instruksi utama untuk manusia maupun agen AI yang mengerjakan
repo ini. Baca `MEMORY.md` untuk konteks lengkap dan `docs/ARCHITECTURE.md` untuk
detail internal.

## Ringkasan proyek

NetLauncher adalah launcher terminal modern berbasis Bash + fzf untuk tool
jaringan dan keamanan yang sudah terpasang di Kali Linux. UI berbahasa Indonesia,
arsitektur modular (`bin/netlauncher` + `lib/*.sh`), registry tool & snippet
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
   terpasang, tetapi resep dan snippet tidak boleh mengotomasi serangan.
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
├── Makefile               # target check/test/lint/install/backup/ui-test
├── .gitignore
├── bin/
│   └── netlauncher        # entrypoint CLI & menu loop (Bash)
├── lib/
│   ├── core.sh            # path, env override, helper, registry, target history
│   ├── ui.sh              # tema truecolor, animasi, badge, wrapper fzf
│   ├── smart.sh           # konteks jaringan, smart picker, command builder, advisor
│   ├── snippets.sh        # browser & runner 104 contoh perintah
│   ├── wordlists.sh       # indexer & browser wordlist
│   ├── recipes.sh         # 10 resep aman & custom automation scripts
│   ├── menu.sh            # menu utama, pencarian global, aksi tool, riwayat & log
│   └── doctor.sh          # doctor, selftest, lint, list (--json), update, help
├── config/
│   ├── tools.tsv          # registry 51 tool, 11 field (delimiter |)
│   ├── snippets.tsv       # 104 contoh perintah, 6 field (delimiter tab)
│   ├── automations/       # starter & custom automation scripts (*.sh)
│   ├── help.md            # panduan pengguna di dalam TUI
│   ├── favorites.tsv      # runtime, tidak di-track
│   ├── wordlists.tsv      # hasil generate, tidak di-track
│   ├── theme.env          # runtime preferensi tema/animasi, tidak di-track
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
    ├── backup.sh
    └── ui-test.sh
```

Data runtime tetap di luar repo:

- `~/.local/share/netlauncher/logs/`
- `~/.local/share/netlauncher/history.log`
- `~/.local/share/netlauncher/targets.history`
- `~/.cache/netlauncher/`
- `~/wordlists/`, `~/laporan/`

## Konvensi kode

- Bash 4+, `set -uo pipefail`, `umask 077`.
- String UI: **Bahasa Indonesia**. Identifier, nama fungsi, dan field TSV: Inggris.
- Semua path memakai variabel (`CONFIG_DIR`, `DATA_DIR`, `REPO_DIR`, dst.), jangan
  hardcode `/home/xamonxx` di script.
- Gunakan `have <binary>` untuk deteksi tool, `find_tool_line`/`tool_field` untuk
  registry, dan helper `ok`/`warn`/`err` untuk output.
- Jangan menambah dependensi baru tanpa memperbarui `doctor` dan dokumentasi.
- Jaga kompatibilitas dengan `fzf` yang terpasang lokal di `~/.local/bin/fzf`.

## Registry tool (`config/tools.tsv`) & Snippet (`config/snippets.tsv`)

Format wajib `tools.tsv` (11 field dengan delimiter `|`):

```text
category|id|label|binary|template|description|help|sudo|arg_prompt|mode|examples
```

Aturan `tools.tsv`:

- `id` unik dan stabil (dipakai favorit, riwayat, `snippets.tsv`, `tool <id>`).
- `%s` hanya dipakai untuk satu argumen pengguna.
- `sudo=1` hanya jika tool memang memerlukan sudo.
- `mode` hanya `term` atau `gui`.
- Hindari karakter `|` di dalam field (termasuk `examples`); gunakan `snippets.tsv`
  untuk perintah dengan shell pipe.
- Baris komentar diawali `#`.

Format wajib `snippets.tsv` (6 field dengan delimiter **TAB** `\t`):

```text
tool_id	title	command	notes	sudo	placeholders
```

- `tool_id` harus ada di `tools.tsv`.
- Placeholder yang didukung Smart Fill: `{TARGET}`, `{SUBNET}`, `{IFACE}`,
  `{DOMAIN}`, `{URL}`, `{PORT}`, `{WORDLIST}`, `{FILE}`, `{QUERY}`, `{DATE}`,
  `{REPORT_DIR}`.
- Setelah menambah tool atau snippet: jalankan `netlauncher lint` dan
  `netlauncher selftest`.

## Alur pengembangan

```bash
cd ~/tools/netlauncher

# 1. Edit sumber
$EDITOR lib/menu.sh              # atau bin/netlauncher, config/tools.tsv, config/snippets.tsv

# 2. Cek cepat
make check                       # bash -n semua script + smoke test
make lint                        # netlauncher lint + shellcheck (jika ada)

# 3. Uji manual
netlauncher selftest
netlauncher doctor
netlauncher --preview-tool ping
netlauncher --preview-snippet 2
netlauncher --preview-category diagnostik

# 4. Uji UI (butuh tmux)
make ui-test
```

Jika mengubah UI atau navigasi, uji minimal: menu utama → kategori → aksi tool →
kembali, serta browser snippet (`Ctrl-E`), pencarian global (`Ctrl-S`), tema
(`Ctrl-T`), browser wordlist, dan menu resep.

## Definition of done

Sebuah perubahan dianggap selesai jika:

- [ ] `make syntax` (`bash -n` pada `bin/netlauncher`, `lib/*.sh`, `config/automations/*.sh`, `scripts/*.sh`) lolos.
- [ ] `netlauncher lint` lolos tanpa error.
- [ ] `make test` (atau `tests/smoke.sh`) lolos.
- [ ] `netlauncher selftest` tanpa error.
- [ ] `netlauncher doctor` tidak memunculkan masalah baru.
- [ ] UI masih tampil normal (`make ui-test`) jika ada perubahan tampilan.
- [ ] Fitur baru punya entri di `config/help.md` dan `docs/CHANGELOG.md`.
- [ ] Perubahan arsitektur/path dicatat di `MEMORY.md`.
- [ ] Tidak ada rahasia atau otomasi ofensif yang masuk.

## Menambah tool

1. Pastikan binary terpasang (`command -v <binary>`).
2. Tambahkan baris 11-field ke `config/tools.tsv`.
3. Tambahkan contoh perintah terkait ke `config/snippets.tsv`.
4. Tambahkan ke kategori yang sesuai; jika kategori baru, ubah `CAT_NAMES`,
   `CAT_ICONS`, `CAT_DESC` di `lib/core.sh`, dan entri di `main_menu()`.
5. Perbarui `config/help.md` bila relevan.
6. Jalankan `make check`, `netlauncher lint`, dan uji preview.

## Menambah resep

1. Tulis fungsi `recipe_<nama>()` di `lib/recipes.sh`; dukung `DRY_RUN=1`,
   tampilkan perintah lebih dulu, minta konfirmasi untuk aksi berdampak, dan
   catat log.
2. Daftarkan di `preview_recipe()`, `recipes_menu()`, dan `run_recipe()`.
3. Tambahkan ke `print_cli_help()` di `lib/doctor.sh` dan `config/help.md`.
4. Uji non-interaktif: `netlauncher --dry-run recipe <nama> < /dev/null`.

## Git

Repo memakai commit kecil dan pesan imperatif, contoh:

```text
tambah resep cek-ip-publik
perbaiki preview wordlist untuk file besar
dokumentasi: perbarui MEMORY.md
```

Jangan commit `config/favorites.tsv`, `config/wordlists.tsv`, `config/theme.env`,
log, atau file rahasia. Semuanya sudah ada di `.gitignore`.
