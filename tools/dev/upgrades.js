// Card upgrade walk-through on a throwaway DB: level-up (eat cards), reincarnation, element change, potential training, succession,
// god evolve, sage growth, equipment upgrade, eight gates. Prints what each step cost and changed, so wrong numbers stand out.
// Usage: node tools/dev/upgrades.js
const os = require('os'), path = require('path'), fs = require('fs');
const { DatabaseSync } = require('node:sqlite');
const tmp = path.join(os.tmpdir(), 'hb-up-' + process.pid + '.db');
const db = new DatabaseSync(tmp);
require('../../schema')(db);
const h = require('../../handlers'), g = require('../../game');
const P = (x = {}) => ({ Uid: '501', Session: 's', ServerID: '1', GroupID: '2', ...x });
h.rl_w_reg2({ db, params: P({ Nick: 'Up', Card: '1', Country: '1' }) });
db.prepare('UPDATE players SET level=150, gold=100000, coin=50000000').run();
const pl = () => db.prepare('SELECT * FROM players WHERE uid=501').get();
const give = (id, type = 1) => g.giveCard(db, 501, 1, id, type);
const card = (seq) => db.prepare('SELECT * FROM cards WHERE seq=?').get(seq);
const wallet = () => { const p = pl(); return `gold ${p.gold} silver ${p.coin}`; };
const short = (x) => String(x).replace(/<fight>.*<\/fight>/, '[fight]').slice(0, 220);
const step = (title, fn) => { const a = wallet(); let out; try { out = fn(); } catch (e) { out = 'CRASH ' + e.message; } console.log(`\n== ${title}\n   ${short(out)}\n   before: ${a}\n   after:  ${wallet()}`); };
for (const id of [7, 8, 11, 28, 33, 34, 9999]) g.propAdd(db, 501, 1, id, 5000);

const main = give(10); // Minato (ATK) 5-star
const food = [give(76), give(88), give(93), give(102)];
step('Level-up: Minato eats 4 cards', () => h.rl_w_strengthen({ db, params: P({ SRCBagID: String(main), EATCardsBagIDList: food.join('|') }) }));
console.log('   card now', JSON.stringify(card(main)));
step('Reincarnation info (Cmd 8)', () => h.rl_w_newlife({ db, params: P({ Cmd: '8', ReadyCard: String(main) }) }));
step('Reincarnation with pills', () => h.rl_w_newlife({ db, params: P({ Cmd: '1', ReadyCard: String(main), EatCard: '0', NewLifeCount: '1' }) }));
console.log('   newlife now', card(main).newlife);
step('Element change price (Cmd 5)', () => h.rl_w_newlife({ db, params: P({ Cmd: '5', ReadyCard: String(main) }) }));
step('Element change (Cmd 6)', () => h.rl_w_newlife({ db, params: P({ Cmd: '6', ReadyCard: String(main) }) }));
const potName = Object.keys(h).find((k) => String(h[k]).includes('potentialRoll'));
step('Potential: load', () => h[potName]({ db, params: P({ Cmd: '1', BagId: String(main) }) }));
step('Potential: roll with pills (CostId 1)', () => h[potName]({ db, params: P({ Cmd: '2', BagId: String(main), CostId: '1' }) }));
step('Potential: save', () => h[potName]({ db, params: P({ Cmd: '3', BagId: String(main) }) }));
console.log('   pot', card(main).pot_att, card(main).pot_def, card(main).pot_ckr);
const twin = give(10);
step('Succession info (comm Cmd 9)', () => h.rl_r_comm({ db, params: P({ Cmd: '9', SrcCardIndex: String(main) }) }));
const inhName = Object.keys(h).find((k) => String(h[k]).includes('game.inherit('));
if (inhName) step(`Succession ${inhName}`, () => h[inhName]({ db, params: P({ Cmd: '13', SrcCardIndex: String(main), DstCardIndex: String(twin) }) }));
console.log('   twin now', JSON.stringify(card(twin)), 'source now', JSON.stringify(card(main) || 'gone'));
const growName = Object.keys(h).find((k) => String(h[k]).includes('sageGrow'));
for (let i = 0; i < 3; i++) step(`Sage growth try ${i + 1} (5 Sage Stone III)`, () => h.rl_w_star({ db, params: P({ Cmd: '1', ReadyCard: String(twin), StarStoneID: '8', StarStoneNum: '5', StarStoneExtID: '0', StarStoneExtNum: '0' }) }));
console.log('   growth now', card(twin).starlevel);
const atk = give(162), def = give(10);
step('God evolve (comm write Cmd 28)', () => h.rl_w_comm({ db, params: P({ Cmd: '28', AttackCardBagIndex: String(def), DefenseCardBagIndex: String(atk) }) }));
const sword = give(79, 2), eqFood = [give(9, 2), give(38, 2)];
step('Equipment level-up', () => h.rl_w_strengthen({ db, params: P({ SRCBagID: String(sword), EATCardsBagIDList: eqFood.join('|') }) }));
step('Eight Gates open a point', () => h.rl_w_eight_gate({ db, params: P({ Cmd: '2' }) }));
db.close(); try { fs.unlinkSync(tmp); } catch {}
