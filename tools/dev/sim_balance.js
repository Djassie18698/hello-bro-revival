// Balance simulations (owner's request, 2 Nov 2026): how fast a free player levels, whether the story can be finished, how much gold
// a free player earns, and what recruits / drops give. Uses the game's own tables and the server's own formulas (game.js), nothing is
// changed. Writes docs/BALANCE-SIMULATIONS.json; the plain-words report is docs/BALANCE-SIMULATIONS.md.
// usage: node tools/dev/sim_balance.js
const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');
const root = path.join(__dirname, '..', '..');
const game = require(path.join(root, 'game'));
const T = (n) => game.table(n).rows;

const out = {};
const rnd = (() => { let s = 12345; return () => (s = (s * 48271) % 2147483647) / 2147483647; })(); // repeatable

// ---- 1. The story: stages, energy, EXP, enemy strength ---------------------------------------------------------------------
const stages = [];
for (let c = 1; c <= 19; c++) for (let s = 1; s <= game.chapterStages(c); s++) {
  const r = game.stageRow(c, s); if (!r) continue;
  const foes = game.stageFoes(c, s);
  stages.push({ chap: c, stage: s, boss: !!r[38], energy: r[22] || 3, exp: r[23] || 6, silver: r[24] || 15, clears: game.clearsNeeded(r), def: foes.reduce((t, f) => t + f.power, 0) });
}
out.story = {
  stages: stages.length, bosses: stages.filter((x) => x.boss).length,
  energyToClear: stages.reduce((t, x) => t + x.energy * x.clears, 0),
  fightsToClear: stages.reduce((t, x) => t + x.clears, 0),
  expFromClearing: stages.reduce((t, x) => t + x.exp * x.clears, 0),
  perChapter: [...new Set(stages.map((x) => x.chap))].map((c) => {
    const l = stages.filter((x) => x.chap === c);
    return { chap: c, stages: l.length, energy: l.reduce((t, x) => t + x.energy * x.clears, 0), expPerEnergy: +(l[l.length - 1].exp / l[l.length - 1].energy).toFixed(1), lastBossDefence: Math.max(...l.filter((x) => x.boss).map((x) => x.def), 0) };
  }),
};

// ---- 2. Team power a free player can have (the server's own teamStats) -----------------------------------------------------
const db = new DatabaseSync(':memory:'); require(path.join(root, 'schema'))(db); game.ensure(db);
db.prepare("INSERT INTO accounts(uid,username,password) VALUES (1,'sim','')").run();
db.prepare("INSERT INTO players(uid,server_id,nick,country,card,created) VALUES (1,1,'sim',1,1,0)").run();
const base = (star) => [...game.ninjas().values()].filter((r) => r[4] === 1 && r[6] === 0 && r[11] === star && r[19] > 0).map((r) => r[0]);
// gear of a given star for weapon / armor / trinket (equipmentinfo [3] slot, [6] stars, [5] = 1 normal gear)
const gearOf = (slot, star) => T('equipmentinfo').filter((r) => r[3] === slot && r[6] === star && r[5] === 1).map((r) => r[0]);
function teamAtk(star, cardLevel, slots, newlife = 0, gearStar = 0, growth = 0) {
  db.exec('DELETE FROM team; DELETE FROM cards; DELETE FROM equipped;');
  const pool = base(star);
  for (let i = 0; i < slots; i++) {
    const seq = game.giveCard(db, 1, 1, pool[(i * 7) % pool.length]);
    db.prepare('UPDATE cards SET level=?, newlife=?, starlevel=? WHERE seq=?').run(cardLevel, newlife, growth, seq);
    db.prepare('INSERT INTO team(uid,server_id,slot,seq) VALUES (1,1,?,?)').run(i, seq);
    if (gearStar) for (const [gslot, kind] of [[0, 1], [1, 2], [2, 3]]) {
      const ids = gearOf(gslot, gearStar); if (!ids.length) continue;
      const g = game.giveEquip(db, 1, 1, ids[i % ids.length]);
      db.prepare('UPDATE cards SET level=? WHERE seq=?').run(cardLevel, g);
      db.prepare('INSERT INTO equipped(uid,server_id,slot,kind,seq) VALUES (1,1,?,?,?)').run(i + 1, kind, g);
    }
  }
  const t = game.teamStats(db, 1, 1).total;
  return Math.round((t.al + t.ah) / 2);
}
const SLOT_LV = T('newcardinfo').map((r) => Number((/(?:level|Lv\.)\s*(\d+)/i.exec(String(r[2])) || [0, 999])[1]));
const slotsAt = (lv) => SLOT_LV.filter((l) => l <= lv).length;
const lastBoss = (chap) => Math.max(...stages.filter((x) => x.chap === chap && x.boss).map((x) => x.def));
const reach = (atk) => { let best = 0; for (const x of stages) if (!x.boss || atk >= x.def / 1.15) best = x.chap; else break; return best; }; // best luck 1.15
out.power = [];
for (const [label, star, nl] of [['3-star cards', 3, 0], ['4-star cards', 4, 0], ['5-star cards', 5, 0], ['God cards', 6, 0], ['God cards, rebirth 8', 6, 8]]) {
  for (const lv of [10, 30, 50]) for (const slots of [3, 6]) {
    const atk = teamAtk(star, lv, slots, nl);
    out.power.push({ team: `${slots} x ${label}, card level ${lv}`, attack: atk, storyChapterReached: reach(atk) });
  }
}
out.lastBossDefence = lastBoss(19);
// A free player's team at a given level (assumptions, (ours)): team slots open by level (newcardinfo); cards 3-star below level 30,
// 4-star below 80, 5-star below 150, God after; card level = min(level, 50); gear of the same star on every card; sage growth 0 / 5 / 10 / 15;
// rebirth 0 / 0 / 2 / 6. Extras (gates, seals, pets, ninjutsu, potential, sets) are left out, so this is on the low side.
const f2p = (lv) => { const st = lv < 30 ? 3 : lv < 80 ? 4 : lv < 150 ? 5 : 6; return { star: st, cardLevel: Math.min(50, lv), slots: slotsAt(lv), gear: Math.min(5, st), growth: [0, 0, 0, 0, 5, 10, 15][st], rebirth: [0, 0, 0, 0, 0, 2, 6][st] }; };
out.f2pTeam = [10, 30, 50, 80, 100, 150, 200, 250, 300, 350].map((lv) => { const f = f2p(lv); const atk = teamAtk(f.star, f.cardLevel, f.slots, f.rebirth, f.gear, f.growth); return { level: lv, ...f, attack: atk, storyChapterReached: reach(atk) }; });

