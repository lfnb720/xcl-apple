# 没有 Mac，怎么拿到 IPA

> 结论：**不需要买 Mac**。用 GitHub 的 macOS 免费构建机（Actions）出 IPA，再在 Windows 上用 Sideloadly 签名装到 iPhone/iPad。

## 路线对比

| 路线 | 成本 | 难度 | 说明 |
|---|---|---|---|
| **A. GitHub Actions（推荐）** | 免费（公开仓库不限分钟数） | 低 | 云端 macOS 跑 `xcodebuild`，产出未签名 IPA，下载即可 |
| B. Codemagic / AppCircle | 有免费额度 | 低 | 连接 GitHub 仓库，图形化触发 iOS 构建 |
| C. 云 Mac 租用（MacinCloud / MacStadium / AWS EC2 Mac） | 约 1–3 美元/小时 | 中 | 远程桌面登录，等于临时拥有一台 Mac，可跑 Xcode |
| D. 买二手 Mac mini | 2000 元起 | — | 长期做 Apple 开发才需要 |

## A 路线：完整步骤（全程 Windows）

### 1. 把工程放到 GitHub

任选一种（都不需要命令行）：

- **GitHub 网页上传**：新建仓库 → `Add file` → `Upload files` → 把 `apple/`、`android/assets/index.html`、`.github/` 三个目录拖进去 → Commit。
- **GitHub Desktop**（推荐，图形化）：安装后 `New repository` → 把上面三个目录复制进仓库目录 → Commit → Publish。

> 已为你准备最小上传包：`apple/xcl-apple-src.zip`（16 KB，解压后就是这三个目录）。

### 2. 触发构建

仓库页面 → **Actions** → 左侧 `Apple` → `Run workflow`（或直接 push 触发）。

大约 5–8 分钟后：
- `XCL-ios-ipa`：未签名 IPA（`XCL.ipa`）
- `XCL-macos-universal`：macOS Universal 压缩包（如有 macOS 需求）

在 Actions 运行页底部 **Artifacts** 下载。

### 3. 在 Windows 上签名安装（Sideloadly）

1. 下载 [Sideloadly](https://sideloadly.io/)（Windows 版）
2. 安装 iTunes（或 Apple Devices 应用，Sideloadly 需要其驱动）
3. iPhone/iPad 用数据线连电脑，信任此电脑
4. Sideloadly 选择 `XCL.ipa`，填 Apple ID（免费账号即可），点 Start
5. 首次安装后：设置 → 通用 → VPN与设备管理 → 信任你的开发者证书
6. 免费账号有效期 **7 天**，到期重新签名即可

> 若设备是 iOS 14.0–17.x 且支持 **TrollStore**，可免签名直接安装 IPA（永久有效）。

### 4. 想上 App Store？

不建议也无法：启动器会下载并运行第三方 Java 代码、内置 JVM，违反 App Store 审核规则（2.5.2 / 4.7）。只能 sideload 或企业分发。

## B 路线：Codemagic 简要步骤

1. 注册 codemagic.io，连接 GitHub 仓库
2. 新建 iOS 应用，选择仓库
3. Build 配置里加脚本：
   ```bash
   brew install xcodegen
   cd apple/ios && ./build_ios_ipa.sh
   ```
4. 产物在 Artifacts 中下载（`XCL.ipa`）

## C 路线：云 Mac（最接近本地开发）

1. 注册 MacinCloud / MacStadium，选 Apple Silicon 机型
2. 远程桌面登录 → 安装 Xcode（App Store）
3. 在云 Mac 上执行：
   ```bash
   brew install xcodegen
   cd apple/ios && ./build_ios_ipa.sh
   ```
4. 用 `scp` 或网盘把 IPA 拿回 Windows，再 Sideloadly 安装

## 常见问题

| 问题 | 处理 |
|---|---|
| Actions 报 `xcodegen: command not found` | workflow 已 `brew install xcodegen`，若失败检查 runner 镜像 |
| 构建报 `Signing for "XCL" requires a development team` | 确认 `CODE_SIGNING_ALLOWED=NO`（脚本已带） |
| 安装后闪退 | 免费签名 7 天过期 / 设备未信任证书，重签重装 |
| 想要免签名永久安装 | 用 TrollStore（需特定 iOS 版本） |
| 需要 iPad 全屏/横屏 | `project.yml` 已声明 iPad 方向，可在 Info.plist 再调 |

## 我需要你提供什么

- 若 Actions 构建失败：把失败步骤的日志（最后 50 行）发我，我按报错改脚本/工程；
- 若能跑起来：把 IPA 安装后的界面截图发我，继续接 JVM 运行层。

我这边没有 macOS/Xcode，无法替你在本机生成 IPA，但**工程、脚本、CI 与排错都可以在我这里完成**。
