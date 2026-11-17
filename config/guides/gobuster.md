# Panduan Resmi: Gobuster

## Ringkasan & Cara Kerja
`gobuster` adalah tool enumerasi berbasis Go dengan subcommand terpisah untuk direktori/file (`dir`), subdomain DNS (`dns`), dan virtual host (`vhost`).

## Subcommand & Flag Utama
- **`gobuster dir -u <URL> -w <wordlist> -t 20`:** Enumerasi path web.
- **`gobuster dns --domain <domain> -w <wordlist> -t 20`:** Enumerasi subdomain DNS.
- **`-x php,txt,html`:** Tambahkan ekstensi file saat mode `dir`.
- **`-k`:** Lewati verifikasi sertifikat TLS (khusus lab/self-signed).

## Otorisasi
Gunakan hanya pada target milik sendiri atau yang memiliki izin tertulis.
