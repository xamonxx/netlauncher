#!/usr/bin/env bash
# Automation: Inventaris Port & Proses Lokal
# Deskripsi: Kumpulkan daftar port listening, koneksi aktif, dan proses pemilik socket.
# Sudo: tidak
set -uo pipefail

echo "== Inventaris Port & Proses Lokal =="
echo "Waktu : $(date -Is)"
echo "Host  : $(hostname 2>/dev/null || echo '-')"
echo

echo "-- Ringkasan Socket (ss -s) --"
ss -s 2>/dev/null || true
echo

echo "-- Port Listening (ss -tulpn) --"
ss -tulpn 2>/dev/null || true
echo

if command -v lsof >/dev/null 2>&1; then
  echo "-- Proses Jaringan (lsof -i -P -n) --"
  lsof -i -P -n 2>/dev/null | head -n 40 || true
fi
