# NetLauncher — Panduan Penggunaan

Launcher terminal modern untuk tool jaringan dan keamanan di Kali Linux.
Dibuat untuk mempercepat navigasi, membantu penggunaan, dan menyimpan riwayat kerja.

> **Gunakan hanya pada aset/jaringan yang Anda miliki atau punya izin tertulis.**
> Launcher ini membuka tool yang sudah terpasang. Tidak ada otomasi serangan
> (deauth, handshake capture, brute-force) di dalam resep bawaan.

## Navigasi

| Tombol | Fungsi |
| --- | --- |
| `↑` / `↓` | Pindah item |
| `Enter` | Buka kategori / jalankan aksi |
| `Esc` | Kembali / keluar |
| Ketik | Cari fuzzy |
| `Ctrl-/` | Tampilkan/sembunyikan preview |
| `Ctrl-C` | Keluar dari fzf |

## Kategori

- **Diagnostik Jaringan** — ping, traceroute, curl, wget
- **DNS & Web** — dig, nslookup, whatweb, nikto, gobuster, ffuf, httpx, nuclei, amass, sqlmap, searchsploit
- **Interface & Routing** — ip addr, ip route, ss, netstat, iw dev
- **Pemindaian & Monitoring** — nmap, tcpdump, wireshark
- **Wireless (Berizin)** — airmon-ng, aircrack-ng, kismet, reaver, wifite
- **Tool Keamanan (Berizin)** — hydra, john, hashcat, msfconsole
- **Hackingtool** — TUI, classic REPL, bantuan

## Perintah CLI

```bash
netlauncher                  # buka menu utama
netlauncher --help           # bantuan CLI
netlauncher help             # panduan ini
netlauncher doctor           # cek dependensi dan tool
netlauncher selftest         # validasi registry dan file
netlauncher wordlists        # browser wordlist
netlauncher wordlists refresh
netlauncher update           # update hackingtool + index wordlist
netlauncher tool <id>        # jalankan tool langsung
netlauncher recipe <nama>    # jalankan resep otomasi
netlauncher --version
```

Contoh:

```bash
netlauncher tool ping
netlauncher recipe cek-koneksi
netlauncher recipe info-jaringan
```

## Wordlist

Wordlist yang terintegrasi:

- `~/wordlists/rockyou.txt`
- `~/wordlists/indonesian/geovedi/*.lst` — public domain
- `~/wordlists/indonesian/kbbi/all_entries_v6.1.0.txt` — KBBI v6.1.0
- `~/wordlists/indonesian/elliottophellia/rei-indonesia-wordlist.txt` — CC BY-SA 4.0
- `~/wordlists/indonesian/indonesian-pwdb-top150.txt` — SecLists
- SecLists, dirb, dirbuster, john, nmap, sqlmap, wfuzz, metasploit, fern-wifi

Di browser wordlist:

- `Enter` membuka aksi
- **Salin path** menyalin lokasi file ke clipboard
- **Buka di less** melihat isi file
- **Statistik** menampilkan jumlah baris, ukuran, dan cuplikan

## Resep Otomasi

| Nama | Fungsi |
| --- | --- |
| `cek-koneksi` | Gateway, internet, DNS, HTTP |
| `info-jaringan` | Interface, route, wireless, port |
| `scan-target` | Nmap top ports ke target berizin |
| `capture` | Capture trafik interface dengan tcpdump |
| `dns` | Query A, MX, NS, TXT |
| `wordlist-stats` | Statistik wordlist |
| `laporan` | Laporan Markdown dari log terbaru |

Setiap resep menampilkan perintah yang akan dijalankan dan meminta konfirmasi
untuk aksi yang berdampak (scan/capture).

## Favorit dan Riwayat

- Tambah/hapus favorit dari menu aksi tool.
- Riwayat menyimpan perintah terakhir di `~/.local/share/netlauncher/history.log`.
- Log per sesi disimpan di `~/.local/share/netlauncher/logs/` (permission 700).

## Troubleshooting

**fzf tidak ditemukan**

```bash
go install github.com/junegunn/fzf@latest
# atau
sudo apt install fzf
```

**hackingtool tidak ditemukan**

```bash
pipx install ~/tools/hackingtool --force
pipx ensurepath
```

**Tool belum terpasang**

Jalankan `netlauncher doctor` untuk melihat status. Pasang lewat apt atau
package manager Kali, lalu buka launcher lagi.

**Capture trafik gagal**

`tcpdump` membutuhkan sudo. Launcher akan meminta password di terminal.
Pastikan interface yang dipilih benar.

**Warna/UI tidak tampil normal**

Pastikan terminal mendukung ANSI dan `TERM` diatur (mis. `xterm-256color`).

## Struktur File

```text
~/.local/bin/netlauncher
~/.config/netlauncher/tools.tsv
~/.config/netlauncher/wordlists.tsv
~/.config/netlauncher/help.md
~/.config/netlauncher/favorites.tsv
~/.local/share/netlauncher/logs/
~/.local/share/netlauncher/history.log
~/.local/share/applications/netlauncher.desktop
~/wordlists/
~/laporan/
```
