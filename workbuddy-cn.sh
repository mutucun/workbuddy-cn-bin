#!/bin/sh
# WorkBuddy 国内版启动器
#
# 为什么默认强制 X11：
#   Electron 在 niri（纯 Wayland）等环境下走 Ozone/Wayland 后端会触发协议层
#   崩溃（启动即退出或白屏）。经 XWayland 走 X11 后端可正常工作。
#   如需自行测试 Wayland 后端，可显式覆盖：
#     ELECTRON_OZONE_PLATFORM_HINT=wayland workbuddy-cn
: "${ELECTRON_OZONE_PLATFORM_HINT:=x11}"
export ELECTRON_OZONE_PLATFORM_HINT

exec /opt/WorkBuddy/workbuddy "$@"
