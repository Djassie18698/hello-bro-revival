// The game's own window (owner, 22 Nov 2026: "it looks like it loads a webpage, can't we make a game that's fully on the PC?").
// A plain Windows window named "Ninja Online" with the game's icon; inside it the drawing engine that is part of Windows
// (WebView2) shows the game. Nothing of a browser is visible or usable: no title of a page, no address, no menus, no right-click
// menu, no browser keys (F5, Ctrl+P ...), no zoom. While the game loads the window is dark with the game's name, never white.
// F11 or Alt+Enter = full screen (the game's own F key too). Links (Wiki, Discord) open in the PC's normal browser.
// Needs next to the program: Microsoft.Web.WebView2.Core.dll, Microsoft.Web.WebView2.WinForms.dll, WebView2Loader.dll
// (Microsoft's WebView2 SDK; BUILD.bat copies them). Written for the C# 5 compiler that comes with Windows.
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

class GameWindow : Form
{
    readonly WebView2 view = new WebView2();
    readonly Label wait = new Label();
    readonly string url, dataDir; readonly bool dev;
    bool full; FormWindowState before; Rectangle beforeBounds;
    bool failed;

    // true = the window ran and was closed; false = WebView2 is not on this PC (the caller falls back to a browser window)
    public static bool Run(string url, string dataDir, bool dev)
    {
        try { string v = CoreWebView2Environment.GetAvailableBrowserVersionString(); if (string.IsNullOrEmpty(v)) return false; } catch { return false; }
        Application.EnableVisualStyles();
        GameWindow w = new GameWindow(url, dataDir, dev);
        Application.Run(w);
        return !w.failed;
    }

    GameWindow(string url, string dataDir, bool dev)
    {
        this.url = url; this.dataDir = dataDir; this.dev = dev;
        Text = "Ninja Online"; BackColor = Color.FromArgb(16, 12, 10); StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(1600, 900); MinimumSize = new Size(480, 640); WindowState = FormWindowState.Maximized; KeyPreview = true;
        try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
        wait.Text = "NINJA ONLINE\n\nloading..."; wait.ForeColor = Color.FromArgb(240, 190, 90); wait.Font = new Font("Segoe UI", 28, FontStyle.Bold);
        wait.TextAlign = ContentAlignment.MiddleCenter; wait.Dock = DockStyle.Fill;
        view.Dock = DockStyle.Fill; view.DefaultBackgroundColor = Color.FromArgb(16, 12, 10); view.Visible = false;
        Controls.Add(view); Controls.Add(wait);
        view.CoreWebView2InitializationCompleted += Ready;
        Load += delegate { Start(); };
    }

    async void Start()
    {
        try {
            Directory.CreateDirectory(dataDir);
            CoreWebView2EnvironmentOptions opt = new CoreWebView2EnvironmentOptions("--autoplay-policy=no-user-gesture-required --disable-features=Translate,msSmartScreenProtection --disable-background-timer-throttling --disable-renderer-backgrounding");
            CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, dataDir, opt);
            await view.EnsureCoreWebView2Async(env);
        } catch { failed = true; Close(); }
    }

    void Ready(object sender, CoreWebView2InitializationCompletedEventArgs e)
    {
        if (!e.IsSuccess) { failed = true; Close(); return; }
        CoreWebView2 c = view.CoreWebView2;
        c.Settings.AreDefaultContextMenusEnabled = dev; c.Settings.AreDevToolsEnabled = dev; c.Settings.IsStatusBarEnabled = false;
        c.Settings.AreBrowserAcceleratorKeysEnabled = dev; c.Settings.IsZoomControlEnabled = false; c.Settings.IsBuiltInErrorPageEnabled = false;
        c.Settings.IsPasswordAutosaveEnabled = false; c.Settings.IsGeneralAutofillEnabled = false; c.Settings.IsSwipeNavigationEnabled = false;
        c.DocumentTitleChanged += delegate { Text = "Ninja Online"; };
        c.NewWindowRequested += delegate(object s, CoreWebView2NewWindowRequestedEventArgs a) { a.Handled = true; try { if (a.Uri.StartsWith("http")) Process.Start(a.Uri); } catch { } };
        c.ContainsFullScreenElementChanged += delegate { SetFull(c.ContainsFullScreenElement); };
        c.NavigationCompleted += delegate(object s, CoreWebView2NavigationCompletedEventArgs a) {
            if (a.IsSuccess) { view.Visible = true; wait.Visible = false; view.Focus(); }
            else { wait.Text = "NINJA ONLINE\n\nThe game could not start.\nClose this window and start it again."; wait.Visible = true; view.Visible = false; }
        };
        // a page other than the game never shows here: anything else goes to the PC's browser
        c.NavigationStarting += delegate(object s, CoreWebView2NavigationStartingEventArgs a) {
            if (!a.Uri.StartsWith("http://127.0.0.1:")) { a.Cancel = true; try { if (a.Uri.StartsWith("http")) Process.Start(a.Uri); } catch { } }
        };
        view.KeyDown += Keys_;
        c.Navigate(url);
    }

    void Keys_(object sender, KeyEventArgs e) { if (e.KeyCode == Keys.F11 || (e.Alt && e.KeyCode == Keys.Enter)) { SetFull(!full); e.Handled = true; } }
    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (keyData == Keys.F11 || keyData == (Keys.Alt | Keys.Enter)) { SetFull(!full); return true; }
        return base.ProcessCmdKey(ref msg, keyData);
    }
    void SetFull(bool on)
    {
        if (on == full) return;
        full = on;
        if (on) { before = WindowState; beforeBounds = Bounds; WindowState = FormWindowState.Normal; FormBorderStyle = FormBorderStyle.None; Bounds = Screen.FromControl(this).Bounds; }
        else { FormBorderStyle = FormBorderStyle.Sizable; Bounds = beforeBounds; WindowState = before; }
    }
}
