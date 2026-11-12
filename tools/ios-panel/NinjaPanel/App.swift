// Ninja Panel: the Hello Bro / Ninja Online control panel as an iPhone app (owner, 12 Nov 2026: "a sideload app, with the Ninja Online logo").
// It is only a full-screen web view of https://ninjaonlinereborn.com/panel (the same pages as the home-screen app: on a phone every tab is its
// own page with the tab row on top, server/appnav.js). The admin password is asked by the page itself and kept by the web view's cookie.
// Built on GitHub's Mac (.github/workflows/ios-panel.yml), installed with Sideloadly (tools/ios-panel/README.md).
import UIKit
import WebKit

let START = URL(string: "https://ninjaonlinereborn.com/panel")!
let HOSTS: Set<String> = ["ninjaonlinereborn.com", "www.ninjaonlinereborn.com", "ninjaonline.duckdns.org"]
let BG = UIColor(red: 11 / 255, green: 10 / 255, blue: 20 / 255, alpha: 1)

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.backgroundColor = BG
    w.rootViewController = PanelViewController()
    w.makeKeyAndVisible()
    window = w
    return true
  }
}

class PanelViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
  private var web: WKWebView!
  private let refresh = UIRefreshControl()

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func loadView() {
    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default() // keeps the login cookie (hb_admin) between starts
    cfg.allowsInlineMediaPlayback = true
    web = WKWebView(frame: .zero, configuration: cfg)
    web.isOpaque = false
    web.backgroundColor = BG
    web.scrollView.backgroundColor = BG
    web.scrollView.contentInsetAdjustmentBehavior = .never // the pages keep clear of the notch themselves (viewport-fit=cover)
    web.allowsBackForwardNavigationGestures = true
    web.navigationDelegate = self
    web.uiDelegate = self
    refresh.tintColor = .white
    refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
    web.scrollView.refreshControl = refresh
    view = web
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    web.load(URLRequest(url: START))
  }

  @objc private func pullToRefresh() {
    if web.url == nil || web.url?.scheme == "about" { web.load(URLRequest(url: START)) } else { web.reload() }
  }

  // links to other sites (Discord, GitHub) open in Safari; the panel's own pages stay in the app
  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = action.request.url else { return decisionHandler(.allow) }
    let ours = url.host.map { HOSTS.contains($0) } ?? true
    if (url.scheme == "http" || url.scheme == "https") && !ours && action.navigationType == .linkActivated {
      UIApplication.shared.open(url)
      return decisionHandler(.cancel)
    }
    if url.scheme != "http" && url.scheme != "https" && url.scheme != "about" {
      UIApplication.shared.open(url)
      return decisionHandler(.cancel)
    }
    decisionHandler(.allow)
  }

  // target="_blank": our pages in this view, other sites in Safari
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    if let url = action.request.url {
      if let h = url.host, HOSTS.contains(h) { webView.load(URLRequest(url: url)) } else { UIApplication.shared.open(url) }
    }
    return nil
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { refresh.endRefreshing() }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { refresh.endRefreshing() }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    refresh.endRefreshing()
    if (error as NSError).code == NSURLErrorCancelled { return }
    let html = """
    <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>
    body{margin:0;min-height:100vh;display:grid;place-items:center;background:#0b0a14;color:#f3f1ff;font:17px -apple-system,system-ui,sans-serif;text-align:center}
    p{color:#a39fc0;margin:8px 24px 22px}a{display:inline-block;padding:14px 26px;border-radius:12px;background:#ff8a1f;color:#1a0f02;font-weight:800;text-decoration:none}
    </style></head><body><div><h2>Can't reach the server</h2><p>Check your internet, then try again.</p><a href="\(START.absoluteString)">Try again</a></div></body></html>
    """
    webView.loadHTMLString(html, baseURL: nil)
  }

  // the pages use alert / confirm / prompt (Restart, Stop, reset a player ...): a web view shows nothing without these
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
    present(a, animated: true)
  }

  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
    let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
    a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
    present(a, animated: true)
  }

  func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
    let a = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
    a.addTextField { $0.text = defaultText }
    a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
    a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(a.textFields?.first?.text) })
    present(a, animated: true)
  }
}
