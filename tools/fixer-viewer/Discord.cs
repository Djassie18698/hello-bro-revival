// Bug Fixer app: Discord REST with the bot token from discord/.env (read at runtime; never shown, stored or put in the exe).
// Reads the two forums; writes only what the owner asks for in the app (owner, 11 Nov 2026): a message in a #bug-fixer post
// (it starts with AppMark, so the fixer treats it as the owner's), the Stopped / New report tag, a new request post,
// and deleting a report (its #bug-fixer post, optionally the player's post, and its #bot-logs line).
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;

namespace FixerViewer
{
    class Post
    {
        public string Id, Forum, Title = "", Author = "", AuthorId = "", LastId = "";
        public List<string> Tags = new List<string>();
        public bool Archived, Pinned;
        public long Created, LastTime; public string LastWho = "", LastText = "";
        public string Starter = ""; public string ReportId = "";
    }

    class Msg
    {
        public string Id, Who = "", Text = ""; public long Time; public bool FromApp, Mine, Owner;
        public List<string> Images = new List<string>();
    }

    class Discord
    {
        public const string AppMark = "📱 **Owner** (Bug fixer app): ";
        readonly string token; readonly string ownerId; readonly string guildEnv;
        public string Error = "", BotId = "", GuildId = "", BugsForum = "", FixerForum = "", BotLogs = "";
        public DateTime Fetched = DateTime.MinValue;
        readonly Dictionary<string, Post> cache = new Dictionary<string, Post>();
        public List<Post> Posts = new List<Post>();
        public Post Pinned;
        Dictionary<string, string> fixerTagIds = new Dictionary<string, string>(), bugsTagIds = new Dictionary<string, string>();
        static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        readonly object net = new object();

        public Discord(Dictionary<string, string> env)
        {
            env.TryGetValue("DISCORD_TOKEN", out token);
            string o; env.TryGetValue("OWNER_IDS", out o); ownerId = (o ?? "").Split(',')[0].Trim();
            env.TryGetValue("GUILD_ID", out guildEnv);
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        }
        public bool HasToken { get { return !string.IsNullOrEmpty(token); } }

        object Call(string method, string path, object body = null)
        {
            for (int attempt = 0; attempt < 4; attempt++)
            {
                var req = (HttpWebRequest)WebRequest.Create("https://discord.com/api/v10" + path);
                req.Method = method;
                req.Headers["Authorization"] = "Bot " + token;
                req.UserAgent = "HelloBroBugFixer (local app, 3.0)";
                req.Timeout = 20000;
                if (body != null)
                {
                    var bytes = Encoding.UTF8.GetBytes(Json.Serialize(body));
                    req.ContentType = "application/json";
                    req.ContentLength = bytes.Length;
                    using (var s = req.GetRequestStream()) s.Write(bytes, 0, bytes.Length);
                }
                else if (method != "GET") req.ContentLength = 0;
                try
                {
                    using (var res = (HttpWebResponse)req.GetResponse())
                    using (var sr = new StreamReader(res.GetResponseStream(), Encoding.UTF8))
                    {
                        var txt = sr.ReadToEnd();
                        return txt.Length == 0 ? null : Json.DeserializeObject(txt);
                    }
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
                    if (r != null)
                    {
                        string msg = "";
                        try { using (var sr = new StreamReader(r.GetResponseStream())) msg = Parser.Str(Json.DeserializeObject(sr.ReadToEnd()), "message") ?? ""; } catch { }
                        if (r.StatusCode == HttpStatusCode.Unauthorized) throw new Exception("the bot token in discord/.env does not work");
                        if (r.StatusCode == HttpStatusCode.NotFound) throw new Exception("not found on Discord (deleted?)");
                        throw new Exception("Discord said " + (int)r.StatusCode + (msg != "" ? ": " + msg : ""));
                    }
                    throw new Exception("Discord can't be reached (" + e.Status + ")");
                }
            }
            throw new Exception("Discord asked to slow down; try again in a minute");
        }
        object Get(string path) { return Call("GET", path); }

