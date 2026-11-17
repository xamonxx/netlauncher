# Panduan Resmi: Traceroute

## Ringkasan & Cara Kerja
`traceroute` melacak setiap hop router menuju host tujuan dengan menaikkan nilai TTL secara bertahap dan mencatat respons ICMP Time Exceeded.

## Flag Penting
- **`traceroute -n <host>`:** Tanpa reverse DNS lookup (jauh lebih cepat).
- **`sudo traceroute -T -p 443 <host>`:** Gunakan probe TCP SYN ke port 443 saat ICMP/UDP diblokir firewall.
- **`-m <max_ttl>`:** Batasi jumlah hop maksimum.
- Catatan: tanda `* * *` pada satu hop berarti router tersebut tidak membalas probe TTL, bukan selalu berarti paket terputus jika hop berikutnya tetap merespons.
