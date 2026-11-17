# Panduan Resmi: SearchSploit

## Ringkasan & Cara Kerja
`searchsploit` adalah antarmuka CLI offline untuk mencari referensi kerentanan dan PoC di database lokal Exploit-DB (`/usr/share/exploitdb`).

## Flag Penting
- **`searchsploit <kata_kunci>`:** Cari berdasarkan nama software/versi.
- **`searchsploit --cve <YYYY-NNNN>`:** Cari berdasarkan nomor CVE spesifik.
- **`searchsploit -t <kata_kunci>`:** Cari hanya pada judul entri agar hasil lebih relevan.
- **`searchsploit -j <kata_kunci>`:** Output JSON untuk diproses dengan `jq`.
