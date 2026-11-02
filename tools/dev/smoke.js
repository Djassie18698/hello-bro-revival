// Calls every handler with a fake player on a throwaway DB and reports crashes / non-XML replies.
// It also tries every Cmd number the game's Lua scripts use for that endpoint (when reference/lua-scripts exists).
// Usage: node tools/dev/smoke.js     (does not touch hellobro.db)
const os = require('os'), path = require('path'), fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const tmp = path.join(os.tmpdir(), 'hb-smoke-' + process.pid + '.db');
const db = new DatabaseSync(tmp);
require('../../schema')(db);
const handlers = require('../../handlers');
const base = { Uid: '77', Session: 'smoke', ServerID: '1', GroupID: '2' };

// endpoint -> Set of Cmd numbers, scraped from GetUrlNormalHeader(uid, CMD, "endpoint") calls (CMD may be a protocol.lua constant).
const cmds = {};
const lua = path.join(__dirname, '..', '..', 'reference', 'lua-scripts');
if (fs.existsSync(lua)) {
  const consts = {};
  const proto = path.join(lua, 'util', 'protocol.lua');
  if (fs.existsSync(proto)) for (const m of fs.readFileSync(proto, 'utf8').matchAll(/^\s*([A-Za-z_0-9]+)\s*=\s*(\d+)/gm)) consts[m[1]] = Number(m[2]);
  const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.lua') ? [path.join(d, e.name)] : []);
  const urlConst = {};
  for (const m of fs.readFileSync(proto, 'utf8').matchAll(/^\s*(URL_[A-Z_0-9]+)\s*=\s*"([a-z_0-9]+)"/gm)) urlConst[m[1]] = m[2];
  for (const f of walk(lua)) {
    for (const m of fs.readFileSync(f, 'utf8').matchAll(/GetUrlNormalHeader\([^,]*,\s*([A-Za-z_.0-9]+)\s*,\s*("?)([A-Za-z_.0-9]+)\2\s*\)/g)) {
      const cmd = /^\d+$/.test(m[1]) ? Number(m[1]) : consts[m[1].replace(/^protocol\./, '')];
      const ep = m[2] ? m[3] : urlConst[m[3].replace(/^protocol\./, '')];
      if (ep && cmd !== undefined) (cmds[ep] = cmds[ep] || new Set()).add(cmd);
    }
  }
}
let bad = 0, calls = 0;
const run = (name, cmd, extra = {}) => {
  calls++;
  try {
    const out = handlers[name]({ db, params: { ...base, Cmd: cmd, SignId: 1, GiftId: 1, Goodsid: 1, Count: 1, Type: 2, ...extra }, host: 'localhost:18080', method: 'POST', body: '' });
    const s = typeof out === 'string' ? out : JSON.stringify(out);
    if (!/^<root|^<\?xml/.test(String(s).trim())) { bad++; console.log('NON-XML', name, cmd, String(s).slice(0, 80)); }
  } catch (e) { bad++; console.log('CRASH  ', name, cmd, e.message); }
};
run('rl_w_login2', 0); run('rl_w_reg2', 0, { Nick: 'Smoke', Card: 1 });
for (const name of Object.keys(handlers)) for (const c of new Set([0, ...(cmds[name] || [])])) run(name, c);
// Limited Super Ninja (limitsuper.js): open, gold pulls through the pray dialog, free pull, refresh, the round's prizes in the Awards chest.
{
  const ck = (ok, what) => { if (!ok) { bad++; console.log('SUPER NINJA', what); } };
  const call = (name, extra) => handlers[name]({ db, params: { ...base, ...extra } });
  const gold = () => db.prepare('SELECT gold FROM players WHERE uid=77').get().gold;
  const cards = () => db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77').get().n;
  db.prepare('UPDATE players SET gold=10000 WHERE uid=77').run();
  call('rl_r_mainpage', { Cmd: 1301 });
  db.exec('DELETE FROM superninja; DELETE FROM superninja_me'); // the calls above already pulled (Cmd 1902 is in the Lua)
  const info = call('rl_r_comm', { Cmd: 6 });
  for (const t of ['resttime=', 'nexttime=', 'protect=', 'gold="300"', 'actstatus="1"', 'limitscore=', '<ninjalist><item name=', 'ninjiaid=', 'dropid=', '<myrank', '<rewardlist><item rankrange=']) ck(info.includes(t), 'open misses ' + t);
  ck(/protect_comming="11"/.test(call('rl_r_recruit', { Cmd: 2900, Type: 1 })), 'pray dialog count is not the event count');
  let g = gold(), c = cards();
  const one = call('rl_w_recruit', { Cmd: 1900, Type: 1, Free: 0, TwoStars: 0, IsSuperAct: 0 });
  ck(/<recruit ninjaid="\d+" cost="300"/.test(one) && /<award/.test(one) && gold() === g - 300 && cards() === c + 1, 'one pull: ' + one.slice(0, 120));
  g = gold(); c = cards();
  const ten = call('rl_w_recruit', { Cmd: 1901, Type: 1, Free: 0, IsSuperAct: 0 });
  ck((ten.match(/<item><award/g) || []).length === 10 && gold() === g - 2800 && cards() === c + 10, 'ten pull: ' + ten.slice(0, 120));
  const free = call('rl_w_recruit', { Cmd: 1902, Type: 1, Free: 1 });
  ck(/<award/.test(free) && gold() === g - 2800, 'free pull: ' + free.slice(0, 120));
  ck(/code="80003"/.test(call('rl_w_recruit', { Cmd: 1902, Type: 1, Free: 1 })), 'second free pull was not refused');
  const ref = call('rl_r_comm', { Cmd: 7 });
  ck(/rank="1" score="120"/.test(ref) && /<ranklist><item rank="1" nick="[^"]*" score="120"\/>/.test(ref), 'refresh: ' + ref.slice(0, 200));
  // back Home: the premium recruit is a normal recruit again (no event points)
  call('rl_r_mainpage', { Cmd: 1301 });
  call('rl_w_recruit', { Cmd: 1900, Type: 1, Free: 0 });
  ck(db.prepare('SELECT score FROM superninja WHERE uid=77').get().score === 120, 'a normal recruit after leaving counted for the event');
  // the hour ends: prizes are mailed once; 1st place (120 points, the minimum is 50) wins that hour's god card
  db.prepare('UPDATE superninja SET round=round-1').run();
  const ls = require('../../limitsuper'), round = db.prepare('SELECT round FROM superninja WHERE uid=77').get().round;
  const god = ls.godList()[round % ls.godList().length];
  ls.settle(db); ls.settle(db);
  const mail = db.prepare("SELECT content, items FROM award_mail WHERE uid=77 AND title='Limited Super Ninja'").all();
  ck(mail.length === 1 && /#1 with 120 points/.test(mail[0].content) && mail[0].items.includes(`"dropid":${god.drop}`), 'round prize mail: ' + JSON.stringify(mail));
}
// Ninja Treasure (sudoku.js): the top list is the 16 original prizes, every board hides exactly one of them, buying the board gives it.
{
  const sudoku = require('../../sudoku');
  const pl = db.prepare('SELECT * FROM players WHERE uid=77').get();
  db.prepare('UPDATE players SET gold=100000 WHERE uid=77').run();
  const top = (sudoku.topXml().match(/<item /g) || []).length;
  if (top !== 16) { bad++; console.log('NINJA TREASURE top list has', top, 'prizes'); }
  for (let i = 0; i < 20; i++) {
    const ids = [...sudoku.refresh(db, pl).xml.matchAll(/drop_id="(\d+)"/g)].map((m) => Number(m[1]));
    const tops = ids.filter((id) => sudoku.TOP.includes(id)).length;
    if (ids.length !== 9 || tops !== 1) { bad++; console.log('NINJA TREASURE board', ids, 'has', tops, 'top prizes'); break; }
  }
  const before = db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77').get().n;
  const all = sudoku.buyAll(db, pl);
  if (all.error || db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77').get().n <= before) { bad++; console.log('NINJA TREASURE buy all gave no card', all.error || ''); }
}
// Arena daily reward: a ladder place 1-1000 also pays its ladder pack (rank 1 = pack 159: gear, a full seal or 300 gold); no place, no pack.
{
  const claim = () => handlers.rl_x_sport_ext({ db, params: { ...base, Cmd: 3 } });
  require('../../game').arenaEnsure(db);
  db.exec("DELETE FROM rank_claims WHERE board='arena'"); db.prepare('DELETE FROM arena WHERE uid=77').run();
  const none = claim();
  if (/dropid="16\d"/.test(none)) { bad++; console.log('ARENA ladder pack paid without a ladder place:', none.slice(0, 100)); }
  db.exec("DELETE FROM rank_claims WHERE board='arena'"); db.prepare('DELETE FROM arena WHERE rank=1').run(); db.prepare('INSERT INTO arena(rank, uid) VALUES(1, 77)').run();
  const top = claim();
  if (!/<award dropid="159"/.test(top) || !/<coin>25000<\/coin>/.test(top) || !(/<card>/.test(top) || /<cash>300<\/cash>/.test(top))) { bad++; console.log('ARENA rank 1 claim:', top.slice(0, 200)); }
  if (!/code="5"/.test(claim())) { bad++; console.log('ARENA second claim the same day was paid'); }
}
// The login data: every card must carry all the fields the client reads (a missing one crashes the game at login).
{
  const home = handlers.rl_r_mainpage({ db, params: { ...base, Cmd: 1302 } });
  const cards = home.match(/<card>.*?<\/card>/g) || [];
  for (const f of ['type', 'id', 'seq', 'level', 'attri', 'starlevel', 'newlife']) {
    const miss = cards.filter((c) => !c.includes(`<${f}>`)).length;
    if (!cards.length || miss) { bad++; console.log('LOGIN DATA', cards.length ? `${miss} card(s) without <${f}>` : 'no cards'); break; }
  }
}
try { db.close(); fs.rmSync(tmp, { force: true }); } catch {}
console.log(bad ? bad + ' problem(s)' : `all ${Object.keys(handlers).length} handlers OK (${calls} calls)`);
process.exit(bad ? 1 : 0);
