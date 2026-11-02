// Soul training (Eight Gates > "Train soul", ui_limitTrainSoulLayer.lua, rl_w_eight_gate Cmd 3 info / 4 train / 5 double / 6 collect).
// Training makes a batch of gate souls (prop 9998) that waits to be collected; before collecting it can be doubled.
// ORIGINAL (the game's own normalconfig): normal training 10 000 silver for 50 souls, 3 a day (rows 263-265); advanced training 35 gold for
// 70 souls (266-267), advanced tries a day = vipinfo [27] ("3 times for high level training per day" at VIP1, +1 a level); normal doubling
// succeeds 100 / 80 / 60 / 10 / 5 % for the 1st-5th doubling and costs 5 / 10 / 20 / 30 / 50 gold (268-277); advanced doubling always works
// and costs 7 / 25 / 75 / 150 / 250 gold (278-282), the first 2 a day free (283).
// (ours): a doubling multiplies by 2; a failed normal doubling collects the batch at the multiple it had; training again collects the
// waiting batch first; VIP0 has no advanced tries; at most 5 doublings a batch.
const game = require('./game');
const vip = require('./vip');

const GATE_SOUL = 9998;
const NORMAL = { coin: 10000, soul: 50, perDay: 3 }, ADV = { gold: 35, soul: 70 };
const NORMAL_CHANCE = [100, 80, 60, 10, 5], NORMAL_COST = [5, 10, 20, 30, 50], ADV_COST = [7, 25, 75, 150, 250], FREE_ADV = 2;
const el = (n, v) => `<${n}>${v}</${n}>`;
const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10);

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS soultrain (uid INTEGER, server_id INTEGER, day TEXT, normal INTEGER DEFAULT 0, adv INTEGER DEFAULT 0,
    free INTEGER DEFAULT 0, batch INTEGER DEFAULT 0, mult INTEGER DEFAULT 1, steps INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id))`);
}
function state(db, pl) {
  ensure(db);
  let s = db.prepare('SELECT * FROM soultrain WHERE uid=? AND server_id=?').get(pl.uid, pl.server_id);
  if (!s) { db.prepare('INSERT INTO soultrain(uid, server_id, day) VALUES(?,?,?)').run(pl.uid, pl.server_id, today()); s = { day: today(), normal: 0, adv: 0, free: 0, batch: 0, mult: 1, steps: 0 }; }
  if (s.day !== today()) { s.day = today(); s.normal = 0; s.adv = 0; s.free = 0; } // a waiting batch survives the new day
  return s;
}
const save = (db, pl, s) => db.prepare('UPDATE soultrain SET day=?, normal=?, adv=?, free=?, batch=?, mult=?, steps=? WHERE uid=? AND server_id=?')
  .run(s.day, s.normal, s.adv, s.free, s.batch, s.mult, s.steps, pl.uid, pl.server_id);
const advPerDay = (db, pl) => { const v = vip.level(db, pl.uid, pl.server_id); return v > 0 ? (game.table('vipinfo').rows.find((r) => r[0] === v) || [])[27] || 0 : 0; };
const souls = (db, pl) => game.propCounts(db, pl.uid, pl.server_id)[GATE_SOUL] || 0;
const nextCost = (list, s) => (s.batch && s.steps < list.length ? list[s.steps] : 0);
const advCost = (s) => (s.free < FREE_ADV ? 0 : nextCost(ADV_COST, s));
function collect(db, pl, s) {
  if (s.batch) game.propAdd(db, pl.uid, pl.server_id, GATE_SOUL, s.batch * s.mult);
  s.batch = 0; s.mult = 1; s.steps = 0;
}
// the price / free-count fields every reply carries
const common = (db, pl, s) => el('need_cash', nextCost(NORMAL_COST, s)) + el('need_cash_ad', advCost(s)) +
  el('free_left_count', Math.max(0, FREE_ADV - s.free)) + el('free_total_count', FREE_ADV);

function infoXml(db, pl) {
  const s = state(db, pl), adv = advPerDay(db, pl);
  return '<basic>' + el('soul', souls(db, pl)) + el('soul_train', NORMAL.soul) + el('soul_train_ad', ADV.soul) + el('cost_coin', NORMAL.coin) + el('cost_cash', ADV.gold) +
    el('left_count', Math.max(0, NORMAL.perDay - s.normal)) + el('allow_count', NORMAL.perDay) + el('left_count_ad', Math.max(0, adv - s.adv)) + el('allow_count_ad', adv) +
    el('vip_count_add', 1) + el('multiple_cash', nextCost(NORMAL_COST, s)) + el('multiple_cash_ad', advCost(s)) + el('multiple_time', s.mult) +
    el('uncollect_soul', s.batch * s.mult) + el('free_left_count', Math.max(0, FREE_ADV - s.free)) + el('free_total_count', FREE_ADV) + '</basic>';
}
function train(db, pl, type) {
  const s = state(db, pl), adv = type === 2;
  if (adv ? s.adv >= advPerDay(db, pl) : s.normal >= NORMAL.perDay) return { error: 'no training chances left today' };
  if (adv ? pl.gold < ADV.gold : pl.coin < NORMAL.coin) return { error: adv ? 'not enough gold' : 'not enough silver' };
  collect(db, pl, s);
  db.prepare(`UPDATE players SET ${adv ? 'gold=gold-?' : 'coin=coin-?'} WHERE uid=? AND server_id=?`).run(adv ? ADV.gold : NORMAL.coin, pl.uid, pl.server_id);
  if (adv) s.adv++; else s.normal++;
  s.batch = adv ? ADV.soul : NORMAL.soul;
  save(db, pl, s);
  return { xml: '<basic>' + el('soul_train', s.batch) + el('left_count', Math.max(0, NORMAL.perDay - s.normal)) + el('left_count_ad', Math.max(0, advPerDay(db, pl) - s.adv)) + common(db, pl, s) + '</basic>' };
}
function double(db, pl, type) {
  const s = state(db, pl), adv = type === 2;
  if (!s.batch) return { error: 'train first' };
  if (s.steps >= NORMAL_COST.length) return { error: 'no more doubling for this batch' };
  const cost = adv ? advCost(s) : nextCost(NORMAL_COST, s);
  if (pl.gold < cost) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(cost, pl.uid, pl.server_id);
  if (adv && s.free < FREE_ADV) s.free++;
  const ok = adv || Math.random() * 100 < NORMAL_CHANCE[s.steps];
  if (ok) { s.mult *= 2; s.steps++; } else collect(db, pl, s); // failed: the batch is collected as it was (the screen says "collected")
  save(db, pl, s);
  return { xml: '<basic>' + el('multiple_times', s.mult) + el('left_cash', pl.gold - cost) + el('total_soul', souls(db, pl)) + common(db, pl, s) + '</basic>' };
}
function collectXml(db, pl) {
  const s = state(db, pl);
  collect(db, pl, s);
  save(db, pl, s);
  return '<basic>' + el('total_soul', souls(db, pl)) + '</basic>';
}

module.exports = { infoXml, train, double, collectXml };
