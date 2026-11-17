# Panduan Resmi: LSOF Network

## Ringkasan & Cara Kerja
`lsof` (List Open Files) dengan flag `-i` menampilkan seluruh socket jaringan yang sedang dibuka oleh proses di sistem, lengkap dengan PID, user, protokol, dan endpoint.

## Flag Penting
- **`lsof -i -P -n`:** Tampilkan semua koneksi/port terbuka dengan nomor port (`-P`) dan IP numerik (`-n`) tanpa delay DNS.
- **`lsof -i :<PORT> -P -n`:** Cari proses spesifik yang memakai port tertentu.
- Jalankan dengan `sudo` jika perlu melihat proses milik user lain/root.
