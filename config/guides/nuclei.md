# Panduan Resmi: Nuclei

## Ringkasan & Cara Kerja
`nuclei` adalah scanner audit keamanan berbasis template YAML yang cepat dan dapat dikustomisasi, cocok untuk memeriksa misconfiguration, exposure, header TLS/HTTP, dan CVE yang diketahui pada target berizin.

## Flag Penting
- **`-u <URL>` / `-l <file>`:** Target tunggal atau daftar target.
- **`-tags misconfig,exposure,ssl,dns`:** Batasi template hanya pada kategori audit yang relevan.
- **`-severity low,medium,high,critical`:** Saring tingkat keparahan temuan.
- **`-rl <req/s>`:** Batasi rate limit request per detik agar aman bagi target.
- **`-jsonl`:** Output JSON Lines terstruktur.
- **`-update-templates`:** Perbarui koleksi template resmi Nuclei.

## Otorisasi
Wajib memiliki izin tertulis sebelum menjalankan template aktif terhadap target.
