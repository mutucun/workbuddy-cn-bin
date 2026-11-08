# workbuddy-cn-bin

> [!success] 2026-11-08 更新：已默认使用原生 Wayland，修复了 `Ctrl+V` 粘贴错误的 Bug。

WorkBuddy **国内版**（`workbuddy.cn`）的 Arch Linux 安装包，基于官方 Debian 包重打包。

- 包名：`workbuddy-cn-bin`
- 上游版本：见 `PKGBUILD` 中的 `_pkgver` / `_build`（自动更新）
- 安装位置：`/opt/WorkBuddy/`
- 启动命令：`workbuddy-cn`
- 状态：**✅ 可用** —— 已在 Arch Linux + niri（Wayland）下实测：`makepkg -si` 构建、启动、登录全部通过；默认以原生 Wayland 运行

> **个人自用打包仓库。** 本仓库不发布到 AUR，也不维护 AUR 版本；安装方式只有「clone 下来自己构建」这一种。
>
> **非官方打包。** 本项目与腾讯无关，不提供任何担保。WorkBuddy 是腾讯的闭源商业软件，
> 本仓库只做「把官方 `.deb` 装进 Arch 的 pacman 体系」这一件事。

---

## 为什么会有这个包

历史上 WorkBuddy 没有 Linux 客户端，社区只能拿 macOS 的 `.dmg` 解包，再用
`electron-rebuild` 重编译 `sqlite3` / `spdlog`——那条路线非常脆，而且只能在 X11 后端下跑。

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
| 应用**没有**任何 Wayland 自适应逻辑 → 平台选择完全由启动器的参数决定 | `main/index.js` 里 `wayland` 只出现在 GPU 降级的注释中 |
| `WM_CLASS = workbuddy` | `deriveLinuxWmClass()` 取 `asciiSlug(applicationName).toLowerCase()`，而 `applicationName = WorkBuddy` |
| Linux 下**不**追加 `--no-sandbox`（只有 Windows 加） | `appendSwitch("no-sandbox")` 被 `process.platform === "win32"` 包住 |
| 数据目录 `~/.workbuddy`，userData `~/.workbuddy/app` | `product.json#dataFolderName`、`main/runtime-paths.js` |
| 内置 GPU 崩溃降级，24h 自动恢复 | `main/desktop-monitor-service.js#gpu-degradation` |

---

## 安装

只有一种方式：从本仓库构建。

```bash
git clone https://github.com/mutucun/workbuddy-cn-bin.git
cd workbuddy-cn-bin
makepkg -si
```

`makepkg -si` 会下载官方 `.deb`（约 410 MB）→ 校验 sha256 → 打包 → 用 pacman 安装。
构建产物体积约 498 MB，安装后占 1.7 GB。

### 启动

```bash
workbuddy-cn
```

或在应用菜单里找 **WorkBuddy（国内版）**。

---

## 与其他第三方包的关系

AUR 上已有 `workbuddy`、`workbuddy-agent` 等包也打包国内版，安装路径同样是
`/opt/WorkBuddy`，**与本包不能共存**。因此本包声明了
`conflicts=('workbuddy' 'workbuddy-agent')` 并 `provides=('workbuddy')`，
安装时会由 pacman 提示替换。

如果你已经在用其中的某一个，装本包前先移除即可；反过来的顺序也一样。

---

## 已解决的问题

### `Ctrl+V` 偶发粘出上一次复制的旧内容（2026-11-08 解决）

| 项 | 内容 |
|---|---|
| 现象 | 应用内按 `Ctrl+V` 偶发粘出上一次复制的旧文本（像是读到了 `PRIMARY` 选区的残留），右键 → 粘贴始终正常 |
| 根因 | 走 XWayland 时，`xwayland-satellite` 的 X11↔Wayland 选区桥接存在 owner 交接时序窗口：`CLIPBOARD` / `PRIMARY` 的所有权转移慢半拍，读取方可能拿到上一个 owner 的内容。与 WorkBuddy 自身的打包质量无关，同环境下的其它 Electron 应用同样可能复现 |
| 解决 | 改为原生 Wayland（`ELECTRON_OZONE_PLATFORM_HINT=auto`），应用不再经卫星进程做选区桥接，该链路被整体绕开 |
| 状态 | ✅ 2026-11-08 起正常 |

