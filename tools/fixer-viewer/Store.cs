// Bug Fixer app: collects everything in the background (run transcripts every 3 s, Discord every 15-30 s) into one Snapshot.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace FixerViewer
{
    class Card
    {
        public string Id, Title = "", Player = "", Stage = "", Why = "", LastWho = "", LastText = "", PlayerId, FixerId, ReportId;
        public List<string> TagsP = new List<string>(), TagsF = new List<string>();
        public long Created, LastTime; public bool Test, Now, Request, Stopped;
        public IEnumerable<string> AllTags { get { return TagsF.Concat(TagsP).Distinct(); } }
    }

    class Snapshot
    {
        public int Version; public DateTime Taken;
        public string Fixer = "idle"; // working | checking | idle | stuck | off | paused
        public bool AppOpen = true, Paused;
        public DateTime Next;
        public Run Active, Latest;
        public List<Run> Runs = new List<Run>();
        public List<Card> Cards = new List<Card>();
        public List<string> GoLive = new List<string>(); public string GoLiveBehind = ""; public bool GoLiveKnown; public string PinnedId;
        public string DiscordError = ""; public bool DiscordLoaded;
    }

    class Store
    {
        public readonly string Repo, ProjDir, DataDir;
        public readonly Discord Discord;
        readonly Dictionary<string, Run> runs = new Dictionary<string, Run>();
        readonly Dictionary<string, bool> isRun = new Dictionary<string, bool>();
        public volatile Snapshot Current = new Snapshot();
        volatile bool refreshNow;
        int version;
        public bool Demo;
        public event Action<string, string, bool> Alert; // title, text, warning

        public Store(string repo, bool demo)
        {
            Repo = repo; Demo = demo;
            Parser.Repo = repo;
            ProjDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".claude", "projects", Regex.Replace(repo.TrimEnd('\\'), @"[:\\/]", "-"));
            DataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HelloBroBugFixerViewer");
            Directory.CreateDirectory(DataDir);
            Discord = new Discord(ReadEnv(Path.Combine(repo, "discord", ".env")));
        }

        public string PauseFile { get { return Path.Combine(DataDir, "PAUSED"); } }
        public bool Paused { get { return File.Exists(PauseFile); } }
        public void SetPaused(bool on)
        {
            if (on) File.WriteAllText(PauseFile, "Paused in the Bug Fixer app on " + DateTime.Now.ToString("d MMM yyyy HH:mm") + ". The bug fixer stops at the start of every run while this file exists.");
            else if (File.Exists(PauseFile)) File.Delete(PauseFile);
            refreshNow = true;
        }
        public void RefreshSoon() { refreshNow = true; }

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

        public void Start() { new Thread(Loop) { IsBackground = true, Name = "collector" }.Start(); }

        void Loop()
        {
            DateTime lastDiscord = DateTime.MinValue;
            bool first = true;
            while (true)
            {
                try
                {
                    ScanRuns();
                    var working = runs.Values.Any(r => r.State == "working");
                    if (refreshNow || (DateTime.Now - lastDiscord).TotalSeconds >= (working ? 15 : 30))
                    {
                        refreshNow = false; lastDiscord = DateTime.Now;
                        Discord.Refresh();
                    }
                    var snap = Build();
                    if (!first || Discord.Fetched != DateTime.MinValue) Notify(snap, first);
                    if (Discord.Fetched != DateTime.MinValue) first = false;
                    Current = snap;
                }
                catch { }
                for (int i = 0; i < 30 && !refreshNow; i++) Thread.Sleep(100);
            }
        }

        void ScanRuns()
        {
            if (!Directory.Exists(ProjDir)) return;
            var cutoff = DateTime.Now.AddDays(-3);
            foreach (var f in Directory.GetFiles(ProjDir, "*.jsonl"))
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
                            if (n < 200 && !yes) continue;
                        }
                    }
                    catch { continue; }
                    isRun[f] = yes;
                }
                if (!yes) continue;
                Run old; runs.TryGetValue(f, out old);
                if (old != null && (old.State == "working" || old.State == "stuck")) old = null;
                try { runs[f] = Parser.Load(f, old); } catch { }
            }
        }

        static bool ClaudeAppOpen() { try { return Process.GetProcessesByName("claude").Length > 0; } catch { return true; } }

        Snapshot Build()
        {
            var now = DateTime.Now;
            var s = new Snapshot { Version = ++version, Taken = now, Paused = Paused, AppOpen = ClaudeAppOpen() };
            s.Runs = runs.Values.OrderByDescending(r => r.Start).ToList();
            s.Active = s.Runs.FirstOrDefault(r => r.State == "working");
            s.Latest = s.Runs.FirstOrDefault();
            var latest = s.Latest;
            if (latest != null && (now - latest.Start).TotalMinutes < 75) { s.Next = latest.Start.AddMinutes(30); while (s.Next < now.AddMinutes(-2)) s.Next = s.Next.AddMinutes(30); }
            else s.Next = new DateTime(now.Year, now.Month, now.Day, now.Hour, 0, 0).AddMinutes(now.Minute < 30 ? 34 : 64);
            if (s.Active != null) s.Fixer = s.Active.Fixing ? "working" : "checking";
            else if (latest != null && latest.State == "stuck" && (now - latest.Start).TotalMinutes < 60) s.Fixer = "stuck";
            else if (s.Paused) s.Fixer = "paused";
            else if (!s.AppOpen) s.Fixer = "off";
            else s.Fixer = "idle";
            if (s.Active == null && latest != null && latest.State == "stuck" && s.Fixer == "stuck") s.Active = latest;

            s.DiscordError = Discord.Error; s.DiscordLoaded = Discord.Fetched != DateTime.MinValue;
            var posts = Discord.Posts;
            var pinned = Discord.Pinned;
            s.PinnedId = pinned != null ? pinned.Id : null;
            var fixerByReport = new Dictionary<string, Post>();
            foreach (var p in posts.Where(p => p.Forum == "fixer" && p.ReportId != "")) if (!fixerByReport.ContainsKey(p.ReportId)) fixerByReport[p.ReportId] = p;
            var used = new HashSet<string>();
            var activeIds = s.Active != null ? s.Active.Ids : new HashSet<string>();
            foreach (var pl in posts.Where(p => p.Forum == "bugs"))
            {
                Post fx; fixerByReport.TryGetValue(pl.Id, out fx);
                if (fx != null) used.Add(fx.Id);
                s.Cards.Add(MakeCard(pl, fx, activeIds));
            }
            foreach (var fx in posts.Where(p => p.Forum == "fixer" && p.Id != s.PinnedId && !used.Contains(p.Id))) s.Cards.Add(MakeCard(null, fx, activeIds));
            s.Cards = s.Cards.OrderByDescending(c => c.LastTime).ToList();

            if (pinned != null)
            {
                s.GoLiveKnown = true;
                var txt = pinned.Starter ?? "";
                if (!Regex.IsMatch(txt, @"(?i)nothing waiting"))
                {
                    foreach (var l in txt.Split('\n'))
                    {
                        var t = l.Trim();
                        if (Regex.IsMatch(t, @"^([-•*]|\d+\.)\s+")) s.GoLive.Add(Parser.OneLine(Regex.Replace(t, @"^([-•*]|\d+\.)\s+", ""), 220));
                        else if (Regex.IsMatch(t, @"(?i)^behind the scenes")) s.GoLiveBehind = Parser.OneLine(t, 140);
                    }
                    if (s.GoLive.Count == 0 && txt.Trim() != "")
                        s.GoLive.AddRange(txt.Split('\n').Select(x => x.Trim()).Where(x => x.Length > 3 && !Regex.IsMatch(x, @"(?i)say .update the public server")).Take(6).Select(x => Parser.OneLine(x, 220)));
                }
            }
            if (Demo) DemoData(s);
            return s;
        }

        static readonly string[] Closed = { "Not possible", "Not a bug" };

        Card MakeCard(Post pl, Post fx, HashSet<string> activeIds)
        {
            var c = new Card { PlayerId = pl != null ? pl.Id : null, FixerId = fx != null ? fx.Id : null };
            c.Id = c.FixerId ?? c.PlayerId;
            c.TagsP = pl != null ? pl.Tags : new List<string>();
            c.TagsF = fx != null ? fx.Tags : new List<string>();
            c.ReportId = fx != null && fx.ReportId != "" ? fx.ReportId : c.PlayerId;
            Func<string, bool> has = n => c.TagsF.Contains(n) || c.TagsP.Contains(n);
            c.Stopped = c.TagsF.Contains("Stopped");
            if (c.Stopped) c.Stage = "closed";
            else if (has("Live")) c.Stage = "live";
            else if (c.TagsF.Contains("Fixed, not live yet") || c.TagsP.Contains("Fixed")) c.Stage = "ready";
            else if (c.TagsF.Contains("Question for you")) c.Stage = fx.LastWho == "you" ? "fixer" : "you";
            else if (Closed.Any(has)) c.Stage = "closed";
            else if (has("Wish")) c.Stage = (fx != null && fx.LastWho == "fixer") ? "you" : "closed";
            else if (fx != null || c.TagsP.Contains("With the developer")) c.Stage = "fixer";
            else c.Stage = "player";
            var last = new[] { pl, fx }.Where(x => x != null).OrderByDescending(x => x.LastTime).First();
            c.Title = Parser.OneLine((pl != null ? pl.Title : fx.Title).Replace("🧪", "").Trim(), 140);
            c.Test = Regex.IsMatch(pl != null ? pl.Title : fx.Title, @"(?i)^\s*(🧪\s*)?test\b") || (fx != null && fx.Title.Contains("🧪"));
            c.Player = pl != null ? pl.Author : (fx.Author == "you" || fx.Starter.StartsWith(Discord.AppMark.Trim()) ? "you" : "");
            c.Request = pl == null && fx != null && fx.ReportId == "";
            c.Created = Math.Min(pl != null ? pl.Created : long.MaxValue, fx != null ? fx.Created : long.MaxValue);
            c.LastTime = last.LastTime; c.LastWho = last.LastWho; c.LastText = last.LastText;
            if (c.Stage == "you") c.Why = has("Wish") ? "A wish: should it be built?" : "The fixer asked you something";
            else if (c.Stage == "fixer" && fx != null && fx.LastWho == "you") c.Why = "You answered: the fixer picks it up on its next check";
            else if (c.Stopped) c.Why = "Stopped by you";
            c.Now = (c.PlayerId != null && activeIds.Contains(c.PlayerId)) || (c.FixerId != null && activeIds.Contains(c.FixerId));
            return c;
        }

        // pop-ups for the tray: a question for you, a fix ready to go live, a new report, the fixer stuck
        readonly Dictionary<string, string> seen = new Dictionary<string, string>();
        void Notify(Snapshot s, bool first)
        {
            if (Alert == null || Demo) return;
            var events = new List<string[]>();
            foreach (var c in s.Cards)
            {
                string was; seen.TryGetValue("card:" + c.Id, out was);
                seen["card:" + c.Id] = c.Stage;
                if (first || was == c.Stage || c.Test) continue;
                if (c.Stage == "you") events.Add(new[] { "The fixer has a question for you", c.Title, "w" });
                else if (c.Stage == "ready" && was != null) events.Add(new[] { "Fixed, ready to go live", c.Title, "" });
                else if ((c.Stage == "fixer" || c.Stage == "player") && was == null) events.Add(new[] { "New bug report", c.Title, "" });
            }
            var gl = string.Join("|", s.GoLive);
            string wasGl; seen.TryGetValue("golive", out wasGl); seen["golive"] = gl;
            if (!first && gl != "" && gl != wasGl) events.Add(new[] { "Ready to go live: " + s.GoLive.Count + (s.GoLive.Count == 1 ? " fix" : " fixes"), "Open Bug Fixer and press Put it live.", "" });
            var fk = s.Fixer + (s.Active != null ? s.Active.Id : "");
            string wasF; seen.TryGetValue("fixer", out wasF); seen["fixer"] = fk;
            if (!first && s.Fixer == "stuck" && wasF != fk) events.Add(new[] { "The bug fixer looks stuck", s.Active != null ? s.Active.Result : "", "w" });
            foreach (var e in events.Take(3)) Alert(e[0], e[1], e[2] == "w");
        }

        // sample cards for screenshots only (--demo)
        static void DemoData(Snapshot s)
        {
            long n = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalMilliseconds, h = 3600000;
            Func<string, string, string, string[], string[], string, string, double, Card> mk = (stage, title, player, tp, tf, who, text, age) => new Card {
                Id = title, Title = title, Player = player, Stage = stage, TagsP = tp.ToList(), TagsF = tf.ToList(), Created = n - (long)(age * h), LastTime = n - (long)(age * h / 3),
                LastWho = who, LastText = text, PlayerId = "p:" + title, FixerId = tf.Length > 0 ? "f:" + title : null };
            s.Cards = new List<Card> {
                mk("player", "Arena rewards not arriving after rank 50", "buva", new[] { "Needs info" }, new string[0], "helper", "Thanks! Which screen shows the reward, and is it every day?", 0.3),
                mk("fixer", "Pet does not attack in boss fights", "Ronin", new[] { "With the developer" }, new[] { "Working on it" }, "fixer", "Found it: the boss fight skips the pet. Fixing now.", 2),
                mk("fixer", "Shop shows 0 gold after a top-up", "polterslave", new[] { "With the developer" }, new[] { "New report" }, "helper", "Report passed on to the developer.", 1),
                mk("you", "Extra stones in Sage Growth: which numbers?", "buva", new[] { "With the developer" }, new[] { "Question for you" }, "fixer", "Option 1: the photo numbers (+0.2 % a stone). Option 2: ours. I would pick 1.", 5),
                mk("you", "Wish: a daily login calendar", "Goat", new[] { "Wish" }, new[] { "Wish" }, "fixer", "Should this be built?", 3),
                mk("ready", "Double EXP Pill gave normal EXP", "buva", new[] { "Fixed" }, new[] { "Fixed, not live yet" }, "fixer", "Fixed. It goes live with the next update.", 9),
                mk("live", "Golden Choji EXP card gives far less EXP", "Ronin", new[] { "Live" }, new[] { "Live" }, "fixer", "Live now on the public server.", 26),
                mk("closed", "Add a dark mode to the shop", "kid", new[] { "Wish" }, new[] { "Stopped" }, "you", "Not now.", 30),
            };
            s.Cards[1].Now = true; s.Cards[3].Why = "The fixer asked you something"; s.Cards[4].Why = "A wish: should it be built?"; s.Cards[7].Stopped = true; s.Cards[7].Why = "Stopped by you";
            s.GoLive = new List<string> { "Double EXP Pill now doubles the EXP on screen too (buva)", "Secret Shop grain x10 costs 400 souls again (buva)" };
            s.GoLiveBehind = "Behind the scenes: 3 other changes"; s.GoLiveKnown = true; s.DiscordLoaded = true;
        }
    }
}
