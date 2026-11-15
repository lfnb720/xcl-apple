#!/usr/bin/env bash
# ============================================================
#  在 macOS 上生成 XCL 的未签名 IPA（Sideloadly / AltStore / TrollStore 用）
#  依赖: Xcode 15+, XcodeGen (brew install xcodegen)
#  内容: 下载 iOS 版 OpenJDK 8 Zero (arm64, 无 JIT) 并打进 App
#  用法: cd apple/ios && ./build_ios_ipa.sh
# ============================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BUILD="$HERE/build"
SCHEME="XCL"
RES="$HERE/Resources"

JRE_URL_PRIMARY="https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre8-99f3f8b/jre8-zero-aarch64-ios.tar.xz"
JRE_URL_FALLBACK="https://ghfast.top/https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre8-99f3f8b/jre8-zero-aarch64-ios.tar.xz"

mkdir -p "$RES"

echo "== 1/7 内置页面与冒烟 jar =="
if [ -f "$ROOT/android/assets/index.html" ]; then
  cp "$ROOT/android/assets/index.html" "$RES/index.html"
fi
if [ -f "$ROOT/android/assets/smoke.jar" ]; then
  cp "$ROOT/android/assets/smoke.jar" "$RES/smoke.jar"
fi

echo "== 2/7 准备 iOS JRE（首次会下载 42 MB） =="
if [ ! -f "$RES/jre8/lib/server/libjvm.dylib" ]; then
  TARBALL="$RES/jre8.tar.xz"
  rm -rf "$RES/jre8" "$RES/_jre_tmp"
  echo "   下载: $JRE_URL_PRIMARY"
  curl -L --retry 3 --retry-delay 2 --max-time 900 -o "$TARBALL" "$JRE_URL_PRIMARY" || \
    curl -L --retry 3 --retry-delay 2 --max-time 900 -o "$TARBALL" "$JRE_URL_FALLBACK"
  echo "   解压..."
  mkdir -p "$RES/_jre_tmp"
  tar -xJf "$TARBALL" -C "$RES/_jre_tmp"
  # 归档内通常是 java-8-openjdk/ 一层, 取出真正根目录
  ROOTDIR="$(find "$RES/_jre_tmp" -maxdepth 2 -type d -name lib | head -n1 | xargs dirname)"
  if [ -z "$ROOTDIR" ] || [ ! -d "$ROOTDIR/lib" ]; then
    echo "   JRE 解压结构异常"; exit 1
  fi
  mv "$ROOTDIR" "$RES/jre8"
  rm -rf "$RES/_jre_tmp" "$TARBALL"
else
  echo "   已存在 jre8, 跳过下载"
fi
echo "   libjvm: $(ls -lh "$RES/jre8/lib/server/libjvm.dylib" | awk '{print $5}')"

echo "== 3/7 生成 Xcode 工程 =="
command -v xcodegen >/dev/null 2>&1 || { echo "请先安装: brew install xcodegen"; exit 1; }
cd "$HERE"
xcodegen generate

echo "== 4/7 编译（无签名, 供 sideload） =="
xcodebuild -project XCL.xcodeproj -scheme "$SCHEME" -configuration Release \
  -sdk iphoneos -derivedDataPath "$BUILD/DerivedData" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build

echo "== 5/7 组装 Payload =="
APP="$(find "$BUILD/DerivedData/Build/Products/Release-iphoneos" -maxdepth 1 -name '*.app' | head -n1)"
[ -n "$APP" ] || { echo "未找到 .app 产物"; exit 1; }
rm -rf "$BUILD/Payload" "$BUILD/XCL.ipa"
mkdir -p "$BUILD/Payload"
cp -R "$APP" "$BUILD/Payload/"

echo "== 6/7 打包 IPA =="
cd "$BUILD"
zip -qry XCL.ipa Payload
SIZE=$(du -h XCL.ipa | cut -f1)
echo "   产物: $BUILD/XCL.ipa ($SIZE)"

echo "== 7/7 校验 =="
unzip -l XCL.ipa | grep -E 'jre8/lib/server/libjvm.dylib|smoke.jar|Info.plist' | head -n 5 || true
shasum -a 256 XCL.ipa

echo
echo "安装: Sideloadly 自签, 或 TrollStore 直接安装。"
