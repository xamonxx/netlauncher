# Panduan Resmi: IW Dev (Wireless Netlink)

## Ringkasan & Cara Kerja
`iw` adalah utilitas konfigurasi wireless modern berbasis `nl80211` untuk melihat kapabilitas adapter WiFi, status koneksi aktif, frekuensi, dan kekuatan sinyal.

## Perintah Diagnostik Aman
- **`iw dev`:** Daftar interface wireless, MAC, mode (`managed`/`monitor`), dan channel.
- **`iw dev <iface> link`:** SSID terhubung, BSSID, frekuensi, sinyal (dBm), dan bitrate TX/RX.
- **`sudo iw dev <iface> scan`:** Pindai access point sekitar (butuh sudo).
