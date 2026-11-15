#!/usr/bin/env bash
# ============================================================
#  在 macOS 上生成 XCL 的未签名 IPA（用于 Sideloadly / AltStore / TrollStore）
#  依赖: Xcode 15+, XcodeGen (brew install xcodegen)
#  用法: cd apple/ios && ./build_ios_ipa.sh
# ============================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BUILD="$HERE/build"
SCHEME="XCL"

echo "== 1/6 准备内置页面 =="
mkdir -p "$HERE/Resources"
if [ -f "$ROOT/android/assets/index.html" ]; then
  cp "$ROOT/android/assets/index.html" "$HERE/Resources/index.html"
  echo "   已复制 android/assets/index.html"
else
  echo "   缺少 index.html（可先用最小页面占位）"
  printf '<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><h2>XCL iOS</h2><p>页面资源缺失</p>' > "$HERE/Resources/index.html"
fi

echo "== 2/6 生成 Xcode 工程 =="
command -v xcodegen >/dev/null 2>&1 || { echo "请先安装: brew install xcodegen"; exit 1; }
cd "$HERE"
xcodegen generate

echo "== 3/6 编译（无签名, 供 sideload） =="
xcodebuild -project XCL.xcodeproj -scheme "$SCHEME" -configuration Release \
  -sdk iphoneos -derivedDataPath "$BUILD/DerivedData" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build

echo "== 4/6 组装 Payload =="
APP="$(find "$BUILD/DerivedData/Build/Products/Release-iphoneos" -maxdepth 1 -name '*.app' | head -n1)"
[ -n "$APP" ] || { echo "未找到 .app 产物"; exit 1; }
rm -rf "$BUILD/Payload" "$BUILD/XCL.ipa"
mkdir -p "$BUILD/Payload"
cp -R "$APP" "$BUILD/Payload/"

echo "== 5/6 打包 IPA =="
cd "$BUILD"
zip -qry XCL.ipa Payload
SIZE=$(du -h XCL.ipa | cut -f1)
echo "   产物: $BUILD/XCL.ipa ($SIZE)"

echo "== 6/6 校验 =="
unzip -l XCL.ipa | head -n 10
shasum -a 256 XCL.ipa

echo
echo "安装方式：Sideloadly / AltStore 自签，或 TrollStore 直接安装。"
