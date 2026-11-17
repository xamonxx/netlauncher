# Alur Pengembangan

## Prasyarat

- Bash 4+
- `fzf` 0.60+ (lokal di `~/.local/bin/fzf`, terpasang `0.75`)
- `git` (untuk versioning)
- `python3` (untuk validasi JSON di `list --json` dan test)
- `jq`, `script` (util-linux), `less` (dipakai runner & post-run viewer)
- `tmux` (opsional, untuk uji UI)
- Tool yang ingin diuji (ping, nmap, dll.)

## Setup awal

Repo sudah menjadi sumber kanonik dan lokasi live berupa symlink. Jika perlu
memasang ulang:

```bash
cd ~/tools/netlauncher
./scripts/install.sh
```

Script ini idempoten: membuat symlink hanya jika belum menunjuk ke repo, dan
membuat backup direktori config lama bila ada.

## Loop pengembangan

```bash
cd ~/tools/netlauncher
$EDITOR lib/menu.sh
make check
make lint
```

`make check` menjalankan:

1. `bash -n` pada `bin/netlauncher`, `lib/*.sh`, `config/automations/*.sh`, `scripts/*.sh`, `tests/smoke.sh`
2. `tests/smoke.sh` (107 asersi: modul, registry, snippet, flag, guide, flow,
   lint/selftest, CLI, preview lama & baru, runner, knowledge, flow, workspace, overlay, symlink)

Uji manual yang disarankan setelah perubahan:

```bash
netlauncher --version
netlauncher lint
netlauncher selftest
netlauncher doctor
netlauncher list --json | head -n 20
netlauncher --preview-tool ping
netlauncher --preview-snippet 2
netlauncher --preview-category dns
netlauncher --preview-recipe audit-web
netlauncher --preview-guide nmap
netlauncher --preview-flag curl --max-time
netlauncher --preview-flow audit-web-lengkap
netlauncher flow list
netlauncher --dry-run flow run healthcheck-harian
netlauncher tool ping 127.0.0.1
```

Untuk menguji tanpa menyentuh konfigurasi atau data pengguna:

```bash
tmp_cfg="$(mktemp -d)" tmp_data="$(mktemp -d)"
cp config/tools.tsv config/snippets.tsv config/flags.tsv config/help.md "$tmp_cfg/"
cp -r config/guides config/flows "$tmp_cfg/"
NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" \
  ./bin/netlauncher --no-anim --dry-run recipe cek-koneksi < /dev/null
NETLAUNCHER_CONFIG_DIR="$tmp_cfg" NETLAUNCHER_DATA_DIR="$tmp_data" \
  ./bin/netlauncher --dry-run flow run healthcheck-harian < /dev/null
rm -rf "$tmp_cfg" "$tmp_data"
```

Karena live path adalah symlink, tidak ada langkah deploy untuk script dan
config. Cukup edit lalu jalankan.

## Uji UI dengan tmux

```bash
make ui-test
```

Atau manual:

```bash
tmux new -d -s nl-dev -x 120 -y 36 "netlauncher"
sleep 1.2
tmux capture-pane -pt nl-dev

# uji shortcut: Ctrl-E (snippets), Ctrl-S (search), Ctrl-T (tema), Ctrl-L (riwayat)
tmux send-keys -t nl-dev C-e
sleep 0.6
tmux capture-pane -pt nl-dev

tmux send-keys -t nl-dev Escape
tmux send-keys -t nl-dev Escape
tmux kill-session -t nl-dev
```

Hal yang perlu dicek:

- Splash screen dan progress bar berjalan mulus tanpa artefak.
- Frame rounded, header status sistem (termasuk workspace aktif), daftar, preview, dan footer tampil rapi.
- Menu utama, kategori, snippet (`Ctrl-E`), pencarian global (`Ctrl-S`),
  Knowledge (`Ctrl-K`), Workspace (`Ctrl-W`), Automation Flow, tema (`Ctrl-T`),
  dan riwayat (`Ctrl-L`) berfungsi.
- Runner: warna tetap tampil, ringkasan temuan muncul, post-run menu bisa dibuka.
- `Esc` kembali tanpa meninggalkan proses atau merusak kursor terminal.
- `make ui-test` mencakup 11 asersi di atas (kecuali runner interaktif).

## Debugging

Aktifkan trace Bash:

```bash
bash -x bin/netlauncher --preview-tool ping
```

Periksa log:

```bash
ls -lt ~/.local/share/netlauncher/logs | head
tail -20 ~/.local/share/netlauncher/history.log
```

## Menambah tool & snippet

