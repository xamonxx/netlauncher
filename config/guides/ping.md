# Panduan Resmi: Ping (`iputils`)

## Ringkasan & Cara Kerja
`ping` mengirim paket ICMP Echo Request untuk menguji keterjangkauan host, mengukur Round-Trip Time (RTT), jitter (`mdev`), dan packet loss.

## Flag Penting
- **`-c <N>`:** Jumlah paket (selalu gunakan di script agar tidak berjalan tanpa henti).
- **`-W <detik>`:** Timeout tunggu balasan per paket.
- **`-n`:** Output IP numerik tanpa reverse DNS lookup.
- **`-D`:** Tambahkan timestamp UNIX di setiap baris balasan.
- **`-I <iface>`:** Uji konektivitas keluar lewat interface tertentu.