// ---- 3. Levelling with natural energy only (free player) --------------------------------------------------------------------
const PL = T('playerlevel');
const lvRow = (l) => PL.find((r) => r[1] === l) || PL[PL.length - 1];
const duel = T('duelinfo').filter((r) => r[0] === r[2]);
function levelSim(sessions, days, extras) {
  let level = 1, exp = 0, energy = 10, at = 0; // at = index of the next story stage to clear
  const clears = new Map(), when = {}, log = [];
  const atkFor = (lv) => { const f = f2p(lv); return teamAtk(f.star, f.cardLevel, f.slots, f.rebirth, f.gear, f.growth); }; // see f2p()
  const atkCache = new Map(); const atk = (lv) => { const k = Math.round(lv / 10) * 10 || 1; if (!atkCache.has(k)) atkCache.set(k, atkFor(k)); return atkCache.get(k); };
  const gain = (e) => { exp += e; while (exp >= lvRow(level)[2] && level < 350) { exp -= lvRow(level)[2]; level++; energy = Math.max(energy, lvRow(level)[4]); for (const m of [30, 50, 80, 100, 150, 200, 250, 300, 350]) if (level === m) when[m] = +(t / 24).toFixed(1); } };
  let t = 0, lastT = 0;
  for (let d = 0; d < days; d++) {
    const bossTries = new Map();
    for (const h of sessions) {
      t = d * 24 + h;
      energy = Math.min(Math.max(energy, energy + Math.floor(((t - lastT) * 3600) / 180)), Math.max(energy, lvRow(level)[4])); lastT = t;
      for (;;) { // spend the energy: push the story while possible, else farm the best stage cleared
        const next = stages[at];
        let st = null;
        if (next && (!next.boss || ((bossTries.get(at) || 0) < 3 && atk(level) * (0.85 + rnd() * 0.3) >= next.def))) st = next;
        else if (next && next.boss && (bossTries.get(at) || 0) < 3) { if (energy < next.energy) break; energy -= next.energy; bossTries.set(at, (bossTries.get(at) || 0) + 1); continue; }
        else { const done = stages.slice(0, at).filter((x) => !x.boss); st = done.reduce((b, x) => (x.exp / x.energy > (b ? b.exp / b.energy : 0) ? x : b), null); if (!st) break; }
        if (energy < st.energy) break;
        energy -= st.energy; gain(st.exp);
        if (st === next) { if (next.boss) bossTries.set(at, (bossTries.get(at) || 0) + 1); clears.set(at, (clears.get(at) || 0) + 1); if (clears.get(at) >= next.clears) at++; }
      }
    }
    if (extras) { // once a day: spar (grudge 12 a day), border war (2 wanders at level 50+), war (10 wins at 36 EXP)
      const d1 = duel.find((r) => r[0] === level) || duel[duel.length - 1];
      gain(12 * d1[5]); if (level >= 50) gain(6600); gain(360);
    }
    if ([0, 6, 13, 29, 59, 89, 179, 364].includes(d)) log.push({ day: d + 1, level, storyAt: stages[at] ? `${stages[at].chap}-${stages[at].stage}` : 'done', teamAttack: atk(level) });
  }
  return { reachedLevel: level, daysToLevel: when, timeline: log };
}
const casual = [8, 13, 18, 22], active = [8, 10, 12, 14, 16, 18, 20, 22, 23.9];
out.levelling = {
  casualTrainingOnly: levelSim(casual, 365, false),
  casualWithSparBorderWar: levelSim(casual, 365, true),
  activeWithSparBorderWar: levelSim(active, 365, true),
  expNeeded: Object.fromEntries([50, 100, 150, 200, 250, 300, 350].map((l) => [l, PL.filter((r) => r[1] < l).reduce((t, r) => t + r[2], 0)])),
  energyPerDay: 480,
};

