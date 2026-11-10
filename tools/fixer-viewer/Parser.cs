// Bug Fixer app: the fixer's run transcripts turned into plain-words lines (read-only).
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

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
            new [] { @"HelloBroBugFixerViewer/PAUSED", "checking if you paused it" },
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
            return label.StartsWith("checking if you paused") || label.StartsWith("looking for new reports") || label.StartsWith("checking the #bug-fixer") || label.StartsWith("checking the players'") ||
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

}
