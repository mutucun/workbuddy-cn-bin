#!/bin/sh
# WorkBuddy 国内版启动器
#
# 平台选择默认 auto：Wayland 会话走原生 Wayland（Ozone/Wayland），X11 会话自动回落 X11。
# 2026-11-08 实测（niri 26.04 + 包内 Electron 37.10.3）：原生 Wayland 可正常启动，
# 无白屏/闪退；输入法需 --enable-wayland-ime（text-input-v3）。
# 若某版本在 Wayland 下出问题，回滚不必重打包：
#   ELECTRON_OZONE_PLATFORM_HINT=x11 workbuddy-cn
: "${ELECTRON_OZONE_PLATFORM_HINT:=auto}"
export ELECTRON_OZONE_PLATFORM_HINT

exec /opt/WorkBuddy/workbuddy \
  --enable-wayland-ime \
  --wayland-text-input-version=3 \
  "$@"
