// Opens a list of script screens in the browser of tools/dev/play.js one after another and, on each, taps the first button that
// looks like the screen's own action (name or title with claim / get / receive / buy / recv / award ...), then prints the request
// it sent and what showed. A quick "does one action work" pass over many events.
//   node tools/dev/play-first.js <script or sub:Function> [more ...] [--port=9811] [--match=regex of button name / title]
const { connect, wait } = require('./play.js');
const args = process.argv.slice(2), list = args.filter((a) => !a.startsWith('--'));
const opt = (k, d) => (args.find((a) => a.startsWith('--' + k + '=')) || '--' + k + '=' + d).slice(k.length + 3);
const RE = new RegExp(opt('match', 'claim|get|receive|recv|award|buy|purchase|exchange|recharge_get|btn_ok'), 'i'), NOT = /main(package|store|fight|round|group|page)|playermsg|btn_left|btn_right|back|close|detail|readme|item_\d|icon/i;
const QUIET = /rl_r_mainpage|rl_r_shoplist|rl_r_trackpoint|rl_r_paypack|rl_r_activity |rl_r_msg|rl_x_custom|purplename/;
(async () => {
  const c = await connect(Number(opt('port', 9811)));
  for (const s of list) {
    await c.home();
    const js = s.startsWith('sub:') ? `HB.game.changeToActivitySubMenu(${JSON.stringify(s.slice(4))})` : s.startsWith('run:') ? `HB.luaRun(${JSON.stringify(s.slice(4) + '.lua')})` : `HB.game.changeToActivity(${JSON.stringify(s)})`;
    await c.ev(`(async () => { try { await Promise.race([${js}, new Promise((r) => setTimeout(r, 4000))]); } catch (e) { console.error('JS ' + (e && e.stack || e)); } })()`);
    await wait(1800);
    const open = await c.log();
    const u = await c.ui(), b = u.btns.find((x) => x.on && RE.test(x.name + ' ' + x.title) && !NOT.test(x.name));
    console.log('== ' + s + (open.lua.length || open.err.length ? '   OPEN ERROR ' + [...open.lua, ...open.err].join(' | ').slice(0, 300) : ''));
    console.log('   buttons: ' + u.btns.filter((x) => !NOT.test(x.name)).map((x) => (x.name || '?') + (x.title ? '"' + x.title + '"' : '') + (x.on ? '' : '(off)')).slice(0, 14).join(' '));
    if (!b) { console.log('   no action button found'); continue; }
    await c.click(b.x, b.y); await wait(1800);
    const l = await c.log(), after = await c.ui();
    const top = Math.max(...after.texts.map((t) => t.top), 0);
    console.log('   tapped ' + (b.name || b.title) + ' "' + b.title + '"');
    l.net.filter((n) => !QUIET.test(n)).forEach((n) => console.log('   > ' + n.slice(0, 260)));
    [...l.err, ...l.lua].slice(0, 3).forEach((e) => console.log('   ERR ' + String(e).slice(0, 300)));
    if (top >= 500) console.log('   shows: ' + after.texts.filter((t) => t.top === top).map((t) => t.t).slice(0, 6).join(' | '));
  }
  await c.home(); c.close(); process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
