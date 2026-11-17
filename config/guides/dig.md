# Panduan Resmi: Dig (Domain Information Groper)

## Ringkasan & Cara Kerja
`dig` adalah utilitas resmi BIND untuk melakukan query DNS secara presisi, memverifikasi propagasi record, mengaudit autentikasi email (SPF/DMARC), dan melacak delegasi dari root server.

## Query Penting untuk Audit DNS
- **Record utama sekaligus:** `dig +noall +answer <domain> A <domain> AAAA <domain> MX <domain> NS <domain> TXT`
- **Audit email (SPF & DMARC):** cek `TXT` pada domain utama (`v=spf1 ...`) dan `TXT` pada `_dmarc.<domain>` (`v=DMARC1 ...`).
- **Trace delegasi:** `dig +trace <domain>` menelusuri jalur dari root `.` → TLD → authoritative nameserver.
- **Reverse DNS (PTR):** `dig -x <IP> +short` untuk memetakan IP kembali ke hostname.

## Cara Membaca Output
- **`status: NOERROR`:** Query berhasil (periksa `ANSWER SECTION` untuk memastikan ada record).
- **`status: NXDOMAIN`:** Domain/subdomain tidak ada.
- **`status: SERVFAIL`:** Kegagalan resolver atau validasi DNSSEC bermasalah.
- Angka sebelum `IN` adalah **TTL (detik)** sisa cache record.
