# Panduan Resmi: ARP Scan & IP Neighbor

## Ringkasan & Cara Kerja
`arp-scan` mengirim paket ARP Request pada segmen Layer-2 lokal untuk menemukan seluruh perangkat aktif beserta alamat IP, MAC address, dan vendor OUI-nya (bahkan jika host memblokir ICMP ping).

## Flag Utama
- **`sudo arp-scan --localnet`:** Pindai subnet pada interface default.
- **`sudo arp-scan -I <iface> --localnet`:** Pilih interface spesifik.
- **Alternatif tanpa sudo (pasif):** `ip neigh show` membaca cache ARP/NDP kernel yang sudah ada tanpa mengirim paket baru.
