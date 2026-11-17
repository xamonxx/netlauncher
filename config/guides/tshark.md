# Panduan Resmi: TShark

## Ringkasan & Cara Kerja
`tshark` adalah versi terminal dari Wireshark dengan dissector protokol yang sama lengkapnya, sangat kuat untuk ekstraksi field terstruktur (`-T fields`) dan statistik protokol (`-z`).

## Pola Penggunaan Resmi
- **Ekstrak query DNS real-time:**
  `sudo tshark -i <iface> -Y 'dns.qry.name' -T fields -e ip.src -e dns.qry.name`
- **Statistik hierarki protokol dari PCAP (tanpa sudo):**
  `tshark -r <file.pcap> -q -z io,phs`
- **Daftar percakapan TCP dari PCAP:**
  `tshark -r <file.pcap> -q -z conv,tcp`

## Perbedaan Filter
- **`-f` (Capture Filter / BPF):** Diterapkan saat menangkap paket (sintaks sama dengan `tcpdump`).
- **`-Y` (Display Filter):** Diterapkan oleh dissector Wireshark (mis. `http.request`, `tls.handshake.type == 1`, `dns.qry.name`).
