# Roadmap

Status: `[x]` selesai, `[ ]` direncanakan, `[~]` sedang dipertimbangkan.

## v2.0.0 (Selesai)

- [x] Pecah `bin/netlauncher` menjadi modul di `lib/`:
  `core.sh`, `ui.sh`, `smart.sh`, `snippets.sh`, `wordlists.sh`, `recipes.sh`, `menu.sh`, `doctor.sh`.
- [x] UI modern `fzf 0.75` (`--style=full:rounded`, `--border=rounded`, panel status sistem, footer, ghost text) + animasi terminal (`ui_splash`, `ui_progress`, `ui_spin`, `--no-anim`).
- [x] Tema warna truecolor yang dapat dikonfigurasi (`config/theme.env`: `cyber`, `tokyo`, `emerald`, `amber`) + pratinjau palet langsung.
- [x] Smart Network Context, Smart Placeholder Picker, Command Builder, dan Missing Tool Advisor.
- [x] Koleksi 104 contoh perintah & code snippets (`config/snippets.tsv`) + Custom Automation Scripts (`config/automations/`).
- [x] Pencarian global (`Ctrl-S`), shortcut menu (`Ctrl-E`, `Ctrl-T`, `Ctrl-L`), dan perluasan registry menjadi 51 tool terpasang.
- [x] Tambah perintah `netlauncher lint` untuk validasi ketat `tools.tsv`, `snippets.tsv`, dan syntax.
- [x] Perluas `tests/smoke.sh`: uji semua preview, registry, snippet, isolasi env, dan perintah CLI.
- [x] Dukung `NETLAUNCHER_CONFIG_DIR` dan `NETLAUNCHER_DATA_DIR` untuk testing tanpa menyentuh data pengguna.
- [x] Rotasi log otomatis (> 30 hari).
- [x] Mode `netlauncher list --json` untuk integrasi skrip lain.
- [x] Opsi `--dry-run` untuk semua tool, snippet, dan resep.

## Jangka menengah (v2.1)

- [ ] Overlay tool pribadi: `config/tools.local.tsv` dan `config/snippets.local.tsv` yang tidak di-track.
- [ ] Import/export favorit, riwayat, dan custom automation.
- [ ] Template laporan: ringkas, teknis, dan compliance.
- [ ] Pemeriksa update wordlist (tanpa mengunduh otomatis).
- [ ] Dukungan Bash completion dan zsh completion.

## Eksplorasi

- [ ] Paket instalasi `.deb` atau rilis tarball.
- [ ] UI alternatif selain fzf (mis. `gum`) sebagai backend opsional.
- [ ] Hook pra/pasca eksekusi untuk logging eksternal.
- [ ] Dukungan locale (ID/EN) dengan file pesan terpisah.

## Non-goals

- Otomasi deauth, handshake capture, brute-force, atau eksploitasi otomatis.
- Penyimpanan password, token, atau kredensial apa pun.
- Server pusat, telemetry, atau pengiriman log ke pihak ketiga.
- Menjalankan tool yang belum terpasang secara diam-diam.

## Prinsip

1. Aman secara default dan hanya untuk penggunaan berizin.
2. Transparan: tampilkan perintah sebelum eksekusi.
3. Lokal: tidak ada dependensi cloud.
4. Sederhana: Bash + fzf, mudah dibaca dan dipatch.
