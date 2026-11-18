# NetLauncher v2.1.0 — Panduan Penggunaan

Smart Network & Security Command Center berbasis terminal (`Bash + fzf 0.75`)
untuk Kali Linux. UI modern truecolor, animasi terminal, deteksi konteks jaringan
otomatis, 104 contoh perintah, Knowledge Base resmi + Flag Builder, 205 flag
terkurasi, 27 panduan resmi Bahasa Indonesia, Automation Flow (`.flow`),
Target Workspace, Modern Execution Runner, dan 10 resep otomasi aman.

> **Gunakan hanya pada aset/jaringan yang Anda miliki atau punya izin tertulis.**
> Launcher ini membuka tool yang sudah terpasang. Tidak ada otomasi serangan
> (deauth, handshake capture, brute-force) di dalam resep, snippet, maupun flow.

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
| `Ctrl-K` | Knowledge Base Resmi & Interactive Flag Builder |
| `Ctrl-W` | Target Workspace |
| `Ctrl-T` | Pengaturan Tema & Animasi |
| `Ctrl-L` | Riwayat Perintah & Log Sesi Viewer |
| `Ctrl-C` | Keluar dari fzf |

`Tab` pada Flag Builder memilih beberapa flag sekaligus sebelum merakit perintah.

## Kategori (51 Tool Terpasang)

- **Diagnostik Jaringan (8)** — `ping`, `traceroute`, `curl`, `wget`, `whois`, `openssl`, `nc`, `socat`
- **DNS & Web (14)** — `dig`, `nslookup`, `whatweb`, `nikto`, `gobuster`, `ffuf`, `feroxbuster`, `dirb`, `wfuzz`, `httpx`, `nuclei`, `amass`, `sqlmap`, `searchsploit`
- **Interface & Routing (8)** — `ip addr`, `ip route`, `ss`, `netstat`, `iw dev`, `nmcli`, `ethtool`, `lsof`
- **Pemindaian & Monitoring (9)** — `nmap`, `masscan`, `arp-scan`, `netdiscover`, `tcpdump`, `tshark`, `tcpflow`, `ngrep`, `wireshark`
- **Wireless (Berizin) (5)** — `airmon-ng`, `aircrack-ng`, `kismet`, `reaver`, `wifite`
- **Tool Keamanan (Berizin) (4)** — `hydra`, `john`, `hashcat`, `msfconsole`
- **Hackingtool (3)** — TUI utama, classic REPL, bantuan CLI

## Fitur Pintar & Modern UI

- **Splash & Animasi Terminal**: banner ASCII, progress bar, dan spinner murni Bash (otomatis nonaktif di non-TTY atau `--no-anim`).
- **4 Tema Truecolor**: `cyber` (default), `tokyo`, `emerald`, `amber` — ubah lewat `Ctrl-T` atau `netlauncher theme <nama>`. Border fzf menampilkan versi, tema, dan workspace aktif.
- **Smart Network Context**: mendeteksi interface, IP/CIDR, subnet, gateway, DNS, SSID WiFi, dan status koneksi.
- **Smart Placeholder Picker**: saran kontekstual untuk `{TARGET}`, `{SUBNET}`, `{IFACE}`, `{DOMAIN}`, `{URL}`, `{PORT}`, `{WORDLIST}`, `{FILE}`, `{QUERY}` — kini mengutamakan nilai Target Workspace.
- **Modern Execution Runner**: setiap perintah dijalankan lewat PTY (`script -qefc` saat TTY, `tee` + `PIPESTATUS[0]` saat non-TTY) sehingga warna/interactive prompt tetap terjaga, exit code tepat, dan log tetap teks polos. Setelah eksekusi tersedia Ringkasan Temuan (parser ping/nmap/HTTP/TLS/DNS/socket/fuzz/vuln), Filter Output (fzf), pager, salin, ekspor Markdown, saran langkah berikutnya, dan jalankan ulang.
- **Knowledge Base Resmi** (`Ctrl-K` / `netlauncher guide [tool_id]`): 27 panduan resmi Bahasa Indonesia, referensi 205 flag terkurasi, dan ekstrak flag langsung dari `--help`/`man` lokal.
- **Interactive Flag Builder** (`netlauncher flags <tool_id>`): pilih banyak flag dengan `Tab`, isi argumen/placeholder, normalisasi subcommand wajib (mis. `gobuster dir`, `openssl s_client -connect`, `amass enum`), lalu jalankan/salin/dry-run/simpan automation.
- **Command Builder**: preset snippet, template, Flag Builder resmi, edit, jalankan dengan konfirmasi otorisasi.
- **Target Workspace** (`Ctrl-W` / `netlauncher workspace`): simpan `TARGET`, `DOMAIN`, `URL`, `SUBNET`, `IFACE`, `NOTE` di `~/.local/share/netlauncher/workspace.env`; dipakai otomatis oleh smart picker, flow, dan advisor.
- **Missing Tool Advisor**: saran instalasi dan alternatif tool terpasang.

## Contoh Perintah & Custom Automation

