// Bug Fixer app: start-up, one copy only, tray icon. Options: --tray (start hidden), --demo (sample cards, for screenshots),
// --snapshot <file.png> [--page you|board|runs] [--detail] (draws the window into a picture without showing it, then quits).
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using WF = System.Windows.Forms;
using SD = System.Drawing;

namespace FixerViewer
{
    static class Program
    {
        static WF.NotifyIcon tray;
        static MainWin win;
        static bool toldTray;

        public static void TellTray()
        {
            if (toldTray || tray == null) return;
            toldTray = true;
            tray.ShowBalloonTip(8000, "Bug Fixer keeps watching", "It's in the tray now and pops up when something needs you. Right-click the icon to quit.", WF.ToolTipIcon.Info);
        }

        static void ShowWin()
        {
            if (win == null) return;
            win.Show();
            if (win.WindowState == WindowState.Minimized) win.WindowState = WindowState.Normal;
            win.Activate(); win.Topmost = true; win.Topmost = false; win.Focus();
        }

        // checks every write action on a throwaway post it makes and deletes again (prints to selftest.log next to error.log)
        static void SelfTest(Store store)
        {
            var log = new List<string>();
            Action<string> say = x => log.Add(DateTime.Now.ToString("HH:mm:ss") + " " + x);
            try
            {
                store.Discord.Refresh(); say("read Discord: " + (store.Discord.Error == "" ? "ok, " + store.Discord.Posts.Count + " posts" : store.Discord.Error));
                var id = store.Discord.NewRequest("🧪 TEST: Bug Fixer app check", "Checking the app's buttons; this post deletes itself in a few seconds."); say("new request: " + id);
                store.Discord.Write(id, "test message from the app"); say("write: ok");
                store.Discord.SetFixerTag(id, "Stopped"); say("tag Stopped: ok");
                store.Discord.SetFixerTag(id, "New report"); say("tag New report: ok");
                var msgs = store.Discord.Messages(id, "fixer"); say("read back: " + msgs.Count + " messages, from app: " + msgs.Count(m => m.FromApp) + ", owner: " + msgs.Count(m => m.Owner));
                var gone = store.Discord.DeleteReport(id, null, false, null); say("delete: " + string.Join(", ", gone));
            }
            catch (Exception e) { say("FAILED: " + e.Message); }
            File.WriteAllLines(Path.Combine(store.DataDir, "selftest.log"), log);
        }

        static string Arg(string[] a, string name) { var i = Array.IndexOf(a, name); return i >= 0 && i + 1 < a.Length ? a[i + 1] : null; }

        [STAThread]
        static void Main(string[] args)
        {
            var snapshot = Arg(args, "--snapshot");
            bool first = true;
            var mutex = snapshot != null ? null : new Mutex(true, "HelloBroBugFixerViewer3", out first);
            if (mutex != null && !first)
            {
                try { EventWaitHandle.OpenExisting("HelloBroBugFixerShow").Set(); } catch { }
                return;
            }
            string repo = null;
            var cands = new List<string>();
            var env = Environment.GetEnvironmentVariable("HB_REPO");
            if (!string.IsNullOrEmpty(env)) cands.Add(env);
            var exeDir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            foreach (var d in new[] { exeDir, Path.Combine(exeDir, ".."), Path.Combine(exeDir, "HelloBroServer"), Path.Combine(exeDir, "..", "HelloBroServer"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "HelloBroServer"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Desktop", "HelloBroServer") }) cands.Add(d);
            foreach (var c in cands)
                if (File.Exists(Path.Combine(c, "discord", "dc.js")) && File.Exists(Path.Combine(c, "CLAUDE.md"))) { repo = Path.GetFullPath(c); break; }
            if (repo == null) { WF.MessageBox.Show("Could not find the HelloBroServer folder. Keep the Bug Fixer folder on the Desktop next to it.", "Bug Fixer"); return; }

            var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
            var store = new Store(repo, args.Contains("--demo"));
            app.DispatcherUnhandledException += (s, e) =>
            {
                try { File.AppendAllText(Path.Combine(store.DataDir, "error.log"), DateTime.Now + " " + e.Exception + "\r\n"); } catch { }
                if (win != null) win.Toast("Something went wrong: " + e.Exception.Message, true);
                e.Handled = true;
            };
            if (args.Contains("--selftest")) { SelfTest(store); return; }
            store.Start();
            win = new MainWin(store);

            if (snapshot != null)
            {
                win.Snapshotting = true;
                win.WindowStartupLocation = WindowStartupLocation.Manual; win.Left = -32000; win.Top = 0; win.Width = 1600; win.Height = 1000;
                win.ShowActivated = false; win.ShowInTaskbar = false;
                win.Show();
                var started = DateTime.Now; var phase = 0;
                var t = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
                t.Tick += (s, e) =>
                {
                    var ready = store.Current.DiscordLoaded || (DateTime.Now - started).TotalSeconds > 40;
                    if (phase == 0 && ready && (DateTime.Now - started).TotalSeconds > 4) { win.ShowPage(Arg(args, "--page") ?? "you"); if (args.Contains("--detail")) win.OpenFirst(Arg(args, "--stage") ?? "fixer"); phase = 1; started = DateTime.Now; }
                    else if (phase == 1 && (DateTime.Now - started).TotalSeconds > 4) { win.Tick(); win.SaveSnapshot(snapshot); t.Stop(); app.Shutdown(); }
                };
                t.Start();
                app.Run();
                return;
            }

            // tray
            SD.Icon icon = null;
            try { using (var s = typeof(Program).Assembly.GetManifestResourceStream("app.ico")) icon = new SD.Icon(s, 32, 32); } catch { }
            tray = new WF.NotifyIcon { Icon = icon ?? SD.SystemIcons.Information, Text = "Bug Fixer", Visible = true };
            var menu = new WF.ContextMenuStrip();
            menu.Items.Add("Open Bug Fixer", null, (s, e) => ShowWin());
            menu.Items.Add("Quit", null, (s, e) => { tray.Visible = false; win.Quitting = true; win.Close(); app.Shutdown(); });
            tray.ContextMenuStrip = menu;
            tray.DoubleClick += (s, e) => ShowWin();
            tray.BalloonTipClicked += (s, e) => ShowWin();
            store.Alert += (title, text, warn) => app.Dispatcher.BeginInvoke((Action)(() =>
                tray.ShowBalloonTip(9000, title, string.IsNullOrEmpty(text) ? " " : text, warn ? WF.ToolTipIcon.Warning : WF.ToolTipIcon.Info)));
            app.Exit += (s, e) => { tray.Visible = false; tray.Dispose(); };

            // a second start just brings this window to the front
            var show = new EventWaitHandle(false, EventResetMode.AutoReset, "HelloBroBugFixerShow");
            new Thread(() => { while (true) { show.WaitOne(); app.Dispatcher.BeginInvoke((Action)ShowWin); } }) { IsBackground = true }.Start();

            if (!args.Contains("--tray")) win.Show();
            app.Run();
            GC.KeepAlive(mutex);
        }
    }
}
