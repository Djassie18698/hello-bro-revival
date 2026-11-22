// Pictures ready before they are needed (owner, 22 Nov 2026: "I see people lagging when they load cards, I don't want that").
// A card's icon, frame and art each live in their own small picture sheet, read from the server the first time a card shows:
// that first time is the lag. This part reads them ahead, quietly, a few at a time while the game is idle:
//   1. as soon as the player's cards are known: the icon and the big art of every card they own, their gear, ninjutsu and seals;
//   2. in the PC program (?pc=1, where every file is on the disk) and on a PC browser: every icon sheet of the game (shinobi,
//      gear, items, ninjutsu, seals; about 30 MB), so shops, rewards, rivals and lists show at once too; phones skip this step
//      to save data (their browser keeps what it has seen).
// Each picture is also decoded ahead (img.decode), so its first drawing costs nothing. `?preload=0` switches it off;
// `HB.preload.state()` says how far it is.
'use strict';
(function () {
  const HB = window.HB;
  const q = new URLSearchParams(location.search);
  if (q.get('preload') === '0') { HB.preload = { state: () => ({ off: true }) }; return; }
  const pc = q.get('pc') === '1' || !/Android|iPhone|iPad|Mobile/i.test(navigator.userAgent);
  const queue = [], seen = new Set();
  let done = 0, running = 0, started = false;
  const add = (sheet, first) => { if (!sheet || seen.has(sheet)) return; seen.add(sheet); if (first) queue.unshift(sheet); else queue.push(sheet); };
  const idle = (fn) => (window.requestIdleCallback ? requestIdleCallback(fn, { timeout: 400 }) : setTimeout(fn, 30));
  async function one(sheet) {
    try {
      const s = await HB.loadSheet(sheet);
      if (s && s.img && s.img.decode) await s.img.decode().catch(() => {});
    } catch (e) { /* a sheet that is not there: nothing to do */ }
    done++;
  }
  // In a browser the files come from the game server, whose flood guard answers 429 after 300 requests in 10 seconds from one
  // address (server.js): read at full speed, 888 of the first 1188 requests were refused, and layouts and pictures the game then
  // asked for stayed missing (empty screens). So outside the PC program (?pc=1 reads its own disk) one sheet starts every 300 ms.
  const paced = q.get('pc') !== '1';
  let nextAt = 0, timer = 0;
  function pump() {
    while (running < (pc ? 6 : 2) && queue.length) {
      if (paced) { const now = Date.now(); if (now < nextAt) { if (!timer) timer = setTimeout(() => { timer = 0; pump(); }, nextAt - now + 5); return; } nextAt = now + 300; }
      const sheet = queue.shift(); running++;
      one(sheet).then(() => { running--; idle(pump); });
    }
  }
  // the sheets of one thing: its icon (and big art) by the frame names data.js uses
  function sheetsOf(index, type, id) {
    const inf = HB.info(type, id), out = [];
    if (!inf.icon) return out;
    const names = type === 1 ? ['icon_' + inf.icon, inf.icon] : type === 5 ? [inf.icon, 'small_' + inf.icon] : ['small_' + inf.icon, 'big_' + inf.icon, inf.icon];
    for (const n of names) if (index[n]) out.push(index[n]);
    return out;
  }
  async function start() {
    if (started) return; started = true;
    const index = HB.frameIndex || (HB.frameIndex = (await HB.json('frames.json')) || {});
    await HB.data.tables();
    // 1. what the player owns, first
    for (const c of HB.data.cards.values()) for (const s of sheetsOf(index, c.type, c.id)) add(s, true);
    // 2. every icon of the game (PC)
    if (pc) {
      const want = /^(icon\/icon_|equip\/small_|props\/|skill\/small_|mark\/small_|ccbResources\/(small|middle)_|com_res\/)/;
      for (const sheet of new Set(Object.values(index))) if (want.test(sheet)) add(sheet);
    }
    pump();
  }
  // cards got later (a recruit, a reward) join the front of the queue
  function refresh() {
    if (!started || !HB.frameIndex) return;
    for (const c of HB.data.cards.values()) for (const s of sheetsOf(HB.frameIndex, c.type, c.id)) add(s, true);
    pump();
  }
  HB.preload = { start, refresh, state: () => ({ done, waiting: queue.length, running, pc }) };
  // begin once the player's cards are there (after login), look again now and then for new cards
  const wait = setInterval(() => { if (HB.data && HB.data.cards && HB.data.cards.size && HB.game && HB.game.subContent) { clearInterval(wait); start(); setInterval(refresh, 5000); } }, 500);
})();
