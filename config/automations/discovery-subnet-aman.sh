#!/usr/bin/env bash
# Automation: Discovery Subnet Lokal (Berizin)
# Deskripsi: Tampilkan tabel ARP lokal dan opsional ping sweep subnet dengan konfirmasi.
# Sudo: tidak
set -uo pipefail

echo "== Discovery Subnet Lokal =="
echo "Waktu: $(date -Is)"
echo

echo "-- Tabel Tetangga ARP/NDP (ip neigh) --"
ip neigh show 2>/dev/null || true
echo

subnet="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | head -n1)"
if [ -z "$subnet" ]; then
  echo "Tidak ada subnet IPv4 global terdeteksi."
  exit 0
fi

echo "Subnet terdeteksi: $subnet"
if command -v nmap >/dev/null 2>&1; then
  echo "Perintah opsional: nmap -sn $subnet"
  read -r -p "Jalankan ping sweep pada subnet berizin ini? (y/N): " ans || true
  if [[ "$ans" =~ ^[yY]$ ]]; then
    nmap -sn "$subnet"
  else
    echo "Ping sweep dilewati."
  fi
fi
