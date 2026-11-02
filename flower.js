// Flower Worship (goddess event, "nvshen", Event menu activity id 15, ui_nvshenLayer.lua). ORIGINAL rules and rewards: the game's own text
// (localizable ui_nvshen_description): "with every $ topped up you get one rose; you are rewarded by the goddess once her happiness is full";
// rewards: Tsunade = Third Raikage + Gold Key*3 + Reincarnation Pill*35; Sakura = Gold Key*2 + Reincarnation Pill*15 + Super Ninja Pill*70;
// Mei Terumi = Gaara + Silver Key*3 + Sage Stone III*20; Konan = Sasori of the Red Sand + Silver Key*2 + Sage Stone III*10; Hinata = Deidara +
// Bronze Key*2 + Sage Stone III*5. Photos (1240, 3864, 4543): favourability 0/1 (one gift fills it), the give button reads "Given 40 / 24 / 95
// flowers" for Mei / Hinata / Konan = the roses one gift costs. (ours): Tsunade 95 and Sakura 95 roses, the goddess can be won again after
// her reward, 7 days per run. Protocol: rl_r_comm Cmd 5 = info (<preview open myflower resttime/> + <itemlist>), rl_w_comm Cmd 9 GirlID =
// give (<preview currsat currflower/>, currsat 0 = full -> <award>).
const game = require('./game');
const settings = require('./settings');

const ROSE = 9992, DAYS = 7;
// [index on screen, id, name (animation nvshenxianhua_<name>), picture, roses a gift, reward drops]
const GIRLS = [ // index = the picture the layout starts with (sprite_avtor_N shows nvshen_meinvN), so the middle one (3) is Mei, as on photo 1240
  [1, 1, 'chutian', 'nvshen_meinv1', 24, [366, 562, 256]],       // Hinata
  [2, 2, 'xiaonan', 'nvshen_meinv2', 95, [980, 563, 380]],       // Konan
  [3, 3, 'zhaomeiming', 'nvshen_meinv3', 40, [941, 564, 239]],   // Mei Terumi
  [4, 4, 'gangshou', 'nvshen_meinv4', 95, [279, 566, 113]],      // Tsunade
  [5, 5, 'chunyeying', 'nvshen_meinv5', 95, [565, 109, 942]],    // Sakura Haruno
];
const el = (n, v) => `<${n}>${v}</${n}>`;
const esc = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const now = () => Math.floor(Date.now() / 1000);
const restTime = (db) => Math.max(0, (settings.switchedOnAt(db, 'flower') || now()) + DAYS * 86400 - now());
const open = (db) => settings.eventOn(db, 'flower') && restTime(db) > 0;
const roses = (db, pl) => game.propCounts(db, pl.uid, pl.server_id)[ROSE] || 0;

// a top-up gives one rose per whole dollar while the event runs
function onTopup(db, pl, cents) {
  if (open(db) && cents >= 100) game.propAdd(db, pl.uid, pl.server_id, ROSE, Math.floor(cents / 100));
}
// reward line on the "Detailed Information" list: icon picture + amount from the drop row
function awardItem(dropId) {
  const r = game.table('dropinfo').rows.find((x) => x[0] === dropId) || [];
  let folder = 'props', name = 'props_033', des = String(r[13] || 1), color = 4;
  if (r[3] > 0) { const n = game.ninjas().get(r[3]) || []; folder = 'npc'; name = n[3]; des = String(n[2] || '').trim(); color = (n[11] || 4) >= 5 ? 4 : 3; }
  else if (r[7] > 0) { const c = game.table('consumeinfo').rows.find((x) => x[1] === r[7]) || []; name = c[3] || name; }
  return `<item dropid="${dropId}" folder="${folder}" name="${esc(name)}" num="${r[13] || 1}" des="${esc(des)}" color="${color}" newlife="0"/>`;
}
function infoXml(db, pl) {
  const items = GIRLS.map(([index, id, name, icon, cost, drops]) => '<item>' + el('ninja_id', id) + el('ninja_name', name) + el('ninja_icon', icon) +
    el('ninja_flowers', cost) + el('ninja_alllikenum', 1) + el('own_like', 0) + el('ninja_index', index) + `<awardlist>${drops.map(awardItem).join('')}</awardlist></item>`).join('');
  return `<preview open="${open(db) ? 1 : 0}" myflower="${roses(db, pl)}" resttime="${restTime(db)}"/><itemlist>${items}</itemlist>`;
}
function give(db, pl, girlId) {
  if (!open(db)) return { error: 'the event is over' };
  const g = GIRLS.find((x) => x[1] === girlId);
  if (!g) return { error: 'choose a goddess' };
  if (roses(db, pl) < g[4]) return { code: 320002 }; // the client opens the top-up window for this code
  game.propAdd(db, pl.uid, pl.server_id, ROSE, -g[4]);
  const award = game.mergeAwards(g[5].map((d) => game.grantDrop(db, pl, d)).filter(Boolean));
  return { xml: `<preview currsat="0" currflower="${roses(db, pl)}"/>` + award };
}

module.exports = { onTopup, infoXml, give };
