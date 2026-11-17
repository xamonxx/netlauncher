# Roadmap

Status: `[x]` selesai, `[ ]` direncanakan, `[~]` sedang dipertimbangkan.

## Jangka pendek (v1.1)

- [ ] Pecah `bin/netlauncher` menjadi modul di `lib/`:
  `core.sh`, `menu.sh`, `registry.sh`, `wordlists.sh`, `recipes.sh`, `doctor.sh`.
- [ ] Tambah perintah `netlauncher lint` untuk validasi `tools.tsv`
  (field, id unik, kategori dikenal, binary).
- [ ] Perluas `tests/smoke.sh`: uji semua preview, registry, dan perintah CLI.
- [ ] Dukung `NETLAUNCHER_CONFIG_DIR` dan `NETLAUNCHER_DATA_DIR` untuk testing
  tanpa menyentuh data pengguna.
- [ ] Rotasi log: simpan maksimal N sesi atau bersihkan otomatis > 30 hari.
- [ ] Mode `netlauncher list --json` untuk integrasi skrip lain.

## Jangka menengah (v1.2)

- [ ] Overlay tool pribadi: `config/tools.local.tsv` yang tidak di-track.
- [ ] Import/export favorit dan riwayat.
- [ ] Tema warna fzf yang bisa dikonfigurasi (`config/theme.env`).
- [ ] Template laporan: ringkas, teknis, dan compliance.
- [ ] Pemeriksa update wordlist (tanpa mengunduh otomatis).
- [ ] Dukungan Bash completion dan zsh completion.
- [ ] Opsi `--dry-run` untuk semua resep.

## Eksplorasi

- [ ] Paket instalasi `.deb` atau rilis tarball.
- [ ] UI alternatif selain fzf (mis. `gum`) sebagai backend opsional.
- [ ] Hook pra/pasca eksekusi untuk logging eksternal.
- [ ] Dukungan locale (ID/EN) dengan file pesan terpisah.
- [ ] Dashboard ringkas: status interface, DNS, dan tool yang belum terpasang.

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
