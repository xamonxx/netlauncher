# Panduan Resmi: Amass

## Ringkasan & Cara Kerja
`amass` adalah tool pemetaan permukaan serangan dan enumerasi subdomain dari sumber OSINT pasif maupun aktif.

## Catatan Kali Linux
Pada eksekusi pertama, `amass` di Kali dapat meminta `sudo` untuk mengunduh data `libpostal`. Gunakan mode `-passive` untuk mengumpulkan subdomain dari sumber publik tanpa mengirim paket langsung ke target:
`amass enum -passive -d <domain>`