> 备注：Chromium 在 Wayland 下另有已知的 stale-read 问题
> （[electron#54645](https://github.com/electron/electron/issues/54645)：一直返回自己缓存的那份内容）。
> 若日后再次出现「粘出旧内容」，先确认是否属于这一类，再判断是不是本包的回归。

---

## 已知问题

### 1. 图形后端：原生 Wayland（2026-11-08 起）

**为什么换掉 XWayland。** 旧方案让 Electron 经 XWayland 以 X11 后端运行。这条链路上，
`xwayland-satellite` 需要在 X11 选区与 Wayland 选区之间做桥接，`CLIPBOARD` 与 `PRIMARY`
两个选区的 owner 交接存在时序窗口：读取方可能拿到上一个 owner 的内容，表现为按 `Ctrl+V`
偶发粘出上一次复制的旧文本，而右键 → 粘贴正常。改走原生 Wayland 后，应用直接作为
Wayland 客户端参与选区协商，这段桥接整体被绕开（详见下方「已解决的问题」）。

现在的默认行为：

| 位置 | 现在的值 |
|---|---|
| `workbuddy-cn.sh` | `ELECTRON_OZONE_PLATFORM_HINT=auto`（`:=` 默认值，可被环境变量覆盖） |
| `workbuddy-cn.desktop` | `Exec=/usr/bin/workbuddy-cn %U`（不带 `env` 前缀） |
| 传给 Electron 的附加参数 | `--enable-wayland-ime --wayland-text-input-version=3` |

`auto` 的语义（Chromium Ozone）：**Wayland 会话走原生 Wayland，X11 会话自动回落 X11**，
所以两种会话共用同一个包。注意 `--ozone-platform-hint` 的默认值直到 Chrome 140 才翻成
`auto`，本包是 Chrome 138，因此必须显式指定，不能依赖默认值。

**输入法**：`--enable-wayland-ime` 让 Chromium 通过 `text-input-v3` 接输入法；
`--wayland-text-input-version=3` 显式钉死协议版本（它目前就是默认值，写出来是防上游变更），
两者配合才能保证 **fcitx5 在原生 Wayland 下正常打字**（niri 26.04 实测可用）。

**回退预案（不需要重新打包）**：如果某个旧版 Electron 在原生 Wayland 下又出现白屏 / 闪退，
在终端用环境变量启动即可覆盖默认值：

```bash
ELECTRON_OZONE_PLATFORM_HINT=x11 workbuddy-cn
```

原理是 `workbuddy-cn.sh` 用的是 `:=`（仅在未设置时赋默认值），外部环境变量优先。
想永久回滚，把 `:=auto` 改回 `:=x11`，再走一遍
`updpkgsums` → `makepkg --printsrcinfo > .SRCINFO` → `makepkg -si`；
两个 `--wayland-*` 参数在 X11 后端下是空转，留不留都行，**不涉及任何依赖增删**。

### 2. 应用内自动更新不可用

Electron 的 `autoUpdater` 只实现于 macOS / Windows，Linux 上没有对应后端；包内也没有
`app-update.yml`。**不要指望应用内「检查更新」**，更新请走下面的「更新本包」。
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

> 若白屏**只在原生 Wayland 下**出现、切 X11 就正常，先按「1. 图形后端」里的回退预案
> 用 `ELECTRON_OZONE_PLATFORM_HINT=x11 workbuddy-cn` 启动再排查，不要先怀疑 GPU。

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

国际版（`workbuddy-international-bin`）装在 `/opt/workbuddy-international`，
两者安装路径不冲突，但会争抢 `x-scheme-handler/workbuddy` 的 MIME 关联
（后装的覆盖先装的）。需要同时用两套时，用上面的 `WORKBUDDY_CONFIG_DIR`
把配置隔离开，避免登录态互相覆盖。

⏳ 国际版的 `dataFolderName` 未核实，不确定两者默认数据目录是否已经分离（不影响本包单独使用）。

---

## 更新本包

上游发新版后，本地这样跟进：

1. 拉取本仓库最新改动：

   ```bash
   git pull
   ```

2. 查官方最新版本：

   ```bash
   curl -s 'https://copilot.tencent.com/v2/update?platform=workbuddy-linux-x64-deb'
   ```

3. 改 `PKGBUILD` 顶部的 `_pkgver` / `_build`（URL 里的
   `WorkBuddy-linux-x64-deb-<版本>-<commit>.deb` 两段）。

4. 重算校验和：

   ```bash
   updpkgsums
   ```

5. 重新生成 `.SRCINFO`：

   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

6. 重新构建安装：

   ```bash
   makepkg -si
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
