import SwiftUI

// ============================================================
//  XCL iOS / iPadOS 原生界面
//  - 布局与电脑版一致: 左侧图标栏 + 右侧内容区
//  - 强制横屏, 状态栏隐藏
//  - 所有按钮均为原生可点 (不再依赖网页桥接)
// ============================================================

private enum Page: String, CaseIterable, Identifiable {
    case home = "主页"
    case versions = "游戏下载"
    case downloads = "下载"
    case skin = "皮肤"
    case online = "联机"
    case content = "内容"
    case toolbox = "百宝袋"
    case theme = "个性化"
    case logs = "日志"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home:      return "house.fill"
        case .versions:  return "gamecontroller.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .skin:      return "face.smiling.fill"
        case .online:    return "globe.asia.australia.fill"
        case .content:   return "square.grid.2x2.fill"
        case .toolbox:   return "wrench.and.screwdriver.fill"
        case .theme:     return "paintpalette.fill"
        case .logs:      return "doc.text.fill"
        }
    }
}

private enum Theme {
    static let accent = Color(red: 0.424, green: 0.361, blue: 0.906)      // #6C5CE7
    static let bg = Color(red: 0.957, green: 0.965, blue: 0.980)          // #F4F6FA
    static let card = Color.white
    static let line = Color(red: 0.894, green: 0.910, blue: 0.941)        // #E4E8F0
    static let text = Color(red: 0.118, green: 0.129, blue: 0.169)        // #1E212B
    static let sub = Color(red: 0.541, green: 0.565, blue: 0.631)         // #8A90A1
    static let green = Color(red: 0.153, green: 0.682, blue: 0.427)       // #27AE60
}

struct ContentView: View {
    @State private var page: Page = .home
    @State private var playerName = "玩家"
    @State private var offlineMode = true
    @State private var memoryMB: Double = 4096
    @State private var versionIndex = 0
    @State private var showLogin = false
    @State private var alertText: String?
    @State private var showAlert = false
    @State private var launching = false
    @State private var runtimeLog: [String] = []

