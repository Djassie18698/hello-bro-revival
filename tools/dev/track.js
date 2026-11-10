// Prints a tracked account's day (server/tracker.js): power, level and exp, top-ups, gold / silver / energy in and out by source, cards and
// items gained and where from, every fight and what it gave, other players' actions on the account, time played. And the drops of every
// player ("drops"). For "let's look at yesterday" with the owner.
// Usage: node tools/dev/track.js [yesterday|today|YYYY-MM-DD|all|drops [day]] [--db public.db] [--uid 7] [--sid 1] [--events] [--fights] [--json]
//   all       one line per day for the whole run
//   drops     what every source gave on a day, for all players together (drop rates per fight / per request)
//   --events  also every logged line of the day;  --fights  also every fight with what it gave
// The public server (DEAN, uid 7):
//   ssh -i ~/.ssh/hellobro-oracle.key ubuntu@ninjaonline.duckdns.org "cd /opt/hellobro && sudo -u hellobro node tools/dev/track.js yesterday --db public.db"
// Reads the save read-only; days are the server's days (the cloud runs on UTC).
const path = require('path'), fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const args = process.argv.slice(2);
const opt = (k) => { const i = args.indexOf(k); return i >= 0 ? args.splice(i, 2)[1] : null; };
const flag = (k) => { const i = args.indexOf(k); if (i >= 0) args.splice(i, 1); return i >= 0; };
const file = opt('--db') || process.env.DB || 'hellobro.db';
let uid = Number(opt('--uid')) || 0;
const sidOpt = Number(opt('--sid')) || 0;
const showEvents = flag('--events'), showFights = flag('--fights'), asJson = flag('--json');
if (!fs.existsSync(file)) { console.error('No save at ' + path.resolve(file) + ' (use --db <file>)'); process.exit(1); }
const db = new DatabaseSync(file, { readOnly: true });
const tr = require('../../server/tracker');
const has = (t) => !!db.prepare('SELECT 1 FROM sqlite_master WHERE name=?').get(t);

const fmt = (n) => (n == null ? '-' : Number(n).toLocaleString('en-US'));
const sgn = (n) => (n > 0 ? '+' : '') + fmt(n);
const hm = (m) => (m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`);
const time = (t) => { const d = new Date(t * 1000); return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`; };
const top = (o, n = 12) => Object.entries(o).sort((a, b) => b[1] - a[1]).slice(0, n);
const per = (n, d) => (d ? (Math.abs(n / d) < 10 ? (n / d).toFixed(2) : fmt(Math.round(n / d))) : "-");
const dayOf = (w) => (w === 'today' || w === 'yesterday' ? tr.dayKey(Math.floor(Date.now() / 1000) - (w === 'yesterday' ? 86400 : 0)) : w);

const what = args[0] || 'yesterday';
if (what === 'drops') {
  if (!has('drop_stats')) { console.log('No drops logged in this save yet.'); process.exit(0); }
  const d = tr.dropStats(db, args[1] ? dayOf(args[1]) : '');
  if (asJson) { console.log(JSON.stringify(d, null, 1)); process.exit(0); }
  console.log(`== Drops of every player on ${d.day} (server clock ${d.tz}; days logged: ${d.days.join(', ') || 'none'})`);
  for (const S of d.sources) {
    const n = S.fightsTotal || S.requests, unit = S.fightsTotal ? 'fight' : 'request';
    const fights = Object.entries(S.fights).map(([k, f]) => `${k} ${f.won}/${f.won + f.lost} won`).join(', ');
    const money = [['silver', S.silver, S.silverOut], ['gold', S.gold, S.goldOut], ['energy', S.energy, S.energyOut]].filter(([, i, o]) => i || o)
      .map(([k, i, o]) => `${k} ${i ? '+' + fmt(i) : ''}${o ? ' -' + fmt(o) : ''} (${per(i - o, n)}/${unit})`);
    if (S.exp) money.push(`exp +${fmt(S.exp)} (${per(S.exp, n)}/${unit})`);
    if (S.levels) money.push(`${S.levels} level-ups`);
    console.log(`\n${S.src}: ${S.players} players, ${fmt(S.requests)} requests${fights ? ', ' + fights : ''}`);
    if (money.length) console.log('   ' + money.join(' | '));
    for (const [ic, l] of [['item', S.items], ['card', S.cards], ['pack', S.drops]]) for (const x of l.slice(0, 30)) console.log(`   ${ic.padEnd(5)} ${x.name}: ${fmt(x.times)}x, total ${fmt(x.amount)} (${per(x.amount, n)}/${unit})`);
  }
  process.exit(0);
}
if (!has('track_log')) { console.log('Nothing tracked in this save yet.'); process.exit(0); }
if (!uid) uid = [...tr.uids(db)][0] || (db.prepare('SELECT uid FROM track_log ORDER BY id DESC LIMIT 1').get() || {}).uid;
if (!uid) { console.log('Nothing tracked in this save yet.'); process.exit(0); }
// the world with the most lines (a reset also writes a line for an unused starter slot); --sid to pick another
const sid = sidOpt || (db.prepare("SELECT sid, COUNT(*) n FROM track_log WHERE uid=? AND kind<>'reset' GROUP BY sid ORDER BY n DESC, sid LIMIT 1").get(uid) || { sid: 1 }).sid;

