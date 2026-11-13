// Ninja Online for iPhone (owner, 13 Nov 2026: "make an IPA for iPhone that preinstalls the files and makes it playable for real").
// The browser version of the original game (server/webclient/emu: an ARM emulator in JavaScript running the Android app's own code)
// inside an app, with every game file (code, 107 MB of pictures and sounds) packed into the app: nothing big is downloaded.
//
// How: the app runs a tiny web server on 127.0.0.1 (LocalServer below) and shows its page full screen in a web view.
//   /play/...        the page and the game files, from the app (folder "web" in the app). A file the app lacks (a newer hot update)
//                    is fetched from the website instead.
//   everything else  the game's requests (login, fights, ...): passed on to https://ninjaonlinereborn.com/game/ (the public server).
// 127.0.0.1 counts as a secure page, so iPhones should keep their fast JavaScript compiler on. If the page measures slow JavaScript
// anyway, it switches itself to the website's page and still reads the files from this app (server/webclient/emu/main.js, ?app=1).
// Built on GitHub's Mac (.github/workflows/ios-game.yml), installed by sideloading (tools/ios-game/README.md).
import AVFoundation
import Network
import UIKit
import WebKit

let SITE = "https://ninjaonlinereborn.com"
let FIRST_PORT: UInt16 = 18765 // keep it fixed: the browser storage (login, downloaded update) belongs to this address

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // game sound plays even with the silent switch on, like other games
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    try? AVAudioSession.sharedInstance().setActive(true)
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.backgroundColor = .black
    w.rootViewController = GameViewController()
    w.makeKeyAndVisible()
    window = w
    return true
  }
}

// ------------------------------------------------------------------------------------------------ the page
class GameViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
  private var web: WKWebView!
  private let server = LocalServer(root: Bundle.main.resourceURL!.appendingPathComponent("web"))
  private var loaded = false

  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default() // keeps the login and the downloaded hot update between starts
    cfg.allowsInlineMediaPlayback = true
    cfg.mediaTypesRequiringUserActionForPlayback = []
    cfg.applicationNameForUserAgent = "NinjaOnlineApp/1.0 Mobile/15E148 Safari/604.1"
    web = WKWebView(frame: view.bounds, configuration: cfg)
    web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    web.isOpaque = false
    web.backgroundColor = .black
    web.scrollView.backgroundColor = .black
    web.scrollView.isScrollEnabled = false
    web.scrollView.bounces = false
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.navigationDelegate = self
    web.uiDelegate = self
    if #available(iOS 16.4, *) { web.isInspectable = true } // a Mac's Safari can look inside (Develop menu)
    view.addSubview(web)

    server.start { [weak self] port in
      DispatchQueue.main.async {
        guard let self = self, !self.loaded else { return }
        self.loaded = true
        self.web.load(URLRequest(url: URL(string: "http://127.0.0.1:\(port)/play/emu/?app=1")!))
      }
    }
    // iOS may close the little server's socket while the app is in the background: open it again on return
    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
      self?.server.ensureRunning()
    }
  }

  // links to other sites (Discord, the wiki) open in Safari; the game's own pages stay here
  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = action.request.url, let host = url.host else { decisionHandler(.allow); return }
    if host == "127.0.0.1" || host == "ninjaonlinereborn.com" || url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" {
      decisionHandler(.allow)
    } else {
      UIApplication.shared.open(url)
      decisionHandler(.cancel)
    }
  }

  // the page's own process ran out of memory or crashed: start the page again
  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    server.ensureRunning()
    webView.reload()
  }

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
}

// ------------------------------------------------------------------------------------------------ the little web server
final class LocalServer {
  private let root: URL
  private let queue = DispatchQueue(label: "local-server", qos: .userInitiated, attributes: .concurrent)
  private var listener: NWListener?
  private var port: UInt16 = FIRST_PORT
  private var onReady: ((UInt16) -> Void)?
  private let session: URLSession = {
    let c = URLSessionConfiguration.default
    c.timeoutIntervalForRequest = 60
    c.requestCachePolicy = .reloadIgnoringLocalCacheData
    c.httpCookieStorage = nil
    c.httpShouldSetCookies = false
    return URLSession(configuration: c)
  }()

  init(root: URL) { self.root = root }

  func start(_ ready: @escaping (UInt16) -> Void) {
    onReady = ready
    listen(on: FIRST_PORT, triesLeft: 10)
  }

  func ensureRunning() {
    if let l = listener, case .ready = l.state { return }
    listener?.cancel()
    listen(on: port, triesLeft: 10)
  }

