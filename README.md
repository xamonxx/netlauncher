<div align="center">

# ⚡ NetLauncher

### **Network & Security Command Center — right in your terminal.**

A modern, Indonesian-first TUI for organizing the networking and security tools already on your Kali Linux system. Explore tools, build commands, run repeatable workflows, and keep project findings together—without losing sight of authorization and scope.

<br>

[![Platform](https://img.shields.io/badge/platform-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](#requirements)
[![Shell](https://img.shields.io/badge/shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](#requirements)
[![Interface](https://img.shields.io/badge/interface-fzf%20TUI-7C3AED?style=for-the-badge)](#highlights)
[![Language](https://img.shields.io/badge/language-Bahasa%20Indonesia-DB2777?style=for-the-badge)](#)
[![Status](https://img.shields.io/badge/status-2.2.0--dev-orange?style=for-the-badge)](docs/CHANGELOG.md)

<br>

**One launcher. 51 registered tools. Repeatable workflows. Local-first project context.**

[Features](#highlights) · [Install](#installation) · [Quick start](#quick-start) · [Commands](#cli-reference) · [Safety](#security--responsible-use) · [Contributing](#development)

</div>

---

> [!WARNING]
> **Authorized use only.** Use NetLauncher only on systems and networks you own or are explicitly authorized to assess. The launcher does not make an action safe merely because it is available in a menu. Review each command, its target, and its impact before execution. No automated deauthentication, handshake capture, brute-force, HTTP flood, or SYN flood workflows are provided.

## What is NetLauncher?

NetLauncher is a local terminal command center built with **Bash + fzf**. It brings installed networking and security utilities into one searchable interface, with Indonesian guides, command examples, an interactive flag builder, a PTY-aware execution runner, project workspaces, and declarative automation flows.

It is designed to help you **work deliberately**: understand a tool before using it, keep project context organized, preview commands, and confirm impactful operations. NetLauncher does not run a server or upload your project data to a NetLauncher service.

> **Development build:** `2.2.0-dev`, based on the `2.1.0` release. Interfaces and behavior may change before a stable release.

## ✨ Highlights

| Area | What you get |
| --- | --- |
| **Terminal UI** | Rounded fzf interface, truecolor themes, preview panels, status context, optional animation, and keyboard-driven navigation. |
| **Tool catalog** | 51 registry entries across diagnostics, DNS/web, interfaces, scanning/monitoring, wireless, security, and Hackingtool. Availability depends on the local system. |
| **Command examples** | 104 curated snippets with Smart Fill, preview, edit, copy, dry-run, and save-to-automation options. |
| **Knowledge & flags** | 27 Indonesian guides, 205 curated flags, and an interactive flag builder with local `--help`/`man` references. |
| **Execution runner** | PTY support for interactive tools, exit-code handling, readable logs, output summaries, and Markdown report export. |
| **Automation Flow** | Six starter `.flow` pipelines with inputs, conditions, confirmation gates, parsing, timeouts, and reports. |
| **Project profiles** | Separate lab/staging/production workspaces, target context, and declared scope per project. Impactful actions are checked against the active scope. |
| **Findings** | Local JSONL findings store, basic deduplication, triage statuses, project filtering, and JSON export. |
| **Local repository checks** | Optional integrations for already-installed Gitleaks, Trivy, and Semgrep. NetLauncher does not install them automatically. |
| **Personalization** | Four themes (`cyber`, `tokyo`, `emerald`, `amber`), favorites, history, wordlist browser, overlays, and Bash/Zsh completion. |
| **Safety controls** | Dry-run support, command preview, authorization prompts for impactful actions, local data storage, and private file permissions for sensitive runtime data. |

### Tool categories

| Category | Registered entries | Example tools |
| --- | ---: | --- |
| Diagnostics | 8 | `ping`, `traceroute`, `curl`, `openssl` |
| DNS & Web | 14 | `dig`, `whatweb`, `httpx`, `nuclei` |
| Interface & Routing | 8 | `ip`, `ss`, `nmcli`, `ethtool` |
| Scanning & Monitoring | 9 | `nmap`, `tcpdump`, `tshark`, `wireshark` |
| Wireless (authorized) | 5 | `iw`, `aircrack-ng`, `kismet` |
| Security (authorized) | 4 | `john`, `hashcat`, `msfconsole` |
| Hackingtool | 3 | `hackingtool` entries |

The registry is a launcher catalog, not a guarantee that every feature of every external utility is installed, configured, or appropriate for a given assessment. Run `netlauncher doctor` to inspect your environment.

## 🖥️ Interface preview

```text
╭──────────────────────────────────────────────────────────────╮
│  ⚡ NETLAUNCHER                         PROJECT: staging-web  │
│  Network & Security Command Center                            │
├──────────────────────────────────────────────────────────────┤
│  ⚡  Diagnostik Jaringan                     (8 tools)        │
│  🌐  DNS & Web                              (14 tools)        │
│  🔌  Interface & Routing                     (8 tools)        │
│  📡  Pemindaian & Monitoring                 (9 tools)        │
│  📶  Wireless (Berizin)                      (5 tools)        │
│  🛡  Tool Keamanan (Berizin)                 (4 tools)        │
│  ◎  Proyek & Target Workspace                               │
│  ▣  Temuan Keamanan                                          │
│  🌊  Automation Flow                                         │
╰──────────────────────────────────────────────────────────────╯
  Enter buka  ·  Ctrl-/ preview  ·  Ctrl-S cari  ·  Esc kembali
```

*Illustrative preview; exact layout depends on terminal size, font, fzf version, and theme.*

## ⚙️ Requirements

- Kali Linux or a compatible Linux environment
- Bash 4 or newer
- `fzf` 0.60+ (the current development environment uses 0.75)
- `jq`, `script` from util-linux, and Python 3 for selected features
- `tmux` is optional; required for the UI test target
- Individual external tools are optional and must be installed separately

NetLauncher does not automatically install the registered tools. Optional repository scanners—Gitleaks, Trivy, and Semgrep—are also not installed automatically.

## 🚀 Installation

Clone or place the repository at your preferred location. For this development environment, the canonical repository is `~/tools/netlauncher`.

```bash
git clone https://github.com/xamonxx/netlauncher.git ~/tools/netlauncher
cd ~/tools/netlauncher
./scripts/install.sh
```

The installer links the repository entry point and configuration into the user-local locations; it does not require a system-wide install. To refresh the links later:

```bash
make install
# or
./scripts/install.sh
```

> [!NOTE]
> If this is a fresh clone, inspect the repository and its documented requirements before running the installer. The current source of truth is the repository; runtime configuration and data remain under your home directory.

### Verify the setup

```bash
netlauncher --version
netlauncher doctor
netlauncher lint
netlauncher selftest
```

`doctor` reports missing dependencies and optional components. A missing optional scanner is not the same as a broken registered tool.

## ⚡ Quick start

```bash
# Open the interactive command center
netlauncher

# Explore registered tools
netlauncher list
netlauncher search

# Read a tool guide and browse examples
netlauncher guide nmap
netlauncher examples curl

# Build a command from curated flags; inspect before running
netlauncher flags nmap

# Inspect available workflows
netlauncher flow list
netlauncher flow show audit-web-lengkap

# Create an isolated project profile
netlauncher workspace create staging-web
netlauncher workspace scope app.example.test,192.0.2.0/24 staging
netlauncher workspace set URL=https://app.example.test
netlauncher workspace show

# Review/export local findings
netlauncher findings list
netlauncher findings export

# Check a local repository if optional scanners are installed
netlauncher repo-scan ~/src/my-project
```

Use `--dry-run` where supported to preview a command without executing it:

```bash
netlauncher --dry-run flow run audit-web-lengkap --var URL=https://example.test
```

Examples use documentation-only domains or reserved IP ranges. Replace them only with assets in your explicitly authorized scope.

## ⌨️ Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Enter` | Open selected item |
| `Esc` | Go back or close the current view |
| `Ctrl-/` | Open preview/details |
| `Ctrl-S` | Global search |
| `Ctrl-E` | Browse command examples |
| `Ctrl-K` | Knowledge base |
| `Ctrl-W` | Project and target workspace |
| `Ctrl-T` | Theme selector |
| `Ctrl-L` | History and logs |
| `Tab` | Select multiple flags in the flag builder |

Shortcuts can vary by view and terminal; the active screen shows its available actions.

## 🧭 CLI reference

```text
netlauncher                         Open the interactive menu
netlauncher search                  Global search
netlauncher list [--json]           List registered tools
netlauncher tool <id> [arguments]   Launch a registered tool
netlauncher examples [tool_id]      Browse curated command examples
netlauncher guide <tool_id>         Show an Indonesian tool guide
netlauncher flags <tool_id>         Interactive flag builder
netlauncher flow [ui|list|show|run] Browse or run declarative flows
netlauncher workspace <subcommand>  Manage projects and target context
netlauncher findings <subcommand>   List/export structured findings
netlauncher repo-scan <directory>   Run installed local repository scanners
netlauncher automation              Manage custom automation scripts
netlauncher wordlists [refresh]     Browse or refresh the wordlist index
netlauncher logs                    View session logs and reports
netlauncher theme [name]            Select a theme
netlauncher recipe <name>           Run a documented safe recipe
netlauncher doctor                  Check dependencies and environment
netlauncher selftest                Check registry and launcher internals
netlauncher lint                    Validate registry, snippets, flags, and flows
netlauncher update                  Run the documented updater
netlauncher --version | --help      Show version or help
```

Global options include `--no-anim`, `--dry-run`, and `--theme <name>`. Run `netlauncher help` for the CLI help bundled with your checkout.

### Project workspace commands

```bash
netlauncher workspace create <name>
netlauncher workspace use <name>
netlauncher workspace projects
netlauncher workspace scope <host-or-network-list> [lab|staging|produksi]
netlauncher workspace set KEY=VALUE [KEY=VALUE ...]
netlauncher workspace show
netlauncher workspace clear
netlauncher workspace delete <name>
```

Scope checking is a guardrail, **not** proof of authorization or a complete security boundary. Review the resolved target and command yourself. Do not put credentials, tokens, or secrets in project notes or scope fields.

### Automation Flow example

```bash
netlauncher flow list
netlauncher flow show audit-web-lengkap
netlauncher --dry-run flow run audit-web-lengkap --var URL=https://example.test
```

Flows are local declarative files in `config/flows/`; inspect their steps before execution. A confirmation prompt does not replace the requirement for written authorization.

## 🛡️ Security & responsible use

- Test only systems you own or are explicitly authorized to assess.
- Keep written authorization, target scope, allowed methods, timing, and stop conditions clear before testing.
- Review every command and its options; a launcher preview is not a safety certification.
- Do not use NetLauncher to cause service disruption, evade detection, access data without permission, or perform unauthorized credential attacks.
- Do not store passwords, API tokens, private keys, session cookies, or other secrets in the repository, workspace, findings, or logs.
- Treat logs, packet captures, scanner output, and reports as sensitive. Review and redact them before sharing.
- NetLauncher does not offer a flood/stress-attack script or automated SYN-flood workflow. For capacity testing, use a controlled load-testing plan and tooling configured with explicit rate, duration, monitoring, and stop limits in an isolated environment.

### Local data

Application data is stored locally by default:

```text
~/.local/share/netlauncher/       logs, history, project profiles, findings
~/.cache/netlauncher/             cache
~/laporan/                        generated reports (configurable)
```

Sensitive runtime files are intended to use restrictive permissions. The directory locations can be affected by XDG environment variables and NetLauncher configuration. Check your local settings before assuming a path or sharing an output file.

## 🧩 Optional repository scanners

`repo-scan` can call Gitleaks, Trivy, and Semgrep **only when already installed**. It does not install dependencies. Scanner behavior and output schemas can vary by version; inspect the generated reports and verify results manually. Repository scanning can expose sensitive paths or findings, so keep reports private.

Check availability with:

```bash
netlauncher doctor
command -v gitleaks trivy semgrep
```

Install optional tools only from their official sources and follow their license and installation guidance.

## 🛠️ Development

```bash
cd ~/tools/netlauncher
make syntax       # Bash syntax validation
make smoke        # non-interactive smoke tests
make check        # syntax + smoke tests
make lint         # registry validation and ShellCheck when available
make ui-test      # basic UI tests; requires tmux
```

Before contributing, read [`AGENTS.md`](AGENTS.md), [`MEMORY.md`](MEMORY.md), and the documentation in [`docs/`](docs/).

### Repository layout

```text
bin/netlauncher        CLI entry point and interactive menu loop
lib/*.sh               Modular UI, registry, runner, knowledge, and workflow logic
config/tools.tsv       Tool registry (pipe-delimited)
config/snippets.tsv    Curated command examples (tab-delimited)
config/flags.tsv       Curated flag reference (tab-delimited)
config/guides/         Indonesian tool guides
config/flows/          Starter declarative workflows
config/automations/    Safe starter automation scripts
scripts/               Installer, backup, UI test, and shell completions
tests/smoke.sh         Non-interactive test suite
docs/                  Architecture, development guide, roadmap, changelog
```

### Contribution checklist

1. Keep changes modular and consistent with the existing Bash style.
2. Preserve authorized-use safeguards and confirmation gates for impactful actions.
3. Never add secrets, offensive automation, or unapproved dependencies.
4. Update user help and documentation when CLI behavior changes.
5. Run `make check` and `make lint`; run `make ui-test` when changing navigation or UI.

## 🗺️ Roadmap & project docs

- [Architecture](docs/ARCHITECTURE.md)
- [Development guide](docs/DEVELOPMENT.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](docs/CHANGELOG.md)
- [Contributor instructions](AGENTS.md)

See the roadmap for planned work; the `2.2.0-dev` features described above are under development and are not a stable release commitment.

## 📄 License

This repository currently does not declare a public software license. Unless a license is added, do not assume that redistribution, modification, or commercial use is permitted. Third-party tools and wordlists retain their own licenses; check those terms independently. Do not redistribute third-party wordlists without verifying their licenses.

---

<div align="center">

**Built for focused, authorized, local-first workflows.**

<sub>NetLauncher · terminal-first · Indonesian-first · security-conscious</sub>

</div>
