# Panduan Resmi: John the Ripper & Hashcat

## Ringkasan & Cara Kerja
`john` dan `hashcat` digunakan untuk mengaudit kekuatan kata sandi dan hash milik sendiri/berizin serta melakukan benchmark performa CPU/GPU lokal.

## Perintah Aman & Diagnostik
- **`john --test` / `hashcat -b`:** Benchmark kecepatan hashing perangkat keras lokal.
- **`john --list=formats`:** Daftar format hash yang didukung.
- **`hashcat -I`:** Daftar perangkat OpenCL/CUDA yang terdeteksi.
- **`john --wordlist=<wordlist> <file_hash>`:** Audit kekuatan file hash lokal milik sendiri.
