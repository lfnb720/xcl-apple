import SwiftUI

// ============================================================
//  诊断用最小界面（仅当正式界面闪退时临时替换 ContentView.swift）
//  作用: 判断"闪退"是界面代码问题, 还是运行层/链接参数问题
// ============================================================

struct ContentView: View {
    @State private var result = "未测试"
    @State private var running = false

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("XCL 诊断模式").font(.system(size: 26, weight: .bold))
                Text("如果这个界面能显示，说明闪退来自原界面的 UI 代码；\n如果仍然闪退，说明问题在 App 启动配置或签名。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Button(action: testJVM) {
                    Text(running ? "正在启动 JVM…" : "测试 JVM")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .background(Color(red: 0.42, green: 0.36, blue: 0.91))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(running)
            }

            ScrollView {
                Text(result)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(width: 520)
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
    }

    private func testJVM() {
        running = true
        result = "启动中…"
        DispatchQueue.global(qos: .userInitiated).async {
            let r = JvmRuntime.shared.runSmoke()
            let log = JvmRuntime.shared.lines.joined(separator: "\n")
            DispatchQueue.main.async {
                running = false
                result = r + "\n\n---- 日志 ----\n" + log
            }
        }
    }
}
