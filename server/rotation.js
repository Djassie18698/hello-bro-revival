// Weekly event rotation (owner, 9 Nov 2026: "make events automatically rotate ... cycle the events in a good way, so that in a week you
// can see all the events. Leave Super Ninja still give a card every 1 hour, but be there for 4 hours. I still want to be able to add or
// remove events, or reset rotation"). (ours: the plan, the days and the hours)
// While the rotation is on, it decides for every event in PLAN whether it runs (settings.eventOn asks here first); events taken out of
// the rotation, and events that are not in the plan (login rewards, Lucky Wheel ...), keep their own switch in the Server Manager.
// An event's run starts when its slot starts (settings.switchedOnAt returns the slot start), so every slot is a fresh run of the event
// (its progress, stock and prizes start again), and its countdown never goes past the end of the slot (settings.capLeft).
// Times are the server's own clock (UTC on the cloud machine; the Netherlands is 1 hour later in winter). Day 1 = the day the rotation
// was (re)started; the 7-day plan then repeats.
const settings = require('./settings');

const H = 3600, DAY = 24 * H, WEEK = 7 * DAY;
const FESTIVALS = ['xmas', 'newyear', 'anniv', 'xmas2']; // one festival per week, in this order (they share one game screen)
const SN_HOURS = [[11, 4], [18, 4]]; // Limited Super Ninja: every day 11:00-15:00 and 18:00-22:00 (server time), a new god card each hour

// [event id, first day (1-7), first hour, length in hours]
const PLAN = [
  // all week: the slow events (daily gifts and streaks; the month card has to stay on or bought cards stop paying)
  ['diligence', 1, 0, 168], ['dailycost', 1, 0, 168], ['lottery', 1, 0, 168], ['keeppay', 1, 0, 168], ['monthcard', 1, 0, 168],
  // days 1-2
  ['caishen', 1, 0, 48], ['consumption', 1, 0, 48], ['discount', 1, 0, 48],
  // days 3-4
  ['flower', 3, 0, 48], ['godrecruit', 3, 0, 48], ['groupbuy', 3, 0, 48],
  // days 5-7
  ['hottreasure', 5, 0, 72], ['festival', 5, 0, 72], ['totalgift', 5, 0, 48],
  // day 7: God Recruit once more; Shard Rush (double god card fragments from fights, shards.js) on days 4 and 7
  ['godrecruit', 7, 0, 24], ['shardrush', 4, 0, 24], ['shardrush', 7, 0, 24],
  ...[1, 2, 3, 4, 5, 6, 7].flatMap((d) => SN_HOURS.map(([h, n]) => ['superninja', d, h, n])),
];
const PLAN_IDS = [...new Set(PLAN.map((p) => p[0]))];
const now = () => Math.floor(Date.now() / 1000);
const offset = (t) => new Date(t * 1000).getTimezoneOffset() * 60; // seconds to add to local time to get UTC
const local = (t) => t - offset(t); // seconds on the server's local clock
const midnight = (t) => { const l = local(t); return l - (l % DAY) + offset(t); }; // the local midnight that starts t's day (UTC seconds)

let cache = null; // the last config read (limitsuper.featured is also called without a db)
function cfg(db) {
  const c = settings.get(db, 'rotation', null);
  cache = { on: true, epoch: 0, out: [], ...(c || {}) };
  if (!cache.epoch) { cache.epoch = midnight(now()); settings.set(db, 'rotation', cache); } // first start: today is day 1
  return cache;
}
const cached = () => cache || { on: true, epoch: midnight(now()), out: [] };

// which festival theme runs this week (the ones not taken out, in order)
function festivalOf(c, t) {
  const themes = FESTIVALS.filter((f) => !c.out.includes(f));
  if (!themes.length) return null;
  const week = Math.floor((local(t) - local(c.epoch)) / WEEK);
  return themes[((week % themes.length) + themes.length) % themes.length];
}
// plan id for an event id (the festival themes all run in the 'festival' rows)
const planId = (id) => (FESTIVALS.includes(id) ? 'festival' : String(id));
const managedBy = (c, id) => c.on && PLAN_IDS.includes(planId(id)) && !c.out.includes(String(id)) && !(planId(id) === 'festival' && c.out.includes('festival'));

// The slot of event id running at time t: { start, end } (UTC seconds), or null.
function slotAt(c, id, t) {
  const pid = planId(id);
  if (pid === 'festival' && festivalOf(c, t) !== id && id !== 'festival') return null;
  const into = (((local(t) - local(c.epoch)) % WEEK) + WEEK) % WEEK; // seconds since day 1 00:00 of this week
  for (const [pidRow, day, hour, hours] of PLAN) {
    if (pidRow !== pid) continue;
    const from = (day - 1) * DAY + hour * H, len = hours * H;
    const d = (((into - from) % WEEK) + WEEK) % WEEK;
    if (d < len) return { start: t - d, end: t - d + len };
  }
  return null;
}
// the next start of event id after t (for the Server Manager's "next" column)
function nextStart(c, id, t) {
  for (let h = 0; h <= 24 * 7 * 4; h++) { // up to 4 weeks ahead (a festival theme comes back every few weeks)
    const at = t + h * H;
    const s = slotAt(c, id, at);
    if (s && s.start > t) return s.start;
    if (s && h === 0) continue;
  }
  return 0;
}