if (what === 'all') {
  const ov = tr.overview(db, uid, sid);
  if (asJson) { console.log(JSON.stringify(ov, null, 1)); process.exit(0); }
  console.log(`uid ${uid}: ${ov.length} days tracked (server clock ${Intl.DateTimeFormat().resolvedOptions().timeZone})`);
  console.log('day         level vip   attack   defence  played   top-up  gold in/out        silver in/out          cards  fights W/L');
  for (const o of ov) {
    console.log(`${o.day}  ${String(o.level).padStart(5)} ${String(o.vip).padStart(3)} ${fmt(o.atk).padStart(9)} ${fmt(o.def).padStart(9)}  ${hm(o.minutes).padEnd(8)} $${String(Math.round(o.topup)).padEnd(6)} +${fmt(o.goldIn)}/-${fmt(o.goldOut)}`.padEnd(97) +
      `+${fmt(o.silverIn)}/-${fmt(o.silverOut)}`.padEnd(23) + `${String(o.cards).padStart(5)}  ${o.won}/${o.lost}${o.reach.length ? '  ' + o.reach.join(', ') : ''}`);
  }
  process.exit(0);
}
const day = dayOf(what);
if (!/^\d{4}-\d\d-\d\d$/.test(day)) { console.error('Day must be yesterday, today, all, drops or YYYY-MM-DD'); process.exit(1); }
const s = tr.summary(db, uid, sid, day);
if (asJson) { console.log(JSON.stringify(s, null, 1)); process.exit(0); }

