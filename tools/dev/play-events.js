// Switches events on in the dev save for a test of the rewritten game and puts the settings back exactly as they were.
//   node tools/dev/play-events.js on <id> [id ...]    e.g. consumption superninja (ids of server/settings.js EVENTS; taken out of the weekly rotation for the test)
//   node tools/dev/play-events.js back                the settings as they were before the first "on" (kept in re/play-events.json)
// The dev server reads the settings with every request, no restart needed. Dev save hellobro.db only (PLAY_DB = another save).
const fs = require('fs'), path = require('path');
const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync(process.env.PLAY_DB || path.join(__dirname, '..', '..', 'hellobro.db'));
const KEEP = path.join(__dirname, '..', '..', 're', 'play-events.json'), KEYS = ['events', 'events_on_at', 'rotation'];
const read = (k) => { const r = db.prepare('SELECT value FROM server_settings WHERE key=?').get(k); return r ? r.value : null; };
const write = (k, v) => { if (v === null) db.prepare('DELETE FROM server_settings WHERE key=?').run(k); else db.prepare('INSERT INTO server_settings(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value').run(k, v); };
const [cmd, ...ids] = process.argv.slice(2);
if (cmd === 'on') {
  if (!fs.existsSync(KEEP)) fs.writeFileSync(KEEP, JSON.stringify(Object.fromEntries(KEYS.map((k) => [k, read(k)]))));
  const ev = JSON.parse(read('events') || '{}'), at = JSON.parse(read('events_on_at') || '{}'), rot = { on: true, epoch: 0, out: [], ...JSON.parse(read('rotation') || '{}') };
  for (const id of ids) { ev[id] = true; at[id] = Math.floor(Date.now() / 1000); if (!rot.out.includes(id)) rot.out.push(id); }
  write('events', JSON.stringify(ev)); write('events_on_at', JSON.stringify(at)); write('rotation', JSON.stringify(rot));
  console.log('on: ' + ids.join(', '));
} else if (cmd === 'back') {
  if (!fs.existsSync(KEEP)) { console.log('nothing to put back'); process.exit(0); }
  const old = JSON.parse(fs.readFileSync(KEEP, 'utf8')); for (const k of KEYS) write(k, old[k]);
  fs.unlinkSync(KEEP); console.log('settings are as before');
} else console.log('on <id ...> | back');
