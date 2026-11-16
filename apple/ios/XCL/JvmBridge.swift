import Foundation

/// iOS 运行层: 在 App 内启动 Java 虚拟机 (OpenJDK 8 Zero, 随包)
final class JvmRuntime {

    static let shared = JvmRuntime()

    private(set) var lines: [String] = []
    private(set) var ready = false

    private init() {}

    private var jreHome: String { Bundle.main.resourcePath.map { $0 + "/jre8" } ?? "" }
    private var smokeJar: String { Bundle.main.resourcePath.map { $0 + "/smoke.jar" } ?? "" }
    private var engineJar: String { Bundle.main.resourcePath.map { $0 + "/xcl-engine.jar" } ?? "" }

    private var tmpDir: String {
        let d = NSTemporaryDirectory() + "xcl"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        return d
    }

    var gameDir: String {
        let d = tmpDir + "/game"
        try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
        return d
    }

    private func add(_ s: String) {
        lines.append(s)
        if lines.count > 600 { lines.removeFirst(lines.count - 600) }
    }

    func resetLog() { lines.removeAll() }

    private func ensureJVM() -> String {
        if ready { return "ok" }
        add("[iOS] JRE: \(jreHome)")

        let fm = FileManager.default
        guard fm.fileExists(atPath: jreHome + "/lib") else {
            add("[错误] 包里没有 jre8/lib")
            return "缺少 iOS JRE"
        }
        add("[iOS] smoke.jar: \(fm.fileExists(atPath: smokeJar))")
        add("[iOS] engine.jar: \(fm.fileExists(atPath: engineJar))")

        var cp = smokeJar
        if fm.fileExists(atPath: engineJar) { cp += ":" + engineJar }

        let opts = [
            "-Djava.home=\(jreHome)",
            "-Djava.class.path=\(cp)",
            "-Djava.io.tmpdir=\(tmpDir)",
            "-Dfile.encoding=UTF-8",
            "-Xmx512m",
            "-Xss1m",
            "-XX:-UsePerfData"
        ].joined(separator: "\n")

        let r = String(cString: xcl_jvm_create(jreHome, opts))
        add("[iOS] JVM 创建: \(r)")
        if r == "ok" { ready = true }
        return r
    }

    func runSmoke() -> String {
        let r0 = ensureJVM()
        guard r0 == "ok" else { return "JVM 创建失败：\(r0)" }

        let outFile = tmpDir + "/smoke.txt"
        try? FileManager.default.removeItem(atPath: outFile)
        let r = String(cString: xcl_jvm_run_main("com.xcl.smoke.Smoke", outFile))
        add("[iOS] 执行 Smoke: \(r)")

        var output = ""
        if let s = try? String(contentsOfFile: outFile, encoding: .utf8) { output = s }
        for line in output.split(separator: "\n") { add("[Java] \(line)") }

        if r == "ok" && output.contains("xcl.smoke=ok") {
            return "JVM 启动成功 ✅\n\n" + output
        }
        return "JVM 已创建，Smoke 未通过：\(r)\n\n\(output)"
    }

    func runEngine() -> String {
        let r0 = ensureJVM()
        guard r0 == "ok" else { return "JVM 创建失败：\(r0)" }

        let outFile = tmpDir + "/engine.txt"
        try? FileManager.default.removeItem(atPath: outFile)
        let args = outFile + "\n" + gameDir
        let r = String(cString: xcl_jvm_run_main("com.xcl.engine.IosBoot", args))
        add("[iOS] 执行 IosBoot: \(r)")

        var output = ""
        if let s = try? String(contentsOfFile: outFile, encoding: .utf8) { output = s }
        for line in output.split(separator: "\n") { add("[Java] \(line)") }

        if r == "ok" && output.contains("engine.smoke=ok") {
            return "引擎联网成功 ✅\n\n" + output
        }
        return "引擎执行结果：\(r)\n\n\(output)"
    }

    /// 下载指定版本的全部文件到沙盒 (IosInstall)
    func runInstall(versionId: String) -> String {
        let r0 = ensureJVM()
        guard r0 == "ok" else { return "JVM 创建失败：\(r0)" }

        let outFile = tmpDir + "/install.txt"
        try? FileManager.default.removeItem(atPath: outFile)
        let args = outFile + "\n" + gameDir + "\n" + versionId
        add("[iOS] 开始安装 \(versionId) → \(gameDir)")
        let r = String(cString: xcl_jvm_run_main("com.xcl.engine.IosInstall", args))
        add("[iOS] IosInstall 返回: \(r)")

        var output = ""
        if let s = try? String(contentsOfFile: outFile, encoding: .utf8) { output = s }
        for line in output.split(separator: "\n") { add("[Java] \(line)") }

        if r == "ok" && output.contains("install.ok=1") {
            return "下载完成 ✅\n\n" + output
        }
        return "安装结果：\(r)\n\n\(output.isEmpty ? "（无输出）" : output)"
    }
}
