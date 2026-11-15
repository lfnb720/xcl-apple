# 从零到装上 iPhone/iPad：XCL iOS 版完整操作手册（无 Mac）

> 全程只需要：一台 Windows 电脑、一根数据线、一个免费 GitHub 账号、一个 Apple ID。
> 每一步都写明"打开哪个网址、点哪个按钮、看到什么算成功"。

---

## 准备清单

| 需要 | 说明 |
|---|---|
| Windows 电脑 | 你现在这台即可 |
| 浏览器 | Edge 或 Chrome（上传文件夹更稳） |
| GitHub 账号 | 没有就注册，见步骤 1 |
| Apple ID | 就是登录 App Store 的那个账号（免费即可，不需要开发者账号） |
| iPhone / iPad | iOS / iPadOS 15 及以上 |
| 数据线 | 能连电脑传输的那种 |

本地已备好的文件：`E:\deepseek\XCL\apple\xcl-apple-src.zip`（18.6 KB）

---

## 步骤 1：注册 / 登录 GitHub

1. 打开 **https://github.com/signup**
2. 填邮箱 → 密码 → 用户名 → 完成人机验证
3. 去邮箱点验证链接
4. 注册完成后打开 **https://github.com/login** 登录

> 已有账号直接登录，跳到步骤 2。

---

## 步骤 2：新建一个仓库

1. 打开 **https://github.com/new**
2. `Repository name` 填：`xcl-apple`
3. 选择 **Public**（必须选 Public：公开仓库的 macOS 构建分钟数免费）
4. 下面的 `Add a README file` **不要勾**
5. 点绿色按钮 **Create repository**

成功标志：页面跳到 `https://github.com/你的用户名/xcl-apple`，显示 "Quick setup"。

---

## 步骤 3：解压本地文件

1. 打开文件夹 `E:\deepseek\XCL\apple\`
2. 右键 `xcl-apple-src.zip` → **全部解压缩** → 解压到 `E:\xcl-apple-src`
3. 打开 `E:\xcl-apple-src`，应该看到三个东西：
   - `apple`（文件夹）
   - `android`（文件夹）
   - `.github`（文件夹，以点开头）

> 这三个必须位于**同一层**，不要多套一层文件夹。

---

## 步骤 4：把三个文件夹上传到仓库

1. 回到刚创建的仓库页面（`https://github.com/你的用户名/xcl-apple`）
2. 点页面中部的 **uploading an existing file** 链接
   （或点右上 **Add file ▾ → Upload files**）
3. 打开资源管理器 `E:\xcl-apple-src`，**全选** `apple`、`android`、`.github` 三个文件夹
4. 拖到网页虚线框里，等文件列表出现（约 10 个文件）
5. 页面底部 `Commit changes` 输入框保持默认，点绿色 **Commit changes**

成功标志：仓库首页能看到 `apple`、`android`、`.github` 三个条目。

> 如果 `.github` 拖不上去（浏览器隐藏点开头文件夹）：
> 点 **Add file → Create new file**，文件名填 `.github/workflows/apple.yml`，
> 然后打开本地 `E:\deepseek\XCL\.github\workflows\apple.yml`，全选复制内容，粘贴到网页编辑器，提交。

---

## 步骤 5：触发云端构建（关键一步）

1. 打开仓库页面，点顶部 **Actions** 标签
   → 网址形如 `https://github.com/你的用户名/xcl-apple/actions`
2. 如果看到绿色按钮 **I understand my workflows, go ahead and enable them**，点它
3. 左侧列表点 **Apple**
4. 右侧出现 `This workflow has a workflow_dispatch event trigger.` → 点 **Run workflow ▾**
5. 分支选 `main`，点绿色 **Run workflow**
6. 刷新页面，会出现一条运行记录（黄色圆点 = 进行中）

### 等待与结果

- 一般 **5–10 分钟**
- 记录变 **绿色 ✓** = 成功；红色 ✗ = 失败（见下方"排错"）

---

## 步骤 6：下载 IPA

1. 在 Actions 里点开那条**绿色 ✓** 的运行记录
2. 页面**最底部**找到 **Artifacts** 区域
3. 点击 **XCL-ios-ipa** 下载（得到 `XCL-ios-ipa.zip`）
4. 解压这个 zip → 里面是 **`XCL.ipa`**（这就是安装包）

