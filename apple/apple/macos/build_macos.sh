#!/usr/bin/env bash
# ============================================================
#  在 macOS 上构建 XCL 桌面版（Universal: arm64 + x86_64）
#  依赖: Xcode Command Line Tools, CMake, Ninja, Qt 6 (brew install qt)
#  用法: cd apple/macos && ./build_macos.sh
# ============================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
QT="${QT_ROOT:-$(brew --prefix qt 2>/dev/null || echo /opt/homebrew/opt/qt)}"
BUILD="$ROOT/build-macos"
DIST="$ROOT/dist/XCL-macos"

echo "== 1/4 配置（Qt: $QT） =="
cmake -S "$ROOT" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DQT_ROOT="$QT"

echo "== 2/4 编译 =="
cmake --build "$BUILD"

echo "== 3/4 打包 .app（macdeployqt） =="
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$BUILD/XCL.app" "$DIST/" 2>/dev/null || { echo "未找到 XCL.app（检查 CMake 的 MACOSX_BUNDLE 配置）"; exit 1; }
"$QT/bin/macdeployqt" "$DIST/XCL.app" -always-overwrite -dmg 2>/dev/null || \
  "$QT/bin/macdeployqt" "$DIST/XCL.app" -always-overwrite

echo "== 4/4 生成压缩包 =="
cd "$DIST"
zip -qry "$ROOT/XCL-macos.zip" .
shasum -a 256 "$ROOT/XCL-macos.zip"
echo "产物: $ROOT/XCL-macos.zip"
