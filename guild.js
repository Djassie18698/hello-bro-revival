// Akatsuki (guild) system. Lua screens read rows as ATTRIBUTES (cell.name etc.) and single values as child text.
// Joining is instant (no approval queue): this is a small friends-only server. The first member is the leader (pos 3).
const CREATE_COST = 789; // matches the "Fund" the create dialog shows

function ensure(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS groups (id INTEGER PRIMARY KEY AUTOINCREMENT, server_id INTEGER, name TEXT, desc TEXT, leader_uid INTEGER, level INTEGER DEFAULT 1, score INTEGER DEFAULT 0);
    CREATE TABLE IF NOT EXISTS group_members (uid INTEGER, server_id INTEGER, group_id INTEGER, pos INTEGER DEFAULT 0, score INTEGER DEFAULT 0, PRIMARY KEY(uid, server_id))`);
}
const esc = (t) => String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const el = (n, v) => `<${n}>${v}</${n}>`;

function myGroup(db, uid, sid) {
  ensure(db);
  return db.prepare('SELECT g.* FROM groups g JOIN group_members m ON m.group_id=g.id WHERE m.uid=? AND m.server_id=?').get(uid, sid);
}
function count(db, gid) { return db.prepare('SELECT COUNT(*) n FROM group_members WHERE group_id=?').get(gid).n; }
function leaderName(db, g) { const r = db.prepare('SELECT nick FROM players WHERE uid=? AND server_id=?').get(g.leader_uid, g.server_id); return r ? r.nick : '?'; }
function rank(db, g) { return db.prepare('SELECT COUNT(*)+1 n FROM groups WHERE server_id=? AND (score>? OR (score=? AND id<?))').get(g.server_id, g.score, g.score, g.id).n; }

function status(db, pl) { const g = myGroup(db, pl.uid, pl.server_id); return { g, member_status: g ? 2 : 0, groupid: g ? g.id : 0 }; }

function listXml(db, pl) {
  const s = status(db, pl);
  const rows = db.prepare('SELECT * FROM groups WHERE server_id=? ORDER BY score DESC, id').all(pl.server_id)
    .map((g) => `<group groupid="${g.id}" groupname="${esc(g.name)}" level="${g.level}" leader="${esc(leaderName(db, g))}" curcount="${count(db, g.id)}" totalcount="${20 + 5 * g.level}"/>`).join('');
  return `<member_status>${s.member_status}</member_status><grouplist>${rows}</grouplist>`;
}

function detailXml(db, pl, gid) {
  const g = db.prepare('SELECT * FROM groups WHERE id=?').get(gid);
  if (!g) return null;
  const mine = myGroup(db, pl.uid, pl.server_id);
  const js = mine ? (mine.id === g.id ? 2 : 3) : 0;
  return '<group_info>' + el('name', esc(g.name)) + el('level', g.level) + el('curcount', count(db, g.id)) + el('totalcount', 20 + 5 * g.level) +
    el('leader', esc(leaderName(db, g))) + el('score', g.score) + el('rank', rank(db, g)) + el('desc', esc(g.desc)) + el('minlevel', 1) +
    el('minfightscore', 0) + el('join_status', js) + '</group_info>';
}

function create(db, pl, name, desc) {
  ensure(db);
  if (myGroup(db, pl.uid, pl.server_id)) return { error: 'already in a group' };
  name = String(name || '').trim().slice(0, 20);
  if (!name) return { error: 'name needed' };
  if (db.prepare('SELECT 1 FROM groups WHERE server_id=? AND name=?').get(pl.server_id, name)) return { error: 'name taken' };
  if (pl.gold < CREATE_COST) return { error: 'not enough gold' };
  db.prepare('UPDATE players SET gold=gold-? WHERE uid=? AND server_id=?').run(CREATE_COST, pl.uid, pl.server_id);
  const id = Number(db.prepare('INSERT INTO groups(server_id,name,desc,leader_uid) VALUES(?,?,?,?)').run(pl.server_id, name, String(desc || '').slice(0, 200), pl.uid).lastInsertRowid);
  db.prepare('INSERT INTO group_members(uid,server_id,group_id,pos) VALUES(?,?,?,3)').run(pl.uid, pl.server_id, id);
  return { id };
}

function join(db, pl, gid) {
  ensure(db);
  if (myGroup(db, pl.uid, pl.server_id)) return { error: 'already in a group' };
  const g = db.prepare('SELECT * FROM groups WHERE id=?').get(gid);
  if (!g) return { error: 'no such group' };
  db.prepare('INSERT INTO group_members(uid,server_id,group_id,pos) VALUES(?,?,?,0)').run(pl.uid, pl.server_id, gid);
  return { id: gid };
}

function quit(db, pl) {
  const g = myGroup(db, pl.uid, pl.server_id);
  if (!g) return;
  db.prepare('DELETE FROM group_members WHERE uid=? AND server_id=?').run(pl.uid, pl.server_id);
  const next = db.prepare('SELECT uid FROM group_members WHERE group_id=? ORDER BY pos DESC, rowid LIMIT 1').get(g.id);
  if (!next) db.prepare('DELETE FROM groups WHERE id=?').run(g.id);
  else if (g.leader_uid === pl.uid) {
    db.prepare('UPDATE groups SET leader_uid=? WHERE id=?').run(next.uid, g.id);
    db.prepare('UPDATE group_members SET pos=3 WHERE uid=? AND group_id=?').run(next.uid, g.id);
  }
}

function buildingsXml(g) {
  return [1, 2, 3, 4, 5].map((i) => `<item${i} level="${g.level}"/>`).join('');
}

function adminXml(db, pl) {
  const g = myGroup(db, pl.uid, pl.server_id);
  if (!g) return null;
  const mem = db.prepare('SELECT m.*, p.nick, p.level lv FROM group_members m JOIN players p ON p.uid=m.uid AND p.server_id=m.server_id WHERE m.group_id=? ORDER BY m.pos DESC, m.score DESC').all(g.id);
  const rows = mem.map((m) => `<member name="${esc(m.nick)}" level="${m.lv}" postion="${m.pos}" score="${m.score}" last_login="${Math.floor(Date.now() / 1000)}" uid="${m.uid}"/>`).join('');
  const me = mem.find((m) => m.uid === pl.uid);
  return `<group_info>${el('name', esc(g.name))}${el('level', g.level)}${el('score', g.score)}${el('curcount', mem.length)}${el('totalcount', 20 + 5 * g.level)}</group_info>` +
    `<member_list>${rows}</member_list>${el('pos', me ? me.pos : 0)}`;
}

module.exports = { CREATE_COST, ensure, status, listXml, detailXml, create, join, quit, buildingsXml, adminXml, myGroup };
