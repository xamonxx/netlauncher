# Panduan Resmi: Ethtool

## Ringkasan & Cara Kerja
`ethtool` memeriksa dan mendiagnosis parameter fisik/driver kartu jaringan (NIC), seperti kecepatan link (100/1000/2500 Mbps), mode duplex, status kabel (`Link detected`), driver kernel, dan statistik error hardware.

## Perintah Utama
- **`ethtool <iface>`:** Status link, speed, duplex, dan auto-negotiation.
- **`ethtool -i <iface>`:** Nama driver kernel, versi, dan firmware NIC.
- **`ethtool -S <iface>`:** Counter statistik hardware (RX/TX errors, CRC, drops).