1. Cek binary: `command -v <binary>`.
2. Tambahkan baris ke `config/tools.tsv` (11 field, hindari karakter `|`).
3. Tambahkan contoh perintah ke `config/snippets.tsv` (6 field tab-delimited).
4. Jika kategori baru, ubah `CAT_NAMES`, `CAT_ICONS`, `CAT_DESC` di `lib/core.sh` dan `main_menu()` di `lib/menu.sh`.
5. Perbarui `config/help.md`.
6. Jalankan `make check`, `netlauncher lint`, `netlauncher selftest`, dan preview tool.

## Menambah resep

1. Tulis `recipe_<nama>()` di `lib/recipes.sh`.
2. Dukung `DRY_RUN=1`, tampilkan perintah, minta konfirmasi untuk aksi berdampak, catat log.
3. Daftarkan di `preview_recipe()`, `recipes_menu()`, dan `run_recipe()`.
4. Tambahkan ke `print_cli_help()` di `lib/doctor.sh` dan `config/help.md`.
5. Uji: `netlauncher --dry-run recipe <nama> < /dev/null`.

Jangan menambahkan otomasi ofensif. Resep harus tetap berupa diagnostik,
inventaris, atau audit dengan konfirmasi otorisasi.

## Menambah flag, panduan, dan flow

1. Flag: tambah baris 7-field tab-delimited ke `config/flags.tsv`
   (`tool_id`, flag, arg_spec, category, risk, deskripsi ID, contoh).
   `risk` hanya `pasif|aman|aktif|sudo`. Field `arg_spec` boleh kosong.
2. Panduan: buat `config/guides/<tool_id>.md` dengan heading `#`, `##`, dan bullet `-`.
3. Flow: buat `config/flows/<id>.flow` dengan blok `[flow]`, `[inputs]`, `[step:N]`.
   Gunakan `when = have:...;confirm:...` untuk aksi berdampak; `capture` untuk
   meneruskan variabel ke langkah berikutnya.
4. Jalankan `netlauncher lint` — kini memvalidasi flag, panduan, dan flow juga.
5. Uji: `netlauncher guide <id>`, `netlauncher flags <id>`,
   `netlauncher --preview-flow <id>`, dan `netlauncher --dry-run flow run <id>`.

Ingat: parsing tab memakai `awk -F'\t'`, bukan `read` dengan `IFS=$'\t'`
karena tab berurutan (field kosong) akan digabung.

## Menambah overlay lokal

Taruh `tools.local.tsv`, `snippets.local.tsv`, atau `flows.local/*.flow` di
`~/.config/netlauncher/`. Format mengikuti file bawaan. Semua sudah masuk
`.gitignore`; tidak perlu mengubah kode untuk mengaktifkannya.

## Menambah sumber wordlist

Tambahkan pemanggilan `add_wordlist` atau `add_dir` di `_wordlist_build_index()` pada `lib/wordlists.sh`:

```bash
add_wordlist "Nama" "/path/file.txt" "Kategori" "Sumber" "Lisensi"
add_dir "/path/dir" "*.txt" "Kategori" "Sumber" "Lisensi" 20
```

Lalu:

```bash
netlauncher wordlists refresh
awk -F'|' '!/^#/ {n++} END{print n}' config/wordlists.tsv
```

Perbarui juga `~/wordlists/README.md` untuk sumber, lisensi, dan SHA256.

## Menambah perintah CLI

1. Tambahkan cabang di `case` dalam `main()` pada `bin/netlauncher`.
2. Tambahkan dokumentasi di `print_cli_help()` (`lib/doctor.sh`).
3. Perbarui `config/help.md`, `README.md`, dan `docs/CHANGELOG.md`.
4. Uji dengan `< /dev/null` agar tidak menggantung.

## Checklist sebelum commit

```bash
make check
make lint
make ui-test
git status --short
git diff --check
```

Pastikan tidak ada:

- password, token, atau kredensial;
- `config/favorites.tsv`, `config/wordlists.tsv`, `config/theme.env`,
  `config/tools.local.tsv`, `config/snippets.local.tsv`, `config/flows.local/`;
- file log atau laporan;
- perubahan yang tidak terkait.

## Backup dan pemulihan

```bash
make backup
# hasil: ~/netlauncher-backup-YYYYMMDD-HHMMSS.tar.gz
```

## Konvensi commit

Pesan pendek, imperatif, Bahasa Indonesia:

```text
tambah tool mtr
perbaiki preview wordlist besar
dokumentasi: perbarui roadmap
refactor: pisahkan helper wordlist
```
