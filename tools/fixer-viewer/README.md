# Bug fixer (BUG-FIXER-VIEWER.exe)

The owner's window on the bug pipeline. Double-click `BUG-FIXER-VIEWER.exe` on the Desktop: a window opens with

- **Waiting for you**: posts in #bug-fixer where the fixer asked you something (tag "Question for you", or a wish it asks about),
  and the fixes waiting to go live (read from the pinned "📦 Waiting to go live" post), each with a button that opens the Discord post.
- **The board**: every report as a card, moving from *Asking player* → *With the fixer* → *Your answer* → *Not live yet* → *Live*
  (wishes / not possible / not a bug below). A card joins the player's #bugs-and-issues post and its #bug-fixer post (the
  "report-id" line). It shows the player, the age, the tags and who wrote last; click it to open Discord. A card the fixer works
  on right now has an orange frame.
- **The fixer**: working / resting / stuck / off (the Claude app is closed), the current step in plain words, the next check
  (every 30 minutes), and the recent runs (quiet checks are grouped). Click a run to see everything it did.
- **Tray icon** (stays when the window is closed): pop-ups for a question for you, a fix ready to go live, a new report and a
  stuck fixer. Double-click the icon to open the window again; right-click > Quit to stop it.

Only reads: Discord through the bot token in `discord/.env` (read at runtime, never shown or stored, only sent to discord.com),
the fixer's run transcripts in `%USERPROFILE%\.claude\projects\C--Users-dj199-Desktop-HelloBroServer`. It never posts or changes anything.

How it works: one C# program (`FixerViewer.cs`) with a tiny web server on 127.0.0.1 (port 47816, or the last one used) that
serves `app.html` (built into the exe) and `/api/state`; the window is Microsoft Edge in app mode (no address bar,
own profile in `%LOCALAPPDATA%\HelloBroBugFixerViewer`). Starting the exe again just opens the window again.

**Build:** close the running one (tray icon > Quit), then double-click `BUILD.bat` (Windows' own C# compiler, nothing to install).
The exe lands on the Desktop (not in git). `make_icon.ps1` draws `app.ico` / `app.png` when they are missing.
Working on the page: set `BFV_DEV=1` before starting the exe and it serves `app.html` from this folder; `#demo` /
`#demo-working` after the address fill every column with sample cards.
