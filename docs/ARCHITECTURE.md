# Arsitektur NetLauncher

## Gambaran umum

```text
+-------------------+       +---------------------+       +------------------+
| Pengguna (terminal)| ----> | bin/netlauncher     | ----> | Tool sistem      |
| fzf / CLI         |       | Bash + fzf          |       | ping, nmap, dll. |
+-------------------+       +----------+----------+       +------------------+
                                     |
                     +---------------+----------------+
                     |                                |
             +-------v--------+               +-------v---------+
             | config/        |               | data runtime    |
             | tools.tsv      |               | logs/, history  |
             | help.md        |               | ~/.local/share  |
             | wordlists.tsv  |               +-----------------+
             +----------------+
```

Semua berjalan lokal. Tidak ada daemon, server, database, atau koneksi jaringan
selain yang dilakukan tool yang dijalankan pengguna.

## Lokasi file

Sumber kanonik berada di `~/tools/netlauncher/`. Lokasi live adalah symlink:

| Live | Kanonik |
| --- | --- |
| `~/.local/bin/netlauncher` | `bin/netlauncher` |
| `~/.config/netlauncher` | `config/` |
| `~/NETLAUNCHER_MEMORY.md` | `MEMORY.md` |

Runtime data tetap di luar repo:

- `~/.local/share/netlauncher/logs/`
- `~/.local/share/netlauncher/history.log`
- `~/.cache/netlauncher/`

## Alur eksekusi

```text
main()
├── ensure_dirs()
├── tanpa argumen → require_fzf() → main_menu_loop()
│   ├── main_menu()            fzf, output: id kategori/aksi
│   ├── category_menu()        fzf, output: id tool
│   ├── tool_action_menu()     run | args | help | examples | fav
│   ├── run_tool()/run_tool_args()
│   │   └── execute_command()  log + eval perintah + pause
│   ├── favorites_menu()
│   ├── history_menu()
│   ├── wordlist_menu()        wordlist_action_menu()
│   ├── recipes_menu()         run_recipe()
│   ├── doctor()
│   ├── do_update()
│   └── show_help()
├── doctor | selftest | wordlists | update
├── tool <id> | recipe <nama>
└── --preview-* (dipanggil fzf sebagai subprocess)
```

### Preview

fzf memanggil ulang script dengan flag internal:

- `--preview-tool <id>`
- `--preview-category <id>`
- `--preview-wordlist <path>`
- `--preview-recipe <nama>`

Preview tidak boleh memodifikasi state. Semua output preview bersifat read-only.

### Eksekusi perintah

`execute_command(id, label, mode, sudo_flag, cmd)`:

1. Menampilkan peringatan sudo bila perlu.
2. Menulis entri ke `history.log` (timestamp, id, perintah).
3. Membuat log sesi di `logs/` dengan header konteks.
4. Menjalankan `eval` untuk mode `term`, atau `setsid`/`nohup` untuk `gui`.
5. Menulis exit code ke log dan menampilkan lokasinya.

Tidak ada penyimpanan password. Prompt sudo diserahkan ke `sudo` di terminal.

## Registry tool

File: `config/tools.tsv`, delimiter `|`, 11 field:

| Field | Nama | Keterangan |
| ---: | --- | --- |
| 1 | `category` | id kategori |
| 2 | `id` | id unik tool |
| 3 | `label` | nama tampilan |
| 4 | `binary` | binary untuk deteksi `command -v` |
| 5 | `template` | perintah; `%s` = satu argumen pengguna |
| 6 | `description` | deskripsi singkat |
| 7 | `help` | perintah bantuan |
| 8 | `sudo` | `1` jika butuh sudo |
| 9 | `arg_prompt` | label prompt argumen |
| 10 | `mode` | `term` atau `gui` |
| 11 | `examples` | contoh singkat |

Baris komentar diawali `#`. Fungsi pembaca utama:

- `find_tool_line <id>` — ambil baris registry
- `tool_field <id> <n>` — ambil field tertentu
- `tool_count_category <cat>` — hitung terpasang/total
- `tool_count_installed` — total tool terpasang

## Kategori

Kategori didefinisikan di tiga tempat dan harus konsisten:

1. `CAT_NAMES` dan `CAT_DESC` di `bin/netlauncher`
2. Entri statis di `main_menu()`
3. Nilai `category` di `config/tools.tsv`

Kategori saat ini: `diagnostik`, `dns`, `interface`, `scan`, `wireless`,
`security`, `hackingtool`.

## Resep

Setiap resep adalah fungsi `recipe_<nama>()` dengan pola:

1. Cek dependensi.
2. Minta input bila perlu.
3. Tampilkan perintah yang akan dijalankan.
4. Minta konfirmasi untuk scan/capture.
5. Jalankan dan `tee` ke log.
6. Tampilkan lokasi log, lalu `pause`.

Pendaftaran resep tersebar di `preview_recipe()`, `recipes_menu()`,
`run_recipe()`, dan `print_cli_help()`.

## Index wordlist

`wordlist_refresh()` memindai sumber tetap dan menulis
`config/wordlists.tsv` dengan format:

```text
name|path|category|lines|size|source|license
```

Duplikat dicegah lewat file sementara `WL_SEEN_FILE` berisi realpath. File ini
adalah cache yang dapat dibangun ulang kapan saja dan tidak di-track git.

## State runtime

| File | Isi | Permission |
| --- | --- | --- |
| `logs/*.log` | output per eksekusi + header | `600` |
| `history.log` | 100 perintah terakhir | `600` |
| `config/favorites.tsv` | daftar id favorit | `600` |
| `config/wordlists.tsv` | index wordlist | `600` |

Direktori data dan log memakai `700`.

## Model keamanan

- Launcher hanya membuka tool yang sudah terpasang; tidak mengunduh payload.
- Resep tidak mengotomasi deauth, handshake capture, atau brute-force.
- Scan dan capture menampilkan perintah dan meminta konfirmasi.
- Tidak ada kredensial yang disimpan.
- Log dapat memuat data sensitif; jangan dibagikan tanpa sanitasi.

## Titik ekstensi

- Tool baru: `config/tools.tsv`.
- Kategori baru: `CAT_NAMES`, `CAT_DESC`, `main_menu()`, dan registry.
- Resep baru: fungsi `recipe_*` + 3 titik pendaftaran.
- Sumber wordlist baru: `wordlist_refresh()`.
- Perintah CLI baru: blok `case` di `main()` + `print_cli_help()`.

## Batasan yang diketahui

- Script masih monolitik (~950 baris); pemecahan modul ada di roadmap.
- `%s` hanya mendukung satu argumen; argumen kompleks memakai menu "Jalankan
  dengan argumen".
- `eval` dipakai untuk template internal, bukan input bebas dari jaringan.
- fzf harus tersedia di PATH atau `FZF_BIN`.
- GUI mode bergantung pada sesi desktop dan `DISPLAY`.
