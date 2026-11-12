// Ninja Panel: the Hello Bro / Ninja Online control panel as an iPhone app (owner, 12 Nov 2026: "a sideload app, with the Ninja Online
// logo", then "make it more pretty, and work with the bug fixer"). A full-screen web view of the panel pages on ninjaonlinereborn.com with
// the app's own tab bar at the bottom (Server, Players, Team, Bugs, More), a start screen with the NINJA ONLINE logo, and a badge on Bugs
// that counts what waits for the owner (the Bugs page: server/bugboard.js). The pages see "NinjaPanelApp" in the browser name and then
// show only their title on top instead of their own tab row (server/appnav.js). The admin password is asked by the page itself and kept
// by the web view's cookie. Built on GitHub's Mac (.github/workflows/ios-panel.yml), installed by sideloading (tools/ios-panel/README.md).
import UIKit
import WebKit

let SITE = "https://ninjaonlinereborn.com"
let HOSTS: Set<String> = ["ninjaonlinereborn.com", "www.ninjaonlinereborn.com", "ninjaonline.duckdns.org"]
let BG = UIColor(red: 11 / 255, green: 10 / 255, blue: 20 / 255, alpha: 1)
let ORANGE = UIColor(red: 1, green: 138 / 255, blue: 31 / 255, alpha: 1)

struct Tab { let title: String; let icon: String; let path: String }
let TABS = [
  Tab(title: "Server", icon: "server.rack", path: "/manager?embed=1&app=1"),
  Tab(title: "Players", icon: "person.2.fill", path: "/admin?embed=1&app=1"),
  Tab(title: "Team", icon: "shield.lefthalf.filled", path: "/admin?embed=1&app=1&tab=team"),
  Tab(title: "Bugs", icon: "ladybug.fill", path: "/admin/bugs?embed=1&app=1"),
]
let MORE: [(String, String)] = [
  ("📈 Player log", "/admin/playerlog?embed=1&app=1"),
  ("🔎 Tracker", "/admin/track?embed=1&app=1"),
  ("🌐 Website visitors", "/admin/sitestats?embed=1&app=1"),
  ("📋 Progress", "/panel?app=1#progress"),
]

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.backgroundColor = BG
    w.overrideUserInterfaceStyle = .dark
    w.tintColor = ORANGE
    w.rootViewController = PanelViewController()
    w.makeKeyAndVisible()
    window = w
    return true
  }
}

class PanelViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UITabBarDelegate {
  private var web: WKWebView!
  private let tabBar = UITabBar()
  private let refresh = UIRefreshControl()
  private let splash = UIView()
  private var badgeTimer: Timer?
  private let tick = UISelectionFeedbackGenerator()

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = BG

    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default() // keeps the login cookie (hb_admin) between starts
    cfg.allowsInlineMediaPlayback = true
    cfg.applicationNameForUserAgent = "NinjaPanelApp/1.1 Mobile/15E148 Safari/604.1" // the pages hide their own tab row (appnav.js)
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

