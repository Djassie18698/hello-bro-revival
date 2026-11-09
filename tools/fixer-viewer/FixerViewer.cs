// BUG-FIXER-VIEWER: shows what the scheduled "hellobro-bug-fixer" Claude runs did, live.
// Read-only: it only reads the run logs (~/.claude/projects/<repo>/*.jsonl), docs/DISCORD-REPORTS.md
// and #bot-logs (through `node --env-file=.env dc.js read bot-logs 50`, which never prints the token).
// It never starts, stops or edits anything.
// Build: tools/fixer-viewer/BUILD.bat (C# 5, .NET Framework 4 csc.exe that ships with Windows).
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace FixerViewer
{
    enum Kind { Start, Action, Say, Found, Problem, Good, Waiting, Summary, Message }

    class Line
    {
        public DateTime Time; public Kind Kind; public string Text;
        public Line(DateTime t, Kind k, string s) { Time = t; Kind = k; Text = s; }
    }

    enum RunState { Working, Finished, Stopped, Stuck }

    class Run
    {
        public string File; public string Id; public DateTime Start; public DateTime Last;
        public long Size; public DateTime Mtime;
        public List<Line> Lines = new List<Line>();
        public RunState State; public string Result = ""; public string LastAction = "";
        public bool Fixing; public string FinalText = ""; public int StuckMinutes;
        public HashSet<string> ReportIds = new HashSet<string>();
        public DateTime PendingSince = DateTime.MinValue; public string PendingLabel = "";
    }

    class Report
    {
        public DateTime Time; public string Who = ""; public string Title = ""; public string Id = "";
        public string Url = ""; public bool Wish; public bool Test; public string State = "";
    }

    static class Parser
    {
        static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
        public static string Repo = "";

        static object Get(object o, string k)
        {
            var d = o as Dictionary<string, object>;
            if (d == null) return null;
            object v; return d.TryGetValue(k, out v) ? v : null;
        }
        static string Str(object o, string k) { var v = Get(o, k); return v == null ? null : v.ToString(); }

        static DateTime Ts(object o)
        {
            var s = Str(o, "timestamp");
            DateTime t;
            if (s != null && DateTime.TryParse(s, CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out t))
                return t.ToLocalTime();
            return DateTime.MinValue;
        }

        public static string Clean(string s)
        {
            if (s == null) return "";
            // never show anything that looks like a secret
            s = Regex.Replace(s, @"[\w-]{23,28}\.[\w-]{6,7}\.[\w-]{27,40}", "[hidden]");
            s = Regex.Replace(s, @"sk-ant-[\w-]+", "[hidden]");
            s = Regex.Replace(s, @"(?i)(token|password|api[_-]?key)\s*[=:]\s*\S+", "$1=[hidden]");
            return s;
        }

        static string OneLine(string s, int max)
        {
            s = Clean(s ?? "");
            s = Regex.Replace(s, @"\*\*|`", "");
            s = Regex.Replace(s, @"\s+", " ").Trim();
            return s.Length > max ? s.Substring(0, max - 1) + "…" : s;
        }

        static string RelPath(string p)
        {
            if (string.IsNullOrEmpty(p)) return "a file";
            p = p.Replace('\\', '/');
            var r = Repo.Replace('\\', '/').TrimEnd('/') + "/";
            if (p.StartsWith(r, StringComparison.OrdinalIgnoreCase)) p = p.Substring(r.Length);
            var m = Regex.Match(p, @"/scratchpad/(.+)$");
            if (m.Success) return "a note (" + m.Groups[1].Value + ")";
            return p;
        }

        static readonly string[][] Patterns = new string[][] {
            new [] { @"dc\.js read bot-logs", "checking #bot-logs for new bug reports" },
            new [] { @"dc\.js read \d{17,20}", "reading the player's thread" },
            new [] { @"dc\.js read (?!bot-logs)([a-z-]+)", "reading Discord #$1" },
            new [] { @"dc\.js post dev-chat", "telling the owner in #dev-chat" },
            new [] { @"dc\.js post \d{17,20}", "answering the player in their thread" },
            new [] { @"dc\.js reply", "replying to the player" },
            new [] { @"dc\.js react", "putting a tick on the player's post" },
            new [] { @"DISCORD-REPORTS", "checking which reports are already handled" },
            new [] { @"check\.sh", "running all the checks" },
            new [] { @"smoke\.js", "running the smoke test" },
            new [] { @"fuzz\.js", "running the bad-input test" },
            new [] { @"exploit\.js", "running the cheat test" },
            new [] { @"realsave\.js", "testing on a copy of a real save" },
            new [] { @"probe\.js", "trying it on the test server" },
            new [] { @"emu\.sh (\w+)", "using the test emulator ($1)" },
            new [] { @"restart\.sh", "restarting the test server" },
            new [] { @"git commit", "committing" },
            new [] { @"git push", "uploading to GitHub" },
            new [] { @"sync_test_folder", "copying it to the owner's play folder" },
            new [] { @"build_wiki", "rebuilding the wiki" },
            new [] { @"build_cdn", "building a game hot update" },
            new [] { @"gh issue comment", "commenting on GitHub" },
            new [] { @"guides\.js", "updating a Discord guide" },
        };

        public static bool IsCheckOnly(string label)
        {
            return label.StartsWith("checking #bot-logs") || label.StartsWith("checking which reports") ||
                   label.StartsWith("planning") || label.StartsWith("loading tools");
        }

        static string BashLabel(string cmd, string desc)
        {
            cmd = cmd ?? "";
            var hits = new List<KeyValuePair<int, string>>();
            foreach (var p in Patterns)
            {
                var m = Regex.Match(cmd, p[0]);
                if (!m.Success) continue;
                var label = m.Result(p[1]);
                if (p[0] == "git commit")
                {
                    var mm = Regex.Match(cmd, "-m\\s+[\"']([^\"'\\n]{3,})");
                    if (mm.Success) label += ": \"" + OneLine(mm.Groups[1].Value, 110) + "\"";
                    var files = Regex.Match(cmd, @"\s--\s+([^;&|\n]+)");
                    if (files.Success) label += " (" + OneLine(files.Groups[1].Value, 120) + ")";
                }
                hits.Add(new KeyValuePair<int, string>(m.Index, label));
            }
            if (Regex.IsMatch(cmd, @"writeFileSync|>\s*(server|tools|docs|discord)/"))
            {
                var paths = Regex.Matches(cmd, @"['""]((?:server|tools|docs|discord)/[\w./-]+\.\w+)['""]").Cast<Match>()
                    .Select(x => x.Groups[1].Value).Distinct().Take(4).ToList();
                if (paths.Count > 0) hits.Add(new KeyValuePair<int, string>(int.MaxValue, "changing " + string.Join(", ", paths) + " with a script"));
            }
            if (hits.Count > 0)
                return string.Join(" + ", hits.OrderBy(h => h.Key).Select(h => h.Value).Distinct());
            if (!string.IsNullOrEmpty(desc)) return "looking: " + Char.ToLower(desc[0]) + desc.Substring(1);
            return "running a command";
        }

        static string ToolLabel(string name, object input)
        {
            switch (name)
            {
                case "Bash": case "PowerShell": return BashLabel(Str(input, "command"), Str(input, "description"));
                case "Edit": case "MultiEdit": return "editing " + RelPath(Str(input, "file_path"));
                case "Write": return "writing " + RelPath(Str(input, "file_path"));
                case "Read": return "reading " + RelPath(Str(input, "file_path"));
                case "Grep": return "searching the code for \"" + OneLine(Str(input, "pattern"), 50) + "\"";
                case "Glob": return "looking for files (" + OneLine(Str(input, "pattern"), 50) + ")";
                case "ToolSearch": return "loading tools";
                case "Skill": return "loading the skill " + Str(input, "skill");
                case "Agent": return "starting a helper: " + OneLine(Str(input, "description"), 80);
                case "SendMessage": return "messaging another Claude session";
                case "mcp__ccd_turn__wrap_up": return null; // handled separately
                case "mcp__ccd_turn__update_plan":
                    {
                        var items = Get(input, "items") as object[];
                        if (items != null)
                            return "planning: " + string.Join(" → ", items.Select(i => Str(i, "content")));
                        return null;
                    }
            }
            if (name.StartsWith("mcp__ccd_")) return null;
            return "using " + name.Replace("mcp__", "").Replace("__", " ");
        }

        static string ResultText(object c)
        {
            var content = Get(c, "content");
            if (content is string) return (string)content;
            var arr = content as object[];
            if (arr == null) return "";
            return string.Join("\n", arr.Select(x => Str(x, "text") ?? ""));
        }

        public static Run Load(string file, Run old)
        {
            var fi = new FileInfo(file);
            if (old != null && old.Size == fi.Length && old.Mtime == fi.LastWriteTimeUtc) return old;
            var run = new Run { File = file, Id = Path.GetFileNameWithoutExtension(file), Size = fi.Length, Mtime = fi.LastWriteTimeUtc };
            string all;
            using (var fs = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            using (var sr = new StreamReader(fs, Encoding.UTF8)) all = sr.ReadToEnd();

            var pending = new Dictionary<string, KeyValuePair<DateTime, string>>(); // tool_use id -> (time, label)
            var waitStart = new Dictionary<string, KeyValuePair<DateTime, string>>();
            int lastRefusalWait = -1;
            var toolNames = new Dictionary<string, string>();
            var toolCmds = new Dictionary<string, string>();
            bool lastWasFinalText = false, interrupted = false;
            DateTime lastEvent = DateTime.MinValue;

            foreach (var raw in all.Split('\n'))
            {
                if (raw.Length < 10) continue;
                if (raw.StartsWith("{\"type\":\"api-request") || raw.StartsWith("{\"type\":\"file-history")) continue;
                if (raw.Contains("\"type\":\"attachment\",\"uuid\"")) continue;
                object j;
                try { j = Json.DeserializeObject(raw); } catch { continue; } // last line may be half written
                var type = Str(j, "type");
                var t = Ts(j);
                if (type == "queue-operation")
                {
                    if (Str(j, "operation") == "enqueue" && run.Start == DateTime.MinValue) run.Start = t;
                    continue;
                }
                if (type != "user" && type != "assistant") continue;
                if (t != DateTime.MinValue) lastEvent = t;
                var msg = Get(j, "message");
                var content = Get(msg, "content");

                if (type == "user")
                {
                    if (content is string)
                    {
                        var s = (string)content;
                        if (s.Contains("<scheduled-task")) run.Lines.Add(new Line(t, Kind.Start, "Run started (scheduled every 2 hours)"));
                        else if (s.Contains("cross-session-message")) run.Lines.Add(new Line(t, Kind.Message, "Another Claude session sent it a message"));
                        else run.Lines.Add(new Line(t, Kind.Message, "Message: " + OneLine(s, 160)));
                        interrupted = false; lastWasFinalText = false;
                        continue;
                    }
                    var arr = content as object[];
                    if (arr == null) continue;
                    foreach (var c in arr)
                    {
                        var ct = Str(c, "type");
                        if (ct == "text")
                        {
                            var s = Str(c, "text") ?? "";
                            if (s.StartsWith("[Request interrupted")) { interrupted = true; }
                            else if (s.Contains("cross-session-message")) { run.Lines.Add(new Line(t, Kind.Message, "Another Claude session sent it a message")); interrupted = false; }
                            else if (s.Contains("<scheduled-task")) run.Lines.Add(new Line(t, Kind.Start, "Run started (scheduled every 2 hours)"));
                        }
                        else if (ct == "tool_result")
                        {
                            var id = Str(c, "tool_use_id") ?? "";
                            pending.Remove(id);
                            lastRefusalWait = -1;
                            var txt = ResultText(c);
                            var isErr = Get(c, "is_error") is bool && (bool)Get(c, "is_error");
                            string name; toolNames.TryGetValue(id, out name);
                            string cmd; toolCmds.TryGetValue(id, out cmd);
                            if (isErr && txt.Contains("doesn't want to proceed"))
                            {
                                KeyValuePair<DateTime, string> pw;
                                if (waitStart.TryGetValue(id, out pw) && t != DateTime.MinValue) lastRefusalWait = (int)(t - pw.Key).TotalMinutes;
                            }
                            if (isErr && txt.Contains("doesn't want to proceed"))
                                run.Lines.Add(new Line(t, Kind.Problem, "PERMISSION: refused or timed out (nobody clicked Allow in the Claude app)"));
                            else if (isErr)
                                run.Lines.Add(new Line(t, Kind.Problem, "FAILED: " + OneLine(txt, 140)));
                            if (cmd != null && cmd.Contains("bot-logs") && !isErr)
                            {
                                var found = FindReports(txt);
                                if (found.Count == 0 && Regex.IsMatch(cmd, @"dc\.js read bot-logs"))
                                    run.Lines.Add(new Line(t, Kind.Found, "No bug reports in that part of #bot-logs"));
                                foreach (var r in found)
                                {
                                    run.ReportIds.Add(r.Id);
                                    run.Lines.Add(new Line(t, Kind.Found, "REPORT: " + r.Title + (r.Who != "" ? " (from " + r.Who + ")" : "")));
                                }
                            }
                            if (cmd != null && Regex.IsMatch(cmd, @"check\.sh") && !isErr)
                            {
                                if (Regex.IsMatch(txt, @"(?i)\bfail|problem")) run.Lines.Add(new Line(t, Kind.Problem, "PROBLEM: the checks reported a problem"));
                            }
                            if (cmd != null && Regex.IsMatch(cmd, @"git push") && !isErr && Regex.IsMatch(txt, @"->\s*main"))
                                run.Lines.Add(new Line(t, Kind.Good, "OK: uploaded to GitHub"));
                            if (cmd != null && Regex.IsMatch(cmd, @"dc\.js (post|reply)") && txt.Contains("posted in"))
                                run.Lines.Add(new Line(t, Kind.Good, "OK: posted in Discord"));
                        }
                    }
                    continue;
                }

                // assistant
                var parts = content as object[];
                if (parts == null) continue;
                bool hadTool = false; string lastText = null;
                foreach (var c in parts)
                {
                    var ct = Str(c, "type");
                    if (ct == "text")
                    {
                        var s = Str(c, "text") ?? "";
                        if (s.Trim().Length == 0) continue;
                        lastText = s;
                        run.Lines.Add(new Line(t, Kind.Say, OneLine(s, 600)));
                    }
                    else if (ct == "tool_use")
                    {
                        hadTool = true;
                        var name = Str(c, "name") ?? "";
                        var input = Get(c, "input");
                        var id = Str(c, "id") ?? "";
                        toolNames[id] = name;
                        if (name == "Bash" || name == "PowerShell") toolCmds[id] = Str(input, "command") ?? "";
                        if (name == "mcp__ccd_turn__wrap_up")
                        {
                            run.Lines.Add(new Line(t, Kind.Summary, "Wrap-up: " + OneLine(Str(input, "recap"), 400)));
                            pending[id] = new KeyValuePair<DateTime, string>(t, "wrapping up");
                            continue;
                        }
                        var label = ToolLabel(name, input);
                        if (label == null) { pending[id] = new KeyValuePair<DateTime, string>(t, "updating its task list"); continue; }
                        label = Clean(label);
                        run.Lines.Add(new Line(t, Kind.Action, label));
                        run.LastAction = label;
                        if (!IsCheckOnly(label)) run.Fixing = true;
                        pending[id] = new KeyValuePair<DateTime, string>(t, label);
                        waitStart[id] = pending[id];
                    }
                }
                if (!hadTool && lastText != null) { lastWasFinalText = true; run.FinalText = lastText; interrupted = false; }
                else if (hadTool) lastWasFinalText = false;
            }

            if (run.Start == DateTime.MinValue) run.Start = run.Lines.Count > 0 ? run.Lines[0].Time : fi.CreationTime;
            run.Last = lastEvent == DateTime.MinValue ? run.Start : lastEvent;
            var now = DateTime.Now;

            if (pending.Count > 0)
            {
                var p = pending.Values.OrderBy(v => v.Key).First();
                run.PendingSince = p.Key; run.PendingLabel = p.Value;
            }
            if (lastWasFinalText && pending.Count == 0)
            {
                run.State = RunState.Finished;
                var first = run.FinalText.Split('\n').Select(x => x.Trim()).FirstOrDefault(x => x.Length > 0) ?? "";
                run.Result = OneLine(first, 160);
                if (run.Lines.Count > 0) { var l = run.Lines[run.Lines.Count - 1]; if (l.Kind == Kind.Say) l.Kind = Kind.Summary; l.Text = "Final summary: " + l.Text; }
            }
            else if (interrupted && pending.Count == 0)
            {
                run.State = RunState.Stopped;
                run.Result = lastRefusalWait >= 0
                    ? "Stopped: waited " + Mins(lastRefusalWait) + " for a permission click, then it was refused or timed out"
                    : "Stopped: a permission was refused or timed out";
            }
            else
            {
                var since = pending.Count > 0 ? run.PendingSince : run.Last;
                var mins = (int)(now - since).TotalMinutes;
                var fileQuiet = (DateTime.UtcNow - fi.LastWriteTimeUtc).TotalMinutes;
                if (mins >= 10 && fileQuiet >= 10)
                {
                    run.State = RunState.Stuck; run.StuckMinutes = mins;
                    run.Result = pending.Count > 0
                        ? "STUCK? Waiting " + Mins(mins) + " on \"" + run.PendingLabel + "\" (probably a permission prompt nobody clicked)"
                        : "STUCK? No activity for " + Mins(mins);
                }
                else
                {
                    run.State = RunState.Working;
                    run.Result = "Working: " + (run.PendingLabel != "" ? run.PendingLabel : run.LastAction);
                }
            }
            if (run.State == RunState.Stuck || (run.State == RunState.Working && pending.Count > 0))
            {
                var mins = (int)(now - run.PendingSince).TotalMinutes;
                if (pending.Count > 0)
                    run.Lines.Add(new Line(run.PendingSince, run.State == RunState.Stuck ? Kind.Problem : Kind.Waiting,
                        run.State == RunState.Stuck ? "STUCK? Waiting " + Mins(mins) + " for this to be allowed or to finish. Is a permission prompt open in the Claude app?"
                                                    : "busy with: " + run.PendingLabel + " (" + Mins(mins) + ")"));
            }
            return run;
        }

        public static string Mins(int m)
        {
            if (m < 1) return "under a minute";
            if (m < 60) return m + " min";
            return (m / 60) + " h " + (m % 60) + " min";
        }

        public static List<Report> FindReports(string text)
        {
            var list = new List<Report>();
            foreach (var msg in Regex.Split(text.Replace("\r", ""), @"\n---\n"))
            {
                var m = Regex.Match(msg, @"^\[(\d+)\] (\d{4}-\d\d-\d\d \d\d:\d\d) [^:\n]*:\s*(🐞|💡) \*\*(Bug report|Wish)\*\*(?: from \S+)?(?: \(([^)\n]*)\))?[ \t]*(?:\n([^\n]*))?");
                if (!m.Success)
                {
                    // a report inside other output (e.g. grep): just the header line
                    m = Regex.Match(msg, @"\[(\d+)\] (\d{4}-\d\d-\d\d \d\d:\d\d) [^:\n]*:\s*(🐞|💡) \*\*(Bug report|Wish)\*\*(?: from \S+)?(?: \(([^)\n]*)\))?[ \t]*(?:\n([^\n]*))?");
                    if (!m.Success) continue;
                }
                var r = new Report();
                DateTime t;
                if (DateTime.TryParseExact(m.Groups[2].Value, "yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out t))
                    r.Time = t.ToLocalTime();
                r.Wish = m.Groups[4].Value == "Wish";
                r.Who = m.Groups[5].Value;
                var title = m.Groups[6].Value;
                if (title.StartsWith("report-id") || title.StartsWith("[")) title = "";
                r.Title = OneLine(title, 140);
                var id = Regex.Match(msg, @"report-id:\s*(\d{17,20})");
                if (id.Success) r.Id = id.Groups[1].Value; else r.Test = true;
                var url = Regex.Match(msg, @"Thread:\s*(https://discord\.com/channels/\d+/\d+)");
                if (url.Success) r.Url = url.Groups[1].Value;
                if (r.Title == "") r.Title = r.Wish ? "(wish)" : "(bug report)";
                list.Add(r);
            }
            // reports found only as "report-id:" lines (e.g. after grep)
            foreach (Match m in Regex.Matches(text, @"report-id:\s*(\d{17,20})"))
                if (!list.Any(r => r.Id == m.Groups[1].Value))
                    list.Add(new Report { Id = m.Groups[1].Value, Title = "report " + m.Groups[1].Value });
            return list;
        }
    }

    class MainForm : Form
    {
        readonly string repo, projDir;
        readonly Dictionary<string, Run> runs = new Dictionary<string, Run>();
        readonly Dictionary<string, bool> isRun = new Dictionary<string, bool>();
        readonly Dictionary<string, string> notified = new Dictionary<string, string>();
        List<Report> reports = new List<Report>();
        string reportsError = "", reportsFetched = "";
        bool fetching, firstPass = true;
        DateTime lastFetch = DateTime.MinValue;
        string selectedId = null; bool userPicked;

        readonly Label lblStatus = new Label(), lblSub = new Label(), lblUpdated = new Label(), lblReports = new Label();
        readonly ListView lvRuns = new ListView(), lvReports = new ListView();
        readonly RichTextBox rtb = new RichTextBox();
        readonly NotifyIcon tray = new NotifyIcon();
        readonly System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();
        int timelineCount = -1; string timelineRun = null;

        static readonly Color Bg = Color.FromArgb(24, 27, 34), Panel = Color.FromArgb(32, 36, 45), Fg = Color.FromArgb(225, 228, 235),
            Dim = Color.FromArgb(140, 148, 160), Green = Color.FromArgb(110, 210, 130), Orange = Color.FromArgb(255, 170, 70),
            Red = Color.FromArgb(255, 105, 95), Blue = Color.FromArgb(120, 180, 255), Yellow = Color.FromArgb(240, 210, 100);

        public MainForm(string repo)
        {
            this.repo = repo;
            Parser.Repo = repo;
            projDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".claude", "projects",
                Regex.Replace(repo.TrimEnd('\\'), @"[:\\/]", "-"));

            Text = "Bug fixer viewer – Hello Bro / Ninja Online";
            Width = 1250; Height = 820; BackColor = Bg; ForeColor = Fg;
            Font = new Font("Segoe UI", 10f);
            StartPosition = FormStartPosition.CenterScreen;
            var appIcon = MakeIcon();
            if (appIcon != null) Icon = appIcon;

            var head = new System.Windows.Forms.Panel { Dock = DockStyle.Top, Height = 92, BackColor = Panel, Padding = new Padding(16, 10, 16, 8) };
            lblStatus.Dock = DockStyle.Top; lblStatus.Height = 36; lblStatus.Font = new Font("Segoe UI Semibold", 16f); lblStatus.AutoEllipsis = true;
            lblSub.Dock = DockStyle.Top; lblSub.Height = 24; lblSub.ForeColor = Dim; lblSub.AutoEllipsis = true;
            lblUpdated.Dock = DockStyle.Top; lblUpdated.Height = 20; lblUpdated.ForeColor = Dim; lblUpdated.Font = new Font("Segoe UI", 8.5f);
            head.Controls.Add(lblUpdated); head.Controls.Add(lblSub); head.Controls.Add(lblStatus);

            var splitMain = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Horizontal, BackColor = Bg, SplitterWidth = 6 };
            var splitTop = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Vertical, BackColor = Bg, SplitterWidth = 6 };

            SetupList(lvRuns, new[] { "Run started", "What happened" }, new[] { 150, 330 });
            lvRuns.SelectedIndexChanged += (s, e) =>
            {
                if (lvRuns.SelectedItems.Count == 0) return;
                var id = (string)lvRuns.SelectedItems[0].Tag;
                if (id != selectedId) { selectedId = id; userPicked = lvRuns.SelectedItems[0].Index != 0; timelineRun = null; ShowTimeline(); }
            };
            var runsBox = Boxed("Runs (newest first)", lvRuns);
            splitTop.Panel1.Controls.Add(runsBox);

            rtb.Dock = DockStyle.Fill; rtb.ReadOnly = true; rtb.BackColor = Panel; rtb.ForeColor = Fg; rtb.BorderStyle = BorderStyle.None;
            rtb.Font = new Font("Segoe UI", 10f); rtb.DetectUrls = false; rtb.WordWrap = true;
            splitTop.Panel2.Controls.Add(Boxed("What this run did", rtb));

            SetupList(lvReports, new[] { "Posted", "Player", "Report", "State" }, new[] { 120, 110, 640, 300 });
            lvReports.DoubleClick += (s, e) =>
            {
                if (lvReports.SelectedItems.Count == 0) return;
                var url = lvReports.SelectedItems[0].Tag as string;
                if (!string.IsNullOrEmpty(url)) try { Process.Start(url); } catch { }
            };
            lblReports.Dock = DockStyle.Bottom; lblReports.Height = 22; lblReports.ForeColor = Dim; lblReports.Font = new Font("Segoe UI", 8.5f);
            var repBox = Boxed("Bug reports from #bot-logs (double-click to open the thread)", lvReports);
            repBox.Controls.Add(lblReports);
            splitMain.Panel1.Controls.Add(splitTop);
            splitMain.Panel2.Controls.Add(repBox);

            Controls.Add(splitMain);
            Controls.Add(head);
            Load += (s, e) => { splitMain.SplitterDistance = (int)(ClientSize.Height * 0.58); splitTop.SplitterDistance = 500; };

            tray.Icon = appIcon ?? SystemIcons.Information;
            tray.Text = "Bug fixer viewer";
            tray.Visible = true;
            tray.DoubleClick += (s, e) => { Show(); WindowState = FormWindowState.Normal; Activate(); };
            tray.BalloonTipClicked += (s, e) => { Show(); WindowState = FormWindowState.Normal; Activate(); };
            FormClosed += (s, e) => { tray.Visible = false; tray.Dispose(); };

            timer.Interval = 4000;
            timer.Tick += (s, e) => Tick();
            Shown += (s, e) => { Tick(); timer.Start(); };
        }

        static Icon MakeIcon()
        {
            try
            {
                var bmp = new Bitmap(32, 32);
                using (var g = Graphics.FromImage(bmp))
                {
                    g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                    g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
                    using (var b = new SolidBrush(Color.FromArgb(255, 140, 40))) g.FillEllipse(b, 1, 1, 30, 30);
                    using (var f = new Font("Segoe UI Black", 15f, FontStyle.Bold, GraphicsUnit.Pixel))
                    using (var w = new SolidBrush(Color.White))
                    {
                        var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
                        g.DrawString("BF", f, w, new RectangleF(0, 1, 32, 32), sf);
                    }
                }
                return Icon.FromHandle(bmp.GetHicon());
            }
            catch { return null; }
        }

        Control Boxed(string title, Control inner)
        {
            var p = new System.Windows.Forms.Panel { Dock = DockStyle.Fill, BackColor = Bg, Padding = new Padding(10, 6, 10, 8) };
            var l = new Label { Text = title, Dock = DockStyle.Top, Height = 24, ForeColor = Blue, Font = new Font("Segoe UI Semibold", 10.5f) };
            inner.Dock = DockStyle.Fill;
            p.Controls.Add(inner); p.Controls.Add(l);
            return p;
        }

        void SetupList(ListView lv, string[] cols, int[] widths)
        {
            lv.View = View.Details; lv.FullRowSelect = true; lv.HideSelection = false; lv.MultiSelect = false;
            lv.BackColor = Panel; lv.ForeColor = Fg; lv.BorderStyle = BorderStyle.None; lv.HeaderStyle = ColumnHeaderStyle.Nonclickable;
            lv.ShowItemToolTips = true;
            for (int i = 0; i < cols.Length; i++) lv.Columns.Add(cols[i], widths[i]);
        }

        // ---------- data ----------
        void ScanRuns()
        {
            if (!Directory.Exists(projDir)) return;
            var cutoff = DateTime.Now.AddDays(-3);
            foreach (var f in Directory.GetFiles(projDir, "*.jsonl"))
            {
                DateTime mt;
                try { mt = File.GetLastWriteTime(f); } catch { continue; }
                if (mt < cutoff) continue;
                bool yes;
                if (!isRun.TryGetValue(f, out yes))
                {
                    yes = false;
                    try
                    {
                        using (var fs = new FileStream(f, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        {
                            var buf = new byte[6000]; int n = fs.Read(buf, 0, buf.Length);
                            var head = Encoding.UTF8.GetString(buf, 0, n);
                            var nl = head.IndexOf('\n');
                            var first = nl > 0 ? head.Substring(0, nl) : head;
                            yes = first.Contains("\"content\":\"<scheduled-task name=\\\"hellobro-bug-fixer");
                            if (n < 200 && !yes) continue; // brand-new file: look again next time
                        }
                    }
                    catch { continue; }
                    isRun[f] = yes;
                }
                if (!yes) continue;
                Run old; runs.TryGetValue(f, out old);
                // working / stuck runs are read again every tick (their state depends on the clock)
                if (old != null && (old.State == RunState.Working || old.State == RunState.Stuck)) old = null;
                try { runs[f] = Parser.Load(f, old); }
                catch { }
            }
        }

        HashSet<string> HandledIds()
        {
            var set = new HashSet<string>();
            try
            {
                var txt = File.ReadAllText(Path.Combine(repo, "docs", "DISCORD-REPORTS.md"));
                foreach (Match m in Regex.Matches(txt, @"\d{17,20}")) set.Add(m.Value);
            }
            catch { }
            return set;
        }

        void FetchReports()
        {
            if (fetching) return;
            fetching = true; lastFetch = DateTime.Now;
            var t = new Thread(() =>
            {
                string err = "", output = "";
                try
                {
                    var psi = new ProcessStartInfo("node", "--env-file=.env dc.js read bot-logs 50")
                    {
                        WorkingDirectory = Path.Combine(repo, "discord"), UseShellExecute = false, CreateNoWindow = true,
                        RedirectStandardOutput = true, RedirectStandardError = true,
                        StandardOutputEncoding = Encoding.UTF8, StandardErrorEncoding = Encoding.UTF8
                    };
                    using (var p = Process.Start(psi))
                    {
                        var so = p.StandardOutput.ReadToEndAsync();
                        var se = p.StandardError.ReadToEndAsync();
                        if (!p.WaitForExit(45000)) { try { p.Kill(); } catch { } err = "Discord did not answer in time"; }
                        else { output = so.Result; if (p.ExitCode != 0) err = "Could not read #bot-logs (" + Parser.Clean(se.Result).Split('\n').FirstOrDefault() + ")"; }
                    }
                }
                catch (Exception ex) { err = "Could not run node: " + ex.Message; }
                List<Report> list = null;
                if (err == "") list = Parser.FindReports(output).Where(r => r.Id != "" || r.Test).ToList();
                try
                {
                    BeginInvoke((Action)(() =>
                    {
                        fetching = false;
                        reportsError = err;
                        if (list != null) { reports = list; reportsFetched = DateTime.Now.ToString("HH:mm:ss"); }
                        Render();
                    }));
                }
                catch { fetching = false; }
            });
            t.IsBackground = true; t.Start();
        }

        DateTime NextRun(List<Run> ordered)
        {
            var now = DateTime.Now;
            var slot = new DateTime(now.Year, now.Month, now.Day, now.Hour - now.Hour % 2, 20, 0);
            for (int i = 0; i < 3; i++)
            {
                var s = slot;
                bool done = ordered.Any(r => r.Start >= s.AddMinutes(-3) && r.Start <= s.AddMinutes(20));
                if (!done && s.AddMinutes(15) > now) return s;
                slot = slot.AddHours(2);
            }
            return slot;
        }

        static bool ClaudeAppOpen()
        {
            try { return Process.GetProcessesByName("Claude").Length > 0 || Process.GetProcessesByName("claude").Length > 0; }
            catch { return true; }
        }

        void Tick()
        {
            try { ScanRuns(); } catch { }
            var working = runs.Values.Any(r => r.State == RunState.Working);
            if (!fetching && (DateTime.Now - lastFetch).TotalSeconds > (working ? 20 : 60)) FetchReports();
            Render();
        }

        // ---------- view ----------
        void Render()
        {
            var ordered = runs.Values.OrderByDescending(r => r.Start).ToList();
            var handled = HandledIds();
            var now = DateTime.Now;

            // status line
            var active = ordered.FirstOrDefault(r => r.State == RunState.Working);
            var latest = ordered.FirstOrDefault();
            var next = NextRun(ordered);
            var appOpen = ClaudeAppOpen();
            if (active != null)
            {
                lblStatus.ForeColor = active.Fixing ? Orange : Green;
                lblStatus.Text = (active.Fixing ? "🔧 The fixer is FIXING something right now" : "🔎 The fixer is checking for new reports") +
                    " (started " + active.Start.ToString("HH:mm") + ")";
            }
            else if (latest != null && latest.State == RunState.Stuck && (now - latest.Start).TotalHours < 2)
            {
                lblStatus.ForeColor = Red;
                lblStatus.Text = "⚠ Stuck? The run of " + latest.Start.ToString("HH:mm") + " has done nothing for " + Parser.Mins(latest.StuckMinutes);
            }
            else
            {
                lblStatus.ForeColor = Fg;
                lblStatus.Text = "💤 Idle" + (latest != null ? ". Last run " + Day(latest.Start) + ": " + Short(latest.Result, 90) : ". No runs found yet");
            }
            var sub = active != null ? "Now: " + Short(active.Result.Replace("Working: ", ""), 110) + "     " : "";
            sub += appOpen ? "Next run: around " + next.ToString("HH:mm") + "–" + next.AddMinutes(10).ToString("HH:mm") + " (every 2 hours, only while the Claude app is open)"
                           : "The Claude app is closed, so the fixer can't run. Open it to let the fixer work.";
            lblSub.Text = sub;
            lblUpdated.Text = "Updated " + now.ToString("HH:mm:ss") + " · checks the run logs every 4 seconds, #bot-logs every " + (active != null ? "20" : "60") + " seconds · this window only reads, it never changes anything";

            // runs list
            lvRuns.BeginUpdate();
            var want = ordered.Take(40).ToList();
            while (lvRuns.Items.Count > want.Count) lvRuns.Items.RemoveAt(lvRuns.Items.Count - 1);
            for (int i = 0; i < want.Count; i++)
            {
                var r = want[i];
                ListViewItem it;
                if (i < lvRuns.Items.Count) it = lvRuns.Items[i];
                else { it = new ListViewItem(new[] { "", "" }); lvRuns.Items.Add(it); }
                SetText(it, 0, Day(r.Start));
                SetText(it, 1, r.Result);
                it.Tag = r.Id; it.ToolTipText = r.Result;
                var c = r.State == RunState.Working ? Orange : r.State == RunState.Stuck ? Red : r.State == RunState.Stopped ? Yellow :
                        (r.Result.StartsWith("No new bug reports") ? Dim : Green);
                if (it.ForeColor != c) it.ForeColor = c;
            }
            if (!userPicked || selectedId == null || !want.Any(r => r.Id == selectedId))
            {
                if (want.Count > 0 && (lvRuns.SelectedItems.Count == 0 || (string)lvRuns.SelectedItems[0].Tag != want[0].Id))
                {
                    selectedId = want[0].Id; userPicked = false;
                    lvRuns.Items[0].Selected = true;
                }
            }
            lvRuns.EndUpdate();
            ShowTimeline();

            // reports
            var activeRuns = ordered.Where(r => r.State == RunState.Working).ToList();
            lvReports.BeginUpdate();
            lvReports.Items.Clear();
            foreach (var r in reports.OrderByDescending(x => x.Time).Take(30))
            {
                string state; Color c;
                if (r.Test) { state = "test post (the fixer skips it)"; c = Dim; }
                else if (handled.Contains(r.Id)) { state = r.Wish ? "✔ noted for the owner" : "✔ handled"; c = Green; }
                else if (activeRuns.Any(a => a.ReportIds.Contains(r.Id) || a.Start >= r.Time)) { state = "🔧 being fixed now"; c = Orange; }
                else { state = "⏳ waiting for the next run (~" + next.ToString("HH:mm") + ")"; c = Yellow; }
                var it = new ListViewItem(new[] { Day(r.Time), r.Who, (r.Wish ? "💡 " : "🐞 ") + r.Title, state }) { ForeColor = c, Tag = r.Url, ToolTipText = r.Title };
                lvReports.Items.Add(it);
            }
            lvReports.EndUpdate();
            lblReports.Text = reportsError != "" ? "⚠ " + reportsError + (reportsFetched != "" ? " (showing the list from " + reportsFetched + ")" : "")
                : reportsFetched == "" ? "Reading #bot-logs…" : "Read from Discord at " + reportsFetched + " · " + reports.Count + " report(s) in the last 50 messages · state from docs/DISCORD-REPORTS.md";

            Notify(ordered);
            firstPass = false;
        }

        static void SetText(ListViewItem it, int i, string s) { if (it.SubItems[i].Text != s) it.SubItems[i].Text = s; }
        static string Short(string s, int n) { return s.Length > n ? s.Substring(0, n - 1) + "…" : s; }
        static string Day(DateTime t)
        {
            if (t == DateTime.MinValue) return "";
            var d = t.Date == DateTime.Today ? "today" : t.Date == DateTime.Today.AddDays(-1) ? "yesterday" : t.ToString("ddd d MMM");
            return d + " " + t.ToString("HH:mm");
        }

        void ShowTimeline()
        {
            Run run = runs.Values.FirstOrDefault(r => r.Id == selectedId);
            if (run == null) { rtb.Clear(); timelineRun = null; return; }
            var sig = run.Lines.Count + (run.Lines.Count > 0 ? run.Lines[run.Lines.Count - 1].Text.GetHashCode() : 0);
            if (timelineRun == run.Id && timelineCount == sig) return;
            bool sameRun = timelineRun == run.Id;
            timelineRun = run.Id; timelineCount = sig;
            rtb.SuspendLayout();
            rtb.Clear();
            Append(run.Start.ToString("dddd d MMMM, HH:mm") + "\n", Blue, true);
            Append(run.Result + "\n\n", run.State == RunState.Stuck ? Red : run.State == RunState.Working ? Orange : run.State == RunState.Stopped ? Yellow : Green, true);
            foreach (var l in run.Lines)
            {
                Append((l.Time == DateTime.MinValue ? "     " : l.Time.ToString("HH:mm")) + "   ", Dim, false);
                Color c; bool bold = false;
                switch (l.Kind)
                {
                    case Kind.Start: c = Blue; bold = true; break;
                    case Kind.Say: c = Color.FromArgb(200, 205, 215); break;
                    case Kind.Found: c = Yellow; bold = true; break;
                    case Kind.Problem: c = Red; bold = true; break;
                    case Kind.Good: c = Green; break;
                    case Kind.Waiting: c = Orange; break;
                    case Kind.Summary: c = Green; bold = true; break;
                    case Kind.Message: c = Blue; break;
                    default: c = Fg; break;
                }
                Append(l.Text + "\n", c, bold);
            }
            rtb.ResumeLayout();
            if (run.State == RunState.Working || !sameRun) { rtb.SelectionStart = run.State == RunState.Working ? rtb.TextLength : 0; rtb.ScrollToCaret(); }
        }

        void Append(string s, Color c, bool bold)
        {
            rtb.SelectionStart = rtb.TextLength; rtb.SelectionLength = 0;
            rtb.SelectionColor = c;
            rtb.SelectionFont = new Font(rtb.Font, bold ? FontStyle.Bold : FontStyle.Regular);
            rtb.AppendText(s);
        }

        void Notify(List<Run> ordered)
        {
            foreach (var r in ordered.Take(5))
            {
                string key = r.State == RunState.Working ? (r.Fixing ? "fixing" : "checking") : r.State.ToString();
                string was; notified.TryGetValue(r.Id, out was);
                notified[r.Id] = key;
                if (firstPass || was == key) continue;
                if (key == "fixing" && was != "fixing")
                    Balloon("The bug fixer is fixing something", Short(r.LastAction, 200), ToolTipIcon.Info);
                else if (key == "Finished" && (was == "fixing" || was == "checking") && r.Fixing)
                    Balloon("The bug fixer is done", Short(r.Result, 200), ToolTipIcon.Info);
                else if (key == "Stuck" && was != null)
                    Balloon("The bug fixer looks stuck", Short(r.Result, 200), ToolTipIcon.Warning);
                else if (key == "Stopped" && was != null)
                    Balloon("The bug fixer stopped", r.Result, ToolTipIcon.Warning);
            }
        }

        void Balloon(string title, string text, ToolTipIcon icon)
        {
            try { tray.ShowBalloonTip(8000, title, string.IsNullOrEmpty(text) ? " " : text, icon); } catch { }
        }
    }

    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            string repo = null;
            var cands = new List<string>();
            if (args.Length > 0) cands.Add(args[0]);
            var env = Environment.GetEnvironmentVariable("HB_REPO");
            if (!string.IsNullOrEmpty(env)) cands.Add(env);
            cands.Add(Path.GetDirectoryName(Application.ExecutablePath));
            cands.Add(Path.Combine(Path.GetDirectoryName(Application.ExecutablePath), "HelloBroServer"));
            cands.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "HelloBroServer"));
            cands.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Desktop", "HelloBroServer"));
            foreach (var c in cands)
                if (File.Exists(Path.Combine(c, "discord", "dc.js")) && File.Exists(Path.Combine(c, "CLAUDE.md"))) { repo = Path.GetFullPath(c); break; }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            if (repo == null)
            {
                MessageBox.Show("Could not find the HelloBroServer folder. Put this program on the Desktop next to it.", "Bug fixer viewer");
                return;
            }
            Application.Run(new MainForm(repo));
        }
    }
}
