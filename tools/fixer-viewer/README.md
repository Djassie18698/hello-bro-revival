# Bug Fixer (the owner's app for the bug pipeline)

A real Windows 11 app (WPF, dark Mica glass, own title bar). It lives in the folder **Desktop\Bug Fixer** (`Bug Fixer.exe`),
with a shortcut **Bug Fixer** on the Desktop. Closing the window keeps it in the tray (pop-ups); right-click the tray icon > Quit.

- **For you**: the questions the fixer asked you (Open shows the post in the app), the fixes waiting to go live (from the pinned
  📦 post) with a **Put it live** button, and what the fixer is doing right now.
- **Board**: every report as a card, moving from *Asking player* → *With the fixer* → *Your answer* → *Not live yet* → *Live*
  (stopped / wishes / not possible below). A card joins the player's #bugs-and-issues post and its #bug-fixer post (the report-id line).
- **Click a card**: the report opens in the app with both posts' messages (pictures too) and the actions:
  **Open in Discord**, **Stop** / **Resume** (tag "Stopped": the fixer leaves it alone), **Delete** (the fixer's post, optionally the
  player's post, and its #bot-logs line, so the fixer never picks it up again; asks first), and a box to **write to the fixer**.
- **New request** (top left): opens a post in #bug-fixer with the tag Request.
- **Pause the fixer** (bottom left): makes the file `%LOCALAPPDATA%\HelloBroBugFixerViewer\PAUSED`; the fixer's STEP 0 stops when it exists.
- **Fixer runs**: every run of the last three days with its plain-words timeline (quiet checks grouped).

What the app writes in Discord (only when you press a button) starts with `📱 **Owner** (Bug fixer app):` and is posted with the bot's
account: `discord/dc.js` shows these as OWNER, and the fixer's prompt (scheduled task hellobro-bug-fixer, SKILL.md) treats them as
yours, but only inside #bug-fixer. `bughelper.js` never starts a message with 📱. The bot token is read from `discord/.env` while
the app runs (never shown, stored or put in the exe).

Files: `Program.cs` (start, one copy, tray), `Ui.cs` (window, pages, report panel, dialogs), `Store.cs` (background collector,
cards and stages), `Discord.cs` (REST: read + the actions), `Parser.cs` (run transcripts → plain words), `app.ico` / `app.png`
(made by `make_icon.ps1`).

**Build:** quit the running Bug Fixer (tray > Quit), then double-click `BUILD.bat` (Windows' own C# compiler and WPF, nothing to
install). It builds `Desktop\Bug Fixer\Bug Fixer.exe` and makes the Desktop shortcut once.
Checks without touching the screen: `"Bug Fixer.exe" --snapshot out.png --page you|board|runs [--detail --stage fixer] [--demo]`
draws the window into a picture; `--selftest` makes a "🧪 TEST" post in #bug-fixer, uses every write action on it and deletes it
(result in `%LOCALAPPDATA%\HelloBroBugFixerViewer\selftest.log`).
