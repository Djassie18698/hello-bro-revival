// Ninja Online for PC (owner, 22 Nov 2026: "make it a downloadable game on PC, I want no lag at all").
// One small program next to a folder "game" that holds the whole rewritten game (server/webclient with its pictures and sounds):
//   1. it serves that folder from this PC on http://127.0.0.1:<a free port>/play/  -> every picture loads from the disk, at once;
//   2. everything else the game asks (/rl_..., /xk_..., /gump/..., /api/..., /status, /cdn/...) is passed on to the game server
//      whose address stands in server.txt next to the program (first line; default: the public server);
//   3. it opens the game in its own window (Microsoft Edge or Chrome in "app" mode: no address bar, own profile) and ends when
//      that window is closed.
// Built with the C# compiler that comes with Windows (BUILD.bat); nothing to install. Switches (for testing):
//   --no-window   only serve (the port is written to %LOCALAPPDATA%\NinjaOnline\port.txt)     --port=<n>   a fixed port
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

static class Launcher
{
    static string gameDir, server;
    static readonly Dictionary<string, string> Types = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
        { ".html", "text/html; charset=utf-8" }, { ".js", "text/javascript; charset=utf-8" }, { ".css", "text/css; charset=utf-8" }, { ".json", "application/json; charset=utf-8" },
        { ".png", "image/png" }, { ".webp", "image/webp" }, { ".jpg", "image/jpeg" }, { ".ico", "image/x-icon" }, { ".svg", "image/svg+xml" },
        { ".mp3", "audio/mpeg" }, { ".ogg", "audio/ogg" }, { ".wav", "audio/wav" }, { ".fnt", "text/plain; charset=utf-8" }, { ".xml", "text/xml; charset=utf-8" },
        { ".lua", "text/plain; charset=utf-8" }, { ".txt", "text/plain; charset=utf-8" }, { ".webmanifest", "application/manifest+json" }, { ".ttf", "font/ttf" }, { ".woff2", "font/woff2" },
    };

    [STAThread]
    static int Main(string[] args)
    {
        string here = AppDomain.CurrentDomain.BaseDirectory;
        gameDir = Path.GetFullPath(Path.Combine(here, "game"));
        bool window = true; int port = 0;
        foreach (string a in args) { if (a == "--no-window") window = false; if (a.StartsWith("--port=")) int.TryParse(a.Substring(7), out port); }
        if (!File.Exists(Path.Combine(gameDir, "index.html"))) { Say("The folder \"game\" is missing next to this program.\nUnpack the whole zip and start Ninja Online.exe from there."); return 1; }
        server = "http://ninjaonline.duckdns.org:18080";
        try { string f = Path.Combine(here, "server.txt"); if (File.Exists(f)) foreach (string line in File.ReadAllLines(f)) { string t = line.Trim(); if (t.Length > 0 && !t.StartsWith("#")) { server = t.TrimEnd('/'); break; } } } catch { }
        if (!server.StartsWith("http://") && !server.StartsWith("https://")) server = "http://" + server;
        ServicePointManager.DefaultConnectionLimit = 32; ServicePointManager.Expect100Continue = false;
        try { ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072; } catch { } // TLS 1.2 for an https server

        HttpListener http = null;
        for (int tries = 0; tries < 20 && http == null; tries++) {
            int p = port > 0 ? port : FreePort();
            try { HttpListener l = new HttpListener(); l.Prefixes.Add("http://127.0.0.1:" + p + "/"); l.Start(); http = l; port = p; } catch { if (port > 0) break; }
        }
        if (http == null) { Say("Could not start: no free port on this PC."); return 1; }
        string data = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "NinjaOnline");
        Directory.CreateDirectory(data);
        try { File.WriteAllText(Path.Combine(data, "port.txt"), port.ToString()); } catch { }
        Thread t2 = new Thread(() => { while (http.IsListening) { try { HttpListenerContext c = http.GetContext(); ThreadPool.QueueUserWorkItem(_ => Handle(c)); } catch { break; } } });
        t2.IsBackground = true; t2.Start();
        ThreadPool.SetMinThreads(16, 16);

        if (!window) { Thread.Sleep(Timeout.Infinite); return 0; }
        string browser = FindBrowser();
        if (browser == null) { Say("Microsoft Edge or Google Chrome is needed to show the game, and neither was found."); return 1; }
        string url = "http://127.0.0.1:" + port + "/play/?pc=1";
        ProcessStartInfo psi = new ProcessStartInfo(browser, "--app=" + url + " --user-data-dir=\"" + Path.Combine(data, "profile") + "\" --no-first-run --no-default-browser-check --start-maximized --autoplay-policy=no-user-gesture-required --disable-features=Translate,msEdgeSidebarV2 --disable-background-timer-throttling --disable-renderer-backgrounding");
        psi.UseShellExecute = false;
        try { Process.Start(psi); } catch (Exception e) { Say("Could not open the game window:\n" + e.Message); return 1; }
        // The process we started is often only a starter that hands over and ends at once (22 Nov 2026: the window then showed
        // "can't reach this page", because we had already stopped serving). So: keep serving for as long as ANY browser process
        // runs with our own profile folder, looked up every 2 seconds; two looks in a row without one (after the first 15 s) =
        // the window is closed.
        string mark = Path.Combine(data, "profile");
        Thread.Sleep(15000);
        int gone = 0;
        while (gone < 2) { Thread.Sleep(2000); gone = WindowOpen(mark) ? 0 : gone + 1; }
        try { http.Stop(); } catch { }
        return 0;
    }

    static bool WindowOpen(string profile)
    {
        try {
            using (var q = new System.Management.ManagementObjectSearcher("SELECT CommandLine FROM Win32_Process WHERE Name='msedge.exe' OR Name='chrome.exe'"))
                foreach (System.Management.ManagementObject o in q.Get()) { string c = o["CommandLine"] as string; if (c != null && c.IndexOf(profile, StringComparison.OrdinalIgnoreCase) >= 0) return true; }
            return false;
        } catch { return true; } // cannot look: better to keep serving
    }
    static void Say(string text) { try { System.Windows.Forms.MessageBox.Show(text, "Ninja Online"); } catch { } }
    static int FreePort() { TcpListener l = new TcpListener(IPAddress.Loopback, 0); l.Start(); int p = ((IPEndPoint)l.LocalEndpoint).Port; l.Stop(); return p; }
    static string FindBrowser()
    {
        string pf = Environment.GetEnvironmentVariable("ProgramFiles"), pf86 = Environment.GetEnvironmentVariable("ProgramFiles(x86)"), local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        foreach (string p in new[] { pf86 + @"\Microsoft\Edge\Application\msedge.exe", pf + @"\Microsoft\Edge\Application\msedge.exe", pf + @"\Google\Chrome\Application\chrome.exe", pf86 + @"\Google\Chrome\Application\chrome.exe", local + @"\Google\Chrome\Application\chrome.exe" })
            if (!string.IsNullOrEmpty(p) && File.Exists(p)) return p;
        return null;
    }

    static void Handle(HttpListenerContext c)
    {
        try {
            string path = Uri.UnescapeDataString(c.Request.Url.AbsolutePath);
            if (path == "/" || path == "/play") { c.Response.Redirect("/play/?pc=1"); c.Response.Close(); return; }
            if (path.StartsWith("/play/")) ServeFile(c, path.Substring(6)); else Forward(c);
        } catch { try { c.Response.Abort(); } catch { } }
    }

    // a file of the game folder: never anything outside it; the browser may keep pictures and sounds (they only change with a new download)
    static void ServeFile(HttpListenerContext c, string rel)
    {
        if (rel.Length == 0 || rel.EndsWith("/")) rel += "index.html";
        string full = Path.GetFullPath(Path.Combine(gameDir, rel.Replace('/', Path.DirectorySeparatorChar)));
        if (!full.StartsWith(gameDir + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) || !File.Exists(full)) { c.Response.StatusCode = 404; c.Response.Close(); return; }
        string ext = Path.GetExtension(full), type;
        c.Response.ContentType = Types.TryGetValue(ext, out type) ? type : "application/octet-stream";
        bool media = ext == ".png" || ext == ".webp" || ext == ".jpg" || ext == ".mp3" || ext == ".ogg" || ext == ".fnt";
        c.Response.AddHeader("Cache-Control", media ? "public, max-age=86400" : "no-cache");
        FileInfo fi = new FileInfo(full);
        string range = c.Request.Headers["Range"]; long from = 0, to = fi.Length - 1;
        if (range != null && range.StartsWith("bytes=")) { // a sound the browser asks for in parts
            string[] p = range.Substring(6).Split('-'); long a, b;
            if (p.Length == 2 && long.TryParse(p[0], out a)) { from = a; if (long.TryParse(p[1], out b)) to = Math.Min(b, fi.Length - 1); if (from <= to) { c.Response.StatusCode = 206; c.Response.AddHeader("Content-Range", "bytes " + from + "-" + to + "/" + fi.Length); } else { from = 0; to = fi.Length - 1; } }
        }
        c.Response.AddHeader("Accept-Ranges", "bytes");
        c.Response.ContentLength64 = to - from + 1;
        if (c.Request.HttpMethod != "HEAD") using (FileStream f = new FileStream(full, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 65536)) {
            f.Seek(from, SeekOrigin.Begin); byte[] buf = new byte[65536]; long left = to - from + 1;
            while (left > 0) { int n = f.Read(buf, 0, (int)Math.Min(buf.Length, left)); if (n <= 0) break; c.Response.OutputStream.Write(buf, 0, n); left -= n; }
        }
        c.Response.Close();
    }

    // a request of the game: passed on to the game server as it is, the answer handed back as it is
    static void Forward(HttpListenerContext c)
    {
        HttpWebRequest q = (HttpWebRequest)WebRequest.Create(server + c.Request.Url.PathAndQuery);
        q.Method = c.Request.HttpMethod; q.Timeout = 30000; q.ReadWriteTimeout = 30000; q.AllowAutoRedirect = false; q.Proxy = null; q.KeepAlive = true;
        q.UserAgent = c.Request.UserAgent ?? "NinjaOnlinePC";
        if (c.Request.ContentType != null) q.ContentType = c.Request.ContentType;
        string cookie = c.Request.Headers["Cookie"]; if (cookie != null) q.Headers["Cookie"] = cookie;
        if (c.Request.HasEntityBody) { using (Stream s = q.GetRequestStream()) c.Request.InputStream.CopyTo(s); } else if (q.Method == "POST") q.ContentLength = 0;
        HttpWebResponse r;
        try { r = (HttpWebResponse)q.GetResponse(); }
        catch (WebException e) { r = e.Response as HttpWebResponse; if (r == null) { c.Response.StatusCode = 502; byte[] m = Encoding.UTF8.GetBytes("game server not reachable"); c.Response.OutputStream.Write(m, 0, m.Length); c.Response.Close(); return; } }
        using (r) {
            c.Response.StatusCode = (int)r.StatusCode;
            if (r.ContentType != null) c.Response.ContentType = r.ContentType;
            foreach (string h in new[] { "Set-Cookie", "Location", "Cache-Control" }) { string v = r.Headers[h]; if (v != null) c.Response.AddHeader(h, v); }
            using (Stream s = r.GetResponseStream()) s.CopyTo(c.Response.OutputStream);
        }
        c.Response.Close();
    }
}
