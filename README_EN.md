# OpenProxifier

[English](README_EN.md) | [中文](README.md)

A Windows transparent SOCKS5/HTTP proxy tool that routes target application traffic through a proxy server, without modifying the target program or system proxy settings.

## Features

- **WinDivert Mode**: Kernel-level packet interception for true transparent proxy
- **Rule-Based Routing**: Per-process rules (PROXY / DIRECT / BLOCK) with per-rule proxy override
- **SOCKS5 & HTTP Proxy**: Supports both SOCKS5 and HTTP CONNECT proxy protocols
- **SOCKS5 Authentication**: Username/password authentication (RFC 1929)
- **CLI Tool**: Ideal for headless servers and service deployments (e.g., AlwaysUp)
- **Qt GUI**: System tray, connection testing, bilingual UI (EN/CN)
- **DLL Injection Mode**: Hook Winsock APIs for legacy application compatibility

## How It Works

```
OpenProxifier (CLI / GUI)
        |
        | WinDivert kernel driver
        v
Network Packets <---> PacketProcessor
        |
        | NAT redirect to LocalProxy
        v
LocalProxy (TCP:34010)
        |
        | SOCKS5/HTTP tunnel
        v
Proxy Server --> Internet
```

## Requirements

- Windows 10/11 (64-bit)
- Administrator privileges (required for WinDivert)

## Quick Start: CLI

The CLI is a pure C program with no Qt dependency, ideal for service-based deployment.

### Download

Get the pre-built package `OpenProxifierCLI-x64.zip` from the `dist/` directory. Contents:
- `OpenProxifierCLI.exe` - Main program
- `WinDivert64.sys` / `WinDivert.dll` - WinDivert driver

### Command Line Syntax

```
OpenProxifierCLI.exe [options]
```

#### Options

| Option | Description |
|--------|-------------|
| `--proxy <url>` | Set proxy server. Format: `socks5://host:port`, `http://host:port`, `socks5://user:pass@host:port` |
| `--rule <rule>` | Add a routing rule (can be specified multiple times) |
| `--dns-direct` | Route DNS queries directly (default: via proxy) |
| `--verbose` | Show all connection logs (default: only PROXY/BLOCK) |
| `-h, --help` | Show help |

#### Rule Format

```
process:hosts:ports:protocol:action
```

| Field | Description | Example |
|-------|-------------|---------|
| process | Process filename, supports wildcards | `chrome.exe`, `*.exe`, `*` |
| hosts | Target IP addresses, supports wildcards | `*` (all), `192.168.*.*` |
| ports | Port numbers, supports multiple and ranges | `*`, `80`, `80;443`, `8000-9000` |
| protocol | `TCP`, `UDP`, or `BOTH` | `TCP` |
| action | See table below | `PROXY` |

**Action Types:**

| Action | Description |
|--------|-------------|
| `PROXY` | Forward via the global proxy set by `--proxy` |
| `DIRECT` | Direct connection, bypass proxy |
| `BLOCK` | Block all connections |
| `socks5://host:port` | Forward via specified SOCKS5 proxy (overrides global) |
| `http://host:port` | Forward via specified HTTP proxy |

### Examples

**Basic - proxy a specific process:**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY"
```

**Multiple processes + multiple rules:**
```batch
OpenProxifierCLI.exe ^
  --proxy socks5://127.0.0.1:1081 ^
  --rule "raidrive.mount.exe:*:*:TCP:PROXY" ^
  --rule "raidrive.mount.service.x64.exe:*:*:TCP:PROXY" ^
  --rule "update.exe:*:*:TCP:BLOCK"
```

**Per-rule proxy override:**
```batch
OpenProxifierCLI.exe ^
  --rule "chrome.exe:*:*:TCP:socks5://127.0.0.1:1081" ^
  --rule "firefox.exe:*:*:TCP:socks5://127.0.0.1:1082"
```

**Proxy with authentication:**
```batch
OpenProxifierCLI.exe --proxy socks5://user:pass@127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY"
```

**Proxy specific ports only:**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "app.exe:*:80;443:TCP:PROXY"
```

**Proxy all processes:**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "*:*:*:TCP:PROXY"
```

**Debug mode (show all connections):**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY" --verbose
```

## GUI Application

The GUI requires Qt 6.x and provides system tray, connection testing, and rule management.

### Usage

1. Launch `OpenProxifier_x64.exe` **as Administrator**
2. Configure SOCKS5/HTTP proxy settings
3. Click "Test Connection" to verify proxy connectivity
4. Add target process names with desired action (PROXY / DIRECT / BLOCK)
5. Click "Start Monitoring"

### Example: Configure Proxy for Antigravity

| Process | Description |
|---------|-------------|
| `Antigravity.exe` | Main application |
| `inno_updater.exe` | Updater |
| `language_server_windows_x64.exe` | Language server |

![Antigravity Example](docs/antigravity_example.png)

## Building from Source

### CLI Only (No Qt Required)

```batch
cmake -B build_cli -A x64 -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake --toolchain build_cli.cmake
cmake --build build_cli --config Release
```

Output: `build_cli/Release/OpenProxifierCLI.exe`

### Full Project (CLI + GUI)

Requires Qt 6.x and vcpkg (for Microsoft Detours):

```batch
vcpkg install detours:x64-windows
cmake -B build -A x64 -DCMAKE_PREFIX_PATH=C:/Qt/6.x/msvc2022_64 -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

Output files in `build/bin/Release/`:
- `OpenProxifier_x64.exe` - GUI application
- `OpenProxifierCLI_x64.exe` - CLI tool
- `OpenProxifierHook_x64.dll` - DLL injection hook
- `ProxyTestApp.exe` - Proxy test tool

## Project Structure

```
OpenProxifier/
├── core/               # WinDivert transparent proxy engine (pure C)
│   ├── ProxyEngine.*   # Main engine interface
│   ├── PacketProcessor.* # Packet interception and NAT
│   ├── LocalProxy.*    # Local SOCKS5/HTTP tunnel proxy
│   ├── RuleEngine.*    # Rule engine
│   ├── ConnectionTracker.* # Connection tracking
│   ├── ProcessTracker.* # Per-process PID tracking
│   ├── Socks5.*        # SOCKS5 protocol
│   └── UdpRelay.*      # UDP relay (experimental)
├── cli/                # CLI tool (pure C, no Qt dependency)
├── launcher/           # Qt GUI application
│   ├── MainWindow.*    # Main window
│   ├── ProxyEngineWrapper.*  # C++/C bridge
│   ├── Injector.*      # DLL injection
│   └── resources/      # Icons and resources
├── hookdll/            # DLL injection hook library
├── proxytestapp/       # Proxy test app (Qt)
├── common/             # Shared headers
├── windivert/          # WinDivert driver and libraries (x86/x64)
├── scripts/            # Build and install scripts
├── build_cli.cmake     # Standalone CLI build script
└── docs/               # Documentation and screenshots
```

## Technical Details

- WinDivert 2.2 for kernel-level packet capture
- Bidirectional NAT for transparent redirection, LocalProxy on TCP 34010
- Per-process rule matching via PID tracking
- SOCKS5 (RFC 1928) + username/password auth (RFC 1929)
- HTTP CONNECT proxy support

## Known Limitations

- Requires Administrator privileges
- UDP proxying is experimental

## License

Apache-2.0

## Acknowledgments

- [WinDivert](https://github.com/basil00/WinDivert) - Windows packet capture/modification library
- [Microsoft Detours](https://github.com/microsoft/Detours) - API hooking library
- [Qt Framework](https://www.qt.io/) - GUI framework
