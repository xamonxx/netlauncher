# Panduan Resmi: Nikto

## Ringkasan & Cara Kerja
`nikto` adalah web server scanner klasik untuk memeriksa misconfiguration server, header keamanan yang hilang, file default berbahaya, dan versi software usang.

## Flag Penting
- **`-h <URL>`:** Host/URL target berizin.
- **`-Tuning 123b`:** Fokus pada file menarik (`1`), misconfiguration (`2`), information disclosure (`3`), dan identifikasi software (`b`).
- **`-maxtime 60s`:** Batasi durasi scan agar terkendali.
- **`-o <file> -Format htm|json|txt`:** Simpan laporan terstruktur.
- **`nikto -H`:** Tampilkan daftar opsi lengkap (catatan: Nikto memakai `-H`, bukan `-help`).
