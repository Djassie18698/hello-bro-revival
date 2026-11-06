// Calls every handler with a fake player on a throwaway DB and reports crashes / non-XML replies.
// It also tries every Cmd number the game's Lua scripts use for that endpoint (when reference/lua-scripts exists).
// Usage: node tools/dev/smoke.js     (does not touch hellobro.db)
const os = require('os'), path = require('path'), fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const tmp = path.join(os.tmpdir(), 'hb-smoke-' + process.pid + '.db');
const db = new DatabaseSync(tmp);
require('../../server/schema')(db);
const handlers = require('../../server/handlers');
const base = { Uid: '77', Session: 'smoke', ServerID: '1', GroupID: '2' };

// endpoint -> Set of Cmd numbers, scraped from GetUrlNormalHeader(uid, CMD, "endpoint") calls (CMD may be a protocol.lua constant).
const cmds = {};
const lua = path.join(__dirname, '..', '..', 'server', 'reference', 'lua-scripts');
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
  const ls = require('../../server/limitsuper'), round = db.prepare('SELECT round FROM superninja WHERE uid=77').get().round;
  const god = ls.godList()[round % ls.godList().length];
  // opening the Awards chest (not the event screen) delivers them, once
  const chest = call('rl_x_award_msg', { Cmd: 1 }); call('rl_x_award_msg', { Cmd: 1 });
  const mail = db.prepare("SELECT content, items FROM award_mail WHERE uid=77 AND title='Limited Super Ninja'").all();
  ck(mail.length === 1 && /#1 with 120 points/.test(mail[0].content) && mail[0].items.includes(`"dropid":${god.drop}`), 'round prize mail: ' + JSON.stringify(mail));
  ck(chest.includes('<title>Limited Super Ninja</title>'), 'the Awards chest did not show the prize: ' + chest.slice(0, 200));
  // 6 Nov 2026: a control-panel mail with an empty Message box crashed the game on opening the Awards chest
  // (ui_awardCenterCell.lua setString(find("content")[1]) = nil). Old empty rows too: never an empty <title>/<content>.
  const ac = require('../../server/awardcenter');
  ac.send(db, { uid: 77, server_id: 1 }, 'W', '', { silver: 3 });
  db.prepare("INSERT INTO award_mail(uid, server_id, ts, title, content, items) VALUES(77, 1, strftime('%s','now'), '', '', '[{\"type\":2,\"dropid\":5}]')").run();
  const list = call('rl_x_award_msg', { Cmd: 1 });
  ck(!/<title><\/title>|<content><\/content>/.test(list), 'Awards chest sent an empty title or content: ' + list.slice(0, 300));
  ck(/error/.test(JSON.stringify(ac.send(db, { uid: 77, server_id: 1 }, 'x', 'y', { gold: 7 }))), 'gold 7 (no such gold pack) was not refused');
  ck(ac.send(db, { uid: 77, server_id: 1 }, 'x', 'y', { gold: 5 }).sent === 1, 'gold 5 (the Gold*5 pack) was refused');
}
// Discord report 3 Nov 2026: seals with several stats, set tiers adding up, the war exploit shop's balance.
{
  const ck = (ok, what) => { if (!ok) { bad++; console.log('DISCORD 3 NOV', what); } }, game = require('../../server/game');
  const b = { al: 1000, ah: 1000, dl: 1000, dh: 1000, cl: 1000, ch: 1000 };
  const seal = (name) => game.sealBonus(b, game.table('markinfo').rows.find((r) => r[2] === name)[0]);
  const s = seal('Saiken Seal'), t = seal('Ten-Tails Seal');
  ck(s.al === 1400 && s.dl === 1400 && s.cl === 1000, 'Saiken (DEF and ATK +40%): ' + JSON.stringify(s));
  ck(t.al > 1800 && t.dl === 1800 && t.cl === 1800, 'Ten-Tails (DEF ATK Cha +80%): ' + JSON.stringify(t));
  // game.table() keeps tables in memory: re-reading the file on every call froze the cloud server for 10 minutes on "Best gear"
  ck(game.table('ninjutsuinfo') === game.table('ninjutsuinfo'), 'game.table() reads the file again on every call');
  const armed = game.table('skill_suit_info').rows.find((r) => r[2] === 'Armed');
  const at = [2, 3, 4].map((num) => game.setBonus(b, [{ row: armed, num }]).al);
  ck(at.join() === '1150,1300,1450', 'Armed set 2/3/4 pieces: ' + at.join());
  game.propAdd(db, 77, 1, 9994, 1234 - (game.propCounts(db, 77, 1)[9994] || 0));
  const shop = handlers.rl_r_warnew({ db, params: { ...base, Cmd: 225 } });
  ck(shop.includes('<curpower>1234</curpower>'), 'exploit shop balance: ' + shop.slice(0, 120));
  // fights: the skill cut-in finds its ninja by AttackNinja = a <ninja><id> of my list; a master pet claws (AttPetSkillHurt) now and then
  {
    const pet = require('../../server/pet'), pl77 = db.prepare('SELECT * FROM players WHERE uid=77').get();
    const fx = game.battleXml(db, pl77, 1, 6, {});
    const ids = [...fx.matchAll(/<killer><ninjalist>(.*?)<\/ninjalist>/g)].flatMap((m) => [...m[1].matchAll(/<ninja><id>(\d+)<\/id>/g)].map((x) => x[1]));
    const atk = [...fx.matchAll(/<AttackNinja>(\d+)<\/AttackNinja>/g)].map((m) => m[1]);
    ck(atk.length && atk.every((a) => ids.includes(a)), `AttackNinja ${atk.join()} is not a ninja id of my list ${ids.join()}`);
    pet.addPet(db, 77, 1, 1);
    let claws = 0;
    for (let k = 0; k < 60; k++) if (/<AttPetSkillHurt>[1-9]/.test(game.battleXml(db, pl77, 1, 6, {}))) claws++;
    ck(claws > 0 && claws < 60, `master pet clawed in ${claws} of 60 fights`);
    // with every ninjutsu firing (HB_SKILLS) the claw moves to a hit without one instead of being lost (Discord report 4 Nov 2026)
    process.env.HB_SKILLS = '1';
    let late = 0, both = 0;
    for (let k = 0; k < 20; k++) {
      for (const r of game.battleXml(db, pl77, 1, 6, {}).match(/<round>.*?<\/round>/g) || []) {
        const claw = /<AttPetSkillHurt>[1-9]/.test(r), jutsu = /<skill>/.test(r);
        if (claw && jutsu) both++; else if (claw) late++;
      }
    }
    delete process.env.HB_SKILLS;
    ck(both === 0, `the pet clawed in ${both} rounds that also fired a ninjutsu (the client then drops the cut-in)`);
    db.prepare('DELETE FROM pets WHERE uid=77').run();
    // elements (CRoundTeamFightView::initLimitData): CauseLimit 1 = the attacker's element beats the defender's (their defence -LimitVal),
    // -1 = the defender's beats the attacker's (my attack -LimitVal). Water(1) > Fire(2) > Wind(3) > Thunder(5) > Earth(4) > Water.
    const beats = { 1: 2, 2: 3, 3: 5, 5: 4, 4: 1 };
    let seen = 0;
    for (let k = 0; k < 40; k++) {
      for (const r of game.battleXml(db, pl77, 1, 6, {}).match(/<round>.*?<\/round>/g) || []) {
        const g = (t) => Number((new RegExp(`<${t}>(-?\\d+)</${t}>`).exec(r) || [])[1]);
        const c = g('CauseLimit'), aa = g('AttackAttri'), da = g('DefenseAttri');
        if (c === 1) { seen++; ck(beats[aa] === da && g('FinalDefense') === g('Defense') - g('LimitVal'), `CauseLimit 1 but ${aa} vs ${da}: ${r.slice(0, 300)}`); }
        if (c === -1) { seen++; ck(beats[da] === aa, `CauseLimit -1 but ${aa} vs ${da}`); }
        if (c === 0) ck(beats[aa] !== da && beats[da] !== aa, `no restrain sent for ${aa} vs ${da}`);
      }
    }
    ck(seen > 0, 'no element restrain in 40 fights');
  }
  // the spar list shows a real rival's real team attack, not a value made from the level (Serii 4220 instead of 7M, 3 Nov 2026)
  {
    const other = db.prepare('SELECT * FROM players WHERE uid!=77 AND server_id=1 LIMIT 1').get();
    if (other) {
      const want = game.teamStats(db, other.uid, 1).total;
      const m = new RegExp(`<id>${other.uid}</id>.*?<attacklow>(\\d+)</attacklow><attackhigh>(\\d+)</attackhigh>`).exec(game.rivalsXml(db, db.prepare('SELECT * FROM players WHERE uid=77').get()));
      ck(m && Number(m[1]) === want.al && Number(m[2]) === want.ah, `spar list attack of ${other.nick}: ${m && m[1]}-${m && m[2]}, team ${want.al}-${want.ah}`);
    }
    // an old-login account (uid 22 000 000+) is a real player too, not a bot (it showed the bot's 32-52, 5 Nov 2026)
    const q = { ...base, Uid: '22000123', Session: 's22000123' };
    handlers.rl_w_login2({ db, params: { ...q, Cmd: 0 } });
    handlers.rl_w_reg2({ db, params: { ...q, Cmd: 0, Nick: 'OldUid', Card: 55 } });
    db.prepare('UPDATE players SET level=(SELECT level FROM players WHERE uid=77 AND server_id=1) WHERE uid=22000123').run();
    const want2 = game.teamStats(db, 22000123, 1).total;
    const xml2 = game.rivalsXml(db, db.prepare('SELECT * FROM players WHERE uid=77').get());
    const m2 = /<id>22000123<\/id>.*?<attacklow>(\d+)<\/attacklow><attackhigh>(\d+)<\/attackhigh>/.exec(xml2);
    ck(!m2 || (Number(m2[1]) === want2.al && Number(m2[2]) === want2.ah), `spar list attack of an old-uid player: ${m2 && m2[1]}-${m2 && m2[2]}, team ${want2.al}-${want2.ah}`);
    ck(!!m2, 'old-uid player not in the spar list');
  }
  // a won story stage must not show the part's boss tries as 0 (chapter 1 part 2 = stages 3-6, boss = 6)
  db.prepare('DELETE FROM stage_clears WHERE uid=77 AND chap=1').run();
  game.setStage(db, 77, 1, 1, 3); db.prepare('UPDATE players SET energy=500 WHERE uid=77').run();
  const story = handlers.rl_w_pve({ db, params: { ...base, Cmd: 3, ChapID: 1, StageID: 2, Pos: 1 } });
  ck(/pk_boss_times="3"/.test(story), 'boss tries after a story stage: ' + (/<pve [^>]*>/.exec(story) || [story.slice(0, 200)])[0]);
  const list = handlers.rl_w_pve({ db, params: { ...base, Cmd: 2, ChapID: 1 } });
  ck(!/stageid="2"[^>]*pk_boss_times="0"/.test(list), 'chapter list boss tries: ' + list.slice(0, 300));
}
// Ninja Treasure (sudoku.js): the top list is the 16 original prizes, every board hides exactly one of them, buying the board gives it.
{
  const sudoku = require('../../server/sudoku');
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
  require('../../server/game').arenaEnsure(db);
  db.exec("DELETE FROM rank_claims WHERE board='arena'"); db.prepare('DELETE FROM arena WHERE uid=77').run();
  const none = claim();
  if (/dropid="16\d"/.test(none)) { bad++; console.log('ARENA ladder pack paid without a ladder place:', none.slice(0, 100)); }
  db.exec("DELETE FROM rank_claims WHERE board='arena'"); db.prepare('DELETE FROM arena WHERE rank=1').run(); db.prepare('INSERT INTO arena(rank, uid) VALUES(1, 77)').run();
  // the Compete list carries the player's own row (<host>1) with the claim button: no countdown, dayrewardstat 0 before / 1 after the claim
  const pl77 = db.prepare('SELECT * FROM players WHERE uid=77').get(), list = () => require('../../server/game').arenaListXml(db, pl77);
  if (!/<host>1<\/host>/.test(list()) || !/<rewardtimeleft>0<\/rewardtimeleft>/.test(list()) || !/<dayrewardstat>0</.test(list())) { bad++; console.log('ARENA list has no claimable own row'); }
  const top = claim();
  if (!/<dayrewardstat>1</.test(list())) { bad++; console.log('ARENA list does not show the claim as done'); }
  if (!/<award dropid="159"/.test(top) || !/<coin>25000<\/coin>/.test(top) || !(/<card>/.test(top) || /<cash>300<\/cash>/.test(top))) { bad++; console.log('ARENA rank 1 claim:', top.slice(0, 200)); }
  if (!/code="5"/.test(claim())) { bad++; console.log('ARENA second claim the same day was paid'); }
}
// Create screen: the game sends the chosen ninja's own id (Neji 55 / Sakura 56 / Shikamaru 57); the new player starts with that one.
for (const pick of [55, 56, 57]) {
  const uid = 900 + pick, p = { ...base, Uid: String(uid), Session: 's' + uid };
  handlers.rl_w_login2({ db, params: { ...p, Cmd: 0 } });
  handlers.rl_w_reg2({ db, params: { ...p, Cmd: 0, Nick: 'Pick' + pick, Card: pick } });
  const got = db.prepare('SELECT c.ninja_id FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.slot=0').get(uid);
  if (!got || got.ninja_id !== pick) { bad++; console.log('STARTER pick', pick, 'gave', got && got.ninja_id); }
}
// Starter gift: after a level-up (Cmd 3) <on_off>1 also opens the gift, so only while it is unclaimed.
{
  const lv = () => handlers.rl_r_newbie_pay({ db, params: { ...base, Cmd: 3 } });
  db.prepare('DELETE FROM stagegift WHERE uid=77').run();
  const before = lv();
  handlers.rl_r_newbie_pay({ db, params: { ...base, Cmd: 2 } });
  if (!/<on_off>1</.test(before) || /<on_off>1</.test(lv())) { bad++; console.log('STARTER GIFT level-up popup', before.slice(0, 60), lv().slice(0, 60)); }
}
// Tutorial OFF (owner 5 Nov 2026: "leave it off"). The app starts its guide by itself for every part in home/userguideConfig.xml that the
// phone has not finished (first_login only decides an ad), so the hot update must keep every part at level 900+ (unreachable). Nothing on
// the server may turn the tutorial helpers on, not even an old saved 'tutorial' switch.
{
  const S = require('../../server/settings');
  const cfg = require('fs').readFileSync(require('path').join(__dirname, '../../server/cdn/src/home/userguideConfig.xml'), 'utf8');
  const lv = [...cfg.matchAll(/<steplevel No="(\d+)"/g)].map((m) => Number(m[1]));
  if (!lv.length || lv.some((n) => n < 900)) { bad++; console.log('TUTORIAL reachable in the hot update', lv.join(',')); }
  S.setEvent(db, 'tutorial', true);
  const fl = (x) => Number((String(x).match(/<first_login>(\d)</) || [])[1]);
  const p = { ...base, Uid: '952', Session: 's952' };
  handlers.rl_w_login2({ db, params: { ...p, Cmd: 0 } });
  const reg = handlers.rl_w_reg2({ db, params: { ...p, Cmd: 0, Nick: 'Tut952', Card: 55 } });
  db.prepare('UPDATE players SET level=5 WHERE uid=952').run();
  const gift = handlers.rl_r_newbie_pay({ db, params: { ...p, Cmd: 3 } });
  if (fl(reg) !== 0 || fl(handlers.rl_w_login2({ db, params: { ...p, Cmd: 0 } })) !== 0 || !/<on_off>1</.test(gift)) { bad++; console.log('TUTORIAL helpers still on', reg.slice(0, 80), gift.slice(0, 80)); }
  S.setEvent(db, 'tutorial', false);
}
// Seal synthesis (original flow, CMarkCardView): Claim starts it (fragments used, ready after 1800 s), Synthesis pays 30 gold to finish now
// (reply message="usecash": the app then fetches), Cmd 2801 takes the seal. Every reply has the message attribute (a missing one crashed).
{
  const seals = require('../../server/seals'), pl = () => db.prepare('SELECT * FROM players WHERE uid=77').get();
  db.prepare('UPDATE players SET gold=100 WHERE uid=77').run();
  for (const f of [11, 12, 13, 14, 15, 16]) db.prepare('INSERT INTO props(uid,server_id,prop_id,count) VALUES(77,1,?,1) ON CONFLICT(uid,server_id,prop_id) DO UPDATE SET count=1').run(seals.FRAG + f);
  const w = (cmd, extra = {}) => handlers.rl_w_markchip({ db, params: { ...base, Cmd: cmd, MarkID: 1, ...extra } });
  const list0 = handlers.rl_r_markchip({ db, params: { ...base, Cmd: 1600 } });
  const start = w(2800), list1 = handlers.rl_r_markchip({ db, params: { ...base, Cmd: 1600 } });
  const early = w(2801), pay = w(2800, { UseCash: 1 }), gold = pl().gold, got = w(2801);
  const ok = !/<mark>/.test(list0) && /<cash>30</.test(list0) && /message="started"/.test(start) && /<mark><id>1<\/id><resttime>1[78]\d\d</.test(list1) &&
    /code="5"/.test(early) && /message="usecash"/.test(pay) && gold === 70 && /<markchip bagid="\d+"/.test(got) &&
    db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77 AND type=5 AND ninja_id=1').get().n >= 1 && !(seals.FRAG + 11 in require('../../server/game').propCounts(db, 77, 1) && require('../../server/game').propCounts(db, 77, 1)[seals.FRAG + 11] > 0);
  if (!ok) { bad++; console.log('SEAL SYNTHESIS', JSON.stringify({ list0: list0.slice(0, 40), start, list1: (list1.match(/<markmerge>.*<\/markmerge>/) || [''])[0], early, pay, gold, got })); }
}
// Arena: a gap in the ranks (a player wiped by the admin reset) must not stop the next newcomer from joining (was UNIQUE constraint failed).
{
  const g = require('../../server/game');
  g.arenaEnsure(db);
  const top = db.prepare('SELECT MAX(rank) m FROM arena').get().m;
  for (const [k, u] of [[1, 951], [2, 952]]) db.prepare('INSERT OR IGNORE INTO arena(rank,uid) VALUES(?,?)').run(top + k, u);
  db.prepare('DELETE FROM arena WHERE uid=951').run(); // what the admin reset of player 951 does
  const out = '';
  const p953 = { ...base, Uid: '953', Session: 's953' };
  handlers.rl_w_login2({ db, params: { ...p953, Cmd: 0 } }); handlers.rl_w_reg2({ db, params: { ...p953, Cmd: 0, Nick: 'Arena953', Card: 55 } });
  const joined = handlers.rl_r_sport({ db, params: { ...p953, Cmd: 8100 } });
  if (!/^<root code="0"><sport>/.test(joined)) { bad++; console.log('ARENA join after a gap', out.slice(0, 60), joined.slice(0, 80)); }
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
// Account window on Android 14+ (the app targets Android 7, so the phone ID is hidden): PLAY sends deviceId="" and must still make a
// guest, and the kept password must log that same guest in again.
(async () => {
  const gump = require('../../server/gumplogin');
  const call = async (url, form) => {
    let out = '';
    await gump.handle({ method: 'POST', url }, { writeHead() {}, end(s) { out = s; } }, async () => new URLSearchParams(form).toString(), db);
    return JSON.parse(out);
  };
  const reg = await call('/quick/reg.do', { deviceId: '', appId: '10015' });
  const again = reg.passwd && await call('/quick/login.do', { deviceId: '', appId: '10015', passwd: reg.passwd });
  const wrong = await call('/quick/login.do', { deviceId: '', appId: '10015', passwd: 'nope' });
  if (reg.code !== 100000 || !again || again.code !== 100000 || again.userId !== reg.userId || wrong.code === 100000) {
    bad++; console.log('LOGIN without a phone ID:', JSON.stringify({ reg: reg.code, again: again && again.code, wrong: wrong.code }));
  }
  // signing up on a phone without an ID names the guest that just played from the same internet address (owner's tablet, 3 Nov 2026)
  {
    const callIp = async (url, form, ip) => {
      let out = '';
      await gump.handle({ method: 'POST', url, socket: { remoteAddress: ip } }, { writeHead() {}, end(s) { out = s; } }, async () => new URLSearchParams(form).toString(), db);
      return JSON.parse(out);
    };
    const g = await callIp('/quick/reg.do', { deviceId: '', appId: '10015' }, '10.9.9.1');
    const same = await callIp('/gump/reg.do', { deviceId: '', appId: '10015', email: 'smokelink', passwd: 'pass1234' }, '10.9.9.1');
    const other = await callIp('/gump/reg.do', { deviceId: '', appId: '10015', email: 'smokelink2', passwd: 'pass1234' }, '10.9.9.2');
    if (same.userId !== g.userId || other.userId === g.userId) { bad++; console.log('SIGN-UP LINK:', JSON.stringify({ guest: g.userId, same: same.userId, other: other.userId })); }
  }
  // ADMIN_OPEN=1 (public server, owner 3 Nov 2026): the item page works without the password; wiping a player and the manager still ask for it
  {
    const admin = require('../../server/admin'), manager = require('../../server/manager');
    const url = require('url');
    let page = '';
    const hit = async (fn, p, method = 'GET') => {
      let status = 200;
      const res = { writeHead(s) { status = s; }, end(s) { page = String(s || ''); }, setHeader() {} };
      await fn({ method, headers: {} }, res, url.parse(p, true), db, async () => JSON.stringify({ player: '77:1' })).catch(() => {});
      return status;
    };
    const keep = { pw: process.env.ADMIN_PASSWORD, open: process.env.ADMIN_OPEN };
    process.env.ADMIN_PASSWORD = 'smoke-secret';
    const shut = await hit(admin, '/admin/api/players');
    process.env.ADMIN_OPEN = '1';
    const r = { players: await hit(admin, '/admin/api/players'), reset: await hit(admin, '/admin/api/reset', 'POST'), manager: await hit(manager, '/manager') };
    if (shut !== 401 || r.players !== 200 || r.reset !== 401 || r.manager !== 401) { bad++; console.log('ADMIN_OPEN:', JSON.stringify({ shut, ...r })); }
    // a player gets the item page alone (the control panel around it polls /manager, which asked for the password) without the Reset tab
    const st = await hit(admin, '/admin');
    if (st !== 200 || page.includes('f-server') || !page.includes('<body class="player">')) { bad++; console.log('ADMIN_OPEN page:', st, page.slice(0, 80)); }
    for (const [k, v] of [['ADMIN_PASSWORD', keep.pw], ['ADMIN_OPEN', keep.open]]) if (v === undefined) delete process.env[k]; else process.env[k] = v;
  }
  // Cards stop at level 50 (the upgrade tables' row count, client IUpgradeable::firefly_GetMaxLevel): the old 99 cap let a weapon reach 51,
  // and reincarnation only lists cards at exactly the top level ("No Lv.50 cards"). Also a card already above it is put back on start.
  {
    const game = require('../../server/game');
    const p77 = db.prepare('SELECT * FROM players WHERE uid=77').get();
    db.prepare('UPDATE players SET level=100, coin=99999999 WHERE uid=77').run();
    const pl = { ...p77, level: 100, coin: 99999999 };
    const w = game.giveCard(db, 77, pl.server_id, 1001, 2);
    db.prepare('UPDATE cards SET level=49 WHERE seq=?').run(w);
    const food = [];
    for (let i = 0; i < 30; i++) { const s = game.giveCard(db, 77, pl.server_id, 1001, 2); db.prepare('UPDATE cards SET level=50 WHERE seq=?').run(s); food.push(s); }
    game.strengthen(db, pl, w, food);
    const lv = db.prepare('SELECT level FROM cards WHERE seq=?').get(w).level;
    const over = game.giveCard(db, 77, pl.server_id, 1001, 2);
    db.prepare('UPDATE cards SET level=51 WHERE seq=?').run(over);
    const { DatabaseSync } = require('node:sqlite');
    const d2 = new DatabaseSync(':memory:'); require('../../server/schema')(d2);
    d2.exec('CREATE TABLE cards (seq INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, server_id INTEGER, type INTEGER, ninja_id INTEGER, level INTEGER NOT NULL DEFAULT 1, exp INTEGER NOT NULL DEFAULT 0, starlevel INTEGER NOT NULL DEFAULT 0)');
    d2.prepare('INSERT INTO cards(uid,server_id,type,ninja_id,level) VALUES(1,1,2,1001,51)').run();
    game.ensure(d2);
    const fixed = d2.prepare('SELECT level FROM cards').get().level;
    if (lv !== 50 || game.cardMaxLevel(1) !== 50 || fixed !== 50) { bad++; console.log('CARD TOP LEVEL:', JSON.stringify({ upgraded: lv, fixedOnStart: fixed })); }
  }
  // Country war log: "you defeated X, get 10 points and N exploit" reads <powernum>; a win gives 10 exploit (was always shown as 0)
  {
    const war = require('../../server/war');
    const pl = db.prepare('SELECT * FROM players WHERE uid=77').get();
    db.prepare("INSERT INTO war_log(server_id,uid,tuid,fromnick,tonick,fromcountry,tocountry,win,score) VALUES(?,?,0,'a','b',1,2,1,10)").run(pl.server_id, pl.uid);
    const x = war.msgXml(db, pl, true);
    if (!/<iswin>1<\/iswin><score>10<\/score><powernum>10<\/powernum>/.test(x)) { bad++; console.log('WAR LOG EXPLOIT:', x.slice(0, 300)); }
    // Country tab "war starts everynight B-E" (seconds of the day): the war is open all day here, so 0:00-24:00 (was 0:00-0:00)
    const ci = require('../../server/country').infoXml(db, pl);
    if (!ci.includes('<timeinfo><begin>0</begin><end>86400</end></timeinfo>')) { bad++; console.log('COUNTRY WAR HOURS:', ci.slice(-80)); }
    // Competing for an official seat costs the original normalconfig 11/12/13 gold (Raikage 20, Custodian 10, Elder 0); it was free
    const country = require('../../server/country');
    const gold = () => db.prepare('SELECT gold FROM players WHERE uid=77').get().gold;
    db.prepare('UPDATE players SET gold=100 WHERE uid=77').run();
    db.prepare('DELETE FROM officials WHERE server_id=? AND country=?').run(pl.server_id, pl.country);
    const fresh = () => db.prepare('SELECT * FROM players WHERE uid=77').get();
    country.take(db, fresh(), 1); const g1 = gold();
    country.take(db, fresh(), 4); const g4 = gold();
    db.prepare('UPDATE players SET gold=5 WHERE uid=77').run();
    db.prepare('DELETE FROM officials WHERE server_id=? AND country=?').run(pl.server_id, pl.country);
    const poor = country.take(db, fresh(), 1);
    if (g1 !== 80 || g4 !== 80 || !poor.error || gold() !== 5 || country.seatCost(2) !== 10) { bad++; console.log('SEAT PRICE:', JSON.stringify({ g1, g4, poor, left: gold() })); }
    // the daily official gift is the game's own pack for the seat (218 Raikage / 219 Custodian / 220 Elder: the text the bag shows)
    const packs = [1, 2, 3, 4, 7].map(country.SALARY_PACK).join(',');
    db.prepare('DELETE FROM officials WHERE server_id=? AND country=?').run(pl.server_id, pl.country);
    db.prepare('UPDATE players SET gold=100 WHERE uid=77').run();
    country.take(db, fresh(), 4);
    const sal = country.salary(db, fresh());
    if (packs !== '218,219,219,220,220' || !sal.xml || !/<award/.test(sal.xml)) { bad++; console.log('OFFICIAL GIFT:', packs, JSON.stringify(sal).slice(0, 200)); }
  }
  // Akatsuki Hall log: the game prints "executed" .. taskname, so the name is " mission A" (was "Task 1" -> "executedTask 1")
  {
    const guild = require('../../server/guild');
    const pl = db.prepare('SELECT * FROM players WHERE uid=77').get();
    db.prepare('UPDATE players SET gold=5000, coin=500000 WHERE uid=77').run();
    if (!guild.myGroup(db, 77, pl.server_id)) guild.create(db, db.prepare('SELECT * FROM players WHERE uid=77').get(), 'SmokeClan', 'x');
    const r = guild.checkin(db, db.prepare('SELECT * FROM players WHERE uid=77').get(), 1);
    if (r.error && !/already/.test(r.error)) { bad++; console.log('HALL CHECKIN:', r.error); }
    else if (r.xml && !r.xml.includes('taskname=" mission A"')) { bad++; console.log('HALL LOG NAME:', r.xml.slice(0, 200)); }
  }
  // story bosses: 5 % their own special reward (the card the boss screen shows; owner 6 Nov 2026). Graduate II = Kakashi Hatake.
  {
    const g = require('../../server/game'), bosses = g.table('roundinfo').rows.filter((r) => r[38]);
    const linked = bosses.filter((r) => g.bossNamedDrop(r)).length;
    if (linked !== bosses.length) { bad++; console.log(`BOSS REWARD: only ${linked} of ${bosses.length} bosses have their special reward`); }
    const pl = db.prepare('SELECT * FROM players WHERE uid=77').get(), before = db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77 AND type=1 AND ninja_id=35').get().n;
    g.grantDrop(db, pl, g.bossNamedDrop(bosses.find((r) => r[0] === 72)));
    if (db.prepare('SELECT COUNT(*) n FROM cards WHERE uid=77 AND type=1 AND ninja_id=35').get().n !== before + 1) { bad++; console.log('BOSS REWARD: Graduate II did not give Kakashi Hatake'); }
    if (g.BOSS_NAMED_CHANCE !== 0.05) { bad++; console.log('BOSS REWARD chance changed:', g.BOSS_NAMED_CHANCE); }
  }
  // GitHub #6: the No.1 Shinobi list's uid needs a 5-digit suffix (the Lua cuts 5 characters off before ToUid), and a challenged real
  // player far from my level fights under his own name, not "Rival"
  {
    const list = handlers.rl_r_ninja_rank({ db, params: { Uid: '77', Session: 'x', ServerID: '1', GroupID: '2', Cmd: '1' } }), m = list.match(/uid="(\d+)"/);
    if (!m || m[1].length < 6 || !db.prepare('SELECT 1 FROM players WHERE uid=?').get(Number(m[1].slice(0, -5)))) { bad++; console.log('RANK UID: the list uid does not end in 5 extra digits:', list.slice(0, 200)); }
    const g = require('../../server/game');
    handlers.rl_w_reg2({ db, params: { Uid: '78123', Session: 'x', ServerID: '1', GroupID: '2', Nick: 'FarAbove', Card: 1, Ninja: 55, Country: 1 } });
    db.prepare("UPDATE players SET level=350 WHERE uid=78123").run();
    const me = db.prepare('SELECT * FROM players WHERE uid=77').get();
    for (let i = 0; i < 15; i++) handlers.rl_w_reg2({ db, params: { Uid: String(78200 + i), Session: 'x', ServerID: '1', GroupID: '2', Nick: 'Near' + i, Card: 1, Ninja: 55, Country: 1 } });
    const r = g.sparFight(db, me, 78123);
    if (!/defensenick="FarAbove"/.test(r.xml || '') || !/defenselevel="350"/.test(r.xml || '')) { bad++; console.log('RANK CHALLENGE: a far-above player fought as', ((r.xml || '').match(/<preview[^>]*>/) || [''])[0]); }
  }
  // GitHub #6: a refused recruit must carry the root's message ATTRIBUTE (CItemView shows it with ShowTextTip; without it the game aborted)
  {
    const b2 = { Uid: '78123', Session: 'x', ServerID: '1', GroupID: '2' };
    const r = require('../../server/errcodes').fix(handlers.rl_w_recruit({ db, params: { ...b2, Cmd: '1900', Type: '3', Free: '1' } }));
    if (!/^<root code="(?!0")\d+" message="[^"]+"/.test(r)) { bad++; console.log('RECRUIT REFUSAL without a message attribute:', r.slice(0, 160)); }
  }
  // GitHub #6: a lost spar against a much stronger real player shows his REAL defence (was scaled down to fit the result)
  {
    const g = require('../../server/game'), me = db.prepare('SELECT * FROM players WHERE uid=77').get();
    const strong = db.prepare('SELECT uid FROM players WHERE uid=78123').get();
    if (strong) {
      db.prepare('UPDATE cards SET level=50 WHERE uid=78123').run();
      const real = g.teamStats(db, 78123, 1).total, mine = g.teamStats(db, 77, 1).total;
      process.env.HB_SPAR = 'lose'; const x = g.sparFight(db, me, 78123).xml || ''; delete process.env.HB_SPAR;
      const guard = x.split('<guard>')[1] || '', ends = [...guard.matchAll(/<end>(\d+)<\/end>/g)].map((m) => +m[1]), shown = ends.reduce((a, v) => a + v, 0);
      const realDef = (real.dl + real.dh) / 2;
      if (realDef > (mine.al + mine.ah) / 2 * 1.2 && Math.abs(shown - realDef) > realDef * 0.15) { bad++; console.log(`SPAR DEFENCE: shown ${shown}, real ${Math.round(realDef)}`); }
    }
  }
  // VIP 19-23 (owner 6 Nov 2026): top-ups reach VIP 23 and its VIP shop pack can be bought (was capped at 18)
  {
    const vip = require('../../server/vip');
    vip.addExp(db, 78123, 1, 3000000);
    if (vip.level(db, 78123, 1) !== 23) { bad++; console.log('VIP 23: $300 000 of top-ups gave VIP', vip.level(db, 78123, 1)); }
    db.prepare('UPDATE players SET gold=100000 WHERE uid=78123').run();
    const r = vip.buy(db, db.prepare('SELECT * FROM players WHERE uid=78123').get(), 23);
    if (r.error) { bad++; console.log('VIP 23 shop pack:', r.error); }
  }
  // story enemy curve (owner 6 Nov 2026, steeper): stage 1-2 = 285 (original video), chapter ends 1 = 2 000, 3 = 8 000, 10 = 300 000,
  // 19 = 10 million; the control panel's inverse (stageForDefence) must agree with it
  {
    const g = require('../../server/game'), tot = (c, s) => g.stageFoes(c, s).reduce((a, x) => a + x.def, 0);
    const got = [tot(1, 2), tot(1, g.chapterStages(1)), tot(3, g.chapterStages(3)), tot(10, g.chapterStages(10)), tot(19, g.chapterStages(19))];
    const want = [285, 2000, 8000, 300000, 10000000];
    if (got.some((v, i) => Math.abs(v - want[i]) > want[i] * 0.01)) { bad++; console.log('BOSS CURVE:', got.join(', '), 'want', want.join(', ')); }
    const back = g.stageForDefence(tot(3, 30));
    if (!back || back.chap !== 3 || Math.abs(back.stage - 30) > 1) { bad++; console.log('BOSS CURVE inverse: chapter 3 stage 30 came back as', JSON.stringify(back)); }
  }
  // HB_ONE_WORLD=1 (public server, 6 Nov 2026): the server list holds only Konoha (main); without it the 3 starter slots stay
  {
    const list = (env) => require('child_process').execFileSync(process.execPath, ['-e',
      "process.stdout.write(require('./server/handlers').xk_r_dir({ host: 'x' }))"], { cwd: path.join(__dirname, '..', '..'), env: { ...process.env, ...env } }).toString();
    const ids = (x) => [...x.matchAll(/<server><id>(\d+)<\/id>/g)].map((m) => m[1]).join();
    if (ids(list({ HB_ONE_WORLD: '1' })) !== '1') { bad++; console.log('ONE WORLD: server list', ids(list({ HB_ONE_WORLD: '1' }))); }
    if (ids(list({ HB_ONE_WORLD: '' })) !== '1,2,3,4') { bad++; console.log('STARTER SLOTS gone without HB_ONE_WORLD:', ids(list({ HB_ONE_WORLD: '' }))); }
  }
  try { db.close(); fs.rmSync(tmp, { force: true }); } catch {}
  console.log(bad ? bad + ' problem(s)' : `all ${Object.keys(handlers).length} handlers OK (${calls} calls)`);
  process.exit(bad ? 1 : 0);
})();
