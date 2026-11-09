# Bug fixer viewer

`BUG-FIXER-VIEWER.exe` shows what the scheduled Claude task **hellobro-bug-fixer** is doing, live:
working / idle / stuck, when it runs next, a plain-words timeline of every run (from its transcript in
`%USERPROFILE%\.claude\projects\C--Users-dj199-Desktop-HelloBroServer\*.jsonl`), and the bug reports in
Discord #bot-logs with their state (waiting / being fixed / handled = report-id in `docs/DISCORD-REPORTS.md`).
A tray icon pops up when a run starts fixing, finishes, gets stuck or stops.

It only reads: it never starts, stops or changes anything, and never shows the Discord token.

**Build:** double-click `BUILD.bat` (uses the C# compiler that comes with Windows, nothing to install).
The exe lands on your Desktop (not in git). It finds the HelloBroServer folder next to it, on the Desktop,
or from the first argument / `HB_REPO`.
