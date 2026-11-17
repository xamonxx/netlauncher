# Alur Pengembangan

## Prasyarat

- Bash 4+
- `fzf` (lokal di `~/.local/bin/fzf` atau system-wide)
- `git` (untuk versioning)
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
$EDITOR bin/netlauncher
make check
```

`make check` menjalankan:

1. `bash -n bin/netlauncher`
2. `tests/smoke.sh`

Uji manual yang disarankan setelah perubahan:

```bash
netlauncher --version
netlauncher --preview-tool ping
netlauncher --preview-category dns
netlauncher --preview-recipe cek-koneksi
netlauncher selftest
netlauncher doctor
```

Karena live path adalah symlink, tidak ada langkah deploy untuk script dan
config. Cukup edit lalu jalankan.

## Uji UI dengan tmux

```bash
tmux new -d -s nl-dev -x 120 -y 40 "netlauncher"
sleep 1
tmux capture-pane -pt nl-dev -S -40

# navigasi: Enter, panah, Esc
tmux send-keys -t nl-dev Enter
tmux capture-pane -pt nl-dev -S -40

tmux send-keys -t nl-dev Escape
tmux kill-session -t nl-dev
```

Hal yang perlu dicek:

- Banner dan header tampil tanpa terpotong.
- Menu utama bisa difilter dan dibuka.
- Preview tool/kategori/resep/wordlist benar.
- `Esc` kembali tanpa meninggalkan proses.
- Eksekusi `ping 127.0.0.1` menghasilkan exit 0 dan log.

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

Uji fzf secara terpisah:

```bash
printf 'a\nb\n' | fzf --height=40% --layout=reverse
```

Jika preview tidak muncul, pastikan `$SELF` menunjuk ke path repo yang benar:

```bash
bash -c 'source bin/netlauncher' 2>/dev/null || true
readlink -f ~/.local/bin/netlauncher
```

## Menambah tool

1. Cek binary: `command -v <binary>`.
2. Tambahkan baris ke `config/tools.tsv` (11 field).
3. Jika kategori baru, ubah `CAT_NAMES`, `CAT_DESC`, dan `main_menu()`.
4. Perbarui `config/help.md`.
5. Jalankan `make check`, `netlauncher selftest`, dan preview tool.

Contoh baris:

```text
diagnostik|mtr|MTR|mtr|mtr -rw %s|Diagnostik rute interaktif.|mtr --help|0|Host/target|term|mtr -rw 1.1.1.1
```

## Menambah resep

1. Tulis `recipe_<nama>()` di `bin/netlauncher`.
2. Tampilkan perintah, minta konfirmasi untuk aksi berdampak, catat log.
3. Daftarkan di `preview_recipe()`, `recipes_menu()`, `run_recipe()`.
4. Tambahkan ke `print_cli_help()` dan `config/help.md`.
5. Uji: `netlauncher recipe <nama> < /dev/null`.

Jangan menambahkan otomasi ofensif. Resep harus tetap berupa diagnostik,
inventaris, atau audit dengan konfirmasi otorisasi.

## Menambah sumber wordlist

Tambahkan pemanggilan `add_wordlist` atau `add_dir` di `wordlist_refresh()`:

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

1. Tambahkan cabang di `case` dalam `main()`.
2. Tambahkan dokumentasi di `print_cli_help()`.
3. Perbarui `config/help.md`, `README.md`, dan `docs/CHANGELOG.md`.
4. Uji dengan `< /dev/null` agar tidak menggantung.

## Checklist sebelum commit

```bash
make check
git status --short
git diff --check
```

Pastikan tidak ada:

- password, token, atau kredensial;
- `config/favorites.tsv` atau `config/wordlists.tsv`;
- file log atau laporan;
- perubahan yang tidak terkait.

## Backup dan pemulihan

```bash
make backup
# hasil: ~/netlauncher-backup-YYYY-MM-DD.tar.gz
```

Pemulihan:

```bash
tar xzf ~/netlauncher-backup-YYYY-MM-DD.tar.gz -C /tmp
# salin kembali bin/ dan config/ ke repo, lalu make install
```

## Konvensi commit

Pesan pendek, imperatif, Bahasa Indonesia:

```text
tambah tool mtr
perbaiki preview wordlist besar
dokumentasi: perbarui roadmap
refactor: pisahkan helper wordlist
```
