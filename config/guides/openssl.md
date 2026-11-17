# Panduan Resmi: OpenSSL TLS Inspector

## Ringkasan & Cara Kerja
Subcommand `openssl s_client` dan `openssl x509` digunakan untuk menguji handshake TLS secara langsung, memverifikasi rantai sertifikat, memeriksa SAN (Subject Alternative Name), dan mengecek masa berlaku sertifikat.

## Pola Perintah Resmi
- **Inspeksi sertifikat lengkap:**
  `echo | openssl s_client -servername <domain> -connect <domain>:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName`
- **Cek protokol & cipher yang dinegosiasikan:**
  `openssl s_client -connect <domain>:443 -servername <domain> </dev/null 2>/dev/null | grep -E 'Protocol|Cipher|Verify return code'`

## Cara Membaca Output
- **`-servername <domain>` (SNI):** Wajib disertakan agar server multi-domain mengirim sertifikat yang benar.
- **`Verify return code: 0 (ok)`:** Rantai sertifikat valid dan dipercaya oleh CA sistem.
- **`notAfter`:** Tanggal kedaluwarsa sertifikat (NetLauncher otomatis menghitung sisa hari di ringkasan output).
