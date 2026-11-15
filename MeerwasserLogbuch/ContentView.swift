import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct WebView: UIViewRepresentable {
    let htmlFileName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // Bridge für Blob/Data-Downloads (JSON-Backup & CSV-Export) in iOS
        let userContentController = config.userContentController
        userContentController.add(context.coordinator, name: "fileExport")

        let downloadScript = """
        (function() {
            const origClick = HTMLAnchorElement.prototype.click;
            HTMLAnchorElement.prototype.click = function() {
                if (this.download && this.href && this.href.startsWith('blob:')) {
                    const filename = this.download;
                    fetch(this.href)
                        .then(r => r.text())
                        .then(text => {
                            window.webkit.messageHandlers.fileExport.postMessage({
                                filename: filename,
                                content: text
                            });
                        })
                        .catch(() => origClick.apply(this, arguments));
                    return;
                }
                return origClick.apply(this, arguments);
            };
        })();
        """
        let userScript = WKUserScript(source: downloadScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url == nil,
           let fileURL = Bundle.main.url(forResource: htmlFileName, withExtension: "html") {
            uiView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
    }

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // JavaScript alert() unterstützen
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: "Meerwasser-Logbuch", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            presentAlert(alert)
        }

        // JavaScript confirm() unterstützen
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: "Meerwasser-Logbuch", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            presentAlert(alert)
        }

        // JavaScript prompt() unterstützen (für neues Becken anlegen)
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let alert = UIAlertController(title: "Meerwasser-Logbuch", message: prompt, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            presentAlert(alert)
        }

        // Externe Links im Safari öffnen
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                if navigationAction.navigationType == .linkActivated {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        // JSON/CSV Export über das iOS Share-Sheet teilen/speichern
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "fileExport",
                  let dict = message.body as? [String: String],
                  let filename = dict["filename"],
                  let content = dict["content"] else { return }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            do {
                try content.write(to: tempURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    if let rootVC = Self.topViewController() {
                        if let popover = activityVC.popoverPresentationController {
                            popover.sourceView = rootVC.view
                            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                            popover.permittedArrowDirections = []
                        }
                        rootVC.present(activityVC, animated: true)
                    }
                }
            } catch {
                print("Export Fehler: \(error)")
            }
        }

        private func presentAlert(_ alert: UIAlertController) {
            DispatchQueue.main.async {
                Self.topViewController()?.present(alert, animated: true)
            }
        }

        private static func topViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
                  var top = window.rootViewController else {
                return nil
            }
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
    }
}

struct ContentView: View {
    var body: some View {
        WebView(htmlFileName: "index")
            .ignoresSafeArea(.container, edges: .bottom)
    }
}
