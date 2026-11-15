import Foundation
import WebKit

/// iOS 桥接: 方法名与桌面/安卓版保持一致, 便于页面复用.
/// 现阶段返回"运行层尚未接入"的真实状态, 不伪造成功.
final class LauncherBridge: NSObject, WKScriptMessageHandler {

    /// 注入到页面的兼容层: 把 postMessage 包装成同步可用的 XCLBridge.* 调用.
    static let bootstrapJS = """
    (function(){
      if (window.XCLBridge) return;
      var pending = {}, seq = 0;
      window.XCLBridge = {
        _call: function(method, args) {
          var id = 'cb' + (++seq);
          window.webkit.messageHandlers.XCLBridge.postMessage({id: id, method: method, args: args || []});
          return id;
        },
        nativeInfo: function(){ return this._call('nativeInfo', []); },
        jvmStatus: function(){ return this._call('jvmStatus', []); },
        glStatus: function(){ return this._call('glStatus', []); },
        runtimeStatus: function(){ return this._call('runtimeStatus', []); },
        installVersion: function(v){ return this._call('installVersion', [v]); },
        installStatus: function(){ return this._call('installStatus', []); },
        launchVersion: function(v, p){ return this._call('launchVersion', [v, p]); },
        launchLog: function(){ return this._call('launchLog', []); }
      };
      window.__XCL_IOS__ = true;
    })();
    """

    private weak var webView: WKWebView?

    func attach(webView: WKWebView) { self.webView = webView }

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else { return }
        let args = body["args"] as? [Any] ?? []
        let result = handle(method: method, args: args)
        let js = "window.dispatchEvent(new CustomEvent('xclbridge', {detail: \(jsonLiteral(result))}));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private func handle(method: String, args: [Any]) -> String {
        switch method {
        case "nativeInfo":
            return json(["ok": true, "abi": "ios-arm64", "os": "iOS/iPadOS",
                         "version": UIDevice.current.systemVersion])
        case "jvmStatus":
            return json(["ready": false, "reason": "iOS 运行层需随包集成 Java 8 Zero (需 macOS 构建)"])
        case "glStatus":
            return json(["loaded": false, "reason": "iOS 图形层待接入 (Metal/GLES)"])
        case "runtimeStatus":
            return json(["platform": "ios", "stage": "scaffold"])
        case "installVersion":
            return json(["state": "error", "message": "iOS 引擎需在 macOS 构建时接入"])
        case "installStatus":
            return json(["state": "idle", "message": "", "done": 0, "total": 0, "mb": 0])
        case "launchVersion":
            return json(["ok": false, "error": "iOS 运行层尚未构建"])
        case "launchLog":
            return json(["text": "(iOS 版暂无启动日志)"])
        default:
            return json(["error": "unknown method: \(method)"])
        }
    }

    private func json(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    private func jsonLiteral(_ s: String) -> String {
        let escaped = s.replacingOccurrences(of: "\\", with: "\\\\")
                       .replacingOccurrences(of: "\"", with: "\\\"")
                       .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }
}
