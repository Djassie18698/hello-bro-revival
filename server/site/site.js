// Ninja Online Reborn home page: fills the line-up, shinobi cards, story chapters and news from home.json (made by tools/build_wiki.js),
// shows the live server status (/status, passed through by Caddy to the game server), and runs the falling petals over the hero.
(() => {
  const $ = (s, el = document) => el.querySelector(s);
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const num = (n) => Number(n).toLocaleString('en-US').replace(/,/g, ' ');
  const wiki = (id) => `/wiki/#/shinobi/${id}`;
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;

  // header gets a background once the page scrolls; the menu button opens the links on small screens
  const top = $('#top');
  const onScroll = () => top.classList.toggle('solid', scrollY > 30);
  addEventListener('scroll', onScroll, { passive: true }); onScroll();
  const menu = $('#menu'), nav = $('#nav');
  const setMenu = (open) => { nav.classList.toggle('open', open); menu.setAttribute('aria-expanded', String(open)); menu.textContent = open ? 'Close' : 'Menu'; };
  menu.addEventListener('click', () => setMenu(!nav.classList.contains('open')));
  nav.addEventListener('click', (e) => { if (e.target.closest('a')) setMenu(false); });
  addEventListener('keydown', (e) => { if (e.key === 'Escape') setMenu(false); });

  // ---- the page's data ----
  fetch('home.json').then((r) => r.json()).then((H) => {
    document.querySelectorAll('[data-count]').forEach((el) => { const v = H.counts[el.dataset.count]; if (v) el.textContent = num(v); });

    $('#lineup').innerHTML = H.hero.map((c, i) => `<a class="char in-${i}" href="${wiki(c.id)}" aria-label="${esc(c.name)}">
      <img src="img/art/${esc(c.art)}.webp" alt="" width="400" height="400"${i === 2 ? ' fetchpriority="high"' : ''}><span>${esc(c.name)}</span></a>`).join('');

    $('#cards').innerHTML = H.featured.map((c) => `<a class="card" data-kind="${esc(c.kind || '')}" href="${wiki(c.id)}">
      <div class="card-in"><div class="card-art">${/\(God\)|God\)$/.test(c.name) ? '<span class="badge">GOD</span>' : ''}
      <img src="img/art/${esc(c.art)}.webp" alt="" loading="lazy" width="400" height="400"></div>
      <div class="card-txt"><h3>${esc(c.name.replace(/\s*\(God\)|\(God\)/, ''))}</h3><div class="stars" aria-label="${c.stars} stars">${'★'.repeat(c.stars)}</div>
      ${c.get && c.get.length ? `<p>Get it: ${c.get.map(esc).join(' · ')}</p>` : ''}</div></div></a>`).join('');

    // story chapters: two rows, scrolled by hand
    const tile = (c) => `<a class="chap" href="/wiki/#/training/${c.id}"><img src="img/ch-${c.id}.webp" alt="" loading="lazy"><span><em>${c.id}</em>${esc(c.name)}</span></a>`;
    const half = Math.ceil(H.chapters.length / 2);
    const rows = [H.chapters.slice(0, half), H.chapters.slice(half)];
    $('#marquee').innerHTML = rows.map((r) => `<div class="track">${r.map(tile).join('')}</div>`).join('');

    $('#newslist').innerHTML = H.news.map((n) => `<li><time>${esc(n.day)}</time><p>${esc(n.text)}</p></li>`).join('');
  }).catch(() => {});

  // ---- live server status (only where Caddy passes /status through: the public site) ----
  const box = $('#status'), txt = $('#status-text');
  const status = () => fetch('/status', { cache: 'no-store' }).then((r) => (r.ok ? r.json() : Promise.reject())).then((s) => {
    if (!s || !s.ok) throw 0;
    box.hidden = false; box.className = 'status on';
    const on = Number(s.online) || 0, all = Number(s.players) || 0;
    txt.innerHTML = `Server online${on ? ` · <b>${num(on)}</b> ${on === 1 ? 'ninja' : 'ninjas'} playing now` : ''}${all ? ` · ${num(all)} ninjas so far` : ''}`;
  }).catch(() => { if (!box.hidden) { box.className = 'status off'; txt.textContent = 'Server offline right now'; } });
  status(); setInterval(() => { if (!document.hidden) status(); }, 60000);

  // ---- shinobi row arrows ----
  document.querySelectorAll('.arrow').forEach((b) => b.addEventListener('click', () => {
    const row = $('#cards'); const step = (row.firstElementChild ? row.firstElementChild.offsetWidth + 18 : 250) * 2;
    row.scrollBy({ left: step * Number(b.dataset.dir), behavior: still ? 'auto' : 'smooth' });
  }));

  // ---- falling leaves and petals over the hero ----
  const cv = $('#fx');
  if (cv && !still && cv.getContext) {
    const g = cv.getContext('2d');
    const colors = ['#ffb3c7', '#ff9a3c', '#ffe3a3', '#ff7aa2', '#9fe0ff'];
    let W = 0, H = 0, bits = [], run = true, raf = 0;
    const size = () => {
      const r = devicePixelRatio || 1; W = cv.clientWidth; H = cv.clientHeight;
      cv.width = W * r; cv.height = H * r; g.setTransform(r, 0, 0, r, 0, 0);
      const n = Math.min(46, Math.round(W / 32));
      bits = Array.from({ length: n }, () => make(true));
    };
    const make = (anywhere) => ({ x: Math.random() * W, y: anywhere ? Math.random() * H : -20, s: 3 + Math.random() * 5, vx: -.25 + Math.random() * .8,
      vy: .35 + Math.random() * .7, a: Math.random() * 6.3, va: -.03 + Math.random() * .06, w: Math.random() * 6.3, c: colors[(Math.random() * colors.length) | 0], o: .45 + Math.random() * .45 });
    const frame = () => {
      g.clearRect(0, 0, W, H);
      for (const b of bits) {
        b.w += .02; b.x += b.vx + Math.sin(b.w) * .5; b.y += b.vy; b.a += b.va;
        if (b.y > H + 20 || b.x < -30 || b.x > W + 30) Object.assign(b, make(false));
        g.save(); g.translate(b.x, b.y); g.rotate(b.a); g.globalAlpha = b.o; g.fillStyle = b.c;
        g.beginPath(); g.ellipse(0, 0, b.s, b.s * .55 * Math.abs(Math.cos(b.w)) + .6, 0, 0, Math.PI * 2); g.fill(); g.restore();
      }
      if (run) raf = requestAnimationFrame(frame);
    };
    const start = () => { if (!raf) { run = true; raf = requestAnimationFrame(frame); } };
    const stop = () => { run = false; cancelAnimationFrame(raf); raf = 0; };
    size(); addEventListener('resize', size);
    if ('IntersectionObserver' in window) new IntersectionObserver(([e]) => (e.isIntersecting ? start() : stop())).observe(cv); else start();
    document.addEventListener('visibilitychange', () => (document.hidden ? stop() : start()));
  }
})();
