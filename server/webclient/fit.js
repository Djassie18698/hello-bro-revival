// Text that fits (ours; owner, 21 Nov 2026: "all text should match the boxes so it looks finished").
// The game's layouts were drawn for short Chinese words; the English ones are often longer and run into the next label or off the
// screen. Twice a second this pass looks at every one-line label of the screen that is showing (and of the windows over it) and
// shrinks a label just enough that it
//   - does not run into another label standing on the same line (4 pixels stay free), and
//   - stays inside the screen and inside the box that clips it (a list, a window).
// A label only gives way on the side it grows to (left-aligned text grows right, centred text both ways) and never below 55 % of
// its size. Labels that wrap (a width was given) are left alone: they already break into lines. `?fit=0` switches the pass off;
// `HB.fit.report()` lists what was shrunk on the screen that is showing (for finding texts worth shortening by hand).
'use strict';
(function () {
  const HB = window.HB;
  const MIN = 0.55, GAP = 4;
  const off = new URLSearchParams(location.search).get('fit') === '0';
  const isLabel = (n) => n instanceof HB.Label || n instanceof HB.BMLabel;

  function collect(root, out, clip) {
    if (!root || !root.visible) return;
    let c = clip;
    if (root.clip && root._wm) { const m = root._wm; const x0 = m[4], x1 = m[4] + m[0] * root.w; c = { x0: Math.max(clip.x0, Math.min(x0, x1)), x1: Math.min(clip.x1, Math.max(x0, x1)) }; }
    if (isLabel(root) && root.w > 0 && root.text !== '' && !(root.dims && root.dims[0] > 0)) out.push({ n: root, clip: c });
    for (const k of root.children) collect(k, out, c);
  }
  function run() {
    if (off || !HB.scene || !HB.game || !HB.game.subContent) return;
    const items = [], whole = { x0: GAP, x1: (HB.size ? HB.size[0] : 768) - GAP };
    collect(HB.game.subContent, items, whole);
    for (const c of HB.scene.children) if (c.z >= 500) collect(c, items, whole);
    // each label at its own (unshrunk) size: world box and where its anchor stands
    for (const it of items) {
      const n = it.n;
      if (n._fitSx !== undefined && n.sx === n._fitSx && n._fitText === n.text) { n.sx = n._fitBase[0]; n.sy = n._fitBase[1]; } // undo our last shrink
      it.base = [n.sx, n.sy];
      const m = n.world();
      if (Math.abs(m[1]) > 0.01 || Math.abs(m[2]) > 0.01 || !(m[0] > 0)) { it.skip = true; continue; } // turned or mirrored text: left alone
      it.x0 = m[4]; it.x1 = m[4] + m[0] * n.w;
      const ya = m[5], yb = m[5] + m[3] * n.h; it.y0 = Math.min(ya, yb); it.y1 = Math.max(ya, yb);
      it.ax = it.x0 + (it.x1 - it.x0) * n.ax;
    }
    const live = items.filter((i) => !i.skip);
    for (const it of live) {
      let k = 1;
      const wl = it.ax - it.x0, wr = it.x1 - it.ax, h = it.y1 - it.y0;
      const limit = (room, part) => { if (part > 0.5 && room < part) k = Math.min(k, Math.max(0, room) / part); };
      limit(it.clip.x1 - it.ax, wr); limit(it.ax - it.clip.x0, wl);
      for (const o of live) {
        if (o === it) continue;
        const over = Math.min(it.y1, o.y1) - Math.max(it.y0, o.y0);
        if (over < Math.min(h, o.y1 - o.y0) * 0.5) continue; // not on the same line
        if (o.x0 > it.ax + 1 && o.x0 < it.x1) limit(o.x0 - GAP - it.ax, wr);       // a label to my right that I run into
        else if (o.x1 < it.ax - 1 && o.x1 > it.x0) limit(it.ax - o.x1 - GAP, wl);  // one to my left
      }
      const n = it.n;
      k = Math.max(MIN, k);
      if (k < 0.995) { n._fitBase = it.base; n.sx = it.base[0] * k; n.sy = it.base[1] * k; n._fitSx = n.sx; n._fitText = n.text; n._fitK = k; }
      else { n._fitSx = undefined; n._fitK = 1; }
    }
    return live;
  }
  HB.fit = {
    run,
    // what is shrunk right now: [text, percent]
    report() { const live = run() || []; return live.filter((i) => i.n._fitK < 0.995).map((i) => [i.n.text, Math.round(i.n._fitK * 100)]); },
  };
  if (!off) setInterval(() => { try { run(); } catch (e) { /* a screen being built */ } }, 400);
})();
