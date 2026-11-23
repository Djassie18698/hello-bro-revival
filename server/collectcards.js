// Collect cards (Event list id 6, "collectCardActivity": collectCardActivity.lua + collectCellView.lua on the layouts
// activity/CollectCardTableView + CollectCardView). Hand in / show a set of cards for a prize.
//
// ORIGINAL (the game's own news texts, innews_info_data.lua 3 and 4; the lists themselves lived on the dead server):
//   "Collect the three Legendary Sannin: Jiraiya, Orochimaru and Tsunade, and trade them for the five-star purple card Minato Namikaze"
//   "Collect Team Guy's three shinobi: Tenten, Neji Hyuga and Rock Lee, and get the four-star blue card Might Guy and 10 Reincarnation Pills"
//   Which copy is handed in: the script's own choice (getTargetNotInUseByDataId): not in a team, lowest rebirth, then lowest level.
// (ours): the Attack versions of the cards; the Sannin set is a trade (the three cards are taken, the screen asks "use material card to
//   exchange?"), the Team Guy set only looks ("Able to collect": nothing is taken); each once per run; a run lasts 7 days.
//
// Protocol: rl_r_comm Cmd 1 = <basic><remain>seconds</remain></basic><collectlist> of <collect>: id, type (2 = collect, else exchange),
//   title, content (the first row's two texts head the page), canexchangetime, hasexchangetime, <materiallist> of up to 5 <material>:
//   icon, type (1 shinobi, 2 gear, 3 ninjutsu, 4 item), kind (1 attack, 2 defence, else god), level, newlife, havecount, needcount, show;
//   <drop> of up to 3 <item><icon value type kind level newlife show/></item>.
//   rl_w_comm Cmd 1 Collectid = claim: <delcards><card bagindex/>...</delcards> (cards the game removes from its list) + <award>.
// v28's two layouts lack nodes its own script writes to (label_remain_time; per card label_card_lv_N, spr_lv_N, spr_frame_corner1/2_N,
// sprite_god_iconN and the reward_ twins), so the original screen stops with a Lua error. Our copies of the two scripts in
// server/cdn/src/script (collectCardActivity.lua, collectCellView.lua) make a hidden stand-in for a missing node; the rewritten game
// runs them already, phones get them with the next hot update.
const game = require('./game');
const settings = require('./settings');

const ID = 'collect', DAYS = 7;
// [id, type, [ninja ids to own], [prize drops], times]
const SETS = [
  [1, 1, [25, 26, 30], [275], 1],      // Jiraiya + Orochimaru + Senju Tsunade -> Minato Namikaze (Attack Card)
  [2, 2, [112, 55, 76], [988, 108], 1], // Tenten + Neji Hyuga + Rock Lee -> Maito Gai(ATK) + Reincarnation Pill*10
];
const TITLE = 'Collect and exchange';
const CONTENT = 'Bring the cards shown for the prize on the right. Cards in a team do not count.';
const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const now = () => Math.floor(Date.now() / 1000);
const ensure = (db) => db.exec('CREATE TABLE IF NOT EXISTS collect_claim (run INTEGER, uid INTEGER, server_id INTEGER, id INTEGER, times INTEGER DEFAULT 0, PRIMARY KEY(run, uid, server_id, id))');
const run = (db) => settings.switchedOnAt(db, ID) || 0;
const rest = (db) => settings.capLeft(db, ID, Math.max(0, (run(db) || now()) + DAYS * 86400 - now()));
const open = (db) => settings.eventOn(db, ID) && rest(db) > 0;
// v28's layout has no clock for <remain> (the script's label_remain_time is missing), so the page's own text says it
const leftText = (s) => 'Ends in ' + (s >= 86400 ? Math.floor(s / 86400) + ' d ' + Math.floor(s % 86400 / 3600) + ' h.' : s >= 3600 ? Math.floor(s / 3600) + ' h ' + Math.floor(s % 3600 / 60) + ' min.' : Math.max(1, Math.ceil(s / 60)) + ' min.');
const kind = (n) => (n[11] >= 6 ? 3 : n[6] === 1 ? 2 : 1); // 1 attack card, 2 defence card, 3 god card
// spare copies of a shinobi: not in a team, weakest first (the copy the screen itself would pick)
const spare = (db, pl, ninjaId) => db.prepare('SELECT seq, level, newlife FROM cards WHERE uid=? AND server_id=? AND type=1 AND ninja_id=? ORDER BY newlife, level, seq').all(pl.uid, pl.server_id, ninjaId)
  .filter((c) => !['team', 'team_alt'].some((t) => db.prepare(`SELECT 1 FROM ${t} WHERE seq=?`).get(c.seq)));
