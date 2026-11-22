// Text that fits (ours; owner, 21 Nov 2026: "all text should match the boxes so it looks finished").
// The game's layouts were drawn for short Chinese words; the English ones are often longer and run into the next label or off the
// screen. Twice a second this pass looks at every one-line label of the screen that is showing (and of the windows over it) and
// shrinks a label just enough that it
//   - does not run into another label standing on the same line (4 pixels stay free),
//   - does not run into a small picture (an icon) standing next to it in the same box: the picture has to begin in the label's
//     far part, so a label lying ON its own background or icon is left alone,
//   - stays inside the screen and inside the box that clips it (a list, a window).
// A button's title that a picture lying over the button covers on one side (the "1st Recharge" sticker on Top-up) moves to the
// middle of the free part of the button.
// A label only gives way on the side it grows to (left-aligned text grows right, centred text both ways) and never below 55 % of
// its size. Labels that wrap (a width was given) are left alone: they already break into lines. Rows of a list that are scrolled
// out of sight are skipped (they used to push against the labels above the list), and so are the copies a glowing name is drawn with. `?fit=0` switches the pass off;
// `HB.fit.report()` lists what was shrunk on the screen that is showing (for finding texts worth shortening by hand).
'use strict';
(function () {
  const HB = window.HB;
  const MIN = 0.55, GAP = 4;
  const off = new URLSearchParams(location.search).get('fit') === '0';
  const isLabel = (n) => n instanceof HB.Label || n instanceof HB.BMLabel;
  const box = (n) => { // a node's box on the screen; null when it is turned
    const m = n.world();
    if (Math.abs(m[1]) > 0.01 || Math.abs(m[2]) > 0.01) return null;
    const xa = m[4], xb = m[4] + m[0] * n.w, ya = m[5], yb = m[5] + m[3] * n.h;
    return { x0: Math.min(xa, xb), x1: Math.max(xa, xb), y0: Math.min(ya, yb), y1: Math.max(ya, yb), k: m[0] };
  };

  function collect(root, out, clip, layer) {
    if (!root || !root.visible) return;
    let c = clip;
    // a big layout hung straight onto another layout (Border war's lists and reward windows are children of its screen): a window, its own layer
    if (root.ccbDoc && root.parent && root.parent.ccbDoc && root.w >= 400 && root.h >= 400) layer = layer + '>' + root.parent.children.indexOf(root);
    if (root.clip && root._wm) { const b = box(root); if (b) c = { x0: Math.max(clip.x0, b.x0), x1: Math.min(clip.x1, b.x1), y0: Math.max(clip.y0, b.y0), y1: Math.min(clip.y1, b.y1) }; }
    if (isLabel(root) && root.w > 0 && root.text !== '' && !(root.dims && root.dims[0] > 0)) out.push({ n: root, clip: c, layer });
    // a script screen laid over another one in the same place (Akatsuki > Donate > its card list): each is a layer of its own,
    // the covered screen's labels do not push against the ones on top
    const stack = HB.game && (root === HB.game.activitySubMenu || root === HB.game.activityContent) && root.children.length > 1;
    root.children.forEach((k, i) => collect(k, out, c, stack ? layer + ':' + i : layer));
  }
  // pictures standing in the same box as a label (its brothers), icon-sized
  function icons(n, h) {
    const out = [];
    if (!n.parent) return out;
    for (const s of n.parent.children) {
      if (s === n || !s.visible || !(s instanceof HB.Sprite) || !s.frame || !(s.opacity > 0)) continue;
      const b = box(s);
      if (!b || b.x1 - b.x0 < 6 || b.x1 - b.x0 > 130 || b.y1 - b.y0 > Math.max(h * 3.2, 70)) continue;
      out.push(b);
    }
    return out;
  }
  // a button's title under a picture that lies over one side of the button: the free part of the button, or null
  function freePart(btn) {
    const p = btn.parent, bb = box(btn);
    if (!p || !bb) return null;
    const at = p.children.indexOf(btn);
    let x0 = bb.x0, x1 = bb.x1;
    p.children.forEach((s, i) => {
      if (s === btn || !s.visible || !(s instanceof HB.Sprite) || !s.frame || !(s.opacity > 0)) return;
      if (s.z < btn.z || (s.z === btn.z && i < at)) return; // drawn under the button
      const b = box(s);
      if (!b || Math.min(b.y1, bb.y1) - Math.max(b.y0, bb.y0) < (bb.y1 - bb.y0) * 0.3) return;
      const mid = (bb.x0 + bb.x1) / 2;
      if (b.x0 < bb.x0 + (bb.x1 - bb.x0) * 0.2 && b.x1 > bb.x0 && b.x1 < mid + 1) x0 = Math.max(x0, b.x1 - (b.x1 - b.x0) * 0.08);       // covers the left side
      else if (b.x1 > bb.x1 - (bb.x1 - bb.x0) * 0.2 && b.x0 < bb.x1 && b.x0 > mid - 1) x1 = Math.min(x1, b.x0 + (b.x1 - b.x0) * 0.08);  // the right side
    });
    return x0 > bb.x0 || x1 < bb.x1 ? { x0, x1, edge0: bb.x0, edge1: bb.x1 } : null;
  }
  function run() {
    if (off || !HB.scene || !HB.game || !HB.game.subContent) return;
    const W = HB.size ? HB.size[0] : 768;
    const items = [], whole = { x0: GAP, x1: W - GAP, y0: -1e6, y1: 1e6 };
    // the screen is one layer, every window over it another: a window's labels do not push against the screen's labels under it
    collect(HB.game.subContent, items, whole, 0);
    let layer = 0;
    for (const c of HB.scene.children) if (c.z >= 500) collect(c, items, whole, ++layer);
    // each label at its own (unshrunk) size: world box and where its anchor stands
    for (const it of items) {
      const n = it.n;
      if (n._fitSx !== undefined && n.sx === n._fitSx && n._fitText === n.text) { n.sx = n._fitBase[0]; n.sy = n._fitBase[1]; } // undo our last shrink
      if (n._fitX !== undefined) { if (n.x === n._fitX) n.x = n._fitX0; n._fitX = undefined; }                                    // and our last move
      it.base = [n.sx, n.sy];
      const b = box(n);
      if (!b || !(b.k > 0)) { it.skip = true; continue; } // turned or mirrored text: left alone
      if (b.y1 <= it.clip.y0 + 2 || b.y0 >= it.clip.y1 - 2) { it.skip = true; n._fitK = 1; continue; } // a row scrolled out of sight
      Object.assign(it, b);
      it.ax = it.x0 + (it.x1 - it.x0) * n.ax;
    }
    const live = items.filter((i) => !i.skip);
    for (const it of live) {
      let k = 1;
      const n = it.n, h = it.y1 - it.y0;
      // a button's title beside a picture that covers part of the button
      const free = n.parent instanceof HB.Button && n.parent.label === n ? freePart(n.parent) : null;
      if (free && (it.x0 < free.x0 + GAP || it.x1 > free.x1 - GAP)) {
        const pad = 10, a = free.x0 > free.edge0 ? free.x0 + GAP : free.x0 + pad, z = free.x1 < free.edge1 ? free.x1 - GAP : free.x1 - pad;
        const room = z - a, w = it.x1 - it.x0;
        if (room > 20) {
          k = Math.max(MIN, Math.min(1, room / w));
          const want = (a + z) / 2, shift = (want - it.ax) / (n.parent.world()[0] || 1);
          n._fitX0 = n.x; n.x += shift; n._fitX = n.x;
          if (k < 0.995) { n._fitBase = it.base; n.sx = it.base[0] * k; n.sy = it.base[1] * k; n._fitSx = n.sx; n._fitText = n.text; n._fitK = k; } else { n._fitSx = undefined; n._fitK = 1; }
          continue;
        }
      }
      const wl = it.ax - it.x0, wr = it.x1 - it.ax;
      const limit = (room, part) => { if (part > 0.5 && room < part) k = Math.min(k, Math.max(0, room) / part); };
      limit(it.clip.x1 - it.ax, wr); limit(it.ax - it.clip.x0, wl);
      for (const o of live) {
        if (o === it || o.layer !== it.layer) continue;
        if (o.n.text === n.text && Math.abs(o.x0 - it.x0) < 14 && Math.abs(o.x1 - it.x1) < 14) continue; // copies of one text on top of each other (a glowing name)
        const over = Math.min(it.y1, o.y1) - Math.max(it.y0, o.y0);
        if (over < Math.min(h, o.y1 - o.y0) * 0.5) continue; // not on the same line
        if (o.x0 > it.ax + 1 && o.x0 < it.x1) limit(o.x0 - GAP - it.ax, wr);       // a label to my right that I run into
        else if (o.x1 < it.ax - 1 && o.x1 > it.x0) limit(it.ax - o.x1 - GAP, wl);  // one to my left
      }
      if (!(n.parent instanceof HB.Button)) for (const s of icons(n, h)) {
        const over = Math.min(it.y1, s.y1) - Math.max(it.y0, s.y0);
        if (over < h * 0.5) continue;
        if (s.x0 > it.ax + wr * 0.45 && s.x0 < it.x1 - 2 && s.x1 > it.x1 - 2) limit(s.x0 - 2 - it.ax, wr);       // an icon my far end runs into
        else if (s.x1 < it.ax - wl * 0.45 && s.x1 > it.x0 + 2 && s.x0 < it.x0 + 2) limit(it.ax - s.x1 - 2, wl);
      }
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
