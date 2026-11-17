# Panduan Resmi: Feroxbuster

## Ringkasan & Cara Kerja
`feroxbuster` adalah scanner konten web rekursif berbasis Rust yang cepat untuk menemukan direktori dan file pada aplikasi web berizin.

## Flag Penting
- **`-u <URL> -w <wordlist>`:** Target URL dan wordlist.
- **`--depth <N>`:** Batasi kedalaman rekursi (disarankan `--depth 2` untuk audit awal).
- **`-t <threads>`:** Atur jumlah thread konkuren.
- **`--no-state`:** Jangan tinggalkan file state resume di direktori kerja.
- **`-k`:** Lewati verifikasi sertifikat TLS (khusus lab).
