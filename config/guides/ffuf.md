# Panduan Resmi: FFUF (Fuzz Faster U Fool)

## Ringkasan & Cara Kerja
`ffuf` adalah web fuzzer berkecepatan tinggi berbasis Go yang menggantikan kata kunci `FUZZ` pada URL, header, atau body dengan entri dari wordlist.

## Flag Penting & Filter Akurat
- **`-u <URL/FUZZ>` & `-w <wordlist>`:** Target dan wordlist wajib.
- **`-mc <codes>`:** Match status code tertentu (mis. `200,204,301,302,307,403`).
- **`-fc <codes>` / `-fs <size>`:** Sembunyikan noise (mis. `-fc 404` atau `-fs <ukuran_halaman_wildcard>`).
- **`-rate <req/s>` & `-t <threads>`:** Kendalikan laju request agar tidak membebani server target.
- **`-of json -o hasil.json`:** Simpan hasil terstruktur untuk dianalisis ulang.

## Best Practice & Otorisasi
- Selalu uji 1 request manual dulu untuk mengetahui ukuran respons 404/wildcard sebelum fuzzing.
- Gunakan hanya pada aplikasi web milik sendiri atau yang memiliki izin tertulis.
