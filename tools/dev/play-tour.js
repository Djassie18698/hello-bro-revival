// Looks at EVERY window of a screen of the rewritten game: opens the screen in the browser of tools/dev/play.js (serve), saves a
// picture, then presses each of its buttons with a real tap, one at a time on a freshly opened screen, and saves a picture
// whenever something new shows (a window, another screen); one level deeper for the windows that opened (--deep).
// Per picture it lists Chinese texts left and what fit.js had to shrink. Pictures + report.txt in re/tour/<name>/.
//   node tools/dev/play-tour.js <name> "<javascript that opens the screen>" [--deep] [--port=9811] [--skip=name,name]
//   e.g. node tools/dev/play-tour.js orgmain "HB.game.changeToActivitySubMenu('ShowOrgMainView')" --deep
// Buttons that pay or leave for good can be left out with --skip (button names or titles). The bottom bar is never pressed.
const fs = require('fs');
const { connect, wait } = require('./play.js');
const args = process.argv.slice(2), flags = args.filter((a) => a.startsWith('--')), [name, open] = args.filter((a) => !a.startsWith('--'));
const opt = (k, d) => (flags.find((a) => a.startsWith('--' + k + '=')) || '--' + k + '=' + d).slice(k.length + 3);
const DEEP = flags.includes('--deep'), port = Number(opt('port', 9811)), SKIP = new Set(opt('skip', '').split(',').filter(Boolean));
const BAR = /^btn_main(package|store|fight|round|group|page)$|^ctrl_btnplayermsg$/;
const LOOK = `(() => JSON.stringify({ zh: HB.texts ? HB.texts.report() : [], fit: HB.fit ? HB.fit.report().map((f) => f[0] + ' ' + f[1] + '%') : [] }))()`;
(async () => {
  const c = await connect(port), out = 're/tour/' + name, lines = [];
  fs.mkdirSync(out, { recursive: true });
  const home = async () => { await c.home(); };
  const reopen = async () => { await home(); await c.ev(`(async () => { try { await Promise.race([${open}, new Promise((r) => setTimeout(r, 4000))]); } catch (e) { console.error('JS ' + (e && e.stack || e)); } })()`); await wait(1800); await c.log(); };
  const sig = async () => { const u = await c.ui(); return JSON.stringify([u.btns.map((b) => b.name + b.title + b.top), u.texts.filter((t) => !/^\d[\d:\/ ]*$/.test(t.t) && t.y > 60).map((t) => t.t)]); };
  const note = async (file, how) => { await c.shot(`${out}/${file}.png`); const look = JSON.parse((await c.ev(LOOK)) || '{}'), log = await c.log();
    const errs = [...log.err, ...log.lua.map((e) => 'LUA ' + String(e).slice(0, 300))];
    const l = file + '  (' + how + ')' + (look.zh.length ? '\n   Chinese: ' + look.zh.join(' | ') : '') + (look.fit.length ? '\n   shrunk: ' + look.fit.join(' | ') : '') + (errs.length ? '\n   ' + [...new Set(errs)].slice(0, 4).join('\n   ') : '');
    console.log(l); lines.push(l); };
  const usable = (u) => u.btns.filter((b) => b.on && !BAR.test(b.name) && !SKIP.has(b.name) && !SKIP.has(b.title));
  await reopen();
  const base = await sig(); await note('0', 'the screen');
  const first = usable(await c.ui()), seen = new Set([base]);
  for (let i = 0; i < first.length && i < 40; i++) {
    if (i) await reopen();
    const u = usable(await c.ui()), b = u[i]; if (!b) continue;
    await c.click(b.x, b.y); await wait(1500);
    const s = await sig(); if (seen.has(s)) { await c.log(); continue; } seen.add(s);
    const tag = (i + 1) + '-' + (b.name || b.title || 'button').replace(/[^A-Za-z0-9_]+/g, '_').slice(0, 30);
    await note(tag, 'after ' + (b.name || b.title) + ' @' + b.x + ',' + b.y);
    if (!DEEP || /back|return/i.test(b.name + ' ' + b.title)) continue; // Back leads to another screen: not this screen's windows
    // one level deeper: the buttons of what just opened (only those that were not there before)
    const before = new Set(u.map((x) => x.name + '|' + x.title + '|' + x.x + ',' + x.y));
    const inner = usable(await c.ui()).filter((x) => !before.has(x.name + '|' + x.title + '|' + x.x + ',' + x.y));
    for (let j = 0; j < inner.length && j < 14; j++) {
      const t = inner[j]; if (/close/i.test(t.name) && j) continue;
      await reopen(); const u2 = usable(await c.ui()), b2 = u2[i]; if (!b2) break;
      await c.click(b2.x, b2.y); await wait(1500);
      await c.click(t.x, t.y); await wait(1500);
      const s2 = await sig(); if (seen.has(s2)) { await c.log(); continue; } seen.add(s2);
      await note(tag + '--' + (j + 1) + '-' + (t.name || t.title || 'button').replace(/[^A-Za-z0-9_]+/g, '_').slice(0, 30), 'then ' + (t.name || t.title) + ' @' + t.x + ',' + t.y);
    }
  }
  await home();
  fs.writeFileSync(out + '/report.txt', lines.join('\n') + '\n');
  c.close(); process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
