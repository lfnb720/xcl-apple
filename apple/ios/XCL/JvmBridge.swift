import Foundation

/// iOS 运行层: 负责在 App 内启动 Java 虚拟机 (OpenJDK 8 Zero, 随包)
final class JvmRuntime {

    static let shared = JvmRuntime()

    private(set) var lines: [String] = []
    private(set) var ready = false

    private init() {}

    /// JRE 在 App 包内的路径 (build_ios_ipa.sh 会把 jre8 放进 Resources)
    private var jreHome: String {
        Bundle.main.resourcePath.map { $0 + "/jre8" } ?? ""
    }

    private var smokeJar: String {
        Bundle.main.resourcePath.map { $0 + "/smoke.jar" } ?? ""
    }

    private var tmpDir: String {
        let d = NSTemporaryDirectory() + "xcl"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        return d
    }

    private func add(_ s: String) {
        lines.append(s)
        if lines.count > 400 { lines.removeFirst(lines.count - 400) }
    }

    func resetLog() { lines.removeAll() }

    /// 启动 JVM 并执行冒烟类, 返回结果摘要 (在主线程外调用)
    func runSmoke() -> String {
        add("[iOS] JRE: \(jreHome)")
        add("[iOS] jar: \(smokeJar)")

        let fm = FileManager.default
        guard fm.fileExists(atPath: jreHome + "/lib") else {
            add("[错误] 包里没有 jre8/lib —— 构建时 JRE 可能没下载成功")
            return "缺少 iOS JRE（构建脚本未打包）"
        }

        let jarExists = fm.fileExists(atPath: smokeJar)
        add("[iOS] smoke.jar 存在: \(jarExists)")
        if !jarExists {
            add("[错误] App 包里没有 smoke.jar —— 资源没打包进去")
        }

        let outFile = tmpDir + "/smoke.txt"
        let opts = [
            "-Djava.home=\(jreHome)",
            "-Djava.class.path=\(smokeJar)",
            "-Djava.io.tmpdir=\(tmpDir)",
            "-Dfile.encoding=UTF-8",
            "-Xmx512m",
            "-Xss1m",
            "-XX:-UsePerfData"
        ].joined(separator: "\n")

        let r1 = String(cString: xcl_jvm_create(jreHome, opts))
        add("[iOS] JVM 创建: \(r1)")
        guard r1 == "ok" else { return "JVM 创建失败：\(r1)" }
        ready = true

        let r2 = String(cString: xcl_jvm_run_main("com.xcl.smoke.Smoke", outFile))
        add("[iOS] 执行 Smoke: \(r2)")

        var output = ""
        if let data = try? String(contentsOfFile: outFile, encoding: .utf8) {
            output = data
            for line in data.split(separator: "\n") { add("[Java] \(line)") }
        }

        if r2 == "ok" && output.contains("xcl.smoke=ok") {
            return "JVM 启动成功 ✅\n\n" + output
        }
        return "JVM 已创建，但 Smoke 未通过：\(r2)\n\n\(output)"
    }
}
