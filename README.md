# OpenProxifier

[English](README_EN.md) | [中文](README.md)

Windows 透明 SOCKS5/HTTP 代理工具。将目标应用程序的网络连接通过代理路由，无需修改目标程序或系统代理设置。

## 功能特性

- **WinDivert 模式**：内核级数据包拦截，实现真正的透明代理
- **规则路由**：为不同进程配置不同规则（代理 / 直连 / 阻止），支持为每条规则指定独立代理
- **SOCKS5 & HTTP 代理**：支持 SOCKS5 和 HTTP CONNECT 代理协议
- **SOCKS5 认证**：支持用户名/密码认证（RFC 1929）
- **CLI 命令行工具**：无头服务器、服务化部署（如 AlwaysUp）的理想选择
- **Qt GUI 图形界面**：系统托盘、连接测试、双语界面
- **DLL 注入模式**：通过 Hook Winsock API 兼容旧版应用

## 工作原理

```
OpenProxifier (CLI / GUI)
        |
        | WinDivert 内核驱动
        v
网络数据包 <---> PacketProcessor
        |
        | NAT 重定向到 LocalProxy
        v
LocalProxy (TCP:34010)
        |
        | SOCKS5/HTTP 隧道
        v
代理服务器 --> 互联网
```

## 系统要求

- Windows 10/11（64位）
- 管理员权限（WinDivert 模式必需）

## 快速开始：CLI

CLI 是纯 C 程序，无 Qt 依赖，适合服务化部署。

### 下载

从 `dist/` 目录获取预编译包 `OpenProxifierCLI-x64.zip`，解压后包含：
- `OpenProxifierCLI.exe` - 主程序
- `WinDivert64.sys` / `WinDivert.dll` - WinDivert 驱动

### 命令行语法

```
OpenProxifierCLI.exe [options]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `--proxy <url>` | 设置代理服务器，格式：`socks5://host:port`、`http://host:port`、`socks5://user:pass@host:port` |
| `--rule <rule>` | 添加路由规则（可多次使用） |
| `--dns-direct` | DNS 查询走直连（默认走代理） |
| `--verbose` | 显示所有连接日志（默认只显示 PROXY/BLOCK） |
| `-h, --help` | 显示帮助 |

#### 规则格式

```
进程名:目标IP:目标端口:协议:动作
```

| 字段 | 说明 | 示例 |
|------|------|------|
| 进程名 | 进程文件名，支持通配符 | `chrome.exe`、`*.exe`、`*` |
| 目标IP | 目标地址，支持通配符 | `*`（全部）、`192.168.*.*` |
| 目标端口 | 端口号，支持多端口和范围 | `*`、`80`、`80;443`、`8000-9000` |
| 协议 | `TCP`、`UDP` 或 `BOTH` | `TCP` |
| 动作 | 见下表 | `PROXY` |

**动作类型：**

| 动作 | 说明 |
|------|------|
| `PROXY` | 通过 `--proxy` 指定的全局代理转发 |
| `DIRECT` | 直连，不走代理 |
| `BLOCK` | 阻止所有连接 |
| `socks5://host:port` | 通过指定的 SOCKS5 代理转发（覆盖全局代理） |
| `http://host:port` | 通过指定的 HTTP 代理转发 |

### 使用示例

**基本用法 - 为特定进程设置代理：**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY"
```

**多进程 + 多规则：**
```batch
OpenProxifierCLI.exe ^
  --proxy socks5://127.0.0.1:1081 ^
  --rule "raidrive.mount.exe:*:*:TCP:PROXY" ^
  --rule "raidrive.mount.service.x64.exe:*:*:TCP:PROXY" ^
  --rule "update.exe:*:*:TCP:BLOCK"
```

**为每条规则指定不同的代理：**
```batch
OpenProxifierCLI.exe ^
  --rule "chrome.exe:*:*:TCP:socks5://127.0.0.1:1081" ^
  --rule "firefox.exe:*:*:TCP:socks5://127.0.0.1:1082"
