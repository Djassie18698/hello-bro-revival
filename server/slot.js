// Slot machine ("Super draw"): spend gold per spin, win gold on matching reels, earn points to exchange for packs.
const game = require('./game');
// a spin costs 100 gold and gives 10 points (ORIGINAL: the game's normalconfig 300/301); the bet multiples are (ours)
const COST = 100, BETS = [1, 2, 5, 10];
const PACKS = [
  { id: 1, score: 100, coin: 20000, drop: 503 }, { id: 2, score: 300, coin: 80000, drop: 502 }, { id: 3, score: 1000, cash: 500, drop: 500 },
]; // drop = the game's own drop row with that content ("20,000 Silver", "80,000 Silver", "500 Gold"): only shown as the pack's picture
const el = (n, v) => `<${n}>${v}</${n}>`;
function st(db, pl) {
  db.exec('CREATE TABLE IF NOT EXISTS slot (uid INTEGER, server_id INTEGER, score INTEGER DEFAULT 0, bet INTEGER DEFAULT 0, last INTEGER DEFAULT 0, got TEXT DEFAULT "", PRIMARY KEY(uid,server_id))');
  db.prepare('INSERT OR IGNORE INTO slot(uid,server_id) VALUES(?,?)').run(pl.uid, pl.server_id);
  return db.prepare('SELECT * FROM slot WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
}
// the screen shows and takes bet_cost + cost (ui_slotMachineLayer.lua): bet_cost is what the bet adds on top of the spin's own price,
// so the two together are the COST * multiple a spin really costs here
const basic = (m, extra = '') => `<basic>${el('score', m.score)}${el('bet_cost', COST * (BETS[m.bet] - 1))}${el('cost', COST)}${el('times', BETS[m.bet])}${el('remain', 86400)}${extra}</basic>`;
function info(db, pl) {
  const m = st(db, pl);
  // five faces (ours): the small icons icon_npc02_1 .. icon_npc06_1 (there is no icon_npc01_1; the plain "npc.." name is the big card art)
  // icon and cash are ATTRIBUTES: the reel and prize rows read cellData.icon / cellData.cash (ui_slotMachineSlotCell.lua); as child
  // elements every row raised a Lua error and the reels stayed empty
  const ninjas = [1, 2, 3, 4, 5].map((i) => `<ninja icon="icon_npc0${i + 1}_1" cash="${100 * i * 5}"/>`).join('');
  return basic(m) + `<ninjas>${ninjas}</ninjas>`;
}
function bet(db, pl) {
  const m = st(db, pl), b = (m.bet + 1) % BETS.length;
  db.prepare('UPDATE slot SET bet=? WHERE uid=? AND server_id=?').run(b, pl.uid, pl.server_id);
  return el('times', BETS[b]) + el('bet_cost', COST * (BETS[b] - 1));
}
function spin(db, pl) {
  const m = st(db, pl), mult = BETS[m.bet], cost = COST * mult;
  if (pl.gold < cost) return { error: 'not enough gold' };
  const pos = [0, 0, 0].map(() => 1 + Math.floor(Math.random() * 5));
  const win = pos[0] === pos[1] && pos[1] === pos[2] ? 1000 * pos[0] * 5 * mult : (pos[0] === pos[1] || pos[1] === pos[2] ? 100 * mult : 0); // (ours), 10x since the spin went 10 -> 100 gold
  db.prepare('UPDATE players SET gold=gold-?+? WHERE uid=? AND server_id=?').run(cost, win, pl.uid, pl.server_id);
  db.prepare('UPDATE slot SET score=score+?, last=? WHERE uid=? AND server_id=?').run(10 * mult, win, pl.uid, pl.server_id);
  const m2 = st(db, pl);
  return { xml: basic(m2).replace(/<remain>.*<\/remain>/, `<remain>86400</remain>${el('cash', win)}`) + `<slot>${el('pos1', pos[0])}${el('pos2', pos[1])}${el('pos3', pos[2])}</slot>` + game.awardFull({ cash: win }) };
}
function listXml(db, pl) {
  const m = st(db, pl);
  const got = new Set(m.got.split(',').filter(Boolean).map(Number));
  // The Exchange list (ui_slotMExchangeLayer / Cell) reads ONE <package> whose children are the rows, each with attributes: id, score,
  // status (1 = can be claimed, 2 = not enough points yet, 3 = claimed) and drop1..drop4 (a drop id, "0" = empty place). Until 22 Nov 2026 it
  // got one <package> per pack with child elements: every row was a Lua error and the window stayed empty.
  return basic(m) + '<package>' + PACKS.map((p) => `<item id="${p.id}" score="${p.score}" status="${got.has(p.id) ? 3 : m.score >= p.score ? 1 : 2}" drop1="${p.drop}" drop2="0" drop3="0" drop4="0" icon1="" icon2="" icon3="" icon4=""/>`).join('') + '</package>';
}
function exchange(db, pl, id) {
  const m = st(db, pl), p = PACKS.find((x) => x.id === id);
  if (!p) return { error: 'bad pack' };
  const got = m.got.split(',').filter(Boolean).map(Number);
  if (got.includes(id) || m.score < p.score) return { error: 'not available' };
  db.prepare('UPDATE slot SET got=? WHERE uid=? AND server_id=?').run([...got, id].join(','), pl.uid, pl.server_id);
  if (p.coin) db.prepare('UPDATE players SET coin=coin+? WHERE uid=? AND server_id=?').run(p.coin, pl.uid, pl.server_id);
  if (p.cash) db.prepare('UPDATE players SET gold=gold+? WHERE uid=? AND server_id=?').run(p.cash, pl.uid, pl.server_id);
  return { xml: game.awardFull({ coin: p.coin || 0, cash: p.cash || 0 }) };
}
module.exports = { info, bet, spin, listXml, exchange };
