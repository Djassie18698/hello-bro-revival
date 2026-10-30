# Working on this together

- **Saves are local.** `hellobro.db` (the SQLite save) is NOT in git. Each person's server creates its own on first start.
  Never commit `*.db` files: they hold accounts and passwords and cannot be merged.
- **Branches + pull requests.** Don't push straight to `main` when several people work at once:
  `git checkout -b my-feature`, commit, `git push -u origin my-feature`, then open a pull request on GitHub.
- **Run it:** Node 22.13+ (Node 24 recommended), then `node server.js` (or `START-SERVER.bat` on Windows). Port 18080.
- **Check before pushing:** `node tools/dev/smoke.js` calls every handler on a throwaway DB and reports crashes.
- **Read first:** `CLAUDE.md`, `PLAN.md`, `docs/NEXT-STEPS.md`, `PROTOCOL-NOTES.txt`. Never guess a reply format; verify it in
  `reference/lua-scripts/` or by disassembly, because a missing field crashes the game client.
- **Unbuilt features** are listed at the end of `docs/NEXT-STEPS.md` (border war, adventure/"Awakens", friend add/chat, tower sweep).