```

**带认证的代理：**
```batch
OpenProxifierCLI.exe --proxy socks5://user:pass@127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY"
```

**仅代理特定端口：**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "app.exe:*:80;443:TCP:PROXY"
```

**代理所有进程：**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "*:*:*:TCP:PROXY"
```

**调试模式（查看所有连接）：**
```batch
OpenProxifierCLI.exe --proxy socks5://127.0.0.1:1081 --rule "chrome.exe:*:*:TCP:PROXY" --verbose
```

## 图形界面（GUI）

GUI 需要 Qt 6.x 环境，提供系统托盘、连接测试、规则管理等功能。

### 使用方法

1. **以管理员身份**启动 `OpenProxifier_x64.exe`
2. 配置 SOCKS5/HTTP 代理设置
3. 点击"测试连接"验证代理连通性
4. 添加目标进程名称，选择动作（代理 / 直连 / 阻止）
5. 点击"开始监控"

### 示例：为 Antigravity 配置代理

| 进程名 | 说明 |
|--------|------|
| `Antigravity.exe` | 主程序 |
| `inno_updater.exe` | 更新程序 |
| `language_server_windows_x64.exe` | 语言服务器 |

![Antigravity示例](docs/antigravity_example.png)

## 从源码构建

### 仅构建 CLI（无需 Qt）

```batch
cmake -B build_cli -A x64 -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake --toolchain build_cli.cmake
cmake --build build_cli --config Release
```

输出：`build_cli/Release/OpenProxifierCLI.exe`

### 构建完整项目（CLI + GUI）

需要 Qt 6.x 和 vcpkg（用于 Microsoft Detours）：

```batch
vcpkg install detours:x64-windows
cmake -B build -A x64 -DCMAKE_PREFIX_PATH=C:/Qt/6.x/msvc2022_64 -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

输出文件位于 `build/bin/Release/`：
- `OpenProxifier_x64.exe` - GUI 主程序
- `OpenProxifierCLI_x64.exe` - CLI 工具
- `OpenProxifierHook_x64.dll` - DLL 注入模式 Hook
- `ProxyTestApp.exe` - 代理测试工具

## 项目结构

```
OpenProxifier/
├── core/               # WinDivert 透明代理引擎（纯 C）
│   ├── ProxyEngine.*   # 主引擎接口
│   ├── PacketProcessor.* # 数据包拦截和 NAT
│   ├── LocalProxy.*    # 本地 SOCKS5/HTTP 隧道代理
│   ├── RuleEngine.*    # 规则引擎
│   ├── ConnectionTracker.* # 连接跟踪
│   ├── ProcessTracker.* # 进程 PID 跟踪
│   ├── Socks5.*        # SOCKS5 协议
│   └── UdpRelay.*      # UDP 中继（实验性）
├── cli/                # CLI 命令行工具（纯 C，无 Qt 依赖）
├── launcher/           # Qt GUI 应用程序
│   ├── MainWindow.*    # 主窗口
│   ├── ProxyEngineWrapper.*  # C++/C 桥接层
│   ├── Injector.*      # DLL 注入
│   └── resources/      # 图标、资源文件
├── hookdll/            # DLL 注入模式 Hook 库
├── proxytestapp/       # 代理测试应用（Qt）
├── common/             # 共享头文件
├── windivert/          # WinDivert 驱动和库（x86/x64）
├── scripts/            # 构建和安装脚本
├── build_cli.cmake     # CLI 独立构建脚本
└── docs/               # 文档和截图
```

## 技术细节

- WinDivert 2.2 内核级数据包捕获
- 双向 NAT 透明重定向，LocalProxy 监听 TCP 34010
- 按进程 PID 匹配规则
- SOCKS5 (RFC 1928) + 用户名/密码认证 (RFC 1929)
- HTTP CONNECT 代理支持

## 已知限制

- 需要管理员权限
- UDP 代理为实验性功能

## 许可证

Apache-2.0

## 致谢

- [WinDivert](https://github.com/basil00/WinDivert) - Windows 数据包捕获/修改库
- [Microsoft Detours](https://github.com/microsoft/Detours) - API 钩子库
- [Qt Framework](https://www.qt.io/) - GUI 框架
