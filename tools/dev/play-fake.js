// Made-up server replies for three old events our server never built (no handler: rl_r_comm Cmd 1 and Cmd 2 answer empty), so the
// rewritten game's side of them can be looked at and tapped: Collect cards (collectCardActivity.lua), Level rank and Fight rank
// (ui_levelRankLayer.lua / ui_fightRankLayer.lua, both ask rl_r_comm Cmd 2). Only inside the browser of tools/dev/play.js: the
// page's requests to those two commands (and their claim requests rl_w_comm Cmd 1 / Cmd 3) are answered here, nothing reaches
// the server, no save changes. Every name and number below is invented for the test.
//   node tools/dev/play-fake.js [port]        install (until the page reloads)
const { connect } = require('./play.js');
const row = (i, name, country, level, power) => `<item><rank>${i}</rank><playerid>${1000 + i}</playerid><name>${name}</name><country>${country}</country><level>${level}</level><power>${power}</power></item>`;
const names = ['Ninja10001', 'Ninja20002', 'Ninja30003', 'Ninja40004', 'Ninja50005', 'Ninja60006', 'Ninja70007', 'Ninja80008'];
// level rank row: rank, playerid, name, country, level; fight rank row: rank, playerid, name, ?, country, power
const levelRows = names.map((n, i) => row(i + 1, n, (i % 4) + 1, 90 - i * 3, 0)).join('');
const powerRows = names.map((n, i) => `<item><rank>${i + 1}</rank><playerid>${1000 + i + 1}</playerid><name>${n}</name><level>${90 - i * 3}</level><country>${(i % 4) + 1}</country><power>${900000 - i * 61234}</power></item>`).join('');
const award = (rank, type, icon, name, drop) => `<award><rank>${rank}</rank><type>${type}</type><icon>${icon}</icon><name>${name}</name><dropid>${drop}</dropid></award>`;
const awards = [1, 2].map((t) => award(1, t, 'props_021', 'Gift for 1st place', 1393) + award(2, t, 'props_020', 'Gift for 2nd-3rd place', 1395) + award(3, t, 'props_020', 'Gift for 2nd-3rd place', 1395) +
  [4, 5, 6, 7, 8, 9, 10].map((r) => award(r, t, 'props_004', 'Gift for 4th-10th place', 1397)).join('')).join('');
const RANK = `<RENLONG code="0"><preview type="1" resttime="183000"/><levelrank my="3">${levelRows}</levelrank><powerrank my="3" mypower="777540">${powerRows}</powerrank><awardlist>${awards}</awardlist></RENLONG>`;
const mat = (icon, have, need, show) => `<material><icon>${icon}</icon><type>1</type><kind>1</kind><level>1</level><newlife>0</newlife><havecount>${have}</havecount><needcount>${need}</needcount><show>${show}</show></material>`;
const collect = (id, type, title, mats, prize, can, has) => `<collect><id>${id}</id><type>${type}</type><title>Collect cards</title><content>Hand in the cards shown for the prize on the right</content>` +
  `<canexchangetime>${can}</canexchangetime><hasexchangetime>${has}</hasexchangetime><materiallist>${mats}</materiallist><drop><item><icon value="${prize}" type="1" kind="1" level="1" newlife="0" show="Prize card"/></item></drop></collect>`;
const COLLECT = `<RENLONG code="0"><basic><remain>183000</remain></basic><collectlist>` +
  collect(1, 1, 'A', mat('icon_npc06_3', 1, 1, 'Sakura Haruno') + mat('icon_npc06_5', 1, 1, 'Neji Hyuga'), 'icon_npc07_1', 3, 0) +
  collect(2, 2, 'B', mat('icon_npc06_3', 1, 2, 'Sakura Haruno') + mat('icon_npc07_1', 0, 1, 'Shikamaru Nara') + mat('icon_npc06_5', 1, 1, 'Neji Hyuga'), 'icon_npc06_5', 1, 0) +
  `</collectlist></RENLONG>`;
const AWARD = `<RENLONG code="0"><delcards></delcards><award dropid="1393" coin="10000"><cardlist></cardlist><proplist></proplist><chipbag></chipbag><coin>10000</coin><cash>0</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award></RENLONG>`;
const HOOK = `(() => { const R = ${JSON.stringify({ RANK, COLLECT, AWARD })}; window.__fake = []; if (window.__faked) return 'already'; window.__faked = true;
  const of = window.fetch; window.fetch = async function (u, o) {
    if (o && o.method === 'POST' && typeof u === 'string') { const q = new URLSearchParams(o.body), cmd = q.get('Cmd');
      const body = u === '/rl_r_comm' && cmd === '1' ? R.COLLECT : u === '/rl_r_comm' && cmd === '2' ? R.RANK : u === '/rl_w_comm' && (cmd === '1' || cmd === '3') ? R.AWARD : null;
      if (body) { window.__fake.push(u + ' Cmd=' + cmd + ' ' + [...q.keys()].filter((k) => /id$/i.test(k) && k !== 'Uid' && k !== 'ServerID' && k !== 'GroupID').map((k) => k + '=' + q.get(k)).join(' ')); return new Response('<?xml version="1.0" encoding="UTF-8"?>' + body, { status: 200, headers: { 'Content-Type': 'text/xml' } }); } }
    return of.apply(this, arguments); };
  return 'made-up replies on'; })()`;
if (require.main === module) (async () => { const c = await connect(Number(process.argv[2]) || 9811); console.log(await c.ev(HOOK)); c.close(); process.exit(0); })();
module.exports = { HOOK };
