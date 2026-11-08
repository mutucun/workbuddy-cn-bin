# workbuddy-cn-bin

WorkBuddy **国内版**（`workbuddy.cn`）的 Arch Linux 安装包，基于官方 Debian 包重打包。

- 包名：`workbuddy-cn-bin`
- 上游版本：`5.6.2.40046327_c7b525f3`（官方 Linux 包发布于 2026-09-30）
- 安装位置：`/opt/WorkBuddy/`
- 启动命令：`workbuddy-cn`

> **非官方打包**。本项目与腾讯无关，不提供任何担保。WorkBuddy 是腾讯的闭源商业软件，
> 本仓库只做「把官方 `.deb` 装进 Arch 的 pacman 体系」这一件事。

---

## 为什么会有这个包

历史上 WorkBuddy 没有 Linux 客户端，社区只能拿 macOS 的 `.dmg` 解包，再用
`electron-rebuild` 重编译 `sqlite3` / `spdlog`，并强制 X11 才能启动——那条路线非常脆。

**现在官方已经提供 Linux 原生包**：

| 格式 | 架构 | 地址 |
|---|---|---|
| `.deb` | x86_64 | `https://download.codebuddy.cn/workbuddy/saas/linux-x64-deb/` |
| `.deb` | aarch64 | `https://download.codebuddy.cn/workbuddy/saas/linux-arm64-deb/` |
| `.rpm` | x86_64 | `https://download.codebuddy.cn/workbuddy/saas/linux-x64-rpm/` |

所以本包走的是**最干净的路线**：下载官方 `.deb` → 展开 `data.tar.xz` → 装到 `/opt`。
**不需要 `electron-rebuild`**，也不需要自己编译任何原生模块（包内 `better_sqlite3.node`
等已是 ELF x86-64）。

官方更新接口（用于查最新版本）：

```bash
curl 'https://copilot.tencent.com/v2/update?platform=workbuddy-linux-x64-deb'
```

---

## 打包时核实过的实现细节

以下结论来自对 `resources/app.asar`（v5.6.2）的静态分析，**不是推测**，改动本包时可据此判断：

| 结论 | 依据 |
|---|---|
| 自带 Electron **37.10.3**，原生模块已是 ELF，**无需 electron-rebuild** | `/opt/WorkBuddy/version`、`file better_sqlite3.node` |
| 应用**没有**任何 Wayland 自适应逻辑 → 强制 X11 是必需的，不是保守选择 | `main/index.js` 里 `wayland` 只出现在 GPU 降级的注释中 |
| `WM_CLASS = workbuddy` | `deriveLinuxWmClass()` 取 `asciiSlug(applicationName).toLowerCase()`，而 `applicationName = WorkBuddy` |
| Linux 下**不**追加 `--no-sandbox`（只有 Windows 加） | `appendSwitch("no-sandbox")` 被 `process.platform === "win32"` 包住 |
| 数据目录 `~/.workbuddy`，userData `~/.workbuddy/app` | `product.json#dataFolderName`、`main/runtime-paths.js` |
| 内置 GPU 崩溃降级，24h 自动恢复 | `main/desktop-monitor-service.js#gpu-degradation` |

---

## 安装

### 从本仓库构建

```bash
git clone https://github.com/mutucun/workbuddy-cn-bin.git
cd workbuddy-cn-bin
makepkg -si
```

### 用 AUR helper（仅在本包已发布到 AUR 时可用）

```bash
yay -S workbuddy-cn-bin
```

### 启动

```bash
workbuddy-cn
```

或在应用菜单里找 **WorkBuddy（国内版）**。

---

## 与 AUR 现有包的关系

AUR 上已有两个同样打包国内版的包：`workbuddy`、`workbuddy-agent`。
三者安装路径都是 `/opt/WorkBuddy`，**不能共存**，因此本包声明了
`conflicts=('workbuddy' 'workbuddy-agent')` 并 `provides=('workbuddy')`。

如果你只是想让 WorkBuddy 跑起来，直接装 AUR 的 `workbuddy` 也行；
本包的区别在于：真实 sha256 校验（不用 `SKIP`）、独立的 `workbuddy-cn` 启动器、
`workbuddy-cn` 命名的图标、以及不依赖 `electron` 这个系统包。

---

## 已知问题

### 1. 必须强制 X11（Wayland 会崩）

Electron 在 niri 这类纯 Wayland 合成器下走 Ozone/Wayland 后端会触发协议层崩溃
（启动即退或白屏）。本包已经在两处强制 X11：

