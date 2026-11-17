# NetLauncher v2.0.0 — Panduan Penggunaan

Smart Network & Security Command Center berbasis terminal (`Bash + fzf 0.75`)
untuk Kali Linux. Dilengkapi UI modern truecolor, animasi terminal, deteksi
konteks jaringan otomatis, 104 contoh perintah siap pakai, Command Builder,
Custom Automation Scripts, dan 10 resep otomasi aman.

> **Gunakan hanya pada aset/jaringan yang Anda miliki atau punya izin tertulis.**
> Launcher ini membuka tool yang sudah terpasang. Tidak ada otomasi serangan
> (deauth, handshake capture, brute-force) di dalam resep maupun snippet bawaan.

## Navigasi & Shortcut

| Tombol | Fungsi |
| --- | --- |
| `↑` / `↓` | Pindah item |
| `Enter` | Buka kategori / jalankan aksi |
| `Esc` | Kembali / keluar |
| Ketik | Cari fuzzy |
| `Ctrl-/` | Tampilkan/sembunyikan panel preview |
| `Ctrl-S` | Pencarian global (51 tool + 104 contoh perintah) |
| `Ctrl-E` | Browser Contoh Perintah & Code Snippets |
| `Ctrl-T` | Pengaturan Tema & Animasi |
| `Ctrl-L` | Riwayat Perintah & Log Sesi Viewer |
| `Ctrl-C` | Keluar dari fzf |

## Kategori (51 Tool Terpasang)

- **Diagnostik Jaringan (8)** — `ping`, `traceroute`, `curl`, `wget`, `whois`, `openssl`, `nc`, `socat`
- **DNS & Web (14)** — `dig`, `nslookup`, `whatweb`, `nikto`, `gobuster`, `ffuf`, `feroxbuster`, `dirb`, `wfuzz`, `httpx`, `nuclei`, `amass`, `sqlmap`, `searchsploit`
- **Interface & Routing (8)** — `ip addr`, `ip route`, `ss`, `netstat`, `iw dev`, `nmcli`, `ethtool`, `lsof`
- **Pemindaian & Monitoring (9)** — `nmap`, `masscan`, `arp-scan`, `netdiscover`, `tcpdump`, `tshark`, `tcpflow`, `ngrep`, `wireshark`
- **Wireless (Berizin) (5)** — `airmon-ng`, `aircrack-ng`, `kismet`, `reaver`, `wifite`
- **Tool Keamanan (Berizin) (4)** — `hydra`, `john`, `hashcat`, `msfconsole`
- **Hackingtool (3)** — TUI utama, classic REPL, bantuan CLI

## Fitur Pintar & Modern UI

- **Splash & Animasi Terminal**: banner ASCII, progress bar, dan spinner murni Bash (otomatis nonaktif di non-TTY atau dengan `--no-anim`).
- **4 Tema Truecolor**: `cyber` (default), `tokyo`, `emerald`, dan `amber` — ubah lewat menu `Tema & Animasi` (`Ctrl-T`) atau `netlauncher theme <nama>`.
- **Smart Network Context**: mendeteksi otomatis interface aktif, IP/CIDR, subnet, gateway, DNS, SSID WiFi, dan status koneksi (`ONLINE`/`LOKAL`/`OFFLINE`).
- **Smart Placeholder Picker**: saat menjalankan tool atau snippet dengan `{TARGET}`, `{SUBNET}`, `{IFACE}`, `{DOMAIN}`, `{URL}`, `{PORT}`, `{WORDLIST}`, atau `{FILE}`, launcher menyarankan nilai kontekstual dan riwayat target terakhir.
- **Command Builder**: pilih preset snippet atau template, isi parameter pintar, edit perintah sebelum eksekusi, lalu jalankan, salin ke clipboard, atau uji dengan `--dry-run`.
- **Missing Tool Advisor**: jika binary belum terpasang, tampilkan saran instalasi dan alternatif tool yang sudah terpasang di kategori yang sama.

## Contoh Perintah & Custom Automation

- **104 Code Snippets (`config/snippets.tsv`)**: mencakup seluruh 51 tool. Dari menu snippet (`Ctrl-E` atau `netlauncher examples [tool_id]`), Anda dapat:
  - Menjalankan dengan Smart Fill parameter
  - Mengedit perintah sebelum dijalankan
  - Menyalin perintah ke clipboard
  - Menyimpan snippet menjadi script Bash di `~/.config/netlauncher/automations/`
  - Menjalankan pratinjau `--dry-run`
- **Custom Automation (`~/.config/netlauncher/automations/*.sh`)**: dilengkapi 4 script starter (`healthcheck-harian.sh`, `audit-tls-domain.sh`, `inventaris-port.sh`, `discovery-subnet-aman.sh`) serta menu untuk membuat, mengedit, dan menjalankan script Bash kustom Anda sendiri.

