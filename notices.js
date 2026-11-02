// Battle reports (News screen > fight notices, CNoticeDataHelper / CFightMsgCellView). ORIGINAL texts (the game's Struct_String_Menu
// 26-34): "Spar" / "Plunder"; "Player %s has defeated you in the spar, you lost %d silver" (result 0) / "... has been defeated by you
// in the spar, you won %d silver" (result 1); plunder: "won you, and stole %s" (iTakeRes 0) / "won you, but failed to steal %s" /
// "wishes to steal %s from your hands, but you have defeated this player" (result 1). Protocol: rl_r_msg Cmd 1800 Page = list
// (<msglist><msg> with child elements), rl_w_msg Cmd 2901 Op (1 delete, 2 read) Index (= <ID>); "Revenge" is an ordinary spar
// (rl_w_pvp 2701 ToUid). On this server the defender never loses silver or fragments (the attacker's reward is created, ours), so
// a lost spar says "you lost 0 silver" and a plunder says "failed to steal".
const game = require('./game');

const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const KEEP = 30; // newest notices kept per player (ours)
function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS fight_notice (id INTEGER PRIMARY KEY AUTOINCREMENT, server_id INTEGER, to_uid INTEGER, from_uid INTEGER,
    subtype INTEGER, result INTEGER, coin INTEGER DEFAULT 0, take INTEGER DEFAULT 1, chip INTEGER DEFAULT 0, ts INTEGER, status INTEGER DEFAULT 0)`);
}
// A real player (from) fought a real player (toUid): subtype 0 spar / 1 plunder, attackerWon from the attacker's side.
function record(db, from, toUid, subtype, attackerWon, chip) {
  ensure(db);
  if (!db.prepare('SELECT 1 FROM players WHERE uid=? AND server_id=?').get(toUid, from.server_id) || toUid === from.uid) return;
  db.prepare('INSERT INTO fight_notice(server_id, to_uid, from_uid, subtype, result, coin, take, chip, ts) VALUES(?,?,?,?,?,0,1,?,?)')
    .run(from.server_id, toUid, from.uid, subtype, attackerWon ? 0 : 1, chip || 0, Math.floor(Date.now() / 1000));
  db.prepare(`DELETE FROM fight_notice WHERE server_id=? AND to_uid=? AND id NOT IN (SELECT id FROM fight_notice WHERE server_id=? AND to_uid=? ORDER BY id DESC LIMIT ${KEEP})`)
    .run(from.server_id, toUid, from.server_id, toUid);
}
function listXml(db, pl, page) {
  ensure(db);
  if (Number(page) > 1) return '<msglist></msglist>';
  const rows = db.prepare(`SELECT n.*, p.nick, p.level, p.country FROM fight_notice n LEFT JOIN players p ON p.uid=n.from_uid AND p.server_id=n.server_id
    WHERE n.server_id=? AND n.to_uid=? ORDER BY n.id DESC`).all(pl.server_id, pl.uid);
  const items = rows.map((r) => {
    const card = db.prepare('SELECT ninja_id, starlevel, newlife FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot LIMIT 1').get(r.from_uid, r.server_id) || {};
    const star = ((game.ninjas().get(card.ninja_id) || [])[11]) || 1;
    return '<msg>' + el('subtype', r.subtype) + el('fromnick', esc(r.nick || '?')) + el('fromuid', r.from_uid) + el('fromninja', card.ninja_id || 5) +
      el('firstninjastar', star) + el('fromcountry', r.country || 1) + el('fromlevel', r.level || 1) + el('result', r.result) + el('iTime', r.ts) +
      el('ID', r.id) + el('iCoin', r.coin) + el('iTakeRes', r.take) + el('iChipid', r.chip) + el('iStatus', r.status) + el('newlife', card.newlife || 0) + '</msg>';
  }).join('');
  return `<msglist>${items}</msglist>`;
}
function op(db, pl, opCode, id) {
  ensure(db);
  if (Number(opCode) === 1) db.prepare('DELETE FROM fight_notice WHERE id=? AND to_uid=? AND server_id=?').run(Number(id), pl.uid, pl.server_id);
  else db.prepare('UPDATE fight_notice SET status=1 WHERE id=? AND to_uid=? AND server_id=?').run(Number(id), pl.uid, pl.server_id);
}

// ---- Friend messages (News > Friend tab, CFriendMsgCellView). A message left from the friend chat (rl_w_friend Msg + ToUid) is a
// "Friend notification" (subtype 3, Struct_String_Menu 21) with the sender's card and the text; its dialog marks it read
// (rl_w_msg 2902 Op Index). Listed by rl_r_msg Cmd 1801 (<msglist><msg> child elements, like the fight notices).
function mailEnsure(db) {
  db.exec('CREATE TABLE IF NOT EXISTS mail (id INTEGER PRIMARY KEY AUTOINCREMENT, to_uid INTEGER, from_nick TEXT, text TEXT, ts INTEGER)');
  for (const c of ['from_uid INTEGER DEFAULT 0', 'status INTEGER DEFAULT 0']) { try { db.exec(`ALTER TABLE mail ADD COLUMN ${c}`); } catch (e) { /* already there */ } }
}
function sendMail(db, from, toUid, text) {
  mailEnsure(db);
  db.prepare('INSERT INTO mail(to_uid, from_nick, from_uid, text, ts) VALUES(?,?,?,?,?)').run(toUid, from.nick, from.uid, String(text).slice(0, 200), Math.floor(Date.now() / 1000));
  db.prepare(`DELETE FROM mail WHERE to_uid=? AND id NOT IN (SELECT id FROM mail WHERE to_uid=? ORDER BY id DESC LIMIT ${KEEP})`).run(toUid, toUid);
}
function friendXml(db, pl) {
  mailEnsure(db);
  const rows = db.prepare(`SELECT m.*, p.level, p.country FROM mail m LEFT JOIN players p ON p.uid=m.from_uid AND p.server_id=?
    WHERE m.to_uid=? ORDER BY m.id DESC`).all(pl.server_id, pl.uid);
  return '<msglist>' + rows.map((r) => {
    const card = db.prepare('SELECT ninja_id, newlife FROM team t JOIN cards c ON c.seq=t.seq WHERE t.uid=? AND t.server_id=? ORDER BY t.slot LIMIT 1').get(r.from_uid, pl.server_id) || {};
    const star = ((game.ninjas().get(card.ninja_id) || [])[11]) || 1;
    return '<msg>' + el('subtype', 3) + el('fromnick', esc(r.from_nick)) + el('fromuid', r.from_uid || 0) + el('fromninja', card.ninja_id || 5) +
      el('firstninjastar', star) + el('fromcountry', r.country || 1) + el('fromlevel', r.level || 1) + el('iTime', r.ts) + el('ID', r.id) +
      el('iStatus', r.status || 0) + el('text', esc(`${r.from_nick}: ${r.text}`)) + /* the cell shows no name, so it leads the text */ el('newlife', card.newlife || 0) + '</msg>';
  }).join('') + '</msglist>';
}
function mailOp(db, pl, opCode, id) {
  mailEnsure(db);
  if (Number(opCode) === 1) db.prepare('DELETE FROM mail WHERE id=? AND to_uid=?').run(Number(id), pl.uid);
  else db.prepare('UPDATE mail SET status=1 WHERE id=? AND to_uid=?').run(Number(id), pl.uid);
}

module.exports = { record, listXml, op, sendMail, friendXml, mailOp };