        static long SnowMs(string id) { long v; return long.TryParse(id, out v) ? (v >> 22) + 1420070400000L : 0; }
        public static long IsoMs(string iso)
        {
            DateTime t;
            if (iso != null && DateTime.TryParse(iso, CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out t))
                return (long)(t - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
            return 0;
        }

        string WhoOf(object author, string content, string forum)
        {
            var aid = Parser.Str(author, "id");
            if (aid == ownerId) return "you";
            if (aid == BotId) return (content ?? "").StartsWith(AppMark.Trim()) ? "you" : forum == "fixer" ? "fixer" : "helper";
            return Parser.Str(author, "global_name") ?? Parser.Str(author, "username") ?? "player";
        }

        public void Refresh()
        {
            if (!HasToken) { Error = "No bot token found in discord/.env, so Discord can't be read."; return; }
            lock (net)
            try
            {
                if (BotId == "")
                {
                    BotId = Parser.Str(Get("/users/@me"), "id");
                    if (!string.IsNullOrEmpty(guildEnv)) GuildId = guildEnv;
                    else { var gs = Get("/users/@me/guilds") as object[]; GuildId = Parser.Str(gs[0], "id"); }
                }
                var chans = (Get("/guilds/" + GuildId + "/channels") as object[]) ?? new object[0];
                var tagNames = new Dictionary<string, string>();
                BugsForum = FixerForum = "";
                foreach (var c in chans)
                {
                    var name = Parser.Str(c, "name");
                    if (Parser.Str(c, "type") == "0" && name == "bot-logs") BotLogs = Parser.Str(c, "id");
                    if (Parser.Str(c, "type") != "15") continue;
                    Dictionary<string, string> ids;
                    if (name == "bugs-and-issues") { BugsForum = Parser.Str(c, "id"); ids = bugsTagIds = new Dictionary<string, string>(); }
                    else if (name == "bug-fixer") { FixerForum = Parser.Str(c, "id"); ids = fixerTagIds = new Dictionary<string, string>(); }
                    else continue;
                    var tags = Parser.Get(c, "available_tags") as object[];
                    if (tags != null) foreach (var t in tags) { tagNames[Parser.Str(t, "id")] = Parser.Str(t, "name"); ids[Parser.Str(t, "name")] = Parser.Str(t, "id"); }
                }
                var forums = new[] { BugsForum, FixerForum }.Where(x => x != "").ToList();
                var threads = new List<object>();
                var active = Parser.Get(Get("/guilds/" + GuildId + "/threads/active"), "threads") as object[];
                if (active != null) threads.AddRange(active.Where(t => forums.Contains(Parser.Str(t, "parent_id"))));
                foreach (var f in forums)
                {
                    try { var arch = Parser.Get(Get("/channels/" + f + "/threads/archived/public?limit=40"), "threads") as object[]; if (arch != null) threads.AddRange(arch); }
                    catch { }
                }
                var list = new List<Post>();
                var seen = new HashSet<string>();
                foreach (var t in threads)
                {
                    var id = Parser.Str(t, "id");
                    if (id == null || !seen.Add(id)) continue;
                    Post p; cache.TryGetValue(id, out p);
                    if (p == null) { p = new Post { Id = id }; cache[id] = p; }
                    p.Forum = Parser.Str(t, "parent_id") == FixerForum ? "fixer" : "bugs";
                    p.Title = Parser.Str(t, "name") ?? "";
                    p.Created = SnowMs(id);
                    var meta = Parser.Get(t, "thread_metadata");
                    p.Archived = Parser.Get(meta, "archived") is bool && (bool)Parser.Get(meta, "archived");
                    var flags = Parser.Get(t, "flags"); p.Pinned = flags != null && (Convert.ToInt64(flags) & 2) != 0;
                    p.Tags = ((Parser.Get(t, "applied_tags") as object[]) ?? new object[0]).Select(x => { string n; return tagNames.TryGetValue(x.ToString(), out n) ? n : ""; }).Where(n => n != "").ToList();
                    p.AuthorId = Parser.Str(t, "owner_id") ?? "";
                    if (p.Starter == "")
                    {
                        try
                        {
                            var st = Get("/channels/" + id + "/messages/" + id);
                            p.Starter = Parser.Str(st, "content") ?? "";
                            var au = Parser.Get(st, "author");
                            p.Author = Parser.Str(au, "id") == ownerId ? "you" : Parser.Str(au, "id") == BotId ? (p.Forum == "fixer" ? "fixer" : "helper") : (Parser.Str(au, "global_name") ?? Parser.Str(au, "username") ?? "");
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
                            var msgs = (Get("/channels/" + id + "/messages?limit=10") as object[]) ?? new object[0];
                            object last = null;
                            foreach (var m in msgs)
                            {
                                var mine = Parser.Str(Parser.Get(m, "author"), "id") == BotId;
                                if (mine && (Parser.Str(m, "content") ?? "").StartsWith("👀 Got it")) continue; // the helper's quick receipt
                                last = m; break;
                            }
                            if (last != null)
                            {
                                var txt = Parser.Str(last, "content") ?? "";
                                p.LastWho = WhoOf(Parser.Get(last, "author"), txt, p.Forum);
                                p.LastTime = IsoMs(Parser.Str(last, "timestamp"));
                                if (txt.StartsWith(AppMark.Trim())) txt = txt.Substring(AppMark.Trim().Length);
                                if (txt.Trim() == "" && Parser.Get(last, "attachments") is object[] && ((object[])Parser.Get(last, "attachments")).Length > 0) txt = "(a picture)";
                                p.LastText = Parser.OneLine(txt, 220);
                            }
                            p.LastId = lastId;
                        }
                        catch { }
                    }
                    list.Add(p);
                }
                Posts = list;
                Pinned = list.FirstOrDefault(x => x.Forum == "fixer" && x.Pinned) ?? list.FirstOrDefault(x => x.Forum == "fixer" && x.Title.StartsWith("📦"));
                if (Pinned != null) { try { Pinned.Starter = Parser.Str(Get("/channels/" + Pinned.Id + "/messages/" + Pinned.Id), "content") ?? ""; } catch { } }
                Error = ""; Fetched = DateTime.Now;
            }
            catch (Exception e) { Error = e.Message; }
        }

        public string Link(string id) { return "https://discord.com/channels/" + GuildId + "/" + id; }

        // ---------- reading one post for the app's detail view
        public List<Msg> Messages(string threadId, string forum)
        {
            lock (net)
            {
                var arr = (Get("/channels/" + threadId + "/messages?limit=60") as object[]) ?? new object[0];
                var list = new List<Msg>();
                foreach (var m in arr.Reverse())
                {
                    var type = Parser.Str(m, "type");
                    if (type != "0" && type != "19") continue;
                    var txt = Parser.Str(m, "content") ?? "";
                    var mine = Parser.Str(Parser.Get(m, "author"), "id") == BotId;
                    if (mine && txt.StartsWith("👀 Got it")) continue;
                    var msg = new Msg { Id = Parser.Str(m, "id"), Time = IsoMs(Parser.Str(m, "timestamp")), Mine = mine };
                    msg.FromApp = mine && txt.StartsWith(AppMark.Trim());
                    if (msg.FromApp) txt = txt.Substring(AppMark.Trim().Length).TrimStart();
                    msg.Who = WhoOf(Parser.Get(m, "author"), Parser.Str(m, "content"), forum);
                    msg.Owner = msg.Who == "you";
                    msg.Text = Parser.Clean(Regex.Replace(txt, @"<@!?\d+>", "@you"));
                    var att = Parser.Get(m, "attachments") as object[];
                    if (att != null)
                        foreach (var a in att)
                        {
                            var url = Parser.Str(a, "url") ?? "";
                            var ct = Parser.Str(a, "content_type") ?? "";
                            if (ct.StartsWith("image/") || Regex.IsMatch(url, @"\.(png|jpe?g|webp|gif)(\?|$)", RegexOptions.IgnoreCase)) msg.Images.Add(url);
                        }
                    list.Add(msg);
                }
                return list;
            }
        }

        // ---------- the owner's actions (each one only when the owner presses it in the app)
        void EnsureFixerTag(string name, string emoji)
        {
            if (fixerTagIds.ContainsKey(name)) return;
            var forum = Get("/channels/" + FixerForum);
            var have = ((Parser.Get(forum, "available_tags") as object[]) ?? new object[0]).Select(t => (object)new Dictionary<string, object> {
                { "id", Parser.Str(t, "id") }, { "name", Parser.Str(t, "name") }, { "emoji_name", Parser.Str(t, "emoji_name") }, { "moderated", Parser.Get(t, "moderated") ?? false } }).ToList();
            have.Add(new Dictionary<string, object> { { "name", name }, { "emoji_name", emoji }, { "moderated", false } });
            var res = Call("PATCH", "/channels/" + FixerForum, new Dictionary<string, object> { { "available_tags", have } });
            foreach (var t in (Parser.Get(res, "available_tags") as object[]) ?? new object[0]) fixerTagIds[Parser.Str(t, "name")] = Parser.Str(t, "id");
        }

        public void Write(string threadId, string text)
        {
            lock (net)
            {
                text = (text ?? "").Trim();
                if (text == "") throw new Exception("the message is empty");
                foreach (var part in Split(AppMark + text, 1900))
                    Call("POST", "/channels/" + threadId + "/messages", new Dictionary<string, object> { { "content", part }, { "allowed_mentions", new Dictionary<string, object> { { "parse", new string[0] } } } });
            }
        }

        static IEnumerable<string> Split(string s, int max)
        {
            while (s.Length > max) { var cut = s.LastIndexOf('\n', max); if (cut < max / 2) cut = max; yield return s.Substring(0, cut); s = s.Substring(cut); }
            if (s.Length > 0) yield return s;
        }

        public void SetFixerTag(string threadId, string tag)
        {
            lock (net)
            {
                if (tag == "Stopped") EnsureFixerTag("Stopped", "⏸️");
                string id;
                if (!fixerTagIds.TryGetValue(tag, out id)) throw new Exception("the #bug-fixer forum has no tag \"" + tag + "\"");
                Call("PATCH", "/channels/" + threadId, new Dictionary<string, object> { { "applied_tags", new[] { id } }, { "archived", false } });
            }
        }

        public string NewRequest(string title, string text)
        {
            lock (net)
            {
                string tag;
                fixerTagIds.TryGetValue("Request", out tag);
                var body = new Dictionary<string, object> {
                    { "name", title.Trim().Length > 100 ? title.Trim().Substring(0, 100) : title.Trim() },
                    { "message", new Dictionary<string, object> { { "content", AppMark + text.Trim() }, { "allowed_mentions", new Dictionary<string, object> { { "parse", new string[0] } } } } } };
                if (tag != null) body["applied_tags"] = new[] { tag };
                return Parser.Str(Call("POST", "/channels/" + FixerForum + "/threads", body), "id");
            }
        }

        // returns what was deleted, in plain words
        public List<string> DeleteReport(string fixerId, string playerId, bool alsoPlayer, string reportId)
        {
            lock (net)
            {
                var done = new List<string>();
                if (!string.IsNullOrEmpty(fixerId)) { Call("DELETE", "/channels/" + fixerId); done.Add("the fixer's post"); }
                if (alsoPlayer && !string.IsNullOrEmpty(playerId)) { Call("DELETE", "/channels/" + playerId); done.Add("the player's post"); }
                var rid = !string.IsNullOrEmpty(reportId) ? reportId : playerId;
                if (!string.IsNullOrEmpty(rid) && BotLogs != "")
                {
                    var msgs = (Get("/channels/" + BotLogs + "/messages?limit=100") as object[]) ?? new object[0];
                    foreach (var m in msgs)
                        if (Parser.Str(Parser.Get(m, "author"), "id") == BotId && (Parser.Str(m, "content") ?? "").Contains("report-id: " + rid))
                        { Call("DELETE", "/channels/" + BotLogs + "/messages/" + Parser.Str(m, "id")); if (!done.Contains("its line in #bot-logs")) done.Add("its line in #bot-logs"); }
                }
                foreach (var k in new[] { fixerId, playerId }) if (k != null) cache.Remove(k);
                Posts = Posts.Where(p => p.Id != fixerId && !(alsoPlayer && p.Id == playerId)).ToList();
                return done;
            }
        }
    }
}
