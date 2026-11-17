# Panduan Resmi: SS (Socket Statistics)

## Ringkasan & Cara Kerja
`ss` adalah pengganti modern `netstat` dari paket `iproute2` yang membaca informasi socket langsung dari kernel Linux via netlink, jauh lebih cepat dan akurat.

## Flag Utama
- **`ss -tulpn`:** Menampilkan semua port **T**CP & **U**DP yang sedang **L**istening beserta nama **P**roses dan angka port **N**umerik.
- **`ss -tunap state established`:** Memantau koneksi aktif yang sedang terhubung.
- **`ss -s`:** Ringkasan total socket per protokol dan state.

## Cara Membaca Output
- **`0.0.0.0:PORT` atau `[::]:PORT`:** Layanan mendengarkan di **semua interface jaringan** (berpotensi diakses dari luar mesin).
- **`127.0.0.1:PORT` atau `[::1]:PORT`:** Layanan hanya mendengarkan di loopback lokal.
- Jalankan dengan `sudo ss -tulpn` jika kolom `Process` kosong untuk proses milik user lain/root.
