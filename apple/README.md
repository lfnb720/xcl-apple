# XCL Apple 版（iOS / iPadOS / macOS）

> 目标：在 Apple 生态提供 XCL 启动器（iPhone / iPad / Mac，不含 Apple Watch）。
> 本文说明可行性边界、架构、构建方式，以及**为什么 IPA 必须在 macOS 上生成**。

## 一、必须先说清的现实约束

| 约束 | 说明 |
|---|---|
| **构建主机** | iOS/iPadOS 应用**只能**在 macOS + Xcode 上编译（Apple 的 SDK 仅随 Xcode 分发）。Windows 上的 `clang`/`cctools` 拼装无法链接 UIKit/SwiftUI，也无法产出可安装的 `.app`。 |
| **签名** | IPA 需要 Apple 开发者证书 + Provisioning Profile，或使用 sideload 工具（AltStore / TrollStore / Sideloadly）做自签。 |
| **App Store** | 本启动器会下载并执行第三方 Java 代码、内置 JVM，**不符合 App Store 审核规则**；只能 sideload / 企业分发。 |
| **JIT** | iOS 默认禁止 JIT。Minecraft Java 版需要 JVM；可行路线是 **OpenJDK Zero（纯解释器）** 的 iOS 构建（Pojav 的 iOS 版即此路线：`jre8-zero-aarch64-ios.tar.xz`）。性能低，仅适合老版本/轻量场景。 |
| **iPadOS** | 与 iOS 同一套构建（同一 `xcarchive`，Universal 或 arm64）。 |

## 二、架构

```
XCL-Apple
├─ shared/            # 可复用的纯 Java 引擎（直接复用 android/engine）
│  └─ engine/         # 版本/安装/下载/JRE/登录/加载器/Mod（238 项断言）
├─ macos/             # Qt 6 桌面版（复用现有 src/，已加 Q_OS_WIN 平台保护）
│  ├─ CMakePresets.json
│  └─ build_macos.sh
├─ ios/               # SwiftUI/UIKit 外壳
│  ├─ project.yml     # XcodeGen 工程描述
│  ├─ XCL/
│  │  ├─ XCLApp.swift
│  │  ├─ ContentView.swift      # WKWebView + JS 桥
│  │  ├─ LauncherBridge.swift   # 对应桌面/安卓的桥接能力
│  │  └─ Info.plist
│  └─ build_ios_ipa.sh          # 生成未签名 IPA（sideload 用）
└─ .github/workflows/apple.yml  # macOS runner 自动构建 macOS + IPA
```

### 三端共享的东西

- **纯 Java 引擎**（`android/engine`）：与平台无关，iOS/macOS 都可用同一份代码。
- **页面**（`android/assets/index.html`）：WebView 方案三端一致。
- **JRE 供给**：macOS 用桌面 JRE（Temurin 17/21）；iOS 用 **Java 8 Zero arm64**（需随包或首次下载）。

### macOS 版

- 直接复用现有 Qt 6 桌面代码；本次已把 Win32 专属代码（`windows.h` / `dwmapi` / 亚克力）全部放进 `#ifdef Q_OS_WIN`，非 Windows 分支退化为普通半透明背景。
- 构建：`cmake -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"`，产出 Universal `.app`，再 `macdeployqt` 打包。
- 分发：未签名版可直接运行（需右键打开）；正式分发需 Apple Developer ID 签名 + 公证（notarization）。

### iOS / iPadOS 版

- 外壳：SwiftUI + `WKWebView` 加载内置页面；`LauncherBridge` 暴露与桌面/安卓相同的方法名（`nativeInfo` / `jvmStatus` / `installVersion` / `launchVersion` …）。
- JVM：`libjvm.dylib`（Zero 解释器）+ `modules`，通过 `dlopen` + `JNI_CreateJavaVM` 调用；受 iOS 限制只能随包或首次下载后 `dlopen`（需 sideload 权限）。
- 图形：iOS 无 GL4ES 需求，直接用 OpenGL ES/Metal 后端；首版先做「管理 + 启动流程 + 日志」，3D 皮肤预览使用 SwiftUI/Metal 简化实现。
- 输入：触摸 → 与安卓相同的输入队列抽象。

## 三、如何真正产出 IPA（在 Mac 上执行）

```bash
# 0) 准备
brew install xcodegen cmake
# 1) 生成并构建（未签名，sideload 用）
cd apple/ios
./build_ios_ipa.sh
# 产物: build/XCL.ipa
```

或使用 GitHub Actions（无需本地 Mac）：推送后运行 `apple.yml`，在 Actions 产物里下载 `XCL-ios-ipa`。

签名安装（三选一）：
- Sideloadly / AltStore：用 Apple ID 自签，7 天有效期
- TrollStore：无需签名（iOS 14–17 特定版本）
- 开发者证书：`xcodebuild -exportArchive` + `ExportOptions.plist`

## 四、当前进度（本仓库）

| 项 | 状态 |
|---|---|
| Windows 32/64 桌面版 | ✅ 已完成 |
| Android 64/32 版 | ✅ 已完成 |
| 桌面代码平台化（macOS 可编译） | ✅ 已加 `Q_OS_WIN` 保护 |
| Apple 工程脚手架（XcodeGen + SwiftUI + WKWebView） | ✅ 已生成 |
| macOS 构建脚本 + Universal 预设 | ✅ 已生成 |
| IPA 构建脚本 + CI | ✅ 已生成 |
| 实际 IPA 产物 | ⬜ **需要 macOS/Xcode 环境执行**（当前为 Windows 主机） |

## 五、诚实结论

我可以在本机完成：代码平台化、iOS/macOS 工程与脚本、CI 流水线、文档。
我**无法**在 Windows 上生成可安装的 IPA（缺 macOS SDK / Xcode / 签名链）。

下一步二选一：
1. 你在 Mac 上运行 `apple/ios/build_ios_ipa.sh`（或触发 CI），把报错发我，我据此继续修；
2. 提供一台 macOS 构建机/CI 运行结果，我继续迭代到 IPA 成功产出。