- `workbuddy-cn.sh`：`ELECTRON_OZONE_PLATFORM_HINT=x11`
- `workbuddy-cn.desktop`：`Exec=env ELECTRON_OZONE_PLATFORM_HINT=x11 ...`

需要 XWayland 可用（`xorg-xwayland`）。想自己试 Wayland 后端：

```bash
ELECTRON_OZONE_PLATFORM_HINT=wayland workbuddy-cn
```

⏳ **本包的 GUI 启动尚未验证**（构建机无图形会话），首次运行请留意终端输出。

### 2. 应用内自动更新不可用

Electron 的 `autoUpdater` 只实现于 macOS / Windows，Linux 上没有对应后端；包内也没有
`app-update.yml`。**请始终通过 pacman 更新**（`yay -Syu`），不要指望应用内「检查更新」。
另外 `/opt/WorkBuddy` 属 pacman 管理、普通用户不可写，任何试图自更新的行为都会失败。

### 3. 版本落后于 macOS / Windows

| 平台 | 版本 |
|---|---|
| Linux | 5.6.2.40046327（2026-09-30） |
| macOS | 5.9.3.42398134 |

Linux 包由官方维护，但发版节奏明显慢于 macOS。这是上游行为，不是打包问题。

### 4. 托盘图标可能不显示

需要 `libappindicator`（已列为 optdepends）。GNOME 还需要
`gnome-shell-extension-appindicator`。

### 5. 白屏 / 花屏

应用**自带 GPU 降级机制**（`main/desktop-monitor-service.js` 中的 `gpu-degradation`）：
检测到上次运行发生 GPU 进程崩溃后，下次启动会自动 `disableHardwareAcceleration()`，
24 小时后自动恢复。所以偶发白屏重启一次通常就好了。

如果持续白屏，手动强制禁用：

```bash
workbuddy-cn --disable-gpu
```

若报 `The SUID sandbox helper binary was found, but is not configured correctly`，
说明内核未启用非特权 user namespace。**不要**用 `--no-sandbox` 长期绕过，
正确的做法是启用 userns：

```bash
sysctl kernel.unprivileged_userns_clone   # 应为 1
```

### 6. 配置目录

国内版**不使用** Electron 默认的 `~/.config/WorkBuddy`。应用启动时会
`app.setPath('userData', ...)` 重定向（见 `main/desktop-monitor-service.js`），实际位置是：

| 用途 | 路径 |
|---|---|
| 数据目录（`product.json#dataFolderName = .workbuddy`） | `~/.workbuddy/` |
| Electron userData | `~/.workbuddy/app/` |
| 日志 | `~/.workbuddy/logs/` |

可用环境变量覆盖，便于开多套独立配置：

```bash
WORKBUDDY_CONFIG_DIR=~/.workbuddy-cn-test workbuddy-cn
```

### 7. 与国际版共存

国际版（AUR `workbuddy-international-bin`）用自己的 `/opt/workbuddy-international`，
两者安装路径不冲突，但会争抢 `x-scheme-handler/workbuddy` 的 MIME 关联
（后装的覆盖先装的）。需要同时用两套时，用上面的 `WORKBUDDY_CONFIG_DIR`
把配置隔离开，避免登录态互相覆盖。

⏳ 国际版的 `dataFolderName` 未核实，不确定两者默认数据目录是否已经分离。

---

## 更新本包

1. 查最新版本：

   ```bash
   curl -s 'https://copilot.tencent.com/v2/update?platform=workbuddy-linux-x64-deb'
   ```

2. 改 `PKGBUILD` 顶部的 `_pkgver` / `_build`（URL 里的
   `WorkBuddy-linux-x64-deb-<版本>-<commit>.deb` 两段）。
3. 重算校验和：

   ```bash
   updpkgsums
   ```

4. 重新生成 `.SRCINFO`：

   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

> `sha256sums` 里前两项是仓库内的 `workbuddy-cn.sh` 与 `workbuddy-cn.desktop`；
> 改这两个文件后同样要跑 `updpkgsums`。

---

## 免责声明

- 本项目**非官方**，与腾讯控股有限公司及其关联公司无任何关系。
- `WorkBuddy` 及相关商标、著作权归腾讯所有。
- 本仓库仅包含打包脚本，**不重新分发**应用二进制；构建时从官方 CDN 下载。
- 使用本包造成的任何问题（数据丢失、账号异常、服务条款风险）由使用者自行承担。
- 官方未声明支持 Arch Linux，上游随时可能改动包结构导致本包失效。

## 许可证

打包脚本（`PKGBUILD`、`workbuddy-cn.sh`、`workbuddy-cn.desktop`）以 MIT 发布。
应用本体为闭源商业软件，适用其自身许可条款。
