# Panduan Resmi: HTTPX Toolkit (ProjectDiscovery)

## Catatan Penting Kali Linux
Di Kali Linux terdapat dua binary berbeda:
- `/usr/bin/httpx` adalah klien HTTP Python (`python3-httpx`).
- `/usr/bin/httpx-toolkit` adalah **ProjectDiscovery HTTPX** untuk probing massal, deteksi title, status code, IP, CDN, dan teknologi web.

NetLauncher otomatis memanggil `httpx-toolkit` untuk seluruh snippet dan flag builder HTTPX.

## Flag Utama
- **`-u <URL>` / `-l <file>`:** Target tunggal atau daftar host dari file.
- **`-status-code -title -tech-detect -ip -cdn`:** Tampilkan status HTTP, judul halaman, teknologi Wappalyzer, IP, dan deteksi CDN/WAF.
- **`-json`:** Output JSONL terstruktur.
