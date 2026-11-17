# Panduan Resmi: SQLMap

## Ringkasan & Cara Kerja
`sqlmap` mengotomatiskan deteksi dan verifikasi celah SQL injection pada parameter HTTP/HTTPS untuk pengujian keamanan aplikasi berizin.

## Flag Aman untuk Verifikasi Awal
- **`-u "<URL>"` atau `-r <request.txt>`:** Target URL berparameter atau raw HTTP request dari proxy.
- **`--batch`:** Mode non-interaktif dengan jawaban default aman.
- **`--level=1 --risk=1`:** Mulai dari level dan risiko paling rendah agar tidak mengganggu integritas data target.
- **`--banner`:** Hanya mengambil banner versi DBMS untuk pembuktian temuan.

## Otorisasi
Dilarang keras menjalankan `sqlmap` pada aplikasi tanpa izin tertulis pemilik sistem.
