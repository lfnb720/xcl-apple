import SwiftUI
import WebKit

/// XCL iOS 外壳: WKWebView 加载内置页面, 通过 JS 桥提供与桌面/安卓一致的接口.
struct ContentView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let controller = WKUserContentController()
        let bridge = LauncherBridge()
        controller.add(bridge, name: "XCLBridge")
        controller.addUserScript(WKUserScript(source: LauncherBridge.bootstrapJS,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: true))
        config.userContentController = controller

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.bounces = false
        web.allowsBackForwardNavigationGestures = false

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            web.loadHTMLString("<h1>XCL</h1><p>缺少内置页面 index.html</p>", baseURL: nil)
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator {}
}
