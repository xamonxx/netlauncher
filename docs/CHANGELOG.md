# Changelog

Format mengikuti Keep a Changelog; versi mengikuti SemVer selama memungkinkan.

## [Unreleased]

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
