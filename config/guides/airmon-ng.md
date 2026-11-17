# Panduan Resmi: Airmon-ng

## Ringkasan & Cara Kerja
`airmon-ng` adalah utilitas dari suite `aircrack-ng` untuk memeriksa status adapter wireless, mendeteksi proses yang mengganggu mode monitor (`check`), dan mengelola interface monitor pada pengujian jaringan WiFi berizin.

## Catatan Penting
- Menjalankan `airmon-ng` membutuhkan hak akses `sudo`.
- Gunakan `man airmon-ng` untuk membaca manual tanpa hak root.
- NetLauncher tidak mengotomasi serangan deauth atau handshake capture; gunakan hanya untuk diagnostik dan audit jaringan milik sendiri/berizin.
