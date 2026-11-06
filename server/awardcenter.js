// Award Center ("Receive" on Home, ui_awardCenterLayer.lua): reward mail the server sends, kept 7 days (<expiry>). ORIGINAL protocol:
// rl_x_award_msg Cmd 1 = list (<expiry/><msglist><msg><id/><ts/><title/><content/><awards><item type dropid/>...</awards></msg>...),
// Cmd 2 MsgID = claim one, Cmd 3 = claim all (both reply <award>). Award item types (ui_awardCenterCellCell): 1 = a drop (dropid),
// 2 = silver (dropid = amount), 3 = arena reputation (amount). The original used it for compensation and rank prizes; here the control
// panel sends it (admin.js /admin/api/sendmail): a message with gold, silver and / or reputation for one player or everyone.
const game = require('./game');

const EXPIRY_DAYS = 7;
const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const now = () => Math.floor(Date.now() / 1000);
function ensure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS award_mail (id INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, server_id INTEGER, ts INTEGER, title TEXT, content TEXT, items TEXT, claimed INTEGER DEFAULT 0)');
}
// gold as the game's own gold-only drops (Gold*50, 100 gold ... 10000), biggest first, so any amount shows as a few gold icons
let goldDrops = null;
function goldItems(amount) {
  if (!goldDrops) {
    goldDrops = {};
    for (const r of game.table('dropinfo').rows) {
      const only = r[10] > 0 && r[12] !== 1 && [3, 4, 5, 6, 7, 8, 9, 11].every((i) => !r[i]);
      const amt = r[10] * (r[13] || 1);
      if (only && !goldDrops[amt]) goldDrops[amt] = r[0];
    }
  }
  const sizes = Object.keys(goldDrops).map(Number).sort((a, b) => b - a), out = [];
  let left = Math.max(0, Math.floor(amount));
  for (const s of sizes) while (left >= s && out.length < 20) { out.push({ type: 1, dropid: goldDrops[s] }); left -= s; }
  return out;
}
// to = { uid, server_id } or 'all' (every character on the server). Returns how many players got it.
function send(db, to, title, content, { gold = 0, silver = 0, renown = 0, drops = [] } = {}) {
  ensure(db);
  const items = [...goldItems(gold), ...drops.map((d) => ({ type: 1, dropid: Number(d) })).filter((x) => x.dropid > 0)];
  if (silver > 0) items.push({ type: 2, dropid: Math.floor(silver) });
  if (renown > 0) items.push({ type: 3, dropid: Math.floor(renown) });
  if (gold > 0 && gold % 10) return { error: 'gold goes in steps of 10 (the game has no smaller gold pack)' };
  if (!items.length) return { error: 'add gold, silver or reputation' };
  const who = to === 'all' ? db.prepare('SELECT uid, server_id FROM players').all() : [to];
  const ins = db.prepare('INSERT INTO award_mail(uid, server_id, ts, title, content, items) VALUES(?,?,?,?,?,?)');
  for (const p of who) ins.run(p.uid, p.server_id, now(), String(title || 'A gift').slice(0, 40), String(content || title || 'A gift').slice(0, 300), JSON.stringify(items));
  return { sent: who.length };
}
const open = (db, pl) => { ensure(db); return db.prepare('SELECT * FROM award_mail WHERE uid=? AND server_id=? AND claimed=0 AND ts>? ORDER BY id DESC').all(pl.uid, pl.server_id, now() - EXPIRY_DAYS * 86400); };
// title and content must never be empty: ui_awardCenterCell.lua does setString(data:find("content")[1]) and an empty element
// gives nil, which crashed the game as soon as the Award Center opened (6 Nov 2026: a mail sent with an empty Message box).
function listXml(db, pl) {
  const msgs = open(db, pl).map((m) => '<msg>' + el('id', m.id) + el('ts', m.ts) + el('title', esc(m.title || 'A gift')) + el('content', esc(m.content || m.title || 'A gift')) +
    '<awards>' + JSON.parse(m.items).map((x) => `<item type="${x.type}" dropid="${x.dropid}"/>`).join('') + '</awards></msg>').join('');
  return el('expiry', EXPIRY_DAYS) + `<msglist>${msgs}</msglist>`;
}
function claim(db, pl, id) {
  const mails = open(db, pl).filter((m) => !id || m.id === Number(id));
  if (!mails.length) return { error: 'nothing to claim' };
  const awards = [];
  let silver = 0;
  for (const m of mails) {
    for (const x of JSON.parse(m.items)) {
      if (x.type === 1) awards.push(game.grantDrop(db, pl, x.dropid));
      else if (x.type === 2) silver += x.dropid;
      else if (x.type === 3) game.propAdd(db, pl.uid, pl.server_id, 9996, x.dropid);
    }
    db.prepare('UPDATE award_mail SET claimed=1 WHERE id=?').run(m.id);
  }
  if (silver) { db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(silver, pl.uid, pl.server_id); awards.push(game.awardFull({ coin: silver })); }
  return { xml: game.mergeAwards(awards.filter(Boolean)) };
}

module.exports = { send, listXml, claim };