const done = (db, pl, id) => { ensure(db); const r = db.prepare('SELECT times FROM collect_claim WHERE run=? AND uid=? AND server_id=? AND id=?').get(run(db), pl.uid, pl.server_id, id); return r ? r.times : 0; };

function prizeItem(dropId) {
  const r = game.table('dropinfo').rows.find((x) => x[0] === dropId) || [];
  if (r[3] > 0) { const n = game.ninjas().get(r[3]) || []; return `<item><icon value="icon_${n[3]}" type="1" kind="${kind(n)}" level="1" newlife="0" show="${esc(String(n[2] || '').trim())}"/></item>`; }
  const c = game.table('consumeinfo').rows.find((x) => x[1] === r[7]) || [];
  return `<item><icon value="${c[3] || 'props_033'}" type="4" kind="0" level="1" newlife="0" show="${esc((c[2] || '') + ' x' + (r[13] || 1))}"/></item>`;
}
function infoXml(db, pl) {
  if (!open(db)) return null;
  const list = SETS.map(([id, type, cards, drops, times]) => '<collect>' + el('id', id) + el('type', type) + el('title', TITLE) + el('content', esc(CONTENT + ' ' + leftText(rest(db)))) +
    el('canexchangetime', times) + el('hasexchangetime', done(db, pl, id)) + '<materiallist>' + cards.map((nid) => { const n = game.ninjas().get(nid) || [];
      return '<material>' + el('icon', 'icon_' + n[3]) + el('type', 1) + el('kind', kind(n)) + el('level', 1) + el('newlife', 0) + el('havecount', spare(db, pl, nid).length) + el('needcount', 1) + el('show', esc(String(n[2] || '').trim())) + '</material>'; }).join('') +
    '</materiallist><drop>' + drops.map(prizeItem).join('') + '</drop></collect>').join('');
  return `<basic><remain>${rest(db)}</remain></basic><collectlist>${list}</collectlist>`;
}
function claim(db, pl, id) {
  if (!open(db)) return { error: 'the event is over' };
  const s = SETS.find((x) => x[0] === id);
  if (!s) return { error: 'no such set' };
  const [, type, cards, drops, times] = s;
  if (done(db, pl, id) >= times) return { error: 'already claimed' };
  const picked = cards.map((nid) => spare(db, pl, nid)[0]);
  if (picked.some((c) => !c)) return { error: 'you do not have every card of this set outside your teams' };
  const taken = type === 2 ? [] : picked;
  const shinobi = drops.reduce((n, d) => n + game.dropShinobi(d), 0);
  if (shinobi && game.bagRoom(db, pl.uid, pl.server_id) + taken.length < shinobi) return { error: game.BAG_FULL };
  db.prepare('INSERT INTO collect_claim VALUES(?,?,?,?,1) ON CONFLICT(run, uid, server_id, id) DO UPDATE SET times=times+1').run(run(db), pl.uid, pl.server_id, id);
  for (const c of taken) db.prepare('DELETE FROM cards WHERE seq=? AND uid=? AND server_id=?').run(c.seq, pl.uid, pl.server_id);
  return { xml: '<delcards>' + taken.map((c) => `<card bagindex="${c.seq}"/>`).join('') + '</delcards>' + game.mergeAwards(drops.map((d) => game.grantDrop(db, pl, d)).filter(Boolean)), taken: taken.map((c) => c.seq) };
}

module.exports = { ID, SETS, open, infoXml, claim };