  private func listen(on p: UInt16, triesLeft: Int) {
    let params = NWParameters.tcp
    params.allowLocalEndpointReuse = true
    params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: p)!)
    guard let l = try? NWListener(using: params) else {
      if triesLeft > 0 { listen(on: p + 1, triesLeft: triesLeft - 1) }
      return
    }
    listener = l
    l.newConnectionHandler = { [weak self] c in self?.accept(c) }
    l.stateUpdateHandler = { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .ready:
        self.port = p
        if let r = self.onReady { self.onReady = nil; r(p) }
      case .failed:
        l.cancel()
        // the port is taken (another app): try the next one; after a background pause: the same one again
        let next = self.onReady != nil ? p + 1 : p
        if triesLeft > 0 { self.queue.asyncAfter(deadline: .now() + 0.3) { self.listen(on: next, triesLeft: triesLeft - 1) } }
      default:
        break
      }
    }
    l.start(queue: queue)
  }

  private func accept(_ c: NWConnection) {
    c.start(queue: queue)
    receive(c, Data())
  }

  private func receive(_ c: NWConnection, _ sofar: Data) {
    c.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [weak self] data, _, done, error in
      guard let self = self else { c.cancel(); return }
      var buf = sofar
      if let d = data { buf.append(d) }
      if let req = Request(buf) { self.handle(req, c); return }
      if done || error != nil || buf.count > 16 << 20 { c.cancel(); return }
      self.receive(c, buf)
    }
  }

  private func handle(_ req: Request, _ c: NWConnection) {
    if req.method == "OPTIONS" { send(c, 204, "text/plain", Data()); return }
    let path = req.path.removingPercentEncoding ?? req.path
    if path.hasPrefix("/play/") {
      var rel = String(path.dropFirst("/play/".count))
      if rel.isEmpty || rel.hasSuffix("/") { rel += "index.html" }
      if !rel.contains(".."), let data = try? Data(contentsOf: root.appendingPathComponent(rel), options: .mappedIfSafe) {
        send(c, 200, LocalServer.type(of: rel), data)
        return
      }
      proxy(req, to: SITE + req.path + req.query, c) // not in the app (a newer hot update): from the website
      return
    }
    proxy(req, to: SITE + "/game" + req.path + req.query, c) // the game's requests: the public server
  }

  private func proxy(_ req: Request, to address: String, _ c: NWConnection) {
    guard let url = URL(string: address) else { send(c, 400, "text/plain", Data("bad address".utf8)); return }
    var r = URLRequest(url: url)
    r.httpMethod = req.method
    if !req.body.isEmpty { r.httpBody = req.body }
    if let t = req.headers["content-type"] { r.setValue(t, forHTTPHeaderField: "Content-Type") }
    session.dataTask(with: r) { [weak self] data, response, _ in
      let h = response as? HTTPURLResponse
      let type = h?.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
      self?.send(c, h?.statusCode ?? 502, type, data ?? Data())
    }.resume()
  }

  private func send(_ c: NWConnection, _ status: Int, _ type: String, _ body: Data) {
    let head = "HTTP/1.1 \(status) \(status < 400 ? "OK" : "Error")\r\n" +
      "Content-Type: \(type)\r\nContent-Length: \(body.count)\r\n" +
      "Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
      "Cache-Control: no-cache\r\nConnection: close\r\n\r\n"
    var out = Data(head.utf8)
    out.append(body)
    c.send(content: out, completion: .contentProcessed { _ in c.cancel() })
  }

  static func type(of name: String) -> String {
    switch (name as NSString).pathExtension.lowercased() {
    case "html": return "text/html; charset=utf-8"
    case "js": return "text/javascript; charset=utf-8"
    case "css": return "text/css"
    case "json": return "application/json"
    case "png": return "image/png"
    case "mp3": return "audio/mpeg"
    default: return "application/octet-stream"
    }
  }
}

// one HTTP request, once all of it has arrived (nil until then)
struct Request {
  let method: String, path: String, query: String
  let headers: [String: String]
  let body: Data

  init?(_ buf: Data) {
    guard let end = buf.range(of: Data("\r\n\r\n".utf8)) else { return nil }
    guard let head = String(data: buf.subdata(in: buf.startIndex..<end.lowerBound), encoding: .utf8) else { return nil }
    let lines = head.components(separatedBy: "\r\n")
    let first = lines[0].split(separator: " ")
    guard first.count >= 2 else { return nil }
    var h: [String: String] = [:]
    for line in lines.dropFirst() {
      if let i = line.firstIndex(of: ":") {
        h[line[..<i].lowercased()] = line[line.index(after: i)...].trimmingCharacters(in: .whitespaces)
      }
    }
    let length = Int(h["content-length"] ?? "0") ?? 0
    let bodyStart = end.upperBound
    guard buf.endIndex - bodyStart >= length else { return nil }
    method = String(first[0])
    let target = String(first[1])
    if let q = target.firstIndex(of: "?") { path = String(target[..<q]); query = String(target[q...]) } else { path = target; query = "" }
    headers = h
    body = buf.subdata(in: bodyStart..<(bodyStart + length))
  }
}