- **104 Code Snippets (`config/snippets.tsv`)**: jalankan dengan Smart Fill, edit, salin, simpan ke automation, atau `--dry-run`.
- **Custom Automation Scripts** (`~/.config/netlauncher/automations/*.sh`): 4 starter script + menu buat/edit/jalankan.
- **Automation Flow** (`~/.config/netlauncher/flows/*.flow`): 6 starter flow deklaratif
  (`healthcheck-harian`, `audit-web-lengkap`, `inventaris-port-lokal`,
  `discovery-subnet-aman`, `audit-dns-mendalam`, `diagnostik-wifi-link`).
  Format INI: `[flow]`, `[inputs]`, `[step:N]` dengan `title`, `tool`, `when`
  (`have:`, `var:`, `prev_ok`, `confirm:`, digabung `;`), `parser`, `on_error`,
  `timeout`, `capture`, dan `cmd`. Variabel memakai `{NAMA}`; hasil `capture`
  dapat dipakai langkah berikutnya. Dashboard + ekspor Markdown otomatis.

## Perintah CLI

```bash
netlauncher                       # menu utama interaktif
netlauncher search                # pencarian global
netlauncher examples [tool_id]    # browser contoh perintah
netlauncher snippets [tool_id]    # alias examples
netlauncher guide [tool_id]       # panduan resmi (cetak ke stdout bila non-TTY)
netlauncher flags [tool_id]       # Interactive Flag Builder
netlauncher flow [ui|list|show|run]  # Automation Flow
netlauncher workspace [show|set|create|use|projects|scope|clear|delete]
netlauncher findings [list|export] # triase temuan terstruktur
netlauncher repo-scan <direktori>   # scan repo lokal, tool opsional
netlauncher automation            # kelola custom automation scripts
netlauncher wordlists [refresh]   # browser / refresh index wordlist
netlauncher logs                  # viewer log sesi & laporan
netlauncher theme [nama]          # ubah tema (cyber|tokyo|emerald|amber)
netlauncher tool <id> [argumen]   # jalankan tool lewat runner modern
netlauncher recipe <nama>         # jalankan resep otomasi aman
netlauncher list [--json]         # daftar semua tool (tabel atau JSON)
netlauncher doctor                # cek dependensi, terminal, dan tool
netlauncher selftest              # validasi registry, snippet, dan file
netlauncher lint                  # validasi tools/snippets/flags/guides/flow & syntax
netlauncher update                # update hackingtool + index wordlist
netlauncher help                  # panduan ini
netlauncher --version
netlauncher --help
```

Opsi global: `--no-anim`, `--dry-run`, `--theme <nama>`.

Contoh Automation Flow:

```bash
netlauncher flow list
netlauncher flow show audit-web-lengkap
netlauncher --dry-run flow run audit-web-lengkap --var URL=https://example.com
netlauncher flow run healthcheck-harian
netlauncher workspace create staging-store
netlauncher workspace scope app.example.test,192.168.1.0/24 staging
netlauncher workspace set URL=https://app.example.test
netlauncher repo-scan ~/src/my-project
netlauncher findings list
netlauncher findings export
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
| `laporan` | 3 template: ringkas / lengkap / audit → `~/laporan/` | tidak |

## Overlay Lokal (tidak di-track)

Letakkan file berikut di `~/.config/netlauncher/` (symlink ke repo config) untuk
menambah data tanpa mengubah repo:

- `tools.local.tsv` — format sama dengan `tools.tsv`
- `snippets.local.tsv` — format sama dengan `snippets.tsv`
- `flows.local/*.flow` — flow pribadi

Semua overlay digabung dengan data bawaan saatlint, pencarian, menu, dan
`list --json`. File ini masuk `.gitignore` agar tidak ikut ter-commit.

## Wordlist

Wordlist yang terintegrasi (136 entri): rockyou, SecLists, dan 4 koleksi
wordlist Indonesia (geovedi, KBBI v6.1.0, REI, SecLists ID).

## Favorit, Riwayat, dan Log

- Favorit dari menu aksi tool.
- Riwayat: `~/.local/share/netlauncher/history.log`.
- Riwayat target: `~/.local/share/netlauncher/targets.history`.
- Workspace: `~/.local/share/netlauncher/workspace.env`.
- Log sesi: `~/.local/share/netlauncher/logs/` (permission `700`, rotasi > 30 hari).
- Laporan: `~/laporan/` (permission `600`).

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
Pastikan terminal mendukung truecolor/ANSI (`TERM=xterm-256color`,
`COLORTERM=truecolor`). Gunakan `netlauncher --no-anim` atau matikan animasi di
menu `Tema & Animasi` (`Ctrl-T`).

**Eksekusi tampak tanpa warna di log**
Itu disengaja: log disimpan sebagai teks polos. Warna asli tetap tampil di
terminal dan bisa dilihat kembali lewat menu "Buka Output Lengkap di Pager
(less -R)".

## Struktur File

```text
~/.local/bin/netlauncher
~/.config/netlauncher/tools.tsv
~/.config/netlauncher/tools.local.tsv          (opsional)
~/.config/netlauncher/snippets.tsv
~/.config/netlauncher/snippets.local.tsv       (opsional)
~/.config/netlauncher/flags.tsv
~/.config/netlauncher/guides/*.md
~/.config/netlauncher/flows/*.flow
~/.config/netlauncher/flows.local/*.flow       (opsional)
~/.config/netlauncher/automations/*.sh
~/.config/netlauncher/wordlists.tsv
~/.config/netlauncher/help.md
~/.config/netlauncher/favorites.tsv
~/.config/netlauncher/theme.env
~/.local/share/netlauncher/logs/
~/.local/share/netlauncher/history.log
~/.local/share/netlauncher/targets.history
~/.local/share/netlauncher/workspace.env
~/.local/share/applications/netlauncher.desktop
~/wordlists/
~/laporan/
```
