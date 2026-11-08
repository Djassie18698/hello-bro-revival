// The live parts of the website, from the game server (server/webapi.js; Caddy passes /api/* to it, tools/vps/wiki-site.sh):
// the top 10 (home page), Today in the game, the players-online graph, and the player pages (/p/<name>, p.html).
// Glowing names look like in the game's No.1 Shinobi list: the colour the server gives, "sparkle" adds twinkling stars.
(() => {
  const $ = (s, el = document) => el.querySelector(s);
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const num = (n) => Number(n || 0).toLocaleString('en-US').replace(/,/g, ' ');
  const rng = (a) => (a && a[0] !== a[1] ? `${num(a[0])}–${num(a[1])}` : num(a && a[0]));
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const api = (p) => fetch('/api/' + p, { cache: 'no-store' }).then((r) => (r.ok ? r.json() : Promise.reject(r.status)));
  const home = fetch('/home.json').then((r) => r.json()).catch(() => null); // the card icon list (wiki icon sheet)
  const playerHref = (n) => '/p/' + encodeURIComponent(n);

  function nameHtml(name, glow) {
    if (!glow) return `<span class="pname">${esc(name)}</span>`;
    return `<span class="pname glow${glow.effect === 'sparkle' ? ' sparkle' : ''}" style="--gc:#${esc(glow.color)}">${esc(name)}</span>`;
  }
  // twinkling stars on "sparkle" names (none with reduced motion: the glow alone stays)
  function sparkle(root) {
    if (still) return;
    root.querySelectorAll('.glow.sparkle').forEach((el) => {
      if (el.querySelector('.spk')) return;
      for (let i = 0; i < 4; i++) {
        const s = document.createElement('i');
        s.className = 'spk'; s.setAttribute('aria-hidden', 'true');
        s.style.left = (8 + Math.random() * 84) + '%'; s.style.top = (10 + Math.random() * 70) + '%';
        s.style.animationDelay = (i * 0.55 + Math.random() * 0.4).toFixed(2) + 's';
        el.appendChild(s);
      }
    });
  }
  function cardIcon(H, id, size, label) {
    const I = H && H.icons, i = I ? I.cards[id] : undefined;
    if (i == null) return `<span class="cic none" style="width:${size}px;height:${size}px" aria-hidden="true"></span>`;
    return `<span class="cic" role="img" aria-label="${esc(label || '')}" style="width:${size}px;height:${size}px;background-image:url(${esc(I.sheet)});` +
      `background-size:${I.cols * size}px ${I.rows * size}px;background-position:-${(i % I.cols) * size}px -${Math.floor(i / I.cols) * size}px"></span>`;
  }
  const starsOf = (n) => (n >= 6 ? '<span class="godtag">GOD</span>' : n > 0 ? `<span class="stars" aria-label="${n} stars">${'★'.repeat(n)}</span>` : '');

  // ---------------------------------------------------------------- home page ----------------------------------------------------------------
  const top10 = $('#top10');
  if (top10) {
    const loadTop = () => api('top').then((d) => {
      top10.innerHTML = d.top.length ? d.top.map((r) => `<li><a href="${playerHref(r.name)}"><span class="rk">${r.rank}</span>${nameHtml(r.name, r.glow)}` +
        `<span class="lv">Lv ${r.level}</span><span class="at" title="Team attack">${rng(r.atk)}</span></a></li>`).join('') : '<li class="wait">No players yet.</li>';
      sparkle(top10);
    }).catch(() => { if (top10.querySelector('.wait')) top10.innerHTML = '<li class="wait">The list shows up when the server is online.</li>'; });

    // Today in the game: game times are on the server's clock; show the visitor's own time next to them when it differs
    const todayBox = $('#today-in');
    const loadToday = () => Promise.all([api('today'), home]).then(([t, H]) => {
      const mine = -new Date().getTimezoneOffset(), shift = (mine - t.offset) / 60;
      const hh = (h) => { const x = ((h + shift) % 24 + 24) % 24; return String(Math.floor(x)).padStart(2, '0') + ':' + (x % 1 ? '30' : '00'); };
      const sv = (h) => String(h % 24).padStart(2, '0') + ':00';
      const both = (a, b) => (shift ? `${sv(a)}–${sv(b)} <small>(${hh(a)}–${hh(b)} your time)</small>` : `${sv(a)}–${sv(b)}`);
      const until = t.god ? new Date(t.god.until * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '';
      const god = t.god && t.superNinja
        ? `<div class="t-god">${cardIcon(H, t.god.id, 64, t.god.name)}<div><span class="t-lbl">God card of the hour</span>` +
          `<a href="/wiki/#/shinobi/${t.god.id}">${esc(t.god.name.replace(/\s*\(God\)$/, ''))}</a>` +
          `<small>Limited Super Ninja on Home, until ${esc(until)}${t.next.length ? ' · next: ' + t.next.map((g) => esc(g.name.replace(/\s*\(God\)$/, ''))).join(', ') : ''}</small></div></div>`
        : '<p class="t-off">Limited Super Ninja is switched off right now.</p>';
      todayBox.innerHTML = god +
        `<ul class="t-times"><li><span class="t-lbl">Free ramen</span>${t.ramen.map(([a, b]) => both(a, b)).join(' and ')}</li>` +
        `<li><span class="t-lbl">Energy refills</span>at ${sv(t.energyRefill)}${shift ? ` <small>(${hh(t.energyRefill)} your time)</small>` : ''}</li></ul>` +
        `<p class="t-ev"><span class="t-lbl">Events running now</span>${t.running.length ? t.running.map(esc).join(', ') : 'Only the everyday ones.'}</p>` +
        (t.off.length ? `<p class="t-ev"><span class="t-lbl">Switched off</span>${t.off.map(esc).join(', ')}</p>` : '') +
        `<p class="t-tz">Times are the server's clock (UTC${t.offset >= 0 ? '+' : '−'}${Math.abs(t.offset / 60)}).</p>`;
    }).catch(() => { todayBox.innerHTML = '<p class="wait">Shows up when the server is online.</p>'; });

    // players online: a line for the last 24 hours or 7 days (logged every 5 minutes since 8 Nov 2026)
    const graph = $('#graph'), box = $('#graph-box');
    let days = 1;
    const draw = (d) => {
      const pts = d.points;
      if (pts.length < 2) { graph.hidden = false; box.innerHTML = '<p class="wait">Not enough data yet: the server counts every 5 minutes.</p>'; return; }
      const W = 600, Hh = 190, L = 30, R = 8, T = 12, B = 24;
      const t1 = Math.floor(Date.now() / 1000), t0 = t1 - days * 86400;
      const max = Math.max(3, ...pts.map((p) => p[1]));
      const x = (t) => L + (t - t0) / (t1 - t0) * (W - L - R), y = (v) => T + (1 - v / max) * (Hh - T - B);
      let line = '', area = '', run = [];
      const flush = () => {
        if (!run.length) return;
        line += 'M' + run.map((p) => `${x(p[0]).toFixed(1)},${y(p[1]).toFixed(1)}`).join('L');
        area += `M${x(run[0][0]).toFixed(1)},${y(0)}L` + run.map((p) => `${x(p[0]).toFixed(1)},${y(p[1]).toFixed(1)}`).join('L') + `L${x(run[run.length - 1][0]).toFixed(1)},${y(0)}Z`;
        run = [];
      };
      pts.forEach((p, i) => { if (i && p[0] - pts[i - 1][0] > d.step * 3) flush(); run.push(p); }); // a gap = the server was off
      flush();
      let ticks = '';
      const day0 = new Date(t0 * 1000); day0.setMinutes(0, 0, 0);
      for (let t = Math.floor(day0.getTime() / 1000); t <= t1; t += 3600) {
        const dt = new Date(t * 1000), h = dt.getHours();
        const show = days === 1 ? h % 6 === 0 : h === 0;
        if (!show || t < t0) continue;
        const lbl = days === 1 ? String(h).padStart(2, '0') + ':00' : dt.toLocaleDateString([], { weekday: 'short' });
        ticks += `<line x1="${x(t).toFixed(1)}" x2="${x(t).toFixed(1)}" y1="${T}" y2="${Hh - B}" class="g-grid"/><text x="${x(t).toFixed(1)}" y="${Hh - 6}" class="g-x">${lbl}</text>`;
      }
      const peak = Math.max(...pts.map((p) => p[1])), nowV = pts[pts.length - 1][1];
      box.innerHTML = `<svg viewBox="0 0 ${W} ${Hh}" role="img" aria-label="Players online: ${nowV} now, at most ${peak} in this time"><title>Players online</title>` +
        `<line x1="${L}" x2="${W - R}" y1="${y(0)}" y2="${y(0)}" class="g-base"/><line x1="${L}" x2="${W - R}" y1="${y(max)}" y2="${y(max)}" class="g-grid"/>` +
        `<text x="${L - 6}" y="${y(max) + 4}" class="g-y">${max}</text><text x="${L - 6}" y="${y(0) + 4}" class="g-y">0</text>${ticks}` +
        `<path d="${area}" class="g-area"/><path d="${line}" class="g-line"/></svg>` +
        `<p class="g-note"><b>${nowV}</b> online now · most in this time: <b>${peak}</b></p>`;
      graph.hidden = false;
    };
    const loadGraph = () => api('online?days=' + days).then(draw).catch(() => {});
    graph.querySelectorAll('[data-days]').forEach((b) => b.addEventListener('click', () => {
      days = Number(b.dataset.days);
      graph.querySelectorAll('[data-days]').forEach((o) => o.setAttribute('aria-pressed', String(o === b)));
      loadGraph();
    }));

    const all = () => { loadTop(); loadToday(); loadGraph(); };
    all();
    setInterval(() => { if (!document.hidden) all(); }, 60000);
  }

  // --------------------------------------------------------------- player page ---------------------------------------------------------------
  const page = $('#player');
  if (page) {
    const fromPath = location.pathname.indexOf('/p/') === 0 ? decodeURIComponent(location.pathname.slice(3).replace(/\/$/, '')) : '';
    const name = fromPath || new URLSearchParams(location.search).get('name') || '';
    if (!name) { page.innerHTML = '<p class="wait">Pick a player from the <a href="/#live">top players</a>.</p>'; return; }
    Promise.all([api('player?name=' + encodeURIComponent(name)), home]).then(([p, H]) => {
      document.title = `${p.name} · Ninja Online Reborn`;
      page.innerHTML = `<header class="p-head">
          <h1>${nameHtml(p.name, p.glow)}</h1>
          <p class="p-meta"><img class="vipb" src="/img/ui/vip-${Number(p.vip) || 0}.webp" alt="VIP ${Number(p.vip) || 0}" width="66" height="33">
            <span>Level <b>${p.level}</b></span>${p.rank ? `<span>No. <b>${p.rank}</b> in the No.1 Shinobi list</span>` : ''}</p>
        </header>
        <div class="p-stats"><div><span class="t-lbl">Team attack</span><b>${rng(p.atk)}</b></div><div><span class="t-lbl">Team defence</span><b>${rng(p.def)}</b></div></div>
        <section class="p-from" aria-labelledby="pf-title">
          <div class="pf-head"><h2 id="pf-title">Where the power comes from</h2>
            <div class="graph-tabs" role="group" aria-label="Attack or defence"><button type="button" data-side="atk" aria-pressed="true">Attack</button><button type="button" data-side="def" aria-pressed="false">Defence</button></div></div>
          <div id="pf-body"></div>
        </section>
        <h2>Team</h2>
        <ul class="p-team">${p.team.map((c) => `<li><a href="/wiki/#/shinobi/${c.id}">${cardIcon(H, c.id, 80, c.name)}
          <span class="c-name">${esc(c.name.replace(/\s*\(God\)$/, ''))}</span>${starsOf(c.stars)}
          <span class="c-line">Lv ${c.level}${c.breakthrough ? ` · <b>+${c.breakthrough}</b>` : ''}${c.growth ? ` · growth ${c.growth}` : ''}${c.rebirth ? ` · rebirth ${c.rebirth}` : ''}</span>
          <span class="c-line">ATK ${rng(c.atk)}</span></a>${c.chains && c.chains.length ? `<details class="c-ch"><summary>${c.chains.length} chain${c.chains.length > 1 ? 's' : ''} on</summary><ul>${c.chains.map((t) => `<li>${esc(t)}</li>`).join('')}</ul></details>` : ''}</li>`).join('')}</ul>`;
      // the breakdown: the parts add up to the team number above (server/webapi.js breakdown)
      const COLORS = { level: '#ffd23f', rebirth: '#ff8a1f', breakthrough: '#ff5f7e', growth: '#7ad36b', training: '#a9b8d8', gear: '#4fb3ff', seals: '#b884ff',
        ninjutsu: '#2fd3c7', sets: '#6f8dff', chains: '#ffb0c8', cardsets: '#f6a35c', gates: '#e8e05a', title: '#c9a227', pets: '#5ce0a0', other: '#888' };
      const body = $('#pf-body');
      const show = (side) => {
        const parts = (p.from && p.from[side] || []).slice().sort((a, b) => (b.v[0] + b.v[1]) - (a.v[0] + a.v[1]));
        const all = parts.reduce((t, x) => t + x.v[0] + x.v[1], 0) || 1;
        const pct = (x) => (x.v[0] + x.v[1]) / all * 100;
        body.innerHTML = `<div class="pf-bar" role="img" aria-label="${side === 'atk' ? 'Attack' : 'Defence'} split">${parts.map((x) => `<span style="width:${pct(x).toFixed(2)}%;background:${COLORS[x.key] || '#888'}" title="${esc(x.label)}"></span>`).join('')}</div>
          <ol class="pf-list">${parts.map((x) => `<li><i style="background:${COLORS[x.key] || '#888'}" aria-hidden="true"></i><span class="pf-l">${esc(x.label)}${x.key === 'gates' && p.gates ? ` <small>(${p.gates} points opened)</small>` : ''}</span>
            <span class="pf-v">+${rng(x.v)}</span><span class="pf-p">${pct(x) < 1 ? '<1' : Math.round(pct(x))}%</span></li>`).join('')}
            <li class="pf-tot"><i aria-hidden="true"></i><span class="pf-l">Total</span><span class="pf-v">${rng(p[side])}</span><span class="pf-p">100%</span></li></ol>`;
      };
      page.querySelectorAll('[data-side]').forEach((b) => b.addEventListener('click', () => {
        page.querySelectorAll('[data-side]').forEach((o) => o.setAttribute('aria-pressed', String(o === b))); show(b.dataset.side);
      }));
      show('atk');
      sparkle(page);
    }).catch((e) => {
      page.innerHTML = e === 404
        ? `<h1>No player called “${esc(name)}”</h1><p class="wait">Check the spelling, or pick a name from the <a href="/#live">top players</a>.</p>`
        : '<p class="wait">The server does not answer right now. Try again in a minute.</p>';
    });
  }
})();
