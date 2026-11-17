# Panduan Resmi: WhatWeb

## Ringkasan & Cara Kerja
`whatweb` mengidentifikasi teknologi web (CMS, framework, web server, library JS, header keamanan, dan cookie) menggunakan ratusan plugin deteksi.

## Level Agresi (`-a`)
- **`-a 1` (Stealthy / Pasif):** Hanya mengirim **1 HTTP request** per target. Direkomendasikan untuk audit awal yang aman.
- **`-a 3` (Aggressive):** Mengirim request tambahan jika ada indikasi plugin tertentu.
- **`-a 4` (Heavy):** Menguji seluruh plugin (berisik; hanya untuk target berizin penuh).