// ---- 4. Recruits ---------------------------------------------------------------------------------------------------------
const RATES = { 1: { 5: 12, 4: 88 }, 2: { 5: 4, 4: 26, 3: 70 }, 3: { 5: 1, 4: 5, 3: 30, 2: 64 } }; // = game.js RATES
function pulls(type, n, pityOn) {
  let pity = 0; const got = { 2: 0, 3: 0, 4: 0, 5: 0 };
  for (let i = 0; i < n; i++) {
    let x = rnd() * 100, star = 2;
    for (const [s, w] of Object.entries(RATES[type])) { if ((x -= w) < 0) { star = Number(s); break; } }
    if (pityOn && pity >= 19) star = 5;
    pity = star >= 5 ? 0 : pity + 1; got[star]++;
  }
  return got;
}
const N = 100000;
out.recruits = {
  fiveStarChance: { purple300: pulls(1, N, true)[5] / N, blue150: pulls(2, N, true)[5] / N, orders: pulls(3, N, false)[5] / N },
  freePerMonth: { purpleFree: 30, blueFree: 90, ordersMax: 150 },
  fiveStarsPerMonthFree: +((pulls(1, 30000, true)[5] + pulls(2, 90000, true)[5]) / 1000).toFixed(1),
};

// ---- 5. Gold a free player gets ------------------------------------------------------------------------------------------
const dropGold = (id) => { const r = T('dropinfo').find((x) => x[0] === id) || []; return (r[10] || 0) * (r[13] || 1); };
const lua = (f) => fs.readFileSync(path.join(root, 'reference', 'lua-scripts', f), 'utf8');
const packGold = (f) => [...lua(f).matchAll(/PackData\[(\d+)\]\s*=\s*\{([^}]*)\}/g)].reduce((t, m) => t + [...m[2].matchAll(/_drop\did=(\d+)/g)].reduce((u, x) => u + dropGold(Number(x[1])), 0), 0);
const scratchEV = [[800, 0.5], [500, 1], [150, 2.5], [50, 8], [20, 18], [5, 22]].reduce((t, [g, p]) => t + (g * p) / 100, 0);
out.gold = {
  start: 50,
  dailyTaskChests: dropGold(97) + dropGold(100), // the 60 and 120 point chests
  monthlySignIn: 20 + 50 + 50,
  scratchCardFreeDaily: +scratchEV.toFixed(1),
  loginGiftsTotal: packGold('loginActivityData.lua'),
  levelGiftsTotal: packGold('upgradeActivityData.lua'),
  stageWheelPerNormalWin: 0.2 * 3,
};
out.gold.perDayFree = +(out.gold.dailyTaskChests + out.gold.monthlySignIn / 30 + out.gold.scratchCardFreeDaily).toFixed(1);

// ---- 6. Drops from story fights ------------------------------------------------------------------------------------------
out.drops = {
  keyPerWin: 0.08,
  normalStage: { sageStoneIII: 0.46, oneTwoStarEquipment: 0.276, oneTwoStarShinobi: 0.184, bronzeKey: 0.08 },
  bossStage: { threeStarEquipment: 0.46, threeStarShinobi: 0.46, silverKey: 0.08 },
  fragmentsPerGodCard: 50,
};

fs.writeFileSync(path.join(root, 'docs', 'BALANCE-SIMULATIONS.json'), JSON.stringify(out, null, 1));
console.log(JSON.stringify({ f2pTeam: out.f2pTeam, story: { ...out.story, perChapter: undefined }, lastBossDefence: out.lastBossDefence, power: out.power, levelling: { casualTrainingOnly: out.levelling.casualTrainingOnly.daysToLevel, casualWithSparBorderWar: out.levelling.casualWithSparBorderWar.daysToLevel, activeWithSparBorderWar: out.levelling.activeWithSparBorderWar.daysToLevel, expNeeded: out.levelling.expNeeded }, recruits: out.recruits, gold: out.gold }, null, 1));
