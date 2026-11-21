// Lists what a layout holds: every named node (its kind, a button's action, a label's text). For rebuilding a screen in
// server/webclient: the screen's code finds nodes by these names and gets buttons by these actions.
//   node tools/dev/ccb-names.js store/StoreItemsView [more layouts]
const path = require('path');
for (const name of process.argv.slice(2)) {
  const j = require(path.join(__dirname, '..', '..', 'server', 'webclient', 'assets', name + '.json'));
  console.log('== ' + name + (j.seqs && j.seqs.length ? '   timelines: ' + j.seqs.map((s) => s.name || s.n || s.id).join(', ') : ''));
  const walk = (n, d) => {
    const p = n.p || {}, bits = [];
    if (p.ccControl) bits.push('-> ' + p.ccControl[0]);
    if (p.block && p.block[0]) bits.push('-> ' + p.block[0]);
    if (p.string) bits.push(JSON.stringify(String(p.string).slice(0, 30)));
    if (p['title|1']) bits.push(JSON.stringify(p['title|1']));
    if (p.ccbFile) bits.push('[' + p.ccbFile + ']');
    if (p.contentSize || p.preferedSize) bits.push((p.contentSize || p.preferedSize).slice(0, 2).join('x'));
    if (n.n || bits.some((b) => b.startsWith('->') || b.startsWith('['))) console.log('  '.repeat(d) + (n.n || '.') + '  ' + n.c.replace(/^CC/, '') + '  ' + bits.join(' '));
    for (const k of n.k || []) walk(k, d + (n.n ? 1 : 0));
  };
  walk(j.root, 1);
}
