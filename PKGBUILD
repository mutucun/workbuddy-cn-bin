# Maintainer: mutucun <mutucun@users.noreply.github.com>

_pkgver=5.6.2.40046327
_build=c7b525f3

pkgname=workbuddy-cn-bin
pkgver=${_pkgver}_${_build}
pkgrel=1
pkgdesc="腾讯 WorkBuddy 国内版 AI Agent 办公工具（非官方移植：官方 deb 重打包）"
arch=('x86_64' 'aarch64')
url="https://www.workbuddy.cn/"
license=('custom')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'gtk3'
  'libcups'
  'libdrm'
  'libnotify'
  'libsecret'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxi'
  'libxkbcommon'
  'libxrandr'
  'libxss'
  'libxtst'
  'mesa'
  'nss'
  'xdg-utils'
)
optdepends=(
  'libappindicator: 系统托盘图标'
  'gnome-shell-extension-appindicator: GNOME 下显示托盘图标'
  'imagemagick: 图片处理相关功能'
  'python-pip: Python 技能依赖'
  'nodejs: 前端技能依赖'
)
provides=('workbuddy')
conflicts=('workbuddy' 'workbuddy-agent')
options=(!strip !debug)

# 官方只提供 .deb / .rpm，没有 AppImage、tar 或 pacman 包。
# 版本号由官方更新接口给出：
#   https://copilot.tencent.com/v2/update?platform=workbuddy-linux-x64-deb
_x64deb="WorkBuddy-linux-x64-deb-${_pkgver}-${_build}.deb"
_aarch64deb="WorkBuddy-linux-arm64-deb-${_pkgver}-${_build}.deb"

source=(
  'workbuddy-cn.sh'
  'workbuddy-cn.desktop'
)
source_x86_64=("${_x64deb}::https://download.codebuddy.cn/workbuddy/saas/linux-x64-deb/${_x64deb}")
source_aarch64=("${_aarch64deb}::https://download.codebuddy.cn/workbuddy/saas/linux-arm64-deb/${_aarch64deb}")

sha256sums=('3a975c59323637a768db87ed4ee79386946963f6c5df31921f7c8b3fd417e372'
            '19036e33e8d742a5bf4a6447ef00be462e36c457c446dd17a1a8876948350672')
sha256sums_x86_64=('12149ad8c0cd748fd5062d8f62c7827d688d8095427ada99b1ae9e7019897523')
sha256sums_aarch64=('561822578435d382a06d0a0b079a4b157f68b588c9fe72d589e2a88b2fd155fa')

prepare() {
  # makepkg 对 .deb 走 bsdtar 兜底，$srcdir 下已有 debian-binary / control.tar.xz / data.tar.xz。
  # 这里只展开 data 部分，control 里的 postinst/prerm 是 Debian 专用（update-alternatives、
  # 杀进程逻辑），在 Arch 上由 pacman 负责，不引入。
  tar -xf data.tar.xz
}

package() {
  install -d "${pkgdir}/opt/WorkBuddy"
  cp -a opt/WorkBuddy/. "${pkgdir}/opt/WorkBuddy/"

  install -Dm755 "${srcdir}/workbuddy-cn.sh" "${pkgdir}/usr/bin/workbuddy-cn"
  install -Dm644 "${srcdir}/workbuddy-cn.desktop" \
    "${pkgdir}/usr/share/applications/workbuddy-cn.desktop"

  # 图标取自官方包内的 hicolor 各尺寸，改名 workbuddy-cn 以免与 AUR workbuddy 冲突。
  local size
  for size in 16 24 32 48 64 96 128 256 512; do
    install -Dm644 "usr/share/icons/hicolor/${size}x${size}/apps/workbuddy.png" \
      "${pkgdir}/usr/share/icons/hicolor/${size}x${size}/apps/workbuddy-cn.png"
  done

  # 应用本体为闭源商业软件，包内只附带 Electron / Chromium 的许可证文本。
  install -Dm644 opt/WorkBuddy/LICENSE.electron.txt \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE.electron.txt"
  install -Dm644 opt/WorkBuddy/LICENSES.chromium.html \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSES.chromium.html"
}