> 同一个页面还会有 `XCL-macos-universal`，那是 Mac 版，iPhone 用不到。

---

## 步骤 7：Windows 安装 Sideloadly

1. 打开 **https://sideloadly.io/**
2. 点页面上的 **Download for Windows**（得到 `SideloadlySetup.exe`）
3. 双击安装，一路 Next
4. **还需要苹果驱动**：打开 **https://www.apple.com/itunes/download/win64**
   - 下载安装 iTunes（只需驱动，不必登录）
   - 或者 Microsoft Store 搜索 **Apple Devices** 安装
5. 装完**重启电脑**（务必重启，否则识别不到设备）

---

## 步骤 8：连接设备并安装 IPA

1. 用数据线把 iPhone/iPad 连到电脑
2. 手机上弹窗 **要信任此电脑吗？** → 点 **信任** → 输入锁屏密码
3. 打开 Sideloadly
4. 顶部 `iDevice` 下拉框里应出现你的设备名
   - 若没有：换 USB 口/换线，确认 iTunes 能识别设备
5. 把 `XCL.ipa` **拖进** Sideloadly 的 IPA 框（或点文件夹图标选择）
6. `Apple ID` 填你的 Apple 账号邮箱
7. 点 **Start**
8. 弹窗输入 Apple ID **密码**；若开了双重认证，会再要一次 **6 位验证码**
9. 进度条走完显示 **Done**（约 1–3 分钟）

### 如果是 iOS 16 及以上，还要开开发者模式

手机上：**设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启手机 → 重启后点"打开"**

---

## 步骤 9：在手机上信任证书并打开

1. 手机上打开 **设置 → 通用 → VPN与设备管理**
2. 找到 **开发者 App**（显示你的 Apple ID 邮箱）→ 点进去
3. 点 **信任"你的邮箱"** → 确认 **信任**
4. 回到桌面，点 **XCL** 图标启动

成功标志：XCL 打开，显示内置页面（手机版界面）。

---

## 步骤 10：后续维护

- 免费 Apple ID 签名 **7 天过期**，过期后 App 打不开（提示"无法验证 App"）
- 处理：重复**步骤 8** 重新签名安装即可（IPA 不用重新构建）
- 免费账号限制：最多同时签 3 个 App、每周 10 个 App ID；报错时删掉不用的自签 App

---

## 排错对照表

| 现象 | 原因 | 处理 |
|---|---|---|
| Actions 里没有 `Apple` | `.github/workflows/apple.yml` 没上传成功 | 按步骤 4 的补充方法用"Create new file"重建 |
| 运行记录红色 ✗ | 构建失败 | 点进去看红色步骤，把最后 50 行日志发我 |
| Artifacts 里没有 `XCL-ios-ipa` | ios job 失败（macos job 可能成功） | 点 `ios` job 看红色日志 |
| Sideloadly 里没有设备 | 缺苹果驱动 / 未信任 | 装 iTunes 或 Apple Devices，重启，重新插线并信任 |
| `Unable to install ...` | 免费账号限制 / 证书冲突 | 删掉旧的自签 App，换一个 Apple ID 再试 |
| 安装后闪退 | 证书未信任 / 7 天到期 | 步骤 9 信任；或重新签名 |
| "Untrusted Developer" | 未信任开发者 | 设置 → 通用 → VPN与设备管理 → 信任 |
| 想要永久免签名 | 需 TrollStore | 仅特定 iOS 版本（14.0–17.x 部分）支持，自行确认设备版本 |

---

## 所有网址一览

| 用途 | 网址 |
|---|---|
| 注册 GitHub | https://github.com/signup |
| 登录 GitHub | https://github.com/login |
| 新建仓库 | https://github.com/new |
| 仓库 Actions 页 | `https://github.com/你的用户名/xcl-apple/actions` |
| Sideloadly 下载 | https://sideloadly.io/ |
| iTunes（Windows 驱动） | https://www.apple.com/itunes/download/win64 |
| TrollStore（可选，免签名） | https://github.com/opa334/TrollStore |

---

## 一句话总结

**上传三个文件夹 → Actions 点 Run workflow → 下载 Artifacts 里的 IPA → Sideloadly 用 Apple ID 签名 → 手机信任证书 → 打开 XCL。**
