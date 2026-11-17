# Panduan Resmi: IP Address & Route (`iproute2`)

## Ringkasan & Cara Kerja
`ip` adalah utilitas resmi `iproute2` untuk memeriksa dan mengelola interface jaringan, alamat IP, tabel routing, dan cache tetangga ARP/NDP.

## Perintah Diagnostik Utama
- **`ip -c -brief addr`:** Ringkasan status `UP`/`DOWN` dan IP tiap interface.
- **`ip -s link show`:** Statistik paket RX/TX, error, dan dropped packets.
- **`ip -c route show`:** Tabel routing dan default gateway.
- **`ip route get <IP>`:** Mengetahui interface dan gateway mana yang dipilih kernel menuju IP tertentu.
- **`ip neigh show`:** Daftar perangkat LAN di cache ARP/NDP kernel.
