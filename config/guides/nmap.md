# Panduan Resmi: Nmap (Network Mapper)

## Ringkasan & Cara Kerja
Nmap adalah pemindai jaringan standar industri untuk host discovery, pemetaan port TCP/UDP, deteksi versi layanan (`-sV`), dan enumerasi aman via Nmap Scripting Engine (`-sC`).

## Perbedaan Mode Scan Utama
- **`-sn` (Ping Scan / Host Discovery):** Hanya mengecek host yang aktif tanpa memindai port. Aman untuk inventaris subnet berizin.
- **`-sT` (TCP Connect):** Memakai syscall `connect()` OS; **tidak butuh sudo**, cocok untuk audit cepat dari user biasa.
- **`-sS` (TCP SYN):** Mengirim paket SYN mentah tanpa menyelesaikan handshake penuh; lebih cepat dan akurat, **butuh sudo**.
- **`-sV` + `-sC`:** Mengidentifikasi banner/versi layanan dan menjalankan script NSE kategori `default` & `safe`.

## Cara Membaca Output
- **`open`:** Ada aplikasi yang menerima koneksi pada port tersebut.
- **`closed`:** Host merespons RST (port dapat dijangkau, tetapi tidak ada layanan yang listen).
- **`filtered`:** Firewall/filter paket menjatuhkan probe sehingga Nmap tidak mendapat respons pasti.

## Best Practice & Otorisasi
- Gunakan `--top-ports 100` atau port spesifik (`-p 22,80,443`) sebelum melakukan full scan `-p-`.
- Gunakan `-T4` untuk LAN/jaringan stabil; turunkan ke `-T2`/`-T3` jika target sensitif terhadap beban.
- **Wajib memiliki izin tertulis** sebelum memindai host atau subnet di luar lab lokal Anda.
