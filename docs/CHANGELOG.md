# Changelog

Format mengikuti Keep a Changelog; versi mengikuti SemVer selama memungkinkan.

## [2.0.0] - 2026-11-17

### Added

- Arsitektur modular: `bin/netlauncher` + 8 modul di `lib/` (`core.sh`, `ui.sh`,
  `smart.sh`, `snippets.sh`, `wordlists.sh`, `recipes.sh`, `menu.sh`, `doctor.sh`).
- UI terminal modern berbasis `fzf 0.75` (`--style=full:rounded`, `--border=rounded`,
  `--height=100%`, panel Status Sistem real-time, ghost text, label border, footer).
- Animasi terminal murni Bash: `ui_splash()` (banner ASCII + progress bar),
  `ui_progress()`, dan `ui_spin()`, dengan opsi `--no-anim` / `NETLAUNCHER_NO_ANIM=1`.
- 4 tema truecolor (`cyber`, `tokyo`, `emerald`, `amber`) dengan pratinjau palet
  langsung (`Ctrl-T` / `netlauncher theme`) dan penyimpanan di `config/theme.env`.
- Smart Network Context (`smart_net_context`), Smart Placeholder Picker
  (`smart_prompt_placeholder`), Command Builder (`smart_command_builder`), dan
  Missing Tool Advisor (`smart_missing_advisor`).
- Koleksi 104 contoh perintah & code snippets di `config/snippets.tsv` (tab-delimited)
  mencakup seluruh 51 tool, lengkap dengan Smart Fill, edit sebelum jalan, salin
  clipboard, `--dry-run`, dan simpan ke Custom Automation.
- Custom Automation Scripts di `config/automations/` dengan 4 starter script
  (`healthcheck-harian.sh`, `audit-tls-domain.sh`, `inventaris-port.sh`,
  `discovery-subnet-aman.sh`) serta menu buat/edit/jalankan.
- Pencarian global (`Ctrl-S` / `netlauncher search`) lintas 51 tool dan 104 snippet.
- Shortcut menu utama: `Ctrl-S` (Cari), `Ctrl-E` (Contoh Perintah), `Ctrl-T` (Tema),
  `Ctrl-L` (Riwayat & Log).
- 3 resep otomasi aman baru: `audit-web`, `discovery-lokal`, `monitor-port` (total 10 resep).
- Perintah CLI baru: `search`, `examples`/`snippets`, `automation`, `logs`, `theme`,
  `lint`, `list [--json]`, serta flag global `--no-anim`, `--dry-run`, `--theme`.
- Dukungan `NETLAUNCHER_CONFIG_DIR`, `NETLAUNCHER_DATA_DIR`, `NETLAUNCHER_REPORT_DIR`,
  dan rotasi log otomatis (> 30 hari).

### Changed

- Registry `config/tools.tsv` diperluas dari 35 menjadi 51 tool terpasang
  (menambahkan `whois`, `openssl`, `nc`, `socat`, `feroxbuster`, `dirb`, `wfuzz`,
  `nmcli`, `ethtool`, `lsof`, `masscan`, `arp-scan`, `netdiscover`, `tshark`,
  `tcpflow`, `ngrep`).
- Seluruh resep mendukung `--dry-run` dan quoting target yang aman.
- `tests/smoke.sh` dan `Makefile` diperbarui untuk memvalidasi seluruh modul,
  51 tool, 104 snippet, `lint`, `list --json`, isolasi env, dan semua preview.

## [1.1.0] - 2026-11-17

### Added

- Repo pengembangan kanonik di `~/tools/netlauncher` dengan struktur
  `bin/`, `config/`, `docs/`, `tests/`, `scripts/`.
- `AGENTS.md` untuk aturan kontribusi manusia/agen dan definition of done.
- `README.md`, `MEMORY.md`, `Makefile`, `.gitignore`.
- Dokumentasi `docs/ARCHITECTURE.md`, `docs/DEVELOPMENT.md`, `docs/ROADMAP.md`,
  `docs/CHANGELOG.md`.
- `tests/smoke.sh` untuk validasi non-interaktif.
- `scripts/install.sh` (symlink idempoten) dan `scripts/backup.sh`.
- Target `make check`, `make test`, `make install`, `make backup`, `make ui-test`.

### Changed

- Sumber kanonik pindah ke repo; `~/.local/bin/netlauncher`,
  `~/.config/netlauncher`, dan `~/NETLAUNCHER_MEMORY.md` kini symlink ke repo.
- `config/favorites.tsv` dan `config/wordlists.tsv` diperlakukan sebagai state
  runtime dan tidak di-track git.

## [1.0.0] - 2026-11-17

### Added

- Launcher Bash + fzf berbahasa Indonesia dengan 7 kategori dan 35 entri
  registry.
- Preview tool, kategori, wordlist, dan resep.
- Aksi per tool: jalankan, argumen, bantuan, contoh, favorit.
- Browser wordlist dengan salin path, buka di `less`, dan statistik.
- Resep aman: `cek-koneksi`, `info-jaringan`, `scan-target`, `capture`, `dns`,
  `wordlist-stats`, `laporan`.
- Riwayat perintah, log per sesi, `doctor`, `selftest`, `update`.
- Integrasi `hackingtool 3.1.0`.
- Index 136 wordlist (rockyou, SecLists, geovedi, KBBI, REI).
- Desktop entry dan alias `net`.
- Verifikasi: `bash -n`, selftest 35 entri, doctor, UI tmux, eksekusi ping,
  resep, dan TUI hackingtool.
