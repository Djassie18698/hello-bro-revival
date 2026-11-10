// BUG-FIXER-VIEWER: the owner's window on the bug pipeline (owner, 10 Nov 2026: "a fully fledged app that looks, acts way better").
// One .exe, no install. It runs a tiny web page on 127.0.0.1 (random port) and shows it in an Edge app window (no address bar),
// plus a tray icon with pop-ups. Everything is READ-ONLY: it reads
//   - the Discord forums #bugs-and-issues (players) and #bug-fixer (the fixer's desk) with the bot token from discord/.env, at runtime
//     (the token is never shown, logged, stored or put in the exe; it only goes to discord.com),
//   - the fixer's run transcripts (~/.claude/projects/<repo>/*.jsonl whose first message is the "hellobro-bug-fixer" scheduled task),
// and never posts, edits, starts or stops anything. Opening a Discord link hands it to the Discord app (or the browser).
// Build: tools/fixer-viewer/BUILD.bat (C# 5 with the .NET Framework csc.exe that ships with Windows; app.html is embedded).
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace FixerViewer
{
    // ===================================================================== fixer runs (transcripts)
    class Line
    {
        public DateTime Time; public string Kind; public string Text;
        public Line(DateTime t, string k, string s) { Time = t; Kind = k; Text = s; }
    }

    class Run
    {
        public string File, Id; public DateTime Start, Last; public long Size; public DateTime Mtime;
        public List<Line> Lines = new List<Line>();
        public string State = "working"; // working | done | stopped | stuck
        public string Result = "", Step = "", Mode = "";
        public bool Fixing, Quiet; public int StuckMinutes;
        public HashSet<string> Ids = new HashSet<string>(); // Discord numbers it touched (posts, reports)
        public DateTime PendingSince = DateTime.MinValue; public string PendingLabel = "";
    }

    static class Parser
    {
        static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
        public static string Repo = "";

        public static object Get(object o, string k)
        {
            var d = o as Dictionary<string, object>;
            if (d == null) return null;
            object v; return d.TryGetValue(k, out v) ? v : null;
        }
        public static string Str(object o, string k) { var v = Get(o, k); return v == null ? null : v.ToString(); }

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
            s = Regex.Replace(s, @"[\w-]{23,28}\.[\w-]{6,7}\.[\w-]{27,40}", "[hidden]"); // Discord token shape
            s = Regex.Replace(s, @"sk-ant-[\w-]+", "[hidden]");
            s = Regex.Replace(s, @"(?i)(token|password|api[_-]?key)\s*[=:]\s*\S+", "$1=[hidden]");
            s = Regex.Replace(s, @"\b\d{1,3}(\.\d{1,3}){3}\b", "[address]");
            return s;
        }

        public static string OneLine(string s, int max)
        {
            s = Clean(s ?? "");
            s = Regex.Replace(s, @"\*\*|__|`|\|\|", "");
            s = Regex.Replace(s, @"<@!?\d+>", "@owner");
            s = Regex.Replace(s, @"<#(\d+)>", "#post");
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

        // plain-words labels for the commands the fixer runs (first match position decides the order)
        static readonly string[][] Patterns = new string[][] {
            new [] { @"dc\.js read bot-logs", "looking for new reports in #bot-logs" },
            new [] { @"dc\.js posts bug-fixer", "checking the #bug-fixer forum" },
            new [] { @"dc\.js posts bugs-and-issues", "checking the players' bug forum" },
            new [] { @"dc\.js read dev-chat", "checking #dev-chat for your messages" },
            new [] { @"dc\.js read \d{17,20}", "reading a Discord post" },
            new [] { @"dc\.js read (?!bot-logs|dev-chat)([a-z-]+)", "reading Discord #$1" },
            new [] { @"dc\.js forum bug-fixer", "opening a new post in #bug-fixer" },
            new [] { @"dc\.js post \S+[^\n;&|]*--ping-owner", "asking YOU something in Discord" },
            new [] { @"dc\.js post updates", "announcing the update in #updates" },
            new [] { @"dc\.js post (?!updates)\S+(?![^\n;&|]*--ping-owner)", "writing in a Discord post" },
            new [] { "dc\\.js tag \\S+ \"([^\"]+)\"", "setting the tag to \"$1\"" },
            new [] { @"dc\.js edit", "updating the 📦 Waiting to go live list" },
            new [] { @"dc\.js reply", "replying in Discord" },
            new [] { @"dc\.js react", "putting a ✅ on the player's post" },
            new [] { @"dc\.js pinpost", "pinning a post" },
            new [] { @"update\.sh\s+check", "checking what is waiting to go live" },
            new [] { @"update\.sh(?!\s+check)", "PUTTING THE FIXES LIVE on the public server" },
            new [] { @"until false; do sleep|timeout 70", "waiting for your answer (looks again every minute, up to 10 min)" },
            new [] { @"FINDINGS-PHOTOS|ocr\.tsv", "looking in the old game photos" },
            new [] { @"check\.sh", "running all the checks" },
            new [] { @"smoke\.js", "running the smoke test" },
            new [] { @"fuzz\.js", "running the bad-input test" },
            new [] { @"exploit\.js", "running the cheat test" },
            new [] { @"realsave\.js", "testing on a copy of a real save" },
            new [] { @"probe\.js", "trying it on the test server" },
            new [] { @"emu\.sh (\w+)", "using the test phone (emulator: $1)" },
            new [] { @"restart\.sh", "restarting the test server" },
            new [] { @"git commit", "saving the fix (commit)" },
            new [] { @"git push", "uploading to GitHub" },
            new [] { @"sync_test_folder", "copying it to your play folder" },
            new [] { @"build_wiki", "rebuilding the wiki" },
            new [] { @"build_cdn", "building a game update for phones" },
            new [] { @"gh issue comment", "commenting on GitHub" },
            new [] { @"guides\.js", "updating a Discord guide" },
            new [] { @"re/all\.txt", "reading the game's own code" },
        };

        public static bool IsCheckOnly(string label)
        {
            return label.StartsWith("looking for new reports") || label.StartsWith("checking the #bug-fixer") || label.StartsWith("checking the players'") ||
                   label.StartsWith("checking #dev-chat") || label.StartsWith("checking which reports") || label.StartsWith("planning") || label.StartsWith("loading tools");
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
                }
                hits.Add(new KeyValuePair<int, string>(m.Index, label));
            }
            if (Regex.IsMatch(cmd, @"DISCORD-REPORTS") && !hits.Any(h => h.Value.StartsWith("saving"))) hits.Add(new KeyValuePair<int, string>(int.MaxValue - 1, "checking which reports are already handled"));
            if (Regex.IsMatch(cmd, @"writeFileSync|>\s*(server|tools|docs|discord)/"))
            {
                var paths = Regex.Matches(cmd, @"['""]((?:server|tools|docs|discord)/[\w./-]+\.\w+)['""]").Cast<Match>()
                    .Select(x => x.Groups[1].Value).Distinct().Take(4).ToList();
                if (paths.Count > 0) hits.Add(new KeyValuePair<int, string>(int.MaxValue, "changing " + string.Join(", ", paths)));
            }
            if (hits.Count > 0)
                return string.Join(" + ", hits.OrderBy(h => h.Key).Select(h => h.Value).Distinct());
            if (!string.IsNullOrEmpty(desc)) return Char.ToUpper(desc[0]) + desc.Substring(1);
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
                case "Glob": return "looking for files";
                case "ToolSearch": return "loading tools";
                case "Skill": return "loading the skill " + Str(input, "skill");
                case "Agent": return "starting a helper: " + OneLine(Str(input, "description"), 80);
                case "SendMessage": return "messaging another Claude session";
                case "mcp__ccd_turn__wrap_up": return null;
                case "mcp__ccd_turn__update_plan":
                    {
                        var items = Get(input, "items") as object[];
                        if (items != null) return "planning: " + string.Join(" → ", items.Select(i => Str(i, "content")));
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

        public static string Mins(int m)
        {
            if (m < 1) return "under a minute";
            if (m < 60) return m + " min";
            return (m / 60) + " h " + (m % 60) + " min";
        }

        public static Run Load(string file, Run old)
        {
            var fi = new FileInfo(file);
            if (old != null && old.Size == fi.Length && old.Mtime == fi.LastWriteTimeUtc) return old;
            var run = new Run { File = file, Id = Path.GetFileNameWithoutExtension(file), Size = fi.Length, Mtime = fi.LastWriteTimeUtc };
            string all;
            using (var fs = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            using (var sr = new StreamReader(fs, Encoding.UTF8)) all = sr.ReadToEnd();

            var pending = new Dictionary<string, KeyValuePair<DateTime, string>>();
            var waitStart = new Dictionary<string, DateTime>();
            var toolCmds = new Dictionary<string, string>();
            bool lastWasFinalText = false, interrupted = false; int refusalWait = -1;
            DateTime lastEvent = DateTime.MinValue;

            foreach (var raw in all.Split('\n'))
            {
                if (raw.Length < 10) continue;
                if (raw.StartsWith("{\"type\":\"api-request") || raw.StartsWith("{\"type\":\"file-history")) continue;
                if (raw.Contains("\"type\":\"attachment\",\"uuid\"")) continue;
                object j;
                try { j = Json.DeserializeObject(raw); } catch { continue; }
                var type = Str(j, "type");
                var t = Ts(j);
                if (type == "queue-operation")
                {
                    if (Str(j, "operation") == "enqueue" && run.Start == DateTime.MinValue) run.Start = t;
                    continue;
                }
                if (type != "user" && type != "assistant") continue;
                if (t != DateTime.MinValue) lastEvent = t;
                var content = Get(Get(j, "message"), "content");

                if (type == "user")
                {
                    var pm = Str(j, "permissionMode");
                    if (pm != null && run.Mode == "") run.Mode = pm;
                    if (content is string)
                    {
                        var s = (string)content;
                        if (s.Contains("<scheduled-task")) run.Lines.Add(new Line(t, "start", "Run started"));
                        else if (s.Contains("cross-session-message")) run.Lines.Add(new Line(t, "msg", "Another Claude session sent it a message"));
                        else run.Lines.Add(new Line(t, "msg", "Message: " + OneLine(s, 160)));
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
                            if (s.StartsWith("[Request interrupted")) interrupted = true;
                            else if (s.Contains("cross-session-message")) { run.Lines.Add(new Line(t, "msg", "Another Claude session sent it a message")); interrupted = false; }
                        }
                        else if (ct == "tool_result")
                        {
                            var id = Str(c, "tool_use_id") ?? "";
                            pending.Remove(id);
                            refusalWait = -1;
                            var txt = ResultText(c);
                            var isErr = Get(c, "is_error") is bool && (bool)Get(c, "is_error");
                            string cmd; toolCmds.TryGetValue(id, out cmd);
                            if (isErr && txt.Contains("doesn't want to proceed"))
                            {
                                DateTime ws;
                                if (waitStart.TryGetValue(id, out ws) && t != DateTime.MinValue) refusalWait = (int)(t - ws).TotalMinutes;
                                run.Lines.Add(new Line(t, "bad", "Permission refused or timed out (nobody clicked Allow in the Claude app)"));
                            }
                            else if (isErr) run.Lines.Add(new Line(t, "bad", "That failed: " + OneLine(txt, 140)));
                            if (cmd == null || isErr) continue;
                            if (Regex.IsMatch(cmd, @"dc\.js read bot-logs"))
                            {
                                var titles = Regex.Matches(txt, @"(?:🐞|💡) \*\*(?:Bug report|Wish)\*\*[^\n]*\n\*\*([^\n*]+)\*\*").Cast<Match>().Select(m => OneLine(m.Groups[1].Value, 120)).ToList();
                                foreach (Match m in Regex.Matches(txt, @"report-id:\s*(\d{17,20})")) run.Ids.Add(m.Groups[1].Value);
                                if (titles.Count > 0) run.Lines.Add(new Line(t, "found", "Reports in #bot-logs: " + string.Join(" · ", titles.Skip(Math.Max(0, titles.Count - 4)))));
                            }
                            if (Regex.IsMatch(cmd, @"dc\.js posts"))
                            {
                                var waiting = Regex.Matches(txt, @"\] ([^\n·]+?) · [^\n]*last: OWNER").Cast<Match>().Select(m => OneLine(m.Groups[1].Value, 80)).ToList();
                                if (waiting.Count > 0) run.Lines.Add(new Line(t, "found", "You wrote in: " + string.Join(" · ", waiting)));
                                var news = Regex.Matches(txt, @"\] ([^\n·]+?) · New report").Cast<Match>().Select(m => OneLine(m.Groups[1].Value, 80)).ToList();
                                if (news.Count > 0) run.Lines.Add(new Line(t, "found", "New reports: " + string.Join(" · ", news)));
                            }
                            if (Regex.IsMatch(cmd, @"check\.sh") && Regex.IsMatch(txt, @"(?i)\bfail|problem\(s\)|crash")) run.Lines.Add(new Line(t, "bad", "The checks found a problem"));
                            if (Regex.IsMatch(cmd, @"git push") && Regex.IsMatch(txt, @"->\s*main")) run.Lines.Add(new Line(t, "good", "Uploaded to GitHub"));
                            if (Regex.IsMatch(cmd, @"dc\.js (post|reply|forum)") && Regex.IsMatch(txt, @"posted|replied|new post")) run.Lines.Add(new Line(t, "good", "Written in Discord"));
                            if (Regex.IsMatch(cmd, @"update\.sh(?!\s+check)") && txt.Contains("Updated to")) run.Lines.Add(new Line(t, "good", "The public server is updated"));
                        }
                    }
                    continue;
                }

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
                        run.Lines.Add(new Line(t, "say", OneLine(s, 700)));
                    }
                    else if (ct == "tool_use")
                    {
                        hadTool = true;
                        var name = Str(c, "name") ?? "";
                        var input = Get(c, "input");
                        var id = Str(c, "id") ?? "";
                        if (name == "Bash" || name == "PowerShell")
                        {
                            var cmd = Str(input, "command") ?? "";
                            toolCmds[id] = cmd;
                            foreach (Match m in Regex.Matches(cmd, @"dc\.js (?:read|post|tag|edit|react|reply) (\d{17,20})")) run.Ids.Add(m.Groups[1].Value);
                        }
                        if (name == "mcp__ccd_turn__wrap_up")
                        {
                            run.Lines.Add(new Line(t, "summary", OneLine(Str(input, "recap"), 400)));
                            pending[id] = new KeyValuePair<DateTime, string>(t, "wrapping up");
                            continue;
                        }
                        var label = ToolLabel(name, input);
                        if (label == null) { pending[id] = new KeyValuePair<DateTime, string>(t, "updating its task list"); continue; }
                        label = Clean(label);
                        run.Lines.Add(new Line(t, "act", label));
                        run.Step = label;
                        if (!IsCheckOnly(label)) run.Fixing = true;
                        pending[id] = new KeyValuePair<DateTime, string>(t, label);
                        waitStart[id] = t;
                    }
                }
                if (!hadTool && lastText != null) { lastWasFinalText = true; interrupted = false; run.Result = lastText; }
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
                run.State = "done";
                var first = run.Result.Split('\n').Select(x => x.Trim()).FirstOrDefault(x => x.Length > 0) ?? "";
                run.Result = OneLine(first, 220);
                run.Quiet = !run.Fixing || Regex.IsMatch(run.Result, @"(?i)^no new (bug )?reports|nothing new came in|had nothing to do");
                if (run.Lines.Count > 0) { var l = run.Lines[run.Lines.Count - 1]; if (l.Kind == "say") l.Kind = "summary"; }
            }
            else if (interrupted && pending.Count == 0)
            {
                run.State = "stopped";
                run.Result = refusalWait >= 0 ? "Stopped: waited " + Mins(refusalWait) + " for a permission click" : "Stopped: a permission was refused";
                if (run.Mode != "" && run.Mode != "bypassPermissions") run.Result += " (it ran in Ask-first mode)";
            }
            else
            {
                var since = pending.Count > 0 ? run.PendingSince : run.Last;
                var mins = (int)(now - since).TotalMinutes;
                var quiet = (DateTime.UtcNow - fi.LastWriteTimeUtc).TotalMinutes;
                if (mins >= 12 && quiet >= 12)
                {
                    run.State = "stuck"; run.StuckMinutes = mins;
                    run.Result = pending.Count > 0 ? "Stuck? Waiting " + Mins(mins) + " on \"" + run.PendingLabel + "\"" : "Stuck? No activity for " + Mins(mins);
                    run.Lines.Add(new Line(since, "bad", run.Result + ". Is a permission prompt open in the Claude app?"));
                }
                else
                {
                    run.State = "working";
                    run.Result = run.PendingLabel != "" ? run.PendingLabel : run.Step;
                }
            }
            return run;
        }
    }

    // ===================================================================== Discord (read-only REST)
    class Post
    {
        public string Id, Forum, Title = "", Author = "", AuthorId = "", LastId = "";
        public List<string> Tags = new List<string>();
        public bool Archived, Pinned;
        public long Created, LastTime; public string LastWho = "", LastText = "";
        public string Starter = ""; public string ReportId = "";
        public int Count;
    }

    class Discord
    {
        readonly string token; readonly string ownerId; string guildEnv;
        public string Error = "", BotId = "", GuildId = "", BugsForum = "", FixerForum = "";
        public DateTime Fetched = DateTime.MinValue;
        readonly Dictionary<string, Post> cache = new Dictionary<string, Post>();
        public List<Post> Posts = new List<Post>();
        public Post Pinned;
        static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

        public Discord(Dictionary<string, string> env)
        {
            env.TryGetValue("DISCORD_TOKEN", out token);
            string o; env.TryGetValue("OWNER_IDS", out o); ownerId = (o ?? "").Split(',')[0].Trim();
            env.TryGetValue("GUILD_ID", out guildEnv);
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        }
        public bool HasToken { get { return !string.IsNullOrEmpty(token); } }

        object Call(string path)
        {
            for (int attempt = 0; attempt < 4; attempt++)
            {
                var req = (HttpWebRequest)WebRequest.Create("https://discord.com/api/v10" + path);
                req.Method = "GET";
                req.Headers["Authorization"] = "Bot " + token;
                req.UserAgent = "HelloBroBugFixerViewer (local, 2.0)";
                req.Timeout = 20000;
                try
                {
                    using (var res = (HttpWebResponse)req.GetResponse())
                    using (var sr = new StreamReader(res.GetResponseStream(), Encoding.UTF8))
                        return Json.DeserializeObject(sr.ReadToEnd());
                }
                catch (WebException e)
                {
                    var r = e.Response as HttpWebResponse;
                    if (r != null && (int)r.StatusCode == 429)
                    {
                        double wait = 1;
                        try { using (var sr = new StreamReader(r.GetResponseStream())) { var j = Json.DeserializeObject(sr.ReadToEnd()); var v = Parser.Get(j, "retry_after"); if (v != null) wait = Convert.ToDouble(v, CultureInfo.InvariantCulture); } } catch { }
                        Thread.Sleep((int)(wait * 1000) + 250);
                        continue;
                    }
                    if (r != null) throw new Exception("Discord said " + (int)r.StatusCode + (r.StatusCode == HttpStatusCode.Unauthorized ? " (the bot token in discord/.env does not work)" : ""));
                    throw new Exception("Discord can't be reached (" + e.Status + ")");
                }
            }
            throw new Exception("Discord asked to slow down; trying again soon");
        }

        static long SnowMs(string id) { long v; return long.TryParse(id, out v) ? (v >> 22) + 1420070400000L : 0; }
        static long IsoMs(string iso)
        {
            DateTime t;
            if (iso != null && DateTime.TryParse(iso, CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out t))
                return (long)(t - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
            return 0;
        }

        public void Refresh()
        {
            if (!HasToken) { Error = "No bot token found in discord/.env, so Discord can't be read."; return; }
            try
            {
                if (BotId == "")
                {
                    BotId = Parser.Str(Call("/users/@me"), "id");
                    if (!string.IsNullOrEmpty(guildEnv)) GuildId = guildEnv;
                    else { var gs = Call("/users/@me/guilds") as object[]; GuildId = Parser.Str(gs[0], "id"); }
                }
                var chans = (Call("/guilds/" + GuildId + "/channels") as object[]) ?? new object[0];
                var tagNames = new Dictionary<string, string>();
                BugsForum = FixerForum = "";
                foreach (var c in chans)
                {
                    if (Parser.Str(c, "type") != "15") continue;
                    var name = Parser.Str(c, "name");
                    if (name == "bugs-and-issues") BugsForum = Parser.Str(c, "id");
                    else if (name == "bug-fixer") FixerForum = Parser.Str(c, "id");
                    else continue;
                    var tags = Parser.Get(c, "available_tags") as object[];
                    if (tags != null) foreach (var t in tags) tagNames[Parser.Str(t, "id")] = Parser.Str(t, "name");
                }
                var forums = new[] { BugsForum, FixerForum }.Where(x => x != "").ToList();
                var threads = new List<object>();
                var active = Parser.Get(Call("/guilds/" + GuildId + "/threads/active"), "threads") as object[];
                if (active != null) threads.AddRange(active.Where(t => forums.Contains(Parser.Str(t, "parent_id"))));
                foreach (var f in forums)
                {
                    try
                    {
                        var arch = Parser.Get(Call("/channels/" + f + "/threads/archived/public?limit=40"), "threads") as object[];
                        if (arch != null) threads.AddRange(arch);
                    }
                    catch { }
                }
                var list = new List<Post>();
                var seen = new HashSet<string>();
                foreach (var t in threads)
                {
                    var id = Parser.Str(t, "id");
                    if (id == null || !seen.Add(id)) continue;
                    Post p; cache.TryGetValue(id, out p);
                    bool isNew = p == null;
                    if (isNew) { p = new Post { Id = id }; cache[id] = p; }
                    p.Forum = Parser.Str(t, "parent_id") == FixerForum ? "fixer" : "bugs";
                    p.Title = Parser.Str(t, "name") ?? "";
                    p.Created = SnowMs(id);
                    var meta = Parser.Get(t, "thread_metadata");
                    p.Archived = Parser.Get(meta, "archived") is bool && (bool)Parser.Get(meta, "archived");
                    var flags = Parser.Get(t, "flags"); p.Pinned = flags != null && (Convert.ToInt64(flags) & 2) != 0;
                    var cnt = Parser.Get(t, "message_count"); p.Count = cnt == null ? 0 : Convert.ToInt32(cnt);
                    p.Tags = ((Parser.Get(t, "applied_tags") as object[]) ?? new object[0]).Select(x => { string n; return tagNames.TryGetValue(x.ToString(), out n) ? n : ""; }).Where(n => n != "").ToList();
                    p.AuthorId = Parser.Str(t, "owner_id") ?? "";
                    if (isNew || p.Starter == "")
                    {
                        try
                        {
                            var st = Call("/channels/" + id + "/messages/" + id);
                            p.Starter = Parser.Str(st, "content") ?? "";
                            var au = Parser.Get(st, "author");
                            p.Author = Parser.Str(au, "global_name") ?? Parser.Str(au, "username") ?? "";
                            var rm = Regex.Match(p.Starter, @"report-id:\s*(\d{17,20})");
                            if (rm.Success) p.ReportId = rm.Groups[1].Value;
                            if (p.Starter == "") p.Starter = " ";
                        }
                        catch { }
                    }
                    var lastId = Parser.Str(t, "last_message_id") ?? "";
                    if (lastId != p.LastId)
                    {
                        try
                        {
                            var msgs = (Call("/channels/" + id + "/messages?limit=10") as object[]) ?? new object[0];
                            object last = null;
                            foreach (var m in msgs)
                            {
                                var au = Parser.Get(m, "author");
                                var mine = Parser.Str(au, "id") == BotId;
                                var txt = Parser.Str(m, "content") ?? "";
                                if (mine && txt.StartsWith("👀 Got it")) continue; // the helper's quick receipt
                                last = m; break;
                            }
                            if (last != null)
                            {
                                var au = Parser.Get(last, "author");
                                var aid = Parser.Str(au, "id");
                                p.LastWho = aid == ownerId ? "you" : aid == BotId ? (p.Forum == "fixer" ? "fixer" : "helper") : (Parser.Str(au, "global_name") ?? Parser.Str(au, "username") ?? "player");
                                p.LastTime = IsoMs(Parser.Str(last, "timestamp"));
                                var txt = Parser.Str(last, "content") ?? "";
                                if (txt.Trim() == "" && Parser.Get(last, "attachments") is object[] && ((object[])Parser.Get(last, "attachments")).Length > 0) txt = "(a picture)";
                                p.LastText = Parser.OneLine(txt, 220);
                            }
                            p.LastId = lastId;
                        }
                        catch { }
                    }
                    if (p.AuthorId == ownerId && p.Author != "") p.Author = "you";
                    list.Add(p);
                }
                Posts = list;
                Pinned = list.FirstOrDefault(x => x.Forum == "fixer" && x.Pinned) ?? list.FirstOrDefault(x => x.Forum == "fixer" && x.Title.StartsWith("📦"));
                if (Pinned != null)
                {
                    try { Pinned.Starter = Parser.Str(Call("/channels/" + Pinned.Id + "/messages/" + Pinned.Id), "content") ?? ""; } catch { }
                }
                Error = ""; Fetched = DateTime.Now;
            }
            catch (Exception e) { Error = e.Message; }
        }

        public string Link(string id) { return "https://discord.com/channels/" + GuildId + "/" + id; }
    }

    // ===================================================================== the app
    class App : ApplicationContext
    {
        readonly string repo, projDir;
        readonly Dictionary<string, Run> runs = new Dictionary<string, Run>();
        readonly Dictionary<string, bool> isRun = new Dictionary<string, bool>();
        readonly Discord discord;
        readonly object gate = new object();
        string stateJson = "{}";
        readonly NotifyIcon tray = new NotifyIcon();
        readonly Control ui = new Control();
        TcpListener listener; public int Port;
        static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        readonly Dictionary<string, string> lastSeen = new Dictionary<string, string>(); // for pop-ups
        bool firstPass = true, toldTray;
        byte[] icoPng;

        public App(string repo)
        {
            this.repo = repo;
            Parser.Repo = repo;
            projDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".claude", "projects", Regex.Replace(repo.TrimEnd('\\'), @"[:\\/]", "-"));
            discord = new Discord(ReadEnv(Path.Combine(repo, "discord", ".env")));
            ui.CreateControl(); var h = ui.Handle; // for BeginInvoke from other threads

            icoPng = Resource("app.png");
            Icon icon = null;
            try { using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream("app.ico")) if (s != null) icon = new Icon(s, 32, 32); } catch { }
            tray.Icon = icon ?? SystemIcons.Information;
            tray.Text = "Bug fixer";
            var menu = new ContextMenuStrip();
            menu.Items.Add("Open Bug fixer", null, (s, e) => OpenWindow());
            menu.Items.Add("Quit", null, (s, e) => { tray.Visible = false; ExitThread(); Environment.Exit(0); });
            tray.ContextMenuStrip = menu;
            tray.DoubleClick += (s, e) => OpenWindow();
            tray.BalloonTipClicked += (s, e) => OpenWindow();
            tray.Visible = true;

            // the last port first (an open window keeps working after a restart), then a fixed one, then any free port
            int last = 0;
            try { int.TryParse(File.ReadAllText(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HelloBroBugFixerViewer", "port.txt")).Trim(), out last); } catch { }
            foreach (var port in new[] { last > 0 ? last : -1, 47816, 0 })
            {
                if (port < 0) continue;
                try { listener = new TcpListener(IPAddress.Loopback, port); listener.Start(); break; } catch { listener = null; }
            }
            Port = ((IPEndPoint)listener.LocalEndpoint).Port;
            new Thread(Serve) { IsBackground = true }.Start();
            new Thread(Collect) { IsBackground = true }.Start();
        }

        static Dictionary<string, string> ReadEnv(string file)
        {
            var d = new Dictionary<string, string>();
            try
            {
                foreach (var l in File.ReadAllLines(file))
                {
                    var m = Regex.Match(l, @"^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$");
                    if (m.Success) d[m.Groups[1].Value] = m.Groups[2].Value.Trim('"', '\'');
                }
            }
            catch { }
            return d;
        }

        static byte[] Resource(string name)
        {
            using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
            {
                if (s == null) return new byte[0];
                var ms = new MemoryStream(); s.CopyTo(ms); return ms.ToArray();
            }
        }

        // ---------- window
        public void OpenWindow()
        {
            var url = "http://127.0.0.1:" + Port + "/";
            var edge = new[] {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe") }.FirstOrDefault(File.Exists);
            try
            {
                if (edge != null)
                {
                    var data = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HelloBroBugFixerViewer", "edge");
                    Process.Start(new ProcessStartInfo(edge, "--app=" + url + " --user-data-dir=\"" + data + "\" --window-size=1500,950 --no-first-run --no-default-browser-check --disable-sync --disable-features=Translate,msEdgeSidebarV2") { UseShellExecute = false });
                }
                else Process.Start(url);
            }
            catch { try { Process.Start(url); } catch { } }
            if (!toldTray)
            {
                toldTray = true;
                Balloon("Bug fixer is watching", "Close the window any time: it keeps watching from the tray icon and pops up when something needs you.", ToolTipIcon.Info);
            }
        }

        void Balloon(string title, string text, ToolTipIcon icon)
        {
            try { ui.BeginInvoke((Action)(() => { try { tray.ShowBalloonTip(9000, title, string.IsNullOrEmpty(text) ? " " : text, icon); } catch { } })); } catch { }
        }

        // ---------- data collection
        void ScanRuns()
        {
            if (!Directory.Exists(projDir)) return;
            var cutoff = DateTime.Now.AddDays(-2);
            foreach (var f in Directory.GetFiles(projDir, "*.jsonl"))
            {
                DateTime mt;
                try { mt = File.GetLastWriteTime(f); } catch { continue; }
                if (mt < cutoff) { runs.Remove(f); continue; }
                bool yes;
                if (!isRun.TryGetValue(f, out yes))
                {
                    try
                    {
                        using (var fs = new FileStream(f, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        {
                            var buf = new byte[6000]; int n = fs.Read(buf, 0, buf.Length);
                            var head = Encoding.UTF8.GetString(buf, 0, n);
                            var nl = head.IndexOf('\n');
                            yes = (nl > 0 ? head.Substring(0, nl) : head).Contains("\"content\":\"<scheduled-task name=\\\"hellobro-bug-fixer");
                            if (n < 200 && !yes) continue; // brand-new file: look again next time
                        }
                    }
                    catch { continue; }
                    isRun[f] = yes;
                }
                if (!yes) continue;
                Run old; runs.TryGetValue(f, out old);
                if (old != null && (old.State == "working" || old.State == "stuck")) old = null; // their state depends on the clock
                try { runs[f] = Parser.Load(f, old); } catch { }
            }
        }

        void Collect()
        {
            DateTime lastDiscord = DateTime.MinValue;
            while (true)
            {
                try
                {
                    ScanRuns();
                    var working = runs.Values.Any(r => r.State == "working");
                    if ((DateTime.Now - lastDiscord).TotalSeconds >= (working ? 15 : 30))
                    {
                        lastDiscord = DateTime.Now;
                        discord.Refresh();
                    }
                    var st = BuildState();
                    lock (gate) stateJson = Json.Serialize(st);
                }
                catch (Exception e) { lock (gate) stateJson = Json.Serialize(new Dictionary<string, object> { { "fatal", e.Message } }); }
                Thread.Sleep(3000);
            }
        }

        static long Ms(DateTime t) { return t == DateTime.MinValue ? 0 : (long)(t.ToUniversalTime() - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds; }

        static bool ClaudeAppOpen()
        {
            try { return Process.GetProcessesByName("claude").Length > 0; } catch { return true; }
        }

        static readonly string[] Closed = { "Not possible", "Not a bug" };

        Dictionary<string, object> BuildState()
        {
            var now = DateTime.Now;
            var ordered = runs.Values.OrderByDescending(r => r.Start).ToList();
            var active = ordered.FirstOrDefault(r => r.State == "working");
            var latest = ordered.FirstOrDefault();

            // next run: every 30 minutes (cron */30 plus a few minutes of jitter)
            DateTime next;
            if (latest != null && (now - latest.Start).TotalMinutes < 75) { next = latest.Start.AddMinutes(30); while (next < now.AddMinutes(-2)) next = next.AddMinutes(30); }
            else { next = new DateTime(now.Year, now.Month, now.Day, now.Hour, now.Minute < 30 ? 30 : 0, 0).AddHours(now.Minute < 30 ? 0 : 1).AddMinutes(4); }

            string fixerState = active != null ? "working" : (latest != null && latest.State == "stuck" && (now - latest.Start).TotalMinutes < 60) ? "stuck" : "idle";
            var appOpen = ClaudeAppOpen();
            if (!appOpen && fixerState == "idle") fixerState = "off";

            // ---- cards: one per report (player post + its #bug-fixer post joined by report-id)
            var posts = discord.Posts;
            var pinnedId = discord.Pinned != null ? discord.Pinned.Id : "";
            var fixerByReport = new Dictionary<string, Post>();
            foreach (var p in posts.Where(p => p.Forum == "fixer" && p.ReportId != "")) if (!fixerByReport.ContainsKey(p.ReportId)) fixerByReport[p.ReportId] = p;
            var usedFixer = new HashSet<string>();
            var cards = new List<Dictionary<string, object>>();
            var activeIds = active != null ? active.Ids : new HashSet<string>();

            Action<Post, Post> add = (pl, fx) =>
            {
                var tagsP = pl != null ? pl.Tags : new List<string>();
                var tagsF = fx != null ? fx.Tags : new List<string>();
                Func<string, bool> has = n => tagsF.Contains(n) || tagsP.Contains(n);
                string stage;
                if (has("Live")) stage = "live";
                else if (tagsF.Contains("Fixed, not live yet") || tagsP.Contains("Fixed")) stage = "ready";
                else if (tagsF.Contains("Question for you")) stage = fx.LastWho == "you" ? "fixer" : "you";
                else if (Closed.Any(has)) stage = "closed";
                else if (has("Wish")) stage = (fx != null && fx.LastWho == "fixer") ? "you" : "closed";
                else if (fx != null) stage = "fixer";
                else if (tagsP.Contains("With the developer")) stage = "fixer";
                else stage = "player";
                var main = fx ?? pl;
                var last = new[] { pl, fx }.Where(x => x != null).OrderByDescending(x => x.LastTime).First();
                var title = (pl != null ? pl.Title : fx.Title);
                if (fx != null && pl == null) title = fx.Title;
                var test = Regex.IsMatch(title, @"(?i)^\s*(🧪\s*)?test\b") || (fx != null && fx.Title.Contains("🧪"));
                bool waitingYou = stage == "you";
                string why = "";
                if (stage == "you") why = has("Wish") ? "A wish: should it be built?" : "The fixer asked you something";
                else if (stage == "fixer" && fx != null && fx.LastWho == "you") why = "You answered: the fixer picks it up on its next run";
                var ids = new[] { pl != null ? pl.Id : null, fx != null ? fx.Id : null }.Where(x => x != null);
                cards.Add(new Dictionary<string, object> {
                    { "id", main.Id }, { "title", Parser.OneLine(title.Replace("🧪", "").Trim(), 120) },
                    { "player", pl != null ? pl.Author : (fx.Author == "you" ? "you" : "") },
                    { "stage", stage }, { "tagsPlayer", tagsP }, { "tagsFixer", tagsF },
                    { "created", Math.Min(pl != null ? pl.Created : long.MaxValue, fx != null ? fx.Created : long.MaxValue) },
                    { "lastTime", last.LastTime }, { "lastWho", last.LastWho }, { "lastText", last.LastText },
                    { "playerUrl", pl != null ? discord.Link(pl.Id) : "" }, { "fixerUrl", fx != null ? discord.Link(fx.Id) : "" },
                    { "test", test }, { "why", why }, { "now", ids.Any(i => activeIds.Contains(i)) },
                    { "request", pl == null && fx != null && fx.ReportId == "" },
                });
            };
            foreach (var pl in posts.Where(p => p.Forum == "bugs"))
            {
                Post fx; fixerByReport.TryGetValue(pl.Id, out fx);
                if (fx != null) usedFixer.Add(fx.Id);
                add(pl, fx);
            }
            foreach (var fx in posts.Where(p => p.Forum == "fixer" && p.Id != pinnedId && !usedFixer.Contains(p.Id))) add(null, fx);
            cards = cards.OrderByDescending(c => (long)c["lastTime"]).ToList();

            // ---- waiting to go live (the pinned 📦 post's first message)
            var golive = new List<string>(); bool nothingWaiting = false; string goliveUrl = "", behind = "";
            if (discord.Pinned != null)
            {
                goliveUrl = discord.Link(discord.Pinned.Id);
                var txt = discord.Pinned.Starter ?? "";
                nothingWaiting = Regex.IsMatch(txt, @"(?i)nothing waiting");
                if (!nothingWaiting)
                    foreach (var l in txt.Split('\n'))
                    {
                        var s = l.Trim();
                        if (Regex.IsMatch(s, @"^([-•*]|\d+\.)\s+")) golive.Add(Parser.OneLine(Regex.Replace(s, @"^([-•*]|\d+\.)\s+", ""), 200));
                        else if (Regex.IsMatch(s, @"(?i)^behind the scenes")) behind = Parser.OneLine(s, 120);
                    }
                if (!nothingWaiting && golive.Count == 0 && txt.Trim() != "")
                    golive.AddRange(txt.Split('\n').Select(x => x.Trim()).Where(x => x.Length > 3 && !Regex.IsMatch(x, @"(?i)say .update the public server")).Take(6).Select(x => Parser.OneLine(x, 200)));
            }

            // ---- runs
            var runList = ordered.Take(60).Select(r => new Dictionary<string, object> {
                { "id", r.Id }, { "start", Ms(r.Start) }, { "last", Ms(r.Last) }, { "state", r.State }, { "result", r.Result },
                { "quiet", r.Quiet }, { "fixing", r.Fixing }, { "mode", r.Mode }, { "step", r.Step },
            }).ToList();
            object activeRun = null;
            var show = active ?? (latest != null && latest.State == "stuck" ? latest : null);
            if (show != null)
                activeRun = new Dictionary<string, object> {
                    { "id", show.Id }, { "start", Ms(show.Start) }, { "state", show.State }, { "result", show.Result }, { "fixing", show.Fixing },
                    { "lines", show.Lines.Skip(Math.Max(0, show.Lines.Count - 14)).Select(l => new Dictionary<string, object> { { "t", Ms(l.Time) }, { "k", l.Kind }, { "x", l.Text } }).ToList() },
                };

            var st = new Dictionary<string, object> {
                { "now", Ms(now) }, { "fixer", fixerState }, { "appOpen", appOpen }, { "next", Ms(next) },
                { "activeRun", activeRun }, { "runs", runList }, { "cards", cards },
                { "golive", golive }, { "goliveBehind", behind }, { "nothingWaiting", nothingWaiting }, { "goliveUrl", goliveUrl }, { "goliveKnown", discord.Pinned != null },
                { "discordError", discord.Error }, { "discordAt", Ms(discord.Fetched) },
            };
            Notify(cards, golive, show, fixerState);
            return st;
        }

        void Notify(List<Dictionary<string, object>> cards, List<string> golive, Run show, string fixerState)
        {
            var events = new List<Action>();
            foreach (var c in cards)
            {
                var key = "card:" + c["id"];
                var stage = (string)c["stage"];
                string was; lastSeen.TryGetValue(key, out was);
                lastSeen[key] = stage;
                if (firstPass || was == stage || (bool)c["test"]) continue;
                var title = (string)c["title"];
                if (stage == "you") events.Add(() => Balloon("The fixer has a question for you", title, ToolTipIcon.Warning));
                else if (stage == "ready" && was != null) events.Add(() => Balloon("Fixed, ready to go live", title, ToolTipIcon.Info));
                else if (stage == "fixer" && was == null) events.Add(() => Balloon("New bug report", title, ToolTipIcon.Info));
            }
            var gl = string.Join("|", golive);
            string wasGl; lastSeen.TryGetValue("golive", out wasGl);
            lastSeen["golive"] = gl;
            if (!firstPass && gl != "" && gl != wasGl && discord.Fetched != DateTime.MinValue)
                events.Add(() => Balloon("Waiting to go live: " + golive.Count + (golive.Count == 1 ? " fix" : " fixes"), "Say \"update the public server\" in the 📦 post to put it live.", ToolTipIcon.Info));
            string wasF; lastSeen.TryGetValue("fixer", out wasF);
            var fkey = fixerState + (show != null ? show.Id : "");
            lastSeen["fixer"] = fkey;
            if (!firstPass && fixerState == "stuck" && wasF != fkey)
                events.Add(() => Balloon("The bug fixer looks stuck", show != null ? show.Result : "", ToolTipIcon.Warning));
            if (discord.Fetched != DateTime.MinValue) firstPass = false;
            foreach (var e in events.Take(3)) e();
        }

        object RunDetail(string id)
        {
            var r = runs.Values.FirstOrDefault(x => x.Id == id);
            if (r == null) return new Dictionary<string, object> { { "missing", true } };
            return new Dictionary<string, object> {
                { "id", r.Id }, { "start", Ms(r.Start) }, { "state", r.State }, { "result", r.Result }, { "mode", r.Mode },
                { "lines", r.Lines.Select(l => new Dictionary<string, object> { { "t", Ms(l.Time) }, { "k", l.Kind }, { "x", l.Text } }).ToList() },
            };
        }

        // ---------- tiny web server (127.0.0.1 only)
        void Serve()
        {
            while (true)
            {
                TcpClient c;
                try { c = listener.AcceptTcpClient(); } catch { Thread.Sleep(200); continue; }
                ThreadPool.QueueUserWorkItem(_ => { try { Handle(c); } catch { } finally { try { c.Close(); } catch { } } });
            }
        }

        void Handle(TcpClient c)
        {
            c.ReceiveTimeout = 5000;
            var ns = c.GetStream();
            var buf = new byte[8192]; int n = 0;
            while (n < buf.Length)
            {
                int r = ns.Read(buf, n, buf.Length - n);
                if (r <= 0) break; n += r;
                if (Encoding.ASCII.GetString(buf, 0, n).Contains("\r\n\r\n")) break;
            }
            var head = Encoding.ASCII.GetString(buf, 0, n);
            var m = Regex.Match(head, @"^GET (\S+) HTTP");
            var host = Regex.Match(head, @"(?im)^Host:\s*(\S+)").Groups[1].Value;
            if (!m.Success || (host != "127.0.0.1:" + Port && host != "localhost:" + Port)) { Send(ns, 403, "text/plain", Encoding.UTF8.GetBytes("no")); return; }
            var path = m.Groups[1].Value;
            var q = path.IndexOf('?'); var query = q >= 0 ? path.Substring(q + 1) : ""; if (q >= 0) path = path.Substring(0, q);
            Func<string, string> arg = k => { var mm = Regex.Match(query, "(?:^|&)" + k + "=([^&]*)"); return mm.Success ? Uri.UnescapeDataString(mm.Groups[1].Value.Replace('+', ' ')) : ""; };
            if (path == "/")
            {
                // BFV_DEV=1: serve tools/fixer-viewer/app.html from the repo (to work on the page without rebuilding)
                var dev = Path.Combine(repo, "tools", "fixer-viewer", "app.html");
                Send(ns, 200, "text/html; charset=utf-8", Environment.GetEnvironmentVariable("BFV_DEV") == "1" && File.Exists(dev) ? File.ReadAllBytes(dev) : Resource("app.html"));
            }
            else if (path == "/api/state") { string s; lock (gate) s = stateJson; Send(ns, 200, "application/json; charset=utf-8", Encoding.UTF8.GetBytes(s)); }
            else if (path == "/api/run") Send(ns, 200, "application/json; charset=utf-8", Encoding.UTF8.GetBytes(Json.Serialize(RunDetail(arg("id")))));
            else if (path == "/icon.png") Send(ns, 200, "image/png", icoPng);
            else if (path == "/open")
            {
                var u = arg("u");
                var mm = Regex.Match(u, @"^https://discord\.com/channels/(\d+)/(\d+)$");
                if (mm.Success)
                {
                    bool app = false;
                    try { using (var k = Microsoft.Win32.Registry.ClassesRoot.OpenSubKey("discord")) app = k != null; } catch { }
                    try { Process.Start(app ? "discord://-/channels/" + mm.Groups[1].Value + "/" + mm.Groups[2].Value : u); } catch { try { Process.Start(u); } catch { } }
                }
                Send(ns, 204, "text/plain", new byte[0]);
            }
            else Send(ns, 404, "text/plain", Encoding.UTF8.GetBytes("not found"));
        }

        static void Send(Stream s, int code, string type, byte[] body)
        {
            var h = "HTTP/1.1 " + code + " OK\r\nContent-Type: " + type + "\r\nContent-Length: " + body.Length + "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n";
            var hb = Encoding.ASCII.GetBytes(h);
            s.Write(hb, 0, hb.Length); s.Write(body, 0, body.Length); s.Flush();
        }
    }

    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            var dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HelloBroBugFixerViewer");
            Directory.CreateDirectory(dataDir);
            var portFile = Path.Combine(dataDir, "port.txt");
            bool first;
            var mutex = new Mutex(true, "HelloBroBugFixerViewer", out first);
            if (!first)
            {
                // already running: just open its window again
                try
                {
                    var port = File.ReadAllText(portFile).Trim();
                    var edge = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe");
                    var url = "http://127.0.0.1:" + port + "/";
                    if (File.Exists(edge)) Process.Start(new ProcessStartInfo(edge, "--app=" + url + " --user-data-dir=\"" + Path.Combine(dataDir, "edge") + "\" --window-size=1500,950 --no-first-run --no-default-browser-check") { UseShellExecute = false });
                    else Process.Start(url);
                }
                catch { }
                return;
            }
            string repo = null;
            var cands = new List<string>();
            if (args.Length > 0 && !args[0].StartsWith("--")) cands.Add(args[0]);
            var env = Environment.GetEnvironmentVariable("HB_REPO");
            if (!string.IsNullOrEmpty(env)) cands.Add(env);
            var exeDir = Path.GetDirectoryName(Application.ExecutablePath);
            cands.Add(exeDir); cands.Add(Path.Combine(exeDir, "HelloBroServer"));
            cands.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "HelloBroServer"));
            cands.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Desktop", "HelloBroServer"));
            foreach (var c in cands)
                if (File.Exists(Path.Combine(c, "discord", "dc.js")) && File.Exists(Path.Combine(c, "CLAUDE.md"))) { repo = Path.GetFullPath(c); break; }
            Application.EnableVisualStyles();
            if (repo == null) { MessageBox.Show("Could not find the HelloBroServer folder. Put this program on the Desktop next to it.", "Bug fixer"); return; }
            var app = new App(repo);
            File.WriteAllText(portFile, app.Port.ToString());
            if (!args.Contains("--tray")) app.OpenWindow();
            Application.Run(app);
            GC.KeepAlive(mutex);
        }
    }
}
