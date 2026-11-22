// What a screen of the rewritten game is made of, for text polish (server/webclient/texts.js): every shown label and button of the
// open screen with its layout, parent, place inside the parent, size, anchor and text.
//   node tools/dev/play-dump.js [filter] [port]      (the browser of tools/dev/play.js serve; filter = part of a name or text)
const { connect } = require('./play.js');
(async () => {
  const filter = process.argv[2] && !/^\d+$/.test(process.argv[2]) ? process.argv[2] : '', port = Number(process.argv[3] || (/^\d+$/.test(process.argv[2] || '') ? process.argv[2] : 0)) || 9811;
  const c = await connect(port);
  const out = await c.ev(`(() => { const rows = [];
    const walk = (n, doc, par) => { if (!n || !n.visible) return; const d = n.ccbDoc || doc;
      const isL = n instanceof HB.Label || n instanceof HB.BMLabel, isB = n instanceof HB.Button;
      if ((isL && String(n.text).trim()) || isB) rows.push([d || '?', par || '-', (isB ? 'B ' : n instanceof HB.BMLabel ? 'F ' : 'L ') + (n.name || '.'), Math.round(n.x) + ',' + Math.round(n.y), Math.round(n.w) + 'x' + Math.round(n.h), 'a' + n.ax + ',' + n.ay, isL ? 's' + (n.size || '') + (n.dims && n.dims[0] ? ' d' + n.dims[0] : '') : '', JSON.stringify(isB ? (n.titles && n.titles[1]) || '' : String(n.text).slice(0, 70))].join('  '));
      (n.children || []).forEach((k) => walk(k, d, n.name || par)); };
    HB.scene.children.filter((k) => k.z >= 500).forEach((k) => walk(k, '', ''));
    if (!rows.length && HB.game && HB.game.subContent) walk(HB.game.subContent, '', ''); // a window is open: only the window
    return rows.join('\\n'); })()`);
  console.log(String(out).split('\n').filter((l) => !filter || l.toLowerCase().includes(filter.toLowerCase())).join('\n'));
  c.close(); process.exit(0);
})();
