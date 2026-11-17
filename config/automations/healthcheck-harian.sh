#!/usr/bin/env bash
# Automation: Healthcheck Jaringan Harian
# Deskripsi: Cek gateway, ping internet, resolusi DNS, HTTP latency, dan status interface.
# Sudo: tidak
set -uo pipefail

echo "== Healthcheck Jaringan Harian =="
echo "Waktu : $(date -Is)"
echo "Host  : $(hostname 2>/dev/null || echo '-')"
echo

gw="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
iface="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
echo "Interface aktif : ${iface:--}"
echo "Default gateway : ${gw:--}"
echo

echo "-- Status Interface --"
ip -brief addr
echo

if [ -n "$gw" ] && command -v ping >/dev/null 2>&1; then
  echo "-- Ping Gateway ($gw) --"
  ping -c 3 -W 2 "$gw" || true
  echo
fi

if command -v ping >/dev/null 2>&1; then
  echo "-- Ping Internet (1.1.1.1) --"
  ping -c 3 -W 2 1.1.1.1 || true
  echo
fi

if command -v dig >/dev/null 2>&1; then
  echo "-- Resolusi DNS (example.com) --"
  dig +short A example.com || true
  echo
fi

if command -v curl >/dev/null 2>&1; then
  echo "-- HTTP Timing (https://example.com) --"
  curl -o /dev/null -sS --max-time 8 -w "HTTP: %{http_code} | DNS: %{time_namelookup}s | TLS: %{time_appconnect}s | Total: %{time_total}s\n" https://example.com || true
fi