    private let versions = ["26.3 · 原版", "1.21.1 · 原版", "1.20.1 · 原版"]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().background(Theme.line)
            content
        }
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $showLogin) { loginSheet }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertText ?? ""), dismissButton: .default(Text("知道了")))
        }
    }

    // MARK: - 左侧图标栏 (与电脑版一致)

    private var sidebar: some View {
        VStack(spacing: 2) {
            Text("XCL")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
                .padding(.top, 14)
                .padding(.bottom, 10)

            ForEach(Page.allCases) { item in
                Button(action: { page = item }) {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(page == item ? Theme.accent : Theme.bg)
                                .frame(width: 38, height: 38)
                            Image(systemName: item.symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(page == item ? .white : Theme.sub)
                        }
                        Text(item.rawValue)
                            .font(.system(size: 10.5))
                            .foregroundColor(page == item ? Theme.accent : Theme.sub)
                    }
                    .frame(width: 76, height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 6)
        }
        .frame(width: 88)
        .background(Color.white)
    }

    // MARK: - 右侧内容区

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(page.rawValue)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.text)

                switch page {
                case .home:      homePage
                case .skin:      skinPage
                case .logs:      logPage
                case .versions:  versionsPage
                case .downloads: downloadsPage
                case .online:    simplePage("联机", "使用 Terracotta 与好友联机（运行层接入后开放）", "person.2.wave.2.fill")
                case .content:   simplePage("内容", "Modrinth / CurseForge 模组与整合包搜索", "square.stack.3d.up.fill")
                case .toolbox:   simplePage("百宝袋", "MCBBS / MC 百科 / 常用工具站一键跳转", "wrench.and.screwdriver.fill")
                case .theme:     themePage
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 主页

    private var homePage: some View {
        HStack(alignment: .top, spacing: 14) {
            Card {
                VStack(spacing: 12) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 74, height: 74)
                        .overlay(Text(String(playerName.prefix(1))).font(.system(size: 32, weight: .bold)).foregroundColor(.white))
                    Text(playerName).font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                    Text(offlineMode ? "离线模式" : "微软正版").font(.system(size: 11)).foregroundColor(Theme.sub)

                    HStack(spacing: 8) {
                        Button(action: { showLogin = true }) {
                            Text("离线 / 微软登录")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(Theme.bg).cornerRadius(9)
                                .foregroundColor(Theme.text)
                        }.buttonStyle(.plain)

                        Button(action: showMicrosoftInfo) {
                            Text("微软登录")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12).padding(.vertical, 9)
                                .background(Theme.accent).cornerRadius(9)
                                .foregroundColor(.white)
                        }.buttonStyle(.plain)
                    }

                    HStack {
                        Text("内存分配").font(.system(size: 12)).foregroundColor(Theme.text)
                        Spacer()
                        Text("\(Int(memoryMB)) MB").font(.system(size: 11)).foregroundColor(Theme.sub)
                    }
                    Slider(value: $memoryMB, in: 1024...8192, step: 512).accentColor(Theme.accent)

                    Button(action: launchGame) {
                        Text("启动游戏")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Theme.text).cornerRadius(10)
                            .foregroundColor(.white)
                    }.buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Button(action: { page = .versions }) {
                            Text("版本选择").font(.system(size: 11.5)).frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(Theme.bg).cornerRadius(8).foregroundColor(Theme.text)
                        }.buttonStyle(.plain)
                        Button(action: { showInfo("版本设置：运行层接入后可修改 JVM 参数、窗口尺寸等。") }) {
                            Text("版本设置").font(.system(size: 11.5)).frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(Theme.bg).cornerRadius(8).foregroundColor(Theme.text)
                        }.buttonStyle(.plain)
                    }

                    Text(versions[versionIndex]).font(.system(size: 11)).foregroundColor(Theme.sub)
                }
            }
            .frame(width: 300)

            VStack(spacing: 14) {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("XCL 小贴士").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        Text("【46/100】JVM 参数可以在版本设置的「高级启动选项」里追加。")
                            .font(.system(size: 11.5)).foregroundColor(Theme.sub)
                        Button(action: refreshTip) {
                            Text("换一条").font(.system(size: 11)).padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Theme.bg).cornerRadius(7).foregroundColor(Theme.text)
                        }.buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("状态").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        statusRow("运行层", "未接入（iOS 需 Java 8 Zero）", false)
                        statusRow("图形层", "待接入 Metal", false)
                        statusRow("界面外壳", "原生 SwiftUI · 横屏", true)
                        statusRow("设备", deviceInfo, true)

                        Button(action: runJvmSmoke) {
                            Text(launching ? "运行中…" : "JVM 自检")
                                .font(.system(size: 11.5, weight: .semibold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Theme.bg).cornerRadius(8)
                                .foregroundColor(Theme.text)
                        }.buttonStyle(.plain).disabled(launching)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var deviceInfo: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "iPadOS \(v.majorVersion).\(v.minorVersion)"
    }

    private func statusRow(_ name: String, _ value: String, _ ok: Bool) -> some View {
        HStack(spacing: 8) {
            Circle().fill(ok ? Theme.green : Color.orange).frame(width: 7, height: 7)
            Text(name).font(.system(size: 11.5)).foregroundColor(Theme.text)
            Spacer()
            Text(value).font(.system(size: 11)).foregroundColor(Theme.sub).lineLimit(1)
        }
    }

    // MARK: - 其他页面

    private func simplePage(_ title: String, _ desc: String, _ symbol: String) -> some View {
        Card {
            VStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 34)).foregroundColor(Theme.accent.opacity(0.8))
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                Text(desc).font(.system(size: 12)).foregroundColor(Theme.sub).multilineTextAlignment(.center)
                Button(action: { showInfo("\(title)：运行层接入后开放此功能。") }) {
                    Text("了解更多").font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Theme.accent).cornerRadius(9).foregroundColor(.white)
                }.buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
        }
    }

    private var versionsPage: some View {
        VStack(spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("已安装版本").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                    ForEach(Array(versions.enumerated()), id: \.offset) { idx, name in
                        Button(action: { versionIndex = idx }) {
                            HStack {
                                Image(systemName: versionIndex == idx ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(versionIndex == idx ? Theme.accent : Theme.sub)
                                Text(name).font(.system(size: 12.5)).foregroundColor(Theme.text)
                                Spacer()
                                Text("原版").font(.system(size: 10.5)).foregroundColor(Theme.sub)
                            }
                            .padding(.vertical, 8).padding(.horizontal, 10)
                            .background(versionIndex == idx ? Theme.bg : Color.clear)
                            .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("下载新版本").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                    Text("原生 iOS 版暂不支持联网安装（需先接入引擎与 JVM）。")
                        .font(.system(size: 11.5)).foregroundColor(Theme.sub)
                    Button(action: { showInfo("下载功能将随运行层一起接入。") }) {
                        Text("检查更新").font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Theme.bg).cornerRadius(8).foregroundColor(Theme.text)
                    }.buttonStyle(.plain)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var downloadsPage: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("下载管理").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                Text("暂无下载任务").font(.system(size: 11.5)).foregroundColor(Theme.sub)
                ProgressView(value: 0).tint(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var skinPage: some View {
        HStack(alignment: .top, spacing: 14) {
            Card {
                VStack(spacing: 8) {
                    HStack {
                        Text("FPS --").font(.system(size: 10.5, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.black.opacity(0.65)).cornerRadius(5)
                            .foregroundColor(Color(red: 0.48, green: 0.94, blue: 0.75))
                        Spacer()
                    }
                    Spacer()
                    Image(systemName: "person.crop.square.fill")
                        .font(.system(size: 84)).foregroundColor(Theme.accent.opacity(0.55))
                    Text("3D 皮肤预览").font(.system(size: 12)).foregroundColor(Theme.sub)
                    Text("（接入 Metal 渲染后显示，当前为占位）").font(.system(size: 10.5)).foregroundColor(Theme.sub.opacity(0.8))
                    Spacer()
                    Text("当前皮肤：暂无").font(.system(size: 10.5)).foregroundColor(Theme.sub)
                }
                .padding(10)
                .frame(width: 330, height: 300)
                .background(Theme.bg.opacity(0.6))
                .cornerRadius(10)
            }
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("皮肤列表").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                    ForEach(["默认皮肤", "示例·史蒂夫"], id: \.self) { name in
                        Button(action: { showInfo("皮肤「\(name)」：3D 渲染接入后生效。") }) {
                            HStack {
                                Image(systemName: "square.fill").foregroundColor(Theme.accent.opacity(0.5))
                                Text(name).font(.system(size: 12)).foregroundColor(Theme.text)
                                Spacer()
                            }
                            .padding(.vertical, 7).padding(.horizontal, 8)
                            .background(Theme.bg.opacity(0.7)).cornerRadius(7)
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var themePage: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("外观").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                ForEach(["浅色（当前）", "深色（待实现）", "跟随系统（待实现）"], id: \.self) { item in
                    Button(action: { showInfo("主题切换将随后续版本提供。") }) {
                        HStack {
                            Text(item).font(.system(size: 12)).foregroundColor(Theme.text)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(Theme.sub)
                        }
                        .padding(.vertical, 9).padding(.horizontal, 10)
                        .background(Theme.bg.opacity(0.7)).cornerRadius(8)
                    }.buttonStyle(.plain)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var logPage: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("运行日志").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(runtimeLog.isEmpty ? logLines : runtimeLog, id: \.self) { line in
                            Text(line).font(.system(size: 10.5, design: .monospaced)).foregroundColor(Theme.sub)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(height: 210)
                Button(action: { showInfo("清空了显示（真实日志来自运行层）。") }) {
                    Text("清空显示").font(.system(size: 11.5))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Theme.bg).cornerRadius(8).foregroundColor(Theme.text)
                }.buttonStyle(.plain)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var logLines: [String] {
        [
            "[iOS] XCL shell started",
            "[iOS] orientation: landscape (forced)",
            "[iOS] device: \(deviceInfo)",
            "[iOS] runtime: not installed (needs Java 8 Zero arm64)",
            "[iOS] graphics: pending Metal backend",
            "[iOS] UI: native SwiftUI (no WebView bridge)"
        ]
    }

    // MARK: - 登录弹窗

    private var loginSheet: some View {
        VStack(spacing: 14) {
            Text("登录").font(.system(size: 18, weight: .bold))
            TextField("玩家名称", text: $playerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Toggle("离线模式", isOn: $offlineMode)
            HStack(spacing: 10) {
                Button("取消") { showLogin = false }
                Button("确定") { showLogin = false }
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(22)
        .frame(width: 340)
    }

    // MARK: - 动作

    private func launchGame() {
        if launching { return }
        launching = true
        runtimeLog = []
        alertText = "正在启动 Java 虚拟机并连接版本清单…\n\n首次约 15–40 秒（OpenJDK 8 Zero 解释器 + 网络）"
        showAlert = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = JvmRuntime.shared.runEngine()
            DispatchQueue.main.async {
                self.launching = false
                self.runtimeLog = JvmRuntime.shared.lines
                self.alertText = result
                self.showAlert = true
            }
        }
    }

    private func runJvmSmoke() {
        if launching { return }
        launching = true
        runtimeLog = []
        alertText = "正在执行 JVM 自检…"
        showAlert = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = JvmRuntime.shared.runSmoke()
            DispatchQueue.main.async {
                self.launching = false
                self.runtimeLog = JvmRuntime.shared.lines
                self.alertText = result
                self.showAlert = true
            }
        }
    }

    private func showMicrosoftInfo() {
        alertText = "微软正版登录需要网络与 Xbox 认证流程，将随运行层接入。\n现在可先用「离线 / 微软登录」设置玩家名。"
        showAlert = true
    }

    private func refreshTip() {
        alertText = "换一条小贴士：\n\n【状态】界面已改为原生 SwiftUI，所有按钮均可点击；横屏已强制生效。"
        showAlert = true
    }

    private func showInfo(_ text: String) {
        alertText = text
        showAlert = true
    }
}

// MARK: - 卡片容器

private struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(14)
            .background(Theme.card)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().previewInterfaceOrientation(.landscapeLeft)
    }
}