// For settings.eventOn: true / false when the rotation decides, null when the event follows its own switch.
function decide(db, id, t = now()) {
  const c = cfg(db);
  if (!managedBy(c, id)) return null;
  return !!slotAt(c, id, t);
}
// The running slot of a rotation-run event (for switchedOnAt / capLeft), or null.
function slot(db, id, t = now()) {
  const c = cfg(db);
  return managedBy(c, id) ? slotAt(c, id, t) : null;
}
// Limited Super Ninja: hours of Super Ninja before t (its god cards step one per hour of its windows, so each window shows the next ones).
// null when the rotation does not run Super Ninja (then the god card simply follows the clock hour, as before).
function superNinjaHour(db, t = now()) {
  const c = db ? cfg(db) : cached();
  if (!managedBy(c, 'superninja')) return null;
  const l = local(t), day = Math.floor(l / DAY), hourOfDay = (l % DAY) / H;
  const perDay = SN_HOURS.reduce((s, [, n]) => s + n, 0);
  let before = 0; // window hours already over today (the current hour not counted, so inside a window it is the index of this hour)
  for (const [h, n] of SN_HOURS) before += Math.max(0, Math.min(n, Math.floor(hourOfDay) - h));
  return day * perDay + before;
}

// ---- the owner's controls (Server Manager) ----
function setOn(db, on) { const c = cfg(db); c.on = !!on; settings.set(db, 'rotation', c); return status(db); }
// take an event out of the rotation (it then follows its own switch) or put it back
function setIn(db, id, inRotation) {
  const c = cfg(db);
  if (!PLAN_IDS.includes(String(id)) && !FESTIVALS.includes(String(id))) return status(db); // not an event of the plan
  c.out = c.out.filter((x) => x !== String(id));
  if (!inRotation) c.out.push(String(id));
  settings.set(db, 'rotation', c);
  return status(db);
}
// start again at day 1, from today's midnight
function reset(db) { const c = cfg(db); c.epoch = midnight(now()); settings.set(db, 'rotation', c); return status(db); }

const NAMES = () => Object.fromEntries(settings.EVENTS.map((e) => [String(e.id), e]));
function when(id) {
  const rows = PLAN.filter((p) => p[0] === planId(id));
  if (id === 'superninja') return 'every day ' + SN_HOURS.map(([h, n]) => `${String(h).padStart(2, '0')}:00-${String(h + n).padStart(2, '0')}:00`).join(' and ');
  return rows.map(([, d, h, n]) => (n >= 168 ? 'all week' : n <= 24 ? `day ${d}` : `days ${d}-${d + Math.ceil(n / 24) - 1}`) + (h ? ` from ${String(h).padStart(2, '0')}:00` : '')).join(', ');
}
function status(db, t = now()) {
  const c = cfg(db), names = NAMES();
  const day = Math.floor((((local(t) - local(c.epoch)) % WEEK) + WEEK) % WEEK / DAY) + 1;
  const ids = [...PLAN_IDS.filter((p) => p !== 'festival'), ...FESTIVALS];
  const events = ids.filter((id) => names[id]).map((id) => {
    const inRot = c.on && !c.out.includes(id) && !(FESTIVALS.includes(id) && c.out.includes('festival'));
    const s = inRot ? slotAt(c, id, t) : null;
    return { id, name: names[id].name, icon: names[id].icon, when: FESTIVALS.includes(id) ? 'days 5-7, one festival a week' : when(id), inRotation: !c.out.includes(id),
      running: !!s, endsAt: s ? s.end : 0, nextAt: inRot && !s ? nextStart(c, id, t) : 0, on: settings.eventOn(db, id) };
  });
  return { on: c.on, epoch: c.epoch, day, week: Math.floor((local(t) - local(c.epoch)) / WEEK) + 1, festival: festivalOf(c, t), now: t, tz: -offset(t) / 3600, events };
}

// Once a minute: pay the Super Ninja hours that ended (their prizes go to the Awards chest even when nobody opens the screen again).
function startTick(db) {
  setInterval(() => { try { require('./limitsuper').settle(db); } catch (e) { console.error('rotation tick:', e.message); } }, 60000).unref();
}

module.exports = { PLAN, PLAN_IDS, FESTIVALS, SN_HOURS, decide, slot, superNinjaHour, setOn, setIn, reset, status, startTick, festivalOf, slotAt, cfg, midnight };
