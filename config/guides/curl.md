# Panduan Resmi: Curl

## Ringkasan & Cara Kerja
`curl` adalah klien transfer URL serbaguna untuk menguji endpoint HTTP/HTTPS, memeriksa rantai redirect, mengaudit security headers, dan mengukur latensi koneksi per fase (DNS, TCP, TLS, TTFB).

## Kombinasi Flag yang Direkomendasikan
- **Cek header & redirect:** `curl -ILsS --max-time 10 <URL>`
- **Audit security headers:** periksa keberadaan `Strict-Transport-Security`, `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, dan `Permissions-Policy`.
- **Benchmark timing:** gunakan `-o /dev/null -s -w '...'` untuk memisahkan waktu `time_namelookup`, `time_connect`, `time_appconnect` (TLS), dan `time_starttransfer` (TTFB).

## Cara Membaca Output
- `HTTP/2 200` atau `HTTP/1.1 301 Moved Permanently` menunjukkan status respons tiap hop redirect.
- Dengan `-v`, baris diawali `*` adalah log koneksi/TLS, `>` adalah request header, dan `<` adalah response header.

## Best Practice
- Selalu pasang `--max-time` agar script otomasi tidak menggantung saat server lambat.
- Hindari `-k` (`--insecure`) di produksi; gunakan hanya saat menguji sertifikat self-signed di lab lokal.
