# Panduan Resmi: Netcat (`nc.traditional`)

## Ringkasan & Cara Kerja
Di Kali Linux, `nc` adalah `nc.traditional` (`v1.10`) yang ringan untuk menguji keterbukaan port TCP/UDP, membaca banner layanan, dan uji koneksi socket lokal.

## Flag Penting
- **`nc -zv -w 3 <host> <port>`:** Mode zero-I/O (`-z`) + verbose (`-v`) + timeout 3 detik (`-w 3`) untuk cek port terbuka.
- **`nc -znv -w 2 <host> 20-25 80 443`:** Uji beberapa port atau rentang port sekaligus.
- **`nc -u`:** Mode UDP.
- **`nc -lvp <port>`:** Mode listen lokal untuk uji konektivitas.