    // the tab bar: dark glass, orange when chosen
    let look = UITabBarAppearance()
    look.configureWithDefaultBackground()
    look.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
    look.backgroundColor = BG.withAlphaComponent(0.72)
    for item in [look.stackedLayoutAppearance, look.inlineLayoutAppearance, look.compactInlineLayoutAppearance] {
      item.normal.iconColor = UIColor(white: 0.62, alpha: 1)
      item.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 0.62, alpha: 1)]
      item.selected.iconColor = ORANGE
      item.selected.titleTextAttributes = [.foregroundColor: ORANGE]
      item.normal.badgeBackgroundColor = UIColor(red: 1, green: 0.36, blue: 0.45, alpha: 1)
    }
    tabBar.standardAppearance = look
    tabBar.scrollEdgeAppearance = look
    var items = TABS.enumerated().map { i, t in UITabBarItem(title: t.title, image: UIImage(systemName: t.icon), tag: i) }
    items.append(UITabBarItem(title: "More", image: UIImage(systemName: "ellipsis.circle.fill"), tag: 99))
    tabBar.items = items
    tabBar.selectedItem = items[0]
    tabBar.delegate = self

    view.addSubview(web)
    view.addSubview(tabBar)
    web.translatesAutoresizingMaskIntoConstraints = false
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      web.topAnchor.constraint(equalTo: view.topAnchor),
      web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      web.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    buildSplash()
    go(TABS[0].path)
    badgeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.updateBadge() }
    NotificationCenter.default.addObserver(self, selector: #selector(cameBack), name: UIApplication.willEnterForegroundNotification, object: nil)
  }

  // the start screen: the NINJA ONLINE logo on the panel's night colour, gone once the first page is there
  private func buildSplash() {
    splash.backgroundColor = BG
    splash.frame = view.bounds
    splash.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    let logo = UIImageView(image: UIImage(named: "LaunchLogo"))
    logo.contentMode = .scaleAspectFit
    logo.translatesAutoresizingMaskIntoConstraints = false
    let spin = UIActivityIndicatorView(style: .medium)
    spin.color = UIColor(white: 1, alpha: 0.7)
    spin.startAnimating()
    spin.translatesAutoresizingMaskIntoConstraints = false
    splash.addSubview(logo)
    splash.addSubview(spin)
    view.addSubview(splash)
    NSLayoutConstraint.activate([
      logo.centerXAnchor.constraint(equalTo: splash.centerXAnchor),
      logo.centerYAnchor.constraint(equalTo: splash.centerYAnchor),
      logo.widthAnchor.constraint(equalToConstant: 280),
      spin.centerXAnchor.constraint(equalTo: splash.centerXAnchor),
      spin.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 34),
    ])
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in self?.hideSplash() } // never stuck on it
  }

  private func hideSplash() {
    guard splash.superview != nil else { return }
    UIView.animate(withDuration: 0.35, animations: { self.splash.alpha = 0; self.splash.transform = CGAffineTransform(scaleX: 1.06, y: 1.06) }) { _ in self.splash.removeFromSuperview() }
  }

  private func go(_ path: String) { if let u = URL(string: SITE + path) { web.load(URLRequest(url: u)) } }

  @objc private func pullToRefresh() {
    if web.url == nil || web.url?.scheme == "about" { let t = tabBar.selectedItem?.tag ?? 0; go(TABS[t < TABS.count ? t : 0].path) } else { web.reload() }
  }

  @objc private func cameBack() { updateBadge() }

  // ---- tab bar
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    tick.selectionChanged()
    if item.tag == 99 { showMore(); return }
    go(TABS[item.tag].path)
  }

  private func showMore() {
    let a = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    for (title, path) in MORE { a.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in self?.go(path) }) }
    a.addAction(UIAlertAction(title: "↻ Reload this page", style: .default) { [weak self] _ in self?.web.reload() })
    a.addAction(UIAlertAction(title: "Open the website", style: .default) { _ in UIApplication.shared.open(URL(string: SITE + "/")!) })
    a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in self?.markTab() })
    a.popoverPresentationController?.sourceView = tabBar
    a.popoverPresentationController?.sourceRect = CGRect(x: tabBar.bounds.maxX - 40, y: 0, width: 1, height: 1)
    present(a, animated: true)
  }

  // the tab that belongs to the page on screen (also after links inside the pages)
  private func markTab() {
    guard let u = web.url, let items = tabBar.items else { return }
    let p = u.path, q = u.query ?? ""
    let i: Int
    if p == "/manager" { i = 0 }
    else if p == "/admin" { i = q.contains("tab=team") ? 2 : 1 }
    else if p.hasPrefix("/admin/bugs") { i = 3 }
    else if p == "/admin/login" { return }
    else { i = 4 }
    tabBar.selectedItem = items[i]
  }

  // the red number on Bugs: reports waiting for the owner (read by the page's own login, so no password here)
  private func updateBadge() {
    guard let u = web.url, let h = u.host, HOSTS.contains(h) else { return }
    let js = "const r = await fetch('/admin/bugs/api', {cache:'no-store'}); if (!r.ok) return -1; const j = await r.json(); return (j.cards||[]).filter(c => c.stage === 'you' && !c.test).length;"
    web.callAsyncJavaScript(js, arguments: [:], in: nil, in: .page) { [weak self] res in
      guard let self = self, case .success(let v) = res, let n = (v as? NSNumber)?.intValue, n >= 0 else { return }
      self.tabBar.items?[3].badgeValue = n > 0 ? String(n) : nil
    }
  }

  // ---- web view
  // links to other sites (Discord, GitHub) open in Safari or their app; the panel's own pages stay here
  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = action.request.url else { return decisionHandler(.allow) }
    let isWeb = url.scheme == "http" || url.scheme == "https"
    let ours = url.host.map { HOSTS.contains($0) } ?? true
    if (isWeb && !ours && action.navigationType == .linkActivated) || (!isWeb && url.scheme != "about") {
      UIApplication.shared.open(url)
      return decisionHandler(.cancel)
    }
    decisionHandler(.allow)
  }

  // target="_blank": our pages here, other sites outside
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    if let url = action.request.url {
      if let h = url.host, HOSTS.contains(h) { webView.load(URLRequest(url: url)) } else { UIApplication.shared.open(url) }
    }
    return nil
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { markTab() }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    refresh.endRefreshing()
    hideSplash()
    markTab()
    updateBadge()
  }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { refresh.endRefreshing() }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    refresh.endRefreshing()
    hideSplash()
    if (error as NSError).code == NSURLErrorCancelled { return }
    let html = """
    <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>
    body{margin:0;min-height:100vh;display:grid;place-items:center;background:#0b0a14;color:#f3f1ff;font:17px -apple-system,system-ui,sans-serif;text-align:center}
    p{color:#a39fc0;margin:8px 24px 22px}a{display:inline-block;padding:14px 26px;border-radius:12px;background:#ff8a1f;color:#1a0f02;font-weight:800;text-decoration:none}
    </style></head><body><div><h2>Can't reach the server</h2><p>Check your internet, then try again.</p><a href="\(SITE + TABS[0].path)">Try again</a></div></body></html>
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
