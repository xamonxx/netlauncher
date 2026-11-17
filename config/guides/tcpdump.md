# Panduan Resmi: Tcpdump

## Ringkasan & Cara Kerja
`tcpdump` adalah packet analyzer CLI berbasis `libpcap` untuk menangkap dan menyaring paket jaringan secara real-time maupun membaca file `.pcap` secara offline.

## Flag & Filter BPF Penting
- **`-i <iface>`:** Interface target (atau `any` untuk semua interface).
- **`-nn`:** Matikan resolusi hostname dan nama port agar output cepat dan tidak memicu trafik DNS tambahan.
- **`-c <N>`:** Berhenti otomatis setelah N paket (selalu gunakan saat uji cepat).
- **`-w <file.pcap>`:** Simpan paket mentah untuk dianalisis lebih lanjut di `tshark` atau `wireshark`.
- **`-r <file.pcap>`:** Baca file PCAP offline (**tidak butuh sudo**).

## Contoh Filter BPF Aman
- `port 53 or port 80 or port 443` — hanya DNS dan web.
- `host 192.168.1.1 and icmp` — hanya ping ke/dari gateway.

## Otorisasi
Capture paket pada interface aktif membutuhkan `sudo` dan hanya boleh dilakukan pada jaringan milik sendiri atau berizin.