## Perintah CLI

```bash
netlauncher                       # buka menu utama interaktif
netlauncher search                # pencarian global tool & contoh perintah
netlauncher examples [tool_id]    # browser contoh perintah & code snippets
netlauncher snippets [tool_id]    # alias untuk examples
netlauncher automation            # kelola & jalankan custom automation scripts
netlauncher wordlists [refresh]   # browser / refresh index wordlist
netlauncher logs                  # buka viewer log sesi
netlauncher theme [nama]          # ubah tema (cyber|tokyo|emerald|amber)
netlauncher tool <id>             # jalankan tool langsung
netlauncher recipe <nama>         # jalankan resep otomasi aman
netlauncher list [--json]         # daftar semua tool (tabel atau JSON)
netlauncher doctor                # cek dependensi, terminal, dan tool
netlauncher selftest              # validasi registry, snippet, dan file
netlauncher lint                  # validasi ketat tools.tsv, snippets.tsv, syntax
netlauncher update                # update hackingtool + index wordlist
netlauncher help                  # panduan ini
netlauncher --version             # tampilkan versi
netlauncher --help                # bantuan CLI singkat
```

Opsi global:

```bash
netlauncher --no-anim             # matikan animasi splash/spinner
netlauncher --dry-run ...         # pratinjau perintah tanpa eksekusi
netlauncher --theme tokyo         # pakai tema sementara
```

## Resep Otomasi Aman (10 Resep)

| Nama | Fungsi | Sudo |
| --- | --- | --- |
| `cek-koneksi` | Ping gateway, ping internet, DNS, HTTP timing | tidak |
| `info-jaringan` | Interface, subnet, route, WiFi, socket, DNS | tidak |
| `audit-web` | HTTP security headers, timing, sertifikat TLS, DNS, WhatWeb | tidak |
| `dns` | Query A, AAAA, MX, NS, TXT, SOA, DMARC, WHOIS | tidak |
| `monitor-port` | Ringkasan socket, port listening, koneksi aktif, `lsof` | tidak |
| `discovery-lokal` | Tabel ARP lokal + opsional ping sweep berizin | tidak |
| `scan-target` | Nmap (Top 100 / Service+NSE / Full TCP) + konfirmasi | tidak |
| `capture` | `tcpdump` dengan smart interface picker & filter BPF | ya |
| `wordlist-stats` | Jumlah baris, ukuran, cuplikan, dan baris unik | tidak |
| `laporan` | Gabungkan log 24 jam terakhir ke Markdown di `~/laporan/` | tidak |

## Wordlist

Wordlist yang terintegrasi (136 entri):

- `~/wordlists/rockyou.txt`
- `~/wordlists/indonesian/geovedi/*.lst` — public domain
- `~/wordlists/indonesian/kbbi/all_entries_v6.1.0.txt` — KBBI v6.1.0
- `~/wordlists/indonesian/elliottophellia/rei-indonesia-wordlist.txt` — CC BY-SA 4.0
- `~/wordlists/indonesian/indonesian-pwdb-top150.txt` — SecLists
- SecLists, dirb, dirbuster, john, nmap, sqlmap, wfuzz, metasploit, fern-wifi

## Favorit, Riwayat, dan Log

- Tambah/hapus favorit dari menu aksi tool.
- Riwayat perintah disimpan di `~/.local/share/netlauncher/history.log`.
- Riwayat target kontekstual disimpan di `~/.local/share/netlauncher/targets.history`.
- Log per sesi disimpan di `~/.local/share/netlauncher/logs/` (permission `700`, rotasi otomatis > 30 hari).

## Troubleshooting

**fzf tidak ditemukan / versi lama**

```bash
GOBIN="$HOME/.local/bin" go install github.com/junegunn/fzf@latest
```

**hackingtool tidak ditemukan**

```bash
pipx install ~/tools/hackingtool --force
pipx ensurepath
```

**Warna/UI tidak tampil normal**

Pastikan terminal mendukung truecolor/ANSI (`TERM=xterm-256color`, `COLORTERM=truecolor`).
Jika terminal lambat atau tidak mendukung animasi, jalankan `netlauncher --no-anim`
atau matikan animasi lewat menu `Tema & Animasi` (`Ctrl-T`).

## Struktur File

```text
~/.local/bin/netlauncher
~/.config/netlauncher/tools.tsv
~/.config/netlauncher/snippets.tsv
~/.config/netlauncher/automations/*.sh
~/.config/netlauncher/wordlists.tsv
~/.config/netlauncher/help.md
~/.config/netlauncher/favorites.tsv
~/.config/netlauncher/theme.env
~/.local/share/netlauncher/logs/
~/.local/share/netlauncher/history.log
~/.local/share/netlauncher/targets.history
~/.local/share/applications/netlauncher.desktop
~/wordlists/
~/laporan/
```
