#!/usr/bin/env bash
# Automation: Audit TLS & Security Headers Domain
# Deskripsi: Periksa sertifikat TLS, masa berlaku, SAN, dan header keamanan HTTP (pasif/berizin).
# Sudo: tidak
set -uo pipefail

domain="${1:-}"
if [ -z "$domain" ]; then
  read -r -p "Domain target (mis. example.com): " domain || true
fi
[ -n "$domain" ] || { echo "Domain kosong, dibatalkan."; exit 0; }
domain="${domain#https://}"
domain="${domain#http://}"
domain="${domain%%/*}"

echo "== Audit TLS & Header: $domain =="
echo "Waktu: $(date -Is)"
echo

if command -v dig >/dev/null 2>&1; then
  echo "-- DNS A / AAAA --"
  dig +short A "$domain"
  dig +short AAAA "$domain"
  echo
fi

if command -v openssl >/dev/null 2>&1; then
  echo "-- Sertifikat TLS (port 443) --"
  echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
    openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null || \
    echo "Gagal mengambil sertifikat TLS."
  echo
fi

if command -v curl >/dev/null 2>&1; then
  echo "-- HTTP Security Headers --"
  curl -sI --max-time 10 "https://$domain" | \
    grep -iE '^(http/|server:|strict-transport|content-security|x-frame|x-content-type|referrer-policy|permissions-policy)' || true
fi