const out = [];
const P = (...a) => out.push(a.join(''));
P(`== ${s.nick || 'uid ' + uid} (uid ${uid}) on ${s.day}  (server clock ${s.tz}; days tracked: ${s.days.length ? s.days[0] + ' .. ' + s.days[s.days.length - 1] : 'none'})`);
if (s.resets.length) P(`!! character reset at ${s.resets.map(time).join(', ')}`);
const p = s.power, a0 = p[0], a1 = p[p.length - 1];
P(`Played     ${hm(s.played.minutes)} in ${s.played.sessions.length} sessions (${s.played.sessions.map((x) => `${time(x.from)}-${time(x.to)}`).join(', ') || '-'}), ${fmt(s.played.requests)} requests`);
P(`Level      ${s.level.start} -> ${s.level.end}, exp ${fmt(s.level.exp)} / ${fmt(s.level.need)} for the next`);
if (s.level.ups.length) P('             ' + s.level.ups.map((l) => `${l.level} at ${time(l.at)}${l.took != null ? ' (' + hm(Math.round(l.took / 60)) + ')' : ''}`).join(', '));
P(`VIP        ${s.vip.start} -> ${s.vip.end}  (+${fmt(s.vip.expIn)} VIP exp)`);
P(`Top-ups    $${s.topup.dollars.toFixed(2)} in ${s.topup.count} top-ups -> ${fmt(s.topup.gold)} gold`);
P(`Attack     ${a0 ? fmt(a0.atk) + ' -> ' + fmt(a1.atk) + (a0.atk ? `  (${sgn(Math.round(((a1.atk - a0.atk) / a0.atk) * 1000) / 10)} %)` : '') : '-'}`);
P(`Defence    ${a0 ? fmt(a0.def) + ' -> ' + fmt(a1.def) : '-'}`);
const flow = (name, f) => {
  P(`${name.padEnd(10)} start ${fmt(f.start)}, end ${fmt(f.end)}: in +${fmt(f.totalIn)}, out -${fmt(f.totalOut)}`);
  if (f.totalIn) P('             in:  ' + top(f.in).map(([k, n]) => `${k} +${fmt(n)}`).join(' | '));
  if (f.totalOut) P('             out: ' + top(f.out).map(([k, n]) => `${k} -${fmt(n)}`).join(' | '));
};
flow('Gold', s.gold); flow('Silver', s.silver); flow('Energy', s.energy);
P(`Exp        +${fmt(s.exp.totalIn)}: ` + top(s.exp.in).map(([k, n]) => `${k} +${fmt(n)}`).join(' | '));
const fights = Object.entries(s.fights);
P(`Fights     ${fights.map(([k, v]) => `${k} ${v.won} won / ${v.lost} lost`).join(' | ') || '-'}`);
for (const [k, L] of Object.entries(s.loot)) {
  P(`   ${k.padEnd(10)} per fight: silver ${per(L.silver, L.fights)}, exp ${per(L.exp, L.fights)}, gold ${per(L.gold, L.fights)}, energy ${per(L.energy, L.fights)}`);
  const things = [...top(L.items, 15).map(([n, c]) => `${n} ${c}`), ...top(L.cards, 15).map(([n, c]) => `${n} ${c}`)];
  if (things.length) P('              got: ' + things.join(' | '));
}
P(`Reached    ${Object.values(s.reach).join(' | ') || '-'}`);
P(`Cards      ${s.cards.length} gained: ` + top(s.cardsBySource).map(([k, n]) => `${k} ${n}`).join(' | '));
const byStars = {};
for (const c of s.cards) byStars[c.stars + '★'] = (byStars[c.stars + '★'] || 0) + 1;
if (s.cards.length) P('             by stars: ' + Object.entries(byStars).sort().map(([k, n]) => `${k} ${n}`).join(', '));
const good = s.cards.filter((c) => c.stars >= 5);
if (good.length) P('             5★+: ' + good.map((c) => `${c.what.replace(/^[^:]+: /, '')} (${c.src}, ${time(c.at)})`).join('; '));
const items = Object.entries(s.items).sort((a, b) => b[1].in - a[1].in);
if (items.length) {
  P('Items');
  for (const [k, v] of items.slice(0, 30)) P(`             ${k}: +${fmt(v.in)}${v.out ? ' / -' + fmt(v.out) : ''}  (${Object.entries(v.by).map(([s2, n]) => `${s2} ${fmt(n)}`).join(', ')})`);
  if (items.length > 30) P(`             ... ${items.length - 30} more`);
}
if (s.ranks.length || s.others.length) {
  P('Others     ' + s.ranks.map((r) => `${time(r.at)} ${r.what} (${r.src})`).join(' | '));
  for (const o of s.others.slice(-15)) P(`             ${time(o.at)} ${o.src}: ${o.kind} ${o.delta != null ? sgn(o.delta) : ''} ${(o.detail || '').slice(0, 80)}`);
}
const big = p.filter((x) => x.datk).sort((a, b) => Math.abs(b.datk) - Math.abs(a.datk)).slice(0, 10);
if (big.length) {
  P('Biggest power changes');
  for (const x of big) P(`             ${time(x.at)} ${sgn(x.datk).padStart(10)} attack -> ${fmt(x.atk)}  ${x.src}: ${x.why}`);
}
if (showFights) {
  P('Every fight');
  for (const f of s.fightList) P(`  ${time(f.at)} ${f.kind.padEnd(8)} ${f.win ? 'won ' : 'lost'} ${f.what}  => ${f.got}`);
}
if (showEvents) {
  P('Every line');
  for (const e of s.events) P(`  ${time(e.at)}  ${e.src.padEnd(24).slice(0, 24)} ${e.kind.padEnd(8)} ${e.delta != null ? sgn(e.delta).padStart(9) : ''.padStart(9)} ${e.value != null ? fmt(e.value).padStart(10) : ''.padStart(10)}  ${e.key && e.kind !== 'item' ? e.key + ' ' : ''}${(e.detail || '').slice(0, 140)}`);
}
console.log(out.join('\n'));
