# Arsitektur NetLauncher

## Gambaran umum

```text
+-------------------+       +---------------------+       +------------------+
| Pengguna (terminal)| ----> | bin/netlauncher     | ----> | Tool sistem      |
| fzf 0.75 / CLI    |       | + lib/*.sh (8 modul)|       | ping, nmap, dll. |
+-------------------+       +----------+----------+       +------------------+
                                     |
                     +---------------+----------------+
                     |                                |
             +-------v--------+               +-------v---------+
             | config/        |               | data runtime    |
             | tools.tsv      |               | logs/, history  |
             | snippets.tsv   |               | targets.history |
             | automations/   |               | ~/.local/share  |
             | help.md        |               +-----------------+
             | wordlists.tsv  |
             | theme.env      |
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

- `~/.local/share/netlauncher/logs/` (rotasi otomatis > 30 hari)
- `~/.local/share/netlauncher/history.log`
- `~/.local/share/netlauncher/targets.history`
- `~/.cache/netlauncher/`

## Struktur Modul (`lib/`)

| Modul | Tanggung Jawab |
| --- | --- |
| `bin/netlauncher` | Entrypoint CLI, parsing flag (`--no-anim`, `--dry-run`, `--theme`), dispatch subcommand & preview, `main_menu_loop()` |
| `lib/core.sh` | Path & env override (`NETLAUNCHER_CONFIG_DIR`, `NETLAUNCHER_DATA_DIR`, `NETLAUNCHER_REPORT_DIR`), kategori, helper output, clipboard, registry lookup, favorit, `record_target_history()` |
| `lib/ui.sh` | 4 tema truecolor (`cyber`, `tokyo`, `emerald`, `amber`), `ui_splash()`, `ui_progress()`, `ui_spin()`, `ui_card_header()`, `ui_badge()`, `ui_fzf()`, `theme_menu()`, `preview_theme()` |
| `lib/smart.sh` | `smart_net_context()`, `smart_prompt_placeholder()`, `smart_resolve_template()`, `smart_command_builder()`, `smart_missing_advisor()` |
| `lib/snippets.sh` | `snippets_menu()`, `preview_snippet()`, `snippet_action_menu()`, `snippet_save_automation()` |
| `lib/wordlists.sh` | `wordlist_refresh()`, `wordlist_menu()`, `preview_wordlist()`, `wordlist_action_menu()`, `wordlist_stats()` |
| `lib/recipes.sh` | 10 fungsi `recipe_*()`, `preview_recipe()`, `recipes_menu()`, `run_recipe()`, `automation_menu()`, `automation_create()`, `preview_automation()` |
| `lib/menu.sh` | `main_header()`, `main_menu()`, `global_search_menu()`, `category_menu()`, `tool_action_menu()`, `execute_command()`, `favorites_menu()`, `logs_menu()`, `history_menu()`, `preview_*()` |
| `lib/doctor.sh` | `doctor()`, `selftest()`, `lint()`, `list_tools()` (`--json`), `do_update()`, `show_help()`, `print_cli_help()` |

## Alur eksekusi

```text
main()
├── parse global flags (--no-anim, --dry-run, --theme)
├── ensure_dirs() + load_theme()
├── tanpa argumen → require_fzf() → main_menu_loop()
│   ├── ui_splash()            animasi ASCII + progress bar (sekali per sesi)
│   ├── main_menu()            fzf full:rounded + shortcut (^S, ^E, ^T, ^L)
│   ├── global_search_menu()   pencarian lintas 51 tool + 104 snippet
│   ├── snippets_menu()        browser & runner contoh perintah
│   ├── automation_menu()      kelola & jalankan script di config/automations/
│   ├── category_menu()        daftar tool per kategori
│   ├── tool_action_menu()     run | builder | snippets | args | help | examples | fav
│   ├── smart_command_builder() preset + smart fill + edit + run/copy/dry-run
│   ├── execute_command()      log + eval/GUI + durasi + pause
│   ├── favorites_menu()
│   ├── history_menu()         riwayat + logs_menu()
│   ├── wordlist_menu()        wordlist_action_menu()
│   ├── recipes_menu()         run_recipe() (10 resep aman)
│   ├── theme_menu()           pilih tema & toggle animasi
│   ├── doctor() / do_update() / show_help()
├── search | examples | automation | logs | theme | doctor | selftest | lint | list | wordlists | update
├── tool <id> | recipe <nama>
└── --preview-* (dipanggil fzf sebagai subprocess)
```

### Preview

fzf memanggil ulang script dengan flag internal (dengan `FORCE_COLOR=1`):

- `--preview-tool <id>`
- `--preview-category <id>`
- `--preview-wordlist <path>`
- `--preview-recipe <nama>`
- `--preview-snippet <baris>`
- `--preview-automation <path>`
- `--preview-log <path>`
- `--preview-theme <item>`
- `--preview-global <item>`
- `--preview-history <item>`

Preview bersifat read-only dan tidak memodifikasi state.

### Eksekusi perintah

`execute_command(id, label, mode, sudo_flag, cmd)`:

1. Menampilkan kartu header perintah.
2. Jika `DRY_RUN=1`, menampilkan `[DRY-RUN]` dan berhenti tanpa eksekusi.
3. Menampilkan peringatan sudo bila perlu.
4. Menulis entri ke `history.log` (timestamp, id, perintah).
5. Membuat log sesi di `logs/` dengan header konteks.
6. Menjalankan `eval` untuk mode `term` (mencatat exit code & durasi), atau `setsid`/`nohup` untuk `gui`.
7. Menampilkan lokasi log, lalu `pause` (jika stdin TTY).

Tidak ada penyimpanan password. Prompt sudo diserahkan ke `sudo` di terminal.

## Registry tool & Snippet

### `config/tools.tsv` (51 entri, delimiter `|`, 11 field)

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
| 11 | `examples` | contoh singkat (tanpa karakter `|`) |

### `config/snippets.tsv` (104 entri, delimiter TAB `\t`, 6 field)

| Field | Nama | Keterangan |
| ---: | --- | --- |
| 1 | `tool_id` | harus cocok dengan `id` di `tools.tsv` |
| 2 | `title` | judul singkat contoh perintah |
| 3 | `command` | perintah lengkap (boleh memakai pipe `|` dan placeholder `{...}`) |
| 4 | `notes` | penjelasan fungsi perintah |
| 5 | `sudo` | `1` jika butuh sudo |
| 6 | `placeholders` | daftar placeholder yang dipakai (mis. `TARGET,PORT`) |

## Kategori

Kategori didefinisikan di `lib/core.sh` (`CAT_NAMES`, `CAT_ICONS`, `CAT_DESC`),
`main_menu()` di `lib/menu.sh`, dan `config/tools.tsv`:

`diagnostik`, `dns`, `interface`, `scan`, `wireless`, `security`, `hackingtool`.

## State runtime

| File | Isi | Permission |
| --- | --- | --- |
| `logs/*.log` | output per eksekusi + header (rotasi > 30 hari) | `600` |
| `history.log` | riwayat perintah | `600` |
| `targets.history` | riwayat target/domain/URL untuk Smart Picker | `600` |
| `config/favorites.tsv` | daftar id favorit | `600` |
| `config/wordlists.tsv` | index wordlist | `600` |
| `config/theme.env` | preferensi tema & animasi | `600` |

Direktori data dan log memakai `700`.

## Model keamanan

- Launcher hanya membuka tool yang sudah terpasang; tidak mengunduh payload.
- Resep dan snippet tidak mengotomasi deauth, handshake capture, atau brute-force.
- Scan, capture, dan snippet berdampak menampilkan perintah dan meminta konfirmasi.
- Tidak ada kredensial yang disimpan (`targets.history` juga menyaring spasi/kata sensitif).
- Log dapat memuat data sensitif; jangan dibagikan tanpa sanitasi.

## Batasan yang diketahui

- `%s` pada `tools.tsv` hanya mendukung satu argumen; perintah multi-parameter
  memakai `snippets.tsv` + `smart_resolve_template()` atau Command Builder.
- `eval` dipakai untuk template internal dan perintah yang telah dikonfirmasi pengguna.
- `fzf` 0.60+ (terpasang `0.75`) diperlukan untuk `--style=full:rounded` dan label border.
- GUI mode bergantung pada sesi desktop dan `DISPLAY`.
