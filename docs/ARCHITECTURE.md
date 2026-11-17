# Arsitektur NetLauncher

## Gambaran umum

```text
+-------------------+       +--------------------------+       +------------------+
| Pengguna (terminal)| ----> | bin/netlauncher          | ----> | Tool sistem      |
| fzf 0.75 / CLI    |       | + lib/*.sh (11 modul)    |       | ping, nmap, dll. |
+-------------------+       +------------+-------------+       +------------------+
                                        |
            +---------------------------+---------------------------+
            |                           |                           |
    +-------v--------+          +--------v--------+          +-------v---------+
    | config/        |          | lib/runner.sh   |          | data runtime    |
    | tools.tsv      |          | lib/knowledge.sh|          | logs/, history  |
    | snippets.tsv   |          | lib/flow.sh     |          | targets.history |
    | flags.tsv      |          +-----------------+          | workspace.env   |
    | guides/*.md    |                                      | ~/.local/share  |
    | flows/*.flow   |                                      +-----------------+
    | automations/   |
    | help.md        |
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
- `~/.local/share/netlauncher/workspace.env`
- `~/.cache/netlauncher/`

## Struktur Modul (`lib/`)

| Modul | Tanggung Jawab |
| --- | --- |
| `bin/netlauncher` | Entrypoint CLI, flag global, dispatch `guide`/`flags`/`flow`/`workspace`/preview, `main_menu_loop()` |
| `lib/core.sh` | Path & env override, overlay (`tools_files`, `snippets_files`), workspace (`load_workspace`, `save_workspace`, `workspace_active_label`), kategori, helper, registry, `confirm_authorized_action()` |
| `lib/ui.sh` | 4 tema truecolor, `ui_splash()`, `ui_progress()`, `ui_spin()`, `ui_badge()`, `ui_fzf()` (border label memuat versi/tema/workspace) |
| `lib/runner.sh` | `runner_exec()` PTY/tee, `runner_parse_highlights()`, `runner_suggest_next_steps()`, `runner_post_menu()`, `runner_export_markdown()` |
| `lib/smart.sh` | `smart_net_context()`, `smart_prompt_placeholder()` (workspace prioritized), `smart_resolve_template()`, `smart_command_builder()` (integrasi Flag Builder), `smart_missing_advisor()` |
| `lib/snippets.sh` | Browser & aksi snippet overlay-aware; referensi `main:N` / `local:N` |
| `lib/wordlists.sh` | `wordlist_refresh()`, `wordlist_menu()`, `preview_wordlist()`, `wordlist_stats()` |
| `lib/knowledge.sh` | `knowledge_menu()`, `knowledge_render_guide()`, `knowledge_flag_builder()` (`mapfile`), `knowledge_live_flags()`, `preview_guide()`, `preview_flag()` |
| `lib/flow.sh` | `flow_parse_file()`, `flow_run()`, `flow_create_wizard()`, `flow_ui()`, `flow_cli()`, `preview_flow()` |
| `lib/recipes.sh` | 10 `recipe_*()`, `recipe_laporan()` (3 template), `recipes_menu()`, `automation_menu()` (integrasi flow) |
| `lib/menu.sh` | `main_menu()`, `workspace_menu()`, `workspace_cli()`, `global_search_menu()`, `category_menu()`, `tool_action_menu()`, `execute_command()` (wrapper → `runner_exec`), `logs_menu()`, `history_menu()` |
| `lib/doctor.sh` | `doctor()`, `selftest()`, `lint()` (TSV + guides + flow + syntax), `list_tools()` (`--json`, overlay), `print_cli_help()` |

## Alur eksekusi

```text
main()
├── parse global flags (--no-anim, --dry-run, --theme)
├── ensure_dirs() + load_theme() + load_workspace()
├── tanpa argumen → require_fzf() → main_menu_loop()
│   ├── main_menu()            ^S cari | ^E contoh | ^K knowledge | ^W workspace | ^T tema | ^L log
│   ├── knowledge_menu()       panduan | flag builder | live --help/man | snippets
│   ├── workspace_menu()       edit TARGET/DOMAIN/URL/SUBNET/IFACE/NOTE → save_workspace()
│   ├── flow_ui() / flow_run() daftar, wizard, pipeline, dashboard
│   ├── global_search_menu()   tool + snippet + overlay
│   ├── tool_action_menu()     run | flag-builder | builder | snippets | knowledge | args | fav
│   ├── smart_command_builder() preset/template/flag builder → edit → konfirmasi
│   ├── execute_command()      → runner_exec()
│   ├── recipes_menu()         resep aman / 3 template laporan
│   └── logs_menu()            log tool/flow/resep + laporan
├── guide | flags | flow | workspace | search | examples | automation | logs | ...
├── tool <id> [arg] | recipe <nama>
└── --preview-* (dipanggil fzf sebagai subprocess)
```

### Preview

fzf memanggil ulang script dengan flag internal (dengan `FORCE_COLOR=1`):
`--preview-tool`, `--preview-category`, `--preview-wordlist`, `--preview-recipe`,
`--preview-snippet`, `--preview-automation`, `--preview-guide`, `--preview-flag
<tool> <flag>`, `--preview-flow`, `--preview-log`, `--preview-theme`,
`--preview-global`, `--preview-history`. Semua bersifat read-only.

### Eksekusi perintah (`runner_exec`)

1. Kartu header + workspace aktif; `DRY_RUN=1` berhenti sebelum eksekusi.
2. Tulis history + log sesi (`600`) dengan header konteks (tanpa kredensial).
3. TTY + `script` tersedia → `script -qefc 'bash -c "$NETLAUNCHER_RUN_CMD"'`
   (warna & prompt interaktif terjaga, exit code child dipertahankan `-e`).
   Non-TTY → `bash -c "$cmd" 2>&1 | tee` dengan `PIPESTATUS[0]`.
4. Normalisasi stream: buang header/footer `script`, ambil potongan setelah `\r`
   terakhir, strip ANSI untuk log.
5. Tampilkan Ringkasan Eksekusi + `runner_parse_highlights()` sesuai tool.
6. Post-run menu: filter output (fzf), pager `less -R`, ringkasan, saran langkah
   berikutnya, salin, ekspor Markdown, jalankan ulang.
7. GUI mode memakai `setsid`/`nohup` di background.

`execute_command()` di `lib/menu.sh` kini hanya wrapper ke `runner_exec()` agar
semua pemanggil lama otomatis memakai runner modern.

### Automation Flow (`lib/flow.sh`)

File `.flow` dengan blok `[flow]` (id, name, category, risk, requires_auth, sudo,
description, tools), `[inputs]` (`KEY = hint`), dan `[step:N]` (title, tool, when,
parser, on_error, timeout, capture, cmd).

- Context awal `FLOW_VARS`: `NET_HOST`, `NET_IFACE`, `NET_IP`, `NET_CIDR`,
  `NET_SUBNET`, `NET_GW`, `NET_DNS`. `DOMAIN` diturunkan dari `URL` (termasuk
  `--var URL=...`).
- `when` mendukung `have:<binary>`, `var:<KEY>`, `prev_ok`,
  `confirm:<pesan>` dan dapat digabung dengan `;`.
- `capture = VAR=filter` dijalankan terhadap output teks langkah (baris pertama).
- Setiap langkah memakai runner yang sama dengan `runner_exec()`, dengan parser
  per-step (`auto`/nama/`none`).
- Dashboard ringkas + `flow_export_markdown()` ke `REPORT_DIR`.

## Registry & data

### `config/tools.tsv` (51 entri, `|`, 11 field)

`category|id|label|binary|template|description|help|sudo|arg_prompt|mode|examples`

### `config/snippets.tsv` (104 entri, TAB, 6 field)

`tool_id|title|command|notes|sudo|placeholders` (delimiter TAB, aman untuk pipe).

### `config/flags.tsv` (205 entri, TAB, 7 field)

`tool_id|flag|arg_spec|category|risk|description_id|example`
`risk ∈ pasif|aman|aktif|sudo`. Parser wajib memakai `awk -F'\t'` karena field
`arg_spec` sering kosong dan `read -r` dengan `IFS=$'\t'` mengabaikan tab berurutan.

### `config/guides/*.md` (27 file)

Panduan resmi Bahasa Indonesia. Fallback: `ip-route` → `ip-addr.md`,
`hashcat` → `john.md`.

### `config/flows/*.flow` (6 file)

Lihat tabel starter flow di `MEMORY.md` bagian 5b.

### Overlay

`tools.local.tsv`, `snippets.local.tsv`, `flows.local/` digabung dengan data
bawaan oleh `tools_files()`, `snippets_files()`, `flow_list_files()`. Semua masuk
`.gitignore`. Snippet overlay memakai ref `local:N` agar preview tidak tertukar.

## Kategori

Didefinisikan di `lib/core.sh` (`CAT_NAMES`, `CAT_ICONS`, `CAT_DESC`),
`main_menu()` di `lib/menu.sh`, dan `config/tools.tsv`:
`diagnostik`, `dns`, `interface`, `scan`, `wireless`, `security`, `hackingtool`.

## State runtime

| File | Isi | Permission |
| --- | --- | --- |
| `logs/*.log` | output per eksekusi + header (rotasi > 30 hari) | `600` |
| `history.log` | riwayat perintah | `600` |
| `targets.history` | riwayat target/domain/URL | `600` |
| `workspace.env` | Target Workspace aktif | `600` |
| `config/favorites.tsv` | id favorit | `600` |
| `config/wordlists.tsv` | index wordlist | `600` |
| `config/theme.env` | preferensi tema & animasi | `600` |
| `~/laporan/*.md` | laporan eksekusi/flow/resep | `600` |

Direktori data dan log memakai `700`.

## Model keamanan

- Hanya tool terpasang; tidak mengunduh payload.
- Resep, snippet, dan flow tidak mengotomasi deauth, handshake capture, atau brute-force.
- Scan, capture, tool berdampak, dan flow berisiko menampilkan perintah lalu
  meminta konfirmasi (`confirm_authorized_action()` / `when = confirm:...`).
- Tidak ada kredensial yang disimpan; prompt sudo diserahkan ke `sudo` di terminal.
- Log dapat memuat data sensitif; jangan dibagikan tanpa sanitasi.

## Batasan yang diketahui

- `%s` di `tools.tsv` hanya satu argumen; multi-parameter memakai snippet/Flow/Flag Builder.
- Flow `when = confirm:...` otomatis gagal (skip) pada stdin non-TTY.
- `script -qefc` bergantung pada util-linux; tersedia di Kali mesin ini.
- `eval`/`bash -c` dipakai hanya untuk perintah yang dibangun launcher dan/atau
  telah dikonfirmasi pengguna. Tidak ada input yang disimpan sebagai kredensial.
- `fzf` 0.60+ (terpasang `0.75`) diperlukan untuk `--style=full:rounded` dan label border.
- GUI mode bergantung pada sesi desktop dan `DISPLAY`.
