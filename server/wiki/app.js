// Ninja Online Wiki: one page, hash routes (#/shinobi/2106), all data from data.json (made by tools/build_wiki.js from the game's tables).
(() => {
  'use strict';
  const $ = (s, el = document) => el.querySelector(s);
  // on https://ninjaonlinereborn.com the wiki sits under the home page (/wiki/); a game server's own /wiki/ (:18080) has no home page
  if (!location.port && location.pathname.indexOf('/wiki/') === 0) document.getElementById('homelink').hidden = false;
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const fmt = (n) => Number(n || 0).toLocaleString('en-US');
  let D = null;
  const by = {};

  // ---- small pieces ------------------------------------------------------------------------------------------------------------
  function icon(ref, size = 40, title = '') {
    const t = title ? ` title="${esc(title)}"` : '';
    if (!ref) return `<span class="ic none" style="width:${size}px;height:${size}px"${t}></span>`;
    const [k, n] = ref.split(':');
    const sh = D.icons.sheets[k], cols = D.icons.cols, i = Number(n);
    if (!sh) return `<span class="ic none" style="width:${size}px;height:${size}px"${t}></span>`;
    return `<span class="ic" role="img" aria-label="${esc(title)}" style="width:${size}px;height:${size}px;background-image:url(img/${sh.file});` +
      `background-size:${cols * size}px ${sh.rows * size}px;background-position:-${(i % cols) * size}px -${Math.floor(i / cols) * size}px"${t}></span>`;
  }
  const stars = (n) => (n >= 6 ? '<span class="god">GOD</span>' : n > 0 ? `<span class="stars" aria-label="${n} stars">${'★'.repeat(n)}</span>` : '');
  const range = (a) => (a && (a[0] || a[1]) ? (a[0] === a[1] ? fmt(a[0]) : `${fmt(a[0])}-${fmt(a[1])}`) : '0');
  const KIND = {
    shinobi: { path: 'shinobi', label: 'Shinobi', one: 'shinobi' },
    gear: { path: 'gear', label: 'Gear', one: 'gear' },
    jutsu: { path: 'ninjutsu', label: 'Ninjutsu', one: 'ninjutsu' },
    seals: { path: 'seals', label: 'Seals', one: 'seal' },
    pets: { path: 'pets', label: 'Pets', one: 'pet' },
    items: { path: 'items', label: 'Items', one: 'item' },
  };
  const WHAT = { card: 'shinobi', gear: 'gear', jutsu: 'jutsu', seal: 'seals', item: 'items', pet: 'pets', fragment: 'shinobi' };
  const href = (kind, id) => `#/${KIND[kind].path}/${id}`;
  function chip(kind, id) {
    const e = by[kind] && by[kind].get(id);
    if (!e) return '';
    return `<a class="chip" href="${href(kind, id)}">${icon(e.icon, 26, e.name)}${esc(e.name)}${e.stars >= 6 ? ' <span class="god">GOD</span>' : ''}</a>`;
  }
  const pctTxt = (o) => [o.atk && `ATK +${o.atk}%`, o.def && `DEF +${o.def}%`, o.ckr && `Chakra +${o.ckr}%`].filter(Boolean).join(', ');
  function inline(s) {
    return esc(s)
      .replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\[\[g:([a-z-]+)\]\]/g, (m, f) => `<a href="#/guides/${f}">${esc(GROUPS[f] || f)}</a>`)
      .replace(/(^|[\s(])(https?:\/\/[^\s<)]+)/g, '$1<a href="$2" target="_blank" rel="noopener">$2</a>');
  }
  function md(text) {
    const out = [];
    let list = null, para = [];
    const flushP = () => { if (para.length) { out.push(`<p>${para.map(inline).join('<br>')}</p>`); para = []; } };
    const flushL = () => { if (list) { out.push(`<${list.tag}>${list.items.map((i) => `<li>${inline(i)}</li>`).join('')}</${list.tag}>`); list = null; } };
    for (const raw of String(text).split('\n')) {
      const line = raw.trim();
      const ul = /^(?:•|-|\*)\s+(.*)$/.exec(line), ol = /^\d+[.)]\s+(.*)$/.exec(line);
      if (!line) { flushP(); flushL(); continue; }
      if (ul || ol) {
        flushP();
        const tag = ul ? 'ul' : 'ol';
        if (!list || list.tag !== tag) { flushL(); list = { tag, items: [] }; }
        list.items.push((ul || ol)[1]);
        continue;
      }
      if (/^#{1,4}\s/.test(line)) { flushP(); flushL(); out.push(`<h3>${inline(line.replace(/^#+\s*/, ''))}</h3>`); continue; }
      flushL();
      para.push(line);
    }
    flushP(); flushL();
    return out.join('');
  }
  const GROUPS = { 'how-to-play': 'How to play', 'install-help': 'Install and connect', faq: 'Questions' };
  const crumbs = (...parts) => `<div class="crumbs"><a href="#/">Wiki</a>${parts.map((p) => `<span>›</span>${p}`).join('')}</div>`;
  const ways = (list) => (list && list.length ? `<div class="ways">${list.map((w) => {
    const [where, link] = String(w.where || '').split('|');
    const m = link && /^round:(\d+)$/.exec(link);
    const to = m && roundHref(Number(m[1]));
    return `<div class="way"><b>${esc(w.how)}</b><span>${esc(where)}${to ? ` · <a href="${to}">see the stage</a>` : ''}</span></div>`;
  }).join('')}</div>` : '<p class="note">No way to get it is known on this server (it may have come from an event of the original game).</p>');
  const sources = (e) => [...new Set((e.get || []).map((w) => w.how.replace(/ \(.*$/, '')))].join(' · ');

  // ---- icons for the side menu ------------------------------------------------------------------------------------------------
  const SVG = {
    home: '<path d="M3 11l9-7 9 7v9H5v-9"/><path d="M10 20v-6h4v6"/>',
    shinobi: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-5 5-7 8-7s7 2 8 7"/><path d="M8 7h8"/>',
    gear: '<path d="M14 4l6 6-9 9-3-3-3 3-1-1 3-3-3-3 9-9z"/>',
    jutsu: '<path d="M12 3c3 4 5 6 5 10a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-4-1-6 1-9z"/>',
    seals: '<circle cx="12" cy="12" r="8"/><path d="M12 7v10M7 12h10"/>',
    pets: '<circle cx="7" cy="9" r="2"/><circle cx="17" cy="9" r="2"/><circle cx="10" cy="5" r="1.6"/><circle cx="14" cy="5" r="1.6"/><path d="M8 17c0-3 2-5 4-5s4 2 4 5-2 3-4 3-4 0-4-3z"/>',
    items: '<path d="M6 8h12l-1 12H7L6 8z"/><path d="M9 8V6a3 3 0 016 0v2"/>',
    sets: '<rect x="4" y="4" width="7" height="7" rx="1"/><rect x="13" y="4" width="7" height="7" rx="1"/><rect x="4" y="13" width="7" height="7" rx="1"/><rect x="13" y="13" width="7" height="7" rx="1"/>',
    training: '<path d="M4 20l6-14 4 8 2-4 4 10H4z"/>',
    book: '<path d="M4 5a2 2 0 012-2h13v16H6a2 2 0 00-2 2V5z"/><path d="M4 19a2 2 0 012-2h13"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 015 0c0 2-2.5 2-2.5 4"/><path d="M12 17h.01"/>',
    down: '<path d="M12 4v12M7 11l5 5 5-5"/><path d="M5 20h14"/>',
    calc: '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 7h8M8 12h2M12 12h2M16 12h0M8 16h2M12 16h2M16 16h0"/>',
  };
  const ico = (k) => `<svg viewBox="0 0 24 24" aria-hidden="true">${SVG[k] || SVG.book}</svg>`;

  function sideMenu(active) {
    const main = [['', 'home', 'Main page'], ['shinobi', 'shinobi', 'Shinobi'], ['gear', 'gear', 'Gear'], ['ninjutsu', 'jutsu', 'Ninjutsu'], ['seals', 'seals', 'Seals'],
      ['pets', 'pets', 'Pets'], ['items', 'items', 'Items'], ['sets', 'sets', 'Sets'], ['training', 'training', 'Training'], ['calculator', 'calc', 'Team calculator']];
    const g = (file, icon) => D.guides.filter((x) => x.file === file).map((x) => `<a class="${active === 'guide/' + x.slug ? 'on' : ''}" href="#/guide/${x.slug}">${ico(icon)}${esc(x.title)}</a>`).join('');
    $('#side').innerHTML = '<h4>The scroll</h4>' + main.map(([p, k, t]) => `<a class="${active.split('/')[0] === p ? 'on' : ''}" href="#/${p}">${ico(k)}${t}</a>`).join('') +
      '<h4>Getting started</h4>' + g('install-help', 'down') + '<h4>How to play</h4>' + g('how-to-play', 'book') + '<h4>Questions</h4>' + g('faq', 'help');
  }
  function tabs(active) {
    const t = [['', 'Main page'], ['shinobi', 'Shinobi'], ['gear', 'Gear'], ['ninjutsu', 'Ninjutsu'], ['seals', 'Seals'], ['training', 'Training'], ['calculator', 'Calculator'], ['guides', 'How to play']];
    const top = active.split('/')[0];
    $('#tabs').innerHTML = t.map(([p, l]) => `<a class="${top === p || (p === 'guides' && top === 'guide') ? 'on' : ''}" href="#/${p}">${l}</a>`).join('');
  }

  // ---- home -------------------------------------------------------------------------------------------------------------------
  function home() {
    const gods = [5061, 5040, 2106, 5010, 2029].map((id) => by.shinobi.get(id)).filter(Boolean);
    const roofs = '<svg class="roofs" viewBox="0 0 400 170" preserveAspectRatio="none" aria-hidden="true"><path fill="rgba(40,22,12,.55)" d="M0 120 L30 96 L60 120 L60 170 L0 170Z M70 110 L120 70 L170 110 L160 110 L160 170 L80 170 L80 110Z M180 125 L215 100 L250 125 L250 170 L180 170Z M260 100 L310 58 L360 100 L350 100 L350 170 L270 170 L270 100Z M360 128 L385 110 L400 122 L400 170 L360 170Z"/><path fill="rgba(25,12,6,.85)" d="M0 150 Q100 132 200 148 T400 142 L400 170 L0 170Z"/></svg>';
    const news = D.news.slice(0, 2).map((n) => `<div><p><b>${esc(n.day)}:</b> ${esc(n.text.length > 190 ? n.text.slice(0, 187).replace(/\s+\S*$/, '') + '...' : n.text)}</p><a href="https://github.com/Djassie18698/hello-bro-revival#-what-changed-recently" target="_blank" rel="noopener">All changes →</a></div>`).join('');
    const rounds = D.chapters.reduce((a, c) => a + c.parts.reduce((b, p) => b + p.rounds.length, 0), 0);
    const look = [
      ['shinobi', 'shinobi', 'Shinobi', 'Every card, where to get it, its stats and every chain it has.', `${D.shinobi.length} cards`],
      ['gear', 'gear', 'Gear', 'Weapons, armour and trinkets, with their sets and which ninja they combo with.', `${D.gear.length} pieces`],
      ['ninjutsu', 'jutsu', 'Ninjutsu', 'Trigger chance, damage, who has it built in.', `${D.jutsu.length} ninjutsu`],
      ['seals', 'seals', 'Seals', 'The tailed-beast seals and their fragments from Plunder.', `${D.seals.filter((s) => !s.fragment).length} seals`],
      ['training', 'training', 'Training', 'Every chapter and stage: energy, EXP, silver, enemies and boss rewards.', `${rounds} stages`],
      ['guides', 'book', 'How to play', 'Installing, connecting, and how everything in the game works.', `${D.guides.length} guides`],
      ['calculator', 'calc', 'Team calculator', 'Pick cards, gear, seals and ninjutsu: see attack, defence and which chains turn on.', 'try a team'],
    ].map(([p, k, t, d, n]) => `<a class="box" href="#/${p}"><h3>${ico(k)}${t}</h3><p>${d}</p><small>${n} →</small></a>`).join('');
    const quick = D.guides.slice(0, 10).map((g) => `<li><a href="#/guide/${g.slug}"><span>${esc(g.title)}</span><span aria-hidden="true">›</span></a></li>`).join('');
    return crumbs('Main page') +
      `<section class="box hero"><div class="lead" style="border-top:0"><div class="kicker">Ninja Online wiki</div><h1>Where is everything?</h1>
        <p class="intro">Every shinobi, piece of gear, ninjutsu, seal and training stage in the game, where to find it and how it works on the revival servers. Something wrong? Tell us on Discord.</p>
        <div class="btns"><a class="btn main" href="#/shinobi">Find a shinobi →</a><a class="btn" href="#/guides/install-help">Start playing</a></div></div>
        <div class="art"><div class="sun"></div>${roofs}<div class="fan">${gods.map((g) => `<a href="${href('shinobi', g.id)}" aria-label="${esc(g.name)}">${icon(g.icon, 76, g.name)}</a>`).join('')}</div></div></section>` +
      `<div class="box strip">${news}<div><p><b>${D.shinobi.length} shinobi, ${D.gear.length} gear, ${D.jutsu.length} ninjutsu, ${rounds} stages.</b> Taken straight from the game's own data (built ${esc(D.built)}).</p><a href="#/guides/how-to-play">How to play →</a></div></div>` +
      `<h2>Look something up</h2><div class="cards">${look}</div>` +
      `<h2>Quick answers</h2><ul class="quick">${quick}</ul>`;
  }

  // ---- generic list --------------------------------------------------------------------------------------------------------------
  const listState = {};
  function listPage(key, cfg) {
    const st = listState[key] || (listState[key] = {});
    const filters = cfg.filters.map((f) => {
      const v = st[f.id] || '';
      if (f.type === 'text') return `<label>${f.label}<input data-f="${f.id}" type="search" value="${esc(v)}" placeholder="${esc(f.ph || '')}"></label>`;
      return `<label>${f.label}<select data-f="${f.id}">${f.options.map(([val, txt]) => `<option value="${esc(val)}"${String(val) === String(v) ? ' selected' : ''}>${esc(txt)}</option>`).join('')}</select></label>`;
    }).join('');
    setTimeout(() => {
      const draw = () => {
        const shown = cfg.items.filter((e) => cfg.filters.every((f) => !st[f.id] || f.test(e, st[f.id])));
        $('#count').textContent = `${shown.length} of ${cfg.items.length}`;
        $('#list').innerHTML = shown.length ? shown.map(cfg.row).join('') : '<div class="empty">Nothing matches. Try fewer filters.</div>';
      };
      document.querySelectorAll('[data-f]').forEach((el) => el.addEventListener('input', () => { st[el.dataset.f] = el.value; draw(); }));
      draw();
    });
    return crumbs(cfg.title) + `<section class="box"><div class="lead"><div class="kicker">${cfg.kicker}</div><h1>${cfg.h1}</h1><p class="intro">${cfg.intro}</p><span class="count" id="count"></span></div>
      <div class="filters">${filters}</div><div class="list" id="list"></div></section>`;
  }
  const nameTest = (e, v) => v.toLowerCase().split(/\s+/).every((w) => e.name.toLowerCase().includes(w));
  const starOpts = (max = 5, god = false) => [['', 'Any']].concat([...Array(max)].map((_, i) => [String(i + 1), '★'.repeat(i + 1)])).concat(god ? [['6', 'God']] : []);

  function shinobiList() {
    const how = [...new Set(D.shinobi.flatMap((c) => (c.get || []).map((w) => w.how.replace(/ \(.*$/, ''))))].sort();
    return listPage('shinobi', {
      title: 'Shinobi', kicker: 'Card list', h1: 'Every shinobi', items: D.shinobi,
      intro: 'Every shinobi card in the game: stars, attack or defence type, and where to get it. Click one for its stats and chains. Most cards come in an attack and a defence version.',
      filters: [
        { id: 'q', label: 'Name', type: 'text', ph: 'e.g. Madara', test: nameTest },
        { id: 's', label: 'Stars', options: starOpts(5, true), test: (e, v) => String(e.stars) === v },
        { id: 'k', label: 'Type', options: [['', 'Any'], ['Attack', 'Attack'], ['Defence', 'Defence'], ['Balanced', 'Balanced (god cards)']], test: (e, v) => e.kind === v },
        { id: 'h', label: 'How to get it', options: [['', 'Any way']].concat(how.map((h) => [h, h])).concat([['-', 'Unknown']]), test: (e, v) => (v === '-' ? !(e.get || []).length : (e.get || []).some((w) => w.how.startsWith(v))) },
      ],
      row: (c) => `<a class="row" href="${href('shinobi', c.id)}">${icon(c.icon, 44, c.name)}<span class="nm">${esc(c.name)}<small>${c.kind} type</small></span><span>${stars(c.stars)}</span><span class="meta">${esc(sources(c)) || '—'}</span></a>`,
    });
  }
  function gearList() {
    return listPage('gear', {
      title: 'Gear', kicker: 'Equipment', h1: 'Every piece of gear', items: D.gear,
      intro: 'Weapons, armour and trinkets. Many are a ninja\'s own gear: worn by that ninja they add a chain bonus, and some make a set together.',
      filters: [
        { id: 'q', label: 'Name', type: 'text', ph: 'e.g. Samehada', test: nameTest },
        { id: 'slot', label: 'Slot', options: [['', 'Any'], ['Weapon', 'Weapon'], ['Armour', 'Armour'], ['Trinket', 'Trinket']], test: (e, v) => e.slot === v },
        { id: 's', label: 'Stars', options: starOpts(5), test: (e, v) => String(e.stars) === v },
      ],
      row: (g) => `<a class="row" href="${href('gear', g.id)}">${icon(g.icon, 44, g.name)}<span class="nm">${esc(g.name)}<small>ATK ${range(g.atk)} · DEF ${range(g.def)}</small></span><span><span class="tag ${g.slot}">${g.slot}</span> ${stars(g.stars)}</span><span class="meta">${esc(sources(g)) || '—'}</span></a>`,
    });
  }
  function jutsuList() {
    return listPage('jutsu', {
      title: 'Ninjutsu', kicker: 'Ninjutsu cards', h1: 'Every ninjutsu', items: D.jutsu,
      intro: 'Equip ninjutsu cards to your ninja. In a fight each one may trigger and hit for chakra damage. The trigger chance comes from the game\'s own table.',
      filters: [
        { id: 'q', label: 'Name', type: 'text', ph: 'e.g. Rasengan', test: nameTest },
        { id: 's', label: 'Stars', options: starOpts(5), test: (e, v) => String(e.stars) === v },
      ],
      row: (j) => `<a class="row" href="${href('jutsu', j.id)}">${icon(j.icon, 44, j.name)}<span class="nm">${esc(j.name)}<small>${j.rate ? `Trigger ${j.rate}%` : ''}${j.damage ? ` · damage ${fmt(j.damage)}` : ''}</small></span><span>${stars(j.stars)}${j.special ? ' <span class="tag special">special</span>' : ''}</span><span class="meta">${esc(sources(j)) || '—'}</span></a>`,
    });
  }
  function sealList() {
    return listPage('seals', {
      title: 'Seals', kicker: 'Tailed-beast seals', h1: 'Seals and their fragments', items: D.seals,
      intro: 'Every tailed-beast seal is made from 8 fragments, which you win from other players with Plunder (Spar > Plunder). A seal is worn in the fourth gear slot.',
      filters: [
        { id: 'q', label: 'Name', type: 'text', ph: 'e.g. Kurama', test: nameTest },
        { id: 'f', label: 'Kind', options: [['', 'Seals and fragments'], ['seal', 'Seals'], ['frag', 'Fragments']], test: (e, v) => (v === 'frag' ? !!e.fragment : !e.fragment) },
      ],
      row: (s) => `<a class="row" href="${href('seals', s.id)}">${icon(s.icon, 44, s.name)}<span class="nm">${esc(s.name)}<small>${esc(s.effect || '')}</small></span><span>${stars(s.stars)}</span><span class="meta">${esc(sources(s)) || '—'}</span></a>`,
    });
  }
  function petList() {
    return listPage('pets', {
      title: 'Pets', kicker: 'Summons', h1: 'Every pet', items: D.pets,
      intro: 'Pets open at level 150 (Base > Pets). Collect 30 fragments of one (mystery shop) and merge them in Backpack > Fragments.',
      filters: [{ id: 'q', label: 'Name', type: 'text', ph: 'e.g. Gamakichi', test: nameTest }],
      row: (p) => `<a class="row" href="${href('pets', p.id)}">${icon(p.icon, 44, p.name)}<span class="nm">${esc(p.name)}<small>${esc(p.skill || '')}</small></span><span>${stars(p.stars)}</span><span class="meta">${esc(sources(p)) || '—'}</span></a>`,
    });
  }
  function itemList() {
    return listPage('items', {
      title: 'Items', kicker: 'Backpack items', h1: 'Every item', items: D.items,
      intro: 'Ramen, pills, keys, stones and everything else in the Backpack, with its Shop price.',
      filters: [
        { id: 'q', label: 'Name', type: 'text', ph: 'e.g. Ramen', test: nameTest },
        { id: 'shop', label: 'Shop', options: [['', 'All items'], ['y', 'Sold in the Shop'], ['n', 'Not in the Shop']], test: (e, v) => (v === 'y' ? !!(e.gold || e.silver) : !(e.gold || e.silver)) },
      ],
      row: (i) => `<a class="row" href="${href('items', i.id)}">${icon(i.icon, 44, i.name)}<span class="nm">${esc(i.name)}<small>${esc((i.desc || '').slice(0, 90))}</small></span><span>${i.gold ? fmt(i.gold) + ' gold' : i.silver ? fmt(i.silver) + ' silver' : ''}</span><span class="meta">${esc(sources(i)) || '—'}</span></a>`,
    });
  }

  // ---- detail pages ------------------------------------------------------------------------------------------------------------
  const head = (e, kind, tags, extra = '') => `<div class="head">${icon(e.icon, 96, e.name)}<div><div class="num">${KIND[kind].label.toUpperCase()} #${e.id}</div><h1>${esc(e.name)}</h1><div class="tags">${tags}</div>${extra}</div></div>`;
  function statGrid(e, levels = 50) {
    const g = e.grow || {};
    const cell = (label, base, gr) => {
      const at = base && gr ? [base[0] + gr[0] * (levels - 1), base[1] + gr[1] * (levels - 1)] : base;
      return `<div class="stat"><small>${label}</small><b>${range(base)}</b><span>+${range(gr)} a level · ${range(at)} at level ${levels}</span></div>`;
    };
    return `<div class="statgrid">${cell('Attack', e.atk, g.atk)}${cell('Defence', e.def, g.def)}${cell('Chakra', e.ckr, g.ckr)}</div><p class="note">Level 1 numbers (min-max) from the game's own table, before gear, training, growth and reincarnation.</p>`;
  }
  function chainBox(ch) {
    const groups = (ch.partners || []).map((ids) => `<div class="chips">${ids.map((id) => chip('shinobi', id)).join('')}</div>`).join(ch.any ? '<p class="note" style="margin:6px 0 0">or</p>' : '');
    const extra = [ch.gear ? chip('gear', ch.gear) : '', ch.jutsu ? chip('jutsu', ch.jutsu) : ''].filter(Boolean).join('');
    return `<div class="chain"><div class="top2"><span>${ch.team ? '<span class="tag team">whole team</span> ' : ''}${esc(ch.text)}</span><span class="boost">${esc(pctTxt(ch))}</span></div>${groups}${extra ? `<div class="chips">${extra}</div>` : ''}</div>`;
  }
  function shinobiPage(id) {
    const c = by.shinobi.get(id);
    if (!c) return notFound();
    const other = D.shinobi.filter((x) => x.name === c.name && x.id !== c.id);
    const tags = `${stars(c.stars)} <span class="tag ${c.kind}">${c.kind}</span>`;
    const quote = c.quote ? `<p class="quote">“${esc(c.quote)}”</p>` : '';
    const partOf = (c.partOf || []).map((x) => chip('shinobi', x)).join('');
    const bonus = (t, l) => (l && l.length ? `<div><h3>${t}</h3><ul>${l.map((x) => `<li>${esc(x)}</li>`).join('')}</ul></div>` : '');
    document.title = `${c.name} · Ninja Online Wiki`;
    return crumbs('<a href="#/shinobi">Shinobi</a>', esc(c.name)) + `<article class="box">${head(c, 'shinobi', tags, quote)}<div class="body">
      ${c.desc ? `<p class="desc">${esc(c.desc)}</p>` : ''}
      ${other.length ? `<p class="note">Other versions: ${other.map((o) => `<a href="${href('shinobi', o.id)}">${esc(o.name)} (${o.stars >= 6 ? 'God' : o.stars + '★'}, ${o.kind.toLowerCase()})</a>`).join(', ')}</p>` : ''}
      <h2>How to get it</h2>${ways(c.get)}
      <h2>Stats</h2>${statGrid(c)}
      ${c.jutsu ? `<h2>Built-in ninjutsu</h2><div class="chips">${chip('jutsu', c.jutsu)}</div>` : ''}
      <h2>Chains</h2>${c.chains && c.chains.length ? `<p class="note">A chain adds its bonus when the named shinobi, gear or ninjutsu is in the same team (or worn by this ninja). "Whole team" chains help every ninja.</p>${c.chains.map(chainBox).join('')}` : '<p class="note">This card has no chains.</p>'}
      ${partOf ? `<h2>Helps the chains of</h2><p class="note">These cards get a chain bonus when ${esc(c.name)} is in their team.</p><div class="chips">${partOf}</div>` : ''}
      ${(c.temper && c.temper.length) || (c.rebirth && c.rebirth.length) ? `<h2>Card bonuses</h2><div class="two">${bonus('Temper', c.temper)}${bonus('Reincarnation', c.rebirth)}</div>` : ''}
    </div></article>`;
  }
  function setBox(sid) {
    const s = D.sets.find((x) => x.id === sid);
    if (!s) return '';
    const kindOf = (p) => (p.kind === 'jutsu' ? 'jutsu' : p.kind === 'seal' ? 'seals' : 'gear');
    const rows = s.bonus.map((b) => {
      const parts = [b.atk && `ATK +${fmt(b.atk)}`, b.atkPct && `ATK +${b.atkPct}%`, b.def && `DEF +${fmt(b.def)}`, b.defPct && `DEF +${b.defPct}%`, b.ckr && `Chakra +${fmt(b.ckr)}`, b.ckrPct && `Chakra +${b.ckrPct}%`, b.skill && `ninjutsu chance +${b.skill}%`].filter(Boolean);
      return parts.length ? `<tr><td>${b.n} pieces</td><td>${parts.join(', ')}</td></tr>` : '';
    }).join('');
    return `<div class="chain"><div class="top2"><b>${esc(s.name)}</b><span class="tag">${esc(s.type)}</span></div><div class="chips">${s.pieces.map((p) => chip(kindOf(p), p.id)).join('')}</div>
      <table class="t" style="margin-top:8px"><tbody>${rows}</tbody></table></div>`;
  }
  function gearPage(id) {
    const g = by.gear.get(id);
    if (!g) return notFound();
    document.title = `${g.name} · Ninja Online Wiki`;
    return crumbs('<a href="#/gear">Gear</a>', esc(g.name)) + `<article class="box">${head(g, 'gear', `<span class="tag ${g.slot}">${g.slot}</span> ${stars(g.stars)}`)}<div class="body">
      ${g.desc ? `<p class="desc">${esc(g.desc)}</p>` : ''}
      <h2>How to get it</h2>${ways(g.get)}
      <h2>Stats</h2>${statGrid(g)}${g.sell ? `<p class="note">Sells for ${fmt(g.sell)} silver.</p>` : ''}
      ${g.sets && g.sets.length ? `<h2>Sets</h2>${g.sets.map(setBox).join('')}` : ''}
      ${g.chains && g.chains.length ? `<h2>Chains</h2><p class="note">These shinobi get a chain bonus when they wear it.</p><div class="chips">${[...new Set(g.chains)].map((x) => chip('shinobi', x)).join('')}</div>` : ''}
    </div></article>`;
  }
  function jutsuPage(id) {
    const j = by.jutsu.get(id);
    if (!j) return notFound();
    document.title = `${j.name} · Ninja Online Wiki`;
    const adds = pctTxt(j.add || {});
    return crumbs('<a href="#/ninjutsu">Ninjutsu</a>', esc(j.name)) + `<article class="box">${head(j, 'jutsu', `${stars(j.stars)}${j.special ? ' <span class="tag special">special</span>' : ''}`)}<div class="body">
      ${j.desc ? `<p class="desc">${esc(j.desc)}</p>` : ''}
      <div class="statgrid"><div class="stat"><small>Trigger chance</small><b>${j.rate || 0}%</b><span>${j.special ? 'counts as 15% on this server (like a normal ninjutsu)' : 'from the game\'s own table'}</span></div>
      <div class="stat"><small>Damage</small><b>${fmt(j.damage)}</b><span>${j.targets ? `hits ${j.targets} enem${j.targets > 1 ? 'ies' : 'y'}` : ''}</span></div>
      <div class="stat"><small>Boost</small><b>${adds || '—'}</b><span>${j.level ? 'card level ' + j.level : ''}</span></div></div>
      <h2>How to get it</h2>${ways(j.get)}${j.price ? `<p class="note">Sells for ${fmt(j.price)} silver.</p>` : ''}
      ${j.owners && j.owners.length ? `<h2>Built into</h2><div class="chips">${j.owners.map((x) => chip('shinobi', x)).join('')}</div>` : ''}
      ${j.sets && j.sets.length ? `<h2>Sets</h2>${j.sets.map(setBox).join('')}` : ''}
      ${j.chains && j.chains.length ? `<h2>Chains</h2><p class="note">These shinobi get a chain bonus with it.</p><div class="chips">${[...new Set(j.chains)].map((x) => chip('shinobi', x)).join('')}</div>` : ''}
    </div></article>`;
  }
  function sealPage(id) {
    const s = by.seals.get(id);
    if (!s) return notFound();
    document.title = `${s.name} · Ninja Online Wiki`;
    const base = s.name.replace(/ Fragment \d+$/, '');
    const family = D.seals.filter((x) => x.id !== s.id && x.name.replace(/ Fragment \d+$/, '') === base);
    return crumbs('<a href="#/seals">Seals</a>', esc(s.name)) + `<article class="box">${head(s, 'seals', `${stars(s.stars)} <span class="tag">${s.fragment ? 'fragment' : 'seal'}</span>`)}<div class="body">
      ${s.effect ? `<div class="statgrid"><div class="stat"><small>Effect</small><b>${esc(s.effect)}</b><span>${s.fragment ? 'once all 8 fragments are joined' : 'worn in the seal slot'}</span></div></div>` : ''}
      <h2>How to get it</h2>${ways(s.get)}${s.sell ? `<p class="note">Sells for ${fmt(s.sell)} silver.</p>` : ''}
      ${s.sets && s.sets.length ? `<h2>Sets</h2>${s.sets.map(setBox).join('')}` : ''}
      ${family.length ? `<h2>${s.fragment ? 'The seal and its other fragments' : 'Its fragments'}</h2><div class="chips">${family.map((x) => chip('seals', x.id)).join('')}</div>` : ''}
    </div></article>`;
  }
  function petPage(id) {
    const p = by.pets.get(id);
    if (!p) return notFound();
    document.title = `${p.name} · Ninja Online Wiki`;
    const pl = p.perLevel || {};
    return crumbs('<a href="#/pets">Pets</a>', esc(p.name)) + `<article class="box">${head(p, 'pets', stars(p.stars))}<div class="body">
      ${p.desc ? `<p class="desc">${esc(p.desc)}</p>` : ''}
      <div class="statgrid"><div class="stat"><small>Attack</small><b>${fmt(p.atk)}</b><span>+${fmt(pl.atk)} a level</span></div><div class="stat"><small>Defence</small><b>${fmt(p.def)}</b><span>+${fmt(pl.def)} a level</span></div>
      <div class="stat"><small>Chakra</small><b>${fmt(p.ckr)}</b><span>+${fmt(pl.ckr)} a level</span></div></div>
      <h2>Skill: ${esc(p.skill || '')}</h2><p>${esc(p.skillDesc || '')}</p>
      <h2>How to get it</h2>${ways(p.get)}
    </div></article>`;
  }
  function itemPage(id) {
    const i = by.items.get(id);
    if (!i) return notFound();
    document.title = `${i.name} · Ninja Online Wiki`;
    return crumbs('<a href="#/items">Items</a>', esc(i.name)) + `<article class="box">${head(i, 'items', i.gold ? `<span class="tag">${fmt(i.gold)} gold</span>` : i.silver ? `<span class="tag">${fmt(i.silver)} silver</span>` : '')}<div class="body">
      ${i.desc ? `<p class="desc">${esc(i.desc)}</p>` : ''}
      <h2>How to get it</h2>${ways(i.get)}
    </div></article>`;
  }
  function setsPage() {
    document.title = 'Sets · Ninja Online Wiki';
    const gearSets = D.sets.filter((s) => s.type === 'Gear set'), jutsuSets = D.sets.filter((s) => s.type !== 'Gear set');
    return crumbs('Sets') + `<section class="box"><div class="lead"><div class="kicker">Sets</div><h1>Gear and ninjutsu sets</h1>
      <p class="intro">Wear 2, 3 or 4 pieces of the same set on one ninja for the bonus below. Gear sets count the weapon, armour, trinket and seal; ninjutsu sets count equipped ninjutsu.</p></div>
      <div class="body"><h2>Gear sets</h2>${gearSets.map((s) => setBox(s.id)).join('')}<h2>Ninjutsu sets</h2>${jutsuSets.map((s) => setBox(s.id)).join('')}</div></section>`;
  }

  // ---- training -----------------------------------------------------------------------------------------------------------------
  const roundIndex = new Map();
  const roundHref = (rid) => { const r = roundIndex.get(rid); return r ? `#/training/${r.chap}?r=${rid}` : ''; };
  function trainingList() {
    document.title = 'Training · Ninja Online Wiki';
    const cards = D.chapters.map((c) => {
      const all = c.parts.flatMap((p) => p.rounds);
      const boss = all.filter((r) => r.boss).length;
      const lv = all.map((r) => r.level).filter(Boolean);
      return `<a class="box" href="#/training/${c.id}"><h3>${ico('training')}${c.id}. ${esc(c.name)}</h3><p>${c.parts.length} parts, ${all.length} stages, ${boss} bosses${lv.length ? ` · level ${Math.min(...lv)}-${Math.max(...lv)}` : ''}</p><small>Open →</small></a>`;
    }).join('');
    return crumbs('Training') + `<section class="box"><div class="lead"><div class="kicker">Story</div><h1>Training</h1>
      <p class="intro">The story mode, chapter by chapter. Each stage costs energy and pays EXP and silver; a stage needs a few clears before the next opens. Bosses have 3 free tries a day (then 10 gold) and a ${Math.round(5)}% chance to drop the reward shown on their row.</p></div></section>
      <h2>Chapters</h2><div class="cards">${cards}</div>`;
  }
  function chapterPage(id, q) {
    const c = D.chapters.find((x) => x.id === id);
    if (!c) return notFound();
    document.title = `${c.name} · Training · Ninja Online Wiki`;
    const prev = D.chapters.find((x) => x.id === id - 1), next = D.chapters.find((x) => x.id === id + 1);
    const parts = c.parts.map((p) => `<h2>${esc(p.name || 'Part ' + p.id)}</h2><div class="scroll"><table class="t"><thead><tr><th>Stage</th><th class="r">Energy</th><th class="r">EXP</th><th class="r">Silver</th><th>Enemies</th><th>Boss reward</th></tr></thead><tbody>${p.rounds.map((r) => {
      const foes = r.foes.map((f) => icon(f.icon, 28, `${f.name} (level ${f.level})`)).join('');
      const rw = r.reward ? chip(WHAT[r.reward.what] || 'gear', r.reward.id) : '';
      return `<tr id="r${r.id}" class="${r.boss ? 'boss' : ''}"><td><b>${esc(r.name)}</b>${r.boss ? ' <span class="tag boss">boss</span>' : ''}<br><span class="note">${r.boss ? '3 free tries a day' : `${r.clears} clear${r.clears > 1 ? 's' : ''} to open the next`}${r.level ? ` · advised level ${r.level}` : ''}</span></td>
        <td class="r">${r.energy}</td><td class="r">${fmt(r.exp)}</td><td class="r">${fmt(r.silver)}</td><td><div class="foes">${foes}</div></td><td>${rw}</td></tr>`;
    }).join('')}</tbody></table></div>`).join('');
    if (q && q.r) setTimeout(() => { const el = document.getElementById('r' + q.r); if (el) { el.scrollIntoView({ block: 'center' }); el.style.outline = '3px solid var(--orange)'; } }, 30);
    return crumbs('<a href="#/training">Training</a>', esc(c.name)) + `<section class="box"><div class="lead"><div class="kicker">Chapter ${c.id}</div><h1>${esc(c.name)}</h1>
      <p class="intro">Hover or tap an enemy picture for its name and level. Boss rewards drop on 5% of wins.</p>
      <div class="btns">${prev ? `<a class="btn" href="#/training/${prev.id}">← ${esc(prev.name)}</a>` : ''}${next ? `<a class="btn" href="#/training/${next.id}">${esc(next.name)} →</a>` : ''}</div></div>
      <div class="body">${parts}</div></section>`;
  }

  // ---- guides -------------------------------------------------------------------------------------------------------------------
  function guidesPage(file) {
    const files = file ? [file] : ['install-help', 'how-to-play', 'faq'];
    document.title = `${file ? GROUPS[file] : 'Guides'} · Ninja Online Wiki`;
    const blocks = files.map((f) => `<h2>${esc(GROUPS[f] || f)}</h2><ul class="quick">${D.guides.filter((g) => g.file === f).map((g) => `<li><a href="#/guide/${g.slug}"><span>${esc(g.title)}</span><span aria-hidden="true">›</span></a></li>`).join('')}</ul>`).join('');
    return crumbs(file ? `<a href="#/guides">Guides</a>` : 'Guides', ...(file ? [esc(GROUPS[file])] : [])) +
      `<section class="box"><div class="lead"><div class="kicker">Guides</div><h1>${file ? esc(GROUPS[file]) : 'How to play'}</h1><p class="intro">The same guides as the Discord server's guide channels.</p></div><div class="body">${blocks}</div></section>`;
  }
  function guidePage(slug) {
    const i = D.guides.findIndex((g) => g.slug === slug);
    if (i < 0) return notFound();
    const g = D.guides[i], prev = D.guides[i - 1], next = D.guides[i + 1];
    document.title = `${g.title} · Ninja Online Wiki`;
    return crumbs(`<a href="#/guides/${g.file}">${esc(g.group)}</a>`, esc(g.title)) + `<article class="box guide"><div class="kicker" style="font:500 12px Kanit;letter-spacing:.16em;text-transform:uppercase;color:var(--orange)">${esc(g.group)}</div><h1>${esc(g.title)}</h1><div style="margin-top:14px">${md(g.body)}</div>
      <div class="gnav">${prev ? `<a href="#/guide/${prev.slug}">← ${esc(prev.title)}</a>` : '<span></span>'}${next ? `<a href="#/guide/${next.slug}">${esc(next.title)} →</a>` : ''}</div></article>`;
  }
  const notFound = () => crumbs('Not found') + '<section class="box lead"><h1>Nothing here</h1><p class="intro">That page does not exist (any more). Try the search at the top.</p><div class="btns"><a class="btn main" href="#/">Main page</a></div></section>';

  // ---- search -------------------------------------------------------------------------------------------------------------------
  let index = [];
  function buildIndex() {
    // p = rank of the kind in the results: cards and gear first, single story stages last
    const P = { shinobi: 0, gear: 1, jutsu: 2, seals: 3, pets: 3, items: 4 };
    for (const [k, cfg] of Object.entries(KIND)) for (const e of D[k]) index.push({ t: e.name, k: cfg.one + (e.stars >= 6 ? ' · god' : e.kind ? ` · ${e.kind.toLowerCase()}` : e.slot ? ` · ${e.slot.toLowerCase()}` : ''), h: href(k, e.id), i: e.icon, p: P[k] });
    for (const c of D.chapters) {
      index.push({ t: c.name, k: 'chapter', h: `#/training/${c.id}`, s: 'training', p: 5 });
      for (const p of c.parts) for (const r of p.rounds) index.push({ t: r.name, k: r.boss ? 'boss stage' : 'stage', h: `#/training/${c.id}?r=${r.id}`, s: 'training', p: r.boss ? 7 : 8 });
    }
    for (const s of D.sets) index.push({ t: s.name + ' set', k: 'set', h: '#/sets', s: 'sets', p: 4 });
    for (const g of D.guides) index.push({ t: g.title, k: 'guide', h: `#/guide/${g.slug}`, s: 'book', p: 6 });
    index = index.map((x) => ({ ...x, l: x.t.toLowerCase() }));
  }
  function search(q) {
    const words = q.toLowerCase().trim().split(/\s+/).filter(Boolean);
    if (!words.length) return [];
    const hits = index.filter((x) => words.every((w) => x.l.includes(w)));
    const whole = words.join(' ');
    const score = (x) => (x.l === whole && x.p < 7 ? 0 : 1) * 100000 + x.p * 10000 + (x.l.startsWith(words[0]) ? 0 : 1000) + x.l.length;
    return hits.sort((a, b) => score(a) - score(b)).slice(0, 14);
  }
  function wireSearch() {
    const q = $('#q'), box = $('#results');
    let sel = 0, hits = [];
    const draw = () => {
      if (!q.value.trim()) { box.hidden = true; return; }
      hits = search(q.value);
      sel = Math.min(sel, Math.max(0, hits.length - 1));
      box.innerHTML = hits.length ? hits.map((h, i) => `<a href="${h.h}" class="${i === sel ? 'on' : ''}" role="option">${h.i ? icon(h.i, 28) : `<span class="ic sym">${ico(h.s)}</span>`}<span>${esc(h.t)}</span><small>${esc(h.k)}</small></a>`).join('') : '<div class="none">Nothing found.</div>';
      box.hidden = false;
    };
    q.addEventListener('input', () => { sel = 0; draw(); });
    q.addEventListener('keydown', (ev) => {
      if (ev.key === 'ArrowDown') { sel = Math.min(sel + 1, hits.length - 1); draw(); ev.preventDefault(); }
      else if (ev.key === 'ArrowUp') { sel = Math.max(sel - 1, 0); draw(); ev.preventDefault(); }
      else if (ev.key === 'Enter' && hits[sel]) { location.hash = hits[sel].h; q.value = ''; box.hidden = true; q.blur(); }
      else if (ev.key === 'Escape') { box.hidden = true; q.blur(); }
    });
    box.addEventListener('click', () => { q.value = ''; box.hidden = true; });
    document.addEventListener('click', (ev) => { if (!ev.target.closest('.search')) box.hidden = true; });
    document.addEventListener('keydown', (ev) => { if (ev.key === '/' && !/input|select|textarea/i.test(document.activeElement.tagName)) { ev.preventDefault(); q.focus(); } });
  }

  // ---- team calculator ----------------------------------------------------------------------------------------------------------
  // Pick cards, gear, a seal and ninjutsu; the game server works the numbers out with its own team maths (server/webapi.js /api/calc ->
  // game.teamSlots): card stats, gear, gear and ninjutsu sets, seals, ninjutsu chance and every chain. The team is kept in the address
  // (#/calculator?s=...), so it can be shared. Card sets, Eight Gates, pets and the W.A. title depend on the whole account: not counted.
  const CALC = { slots: 26, level: 50, gearLevel: 50, rebirth: 9 };
  const ELEMENTS = [[1, 'Water'], [2, 'Fire'], [3, 'Wind'], [4, 'Earth'], [5, 'Thunder']];
  const calcSlot = () => ({ n: 0, lv: 50, bk: 0, gr: 0, el: 2, rb: 0, w: 0, wl: 50, a: 0, al: 50, t: 0, tl: 50, m: 0, j: [0, 0, 0, 0] });
  function calcParse(str) {
    return String(str || '').split('|').filter(Boolean).slice(0, CALC.slots).map((part) => {
      const o = calcSlot(); let js = 0;
      for (const tok of part.split(',')) {
        const k = tok[0], v = tok.slice(1).split('.').map(Number);
        if (k === 'n') Object.assign(o, { n: v[0] || 0, lv: v[1] || 1, bk: v[2] || 0, gr: v[3] || 0, el: v[4] || 2, rb: v[5] || 0 });
        else if (k === 'e') { const g = by.gear.get(v[0]); if (!g) continue; const key = g.slot === 'Weapon' ? 'w' : g.slot === 'Trinket' ? 't' : 'a'; o[key] = v[0]; o[key + 'l'] = v[1] || 1; }
        else if (k === 'm') o.m = v[0] || 0;
        else if (k === 'j' && js < 4) o.j[js++] = v[0] || 0;
      }
      return o;
    });
  }
  const calcStr = (slots) => slots.filter((o) => o.n).map((o) => [`n${o.n}.${o.lv}.${o.bk}.${o.gr}.${o.el}.${o.rb}`,
    ...['w', 'a', 't'].filter((k) => o[k]).map((k) => `e${o[k]}.${o[k + 'l']}`), ...(o.m ? [`m${o.m}`] : []), ...o.j.filter(Boolean).map((id) => `j${id}`)].join(',')).join('|');
  const opts = (list, sel, none) => `<option value="0">${none}</option>` + list.map((e) => `<option value="${e.id}"${e.id === sel ? ' selected' : ''}>${esc(e.name)}${e.stars >= 6 ? ' (God)' : e.stars ? ' ' + '★'.repeat(e.stars) : ''}</option>`).join('');
  const byName = (a, b) => a.name.localeCompare(b.name);
  function calcSlotHtml(o, i) {
    const gear = (slot) => D.gear.filter((g) => g.slot === slot).sort(byName);
    const card = by.shinobi.get(o.n);
    const num = (key, v, min, max, label) => `<label class="cf"><span>${label}</span><input type="number" inputmode="numeric" data-k="${key}" value="${v}" min="${min}" max="${max}"></label>`;
    return `<fieldset class="box cslot" data-i="${i}">
      <legend>${card ? icon(card.icon, 34, card.name) : ''}<span>Place ${i + 1}</span></legend>
      <button type="button" class="cdel" data-del="${i}" aria-label="Take place ${i + 1} out">×</button>
      <label class="cf wide"><span>Shinobi</span><input list="calc-ninjas" data-k="name" value="${card ? esc(card.name) : ''}" placeholder="Type a name…" autocomplete="off"></label>
      <div class="crow">${num('lv', o.lv, 1, CALC.level, 'Level')}${num('rb', o.rb, 0, CALC.rebirth, 'Rebirth')}${num('gr', o.gr, 0, 15, 'Sage growth')}
        ${card && card.stars >= 6 ? num('bk', o.bk, 0, 10, 'Breakthrough') + `<label class="cf"><span>Element</span><select data-k="el">${ELEMENTS.map(([v, l]) => `<option value="${v}"${v === o.el ? ' selected' : ''}>${l}</option>`).join('')}</select></label>` : ''}</div>
      <div class="crow">${[['w', 'Weapon'], ['a', 'Armour'], ['t', 'Trinket']].map(([k, slot]) => `<label class="cf gear"><span>${slot}</span><select data-k="${k}">${opts(gear(slot), o[k], 'none')}</select></label>` +
        num(k + 'l', o[k + 'l'], 1, CALC.gearLevel, 'Lv')).join('')}</div>
      <div class="crow"><label class="cf wide"><span>Seal</span><select data-k="m">${opts(D.seals.filter((x) => !x.fragment).sort(byName), o.m, 'none')}</select></label></div>
      <div class="crow">${o.j.map((id, n) => `<label class="cf"><span>Ninjutsu ${n + 1}</span><select data-k="j${n}">${opts(D.jutsu.slice().sort(byName), id, 'none')}</select></label>`).join('')}</div>
    </fieldset>`;
  }
  function calcPage(q) {
    document.title = 'Team calculator · Ninja Online Wiki';
    const slots = calcParse(q.s);
    if (!slots.length) slots.push(calcSlot());
    return crumbs('Team calculator') +
      `<section class="box lead"><h1>Team calculator</h1>
        <p class="intro">Pick shinobi, gear, a seal and ninjutsu for each place. The game server works out attack, defence and chakra with the same team maths the game uses, and shows which chains and sets turn on. Card sets, Eight Gates, pets and the W.A. title count on top in the game (they depend on your whole account).</p></section>
      <datalist id="calc-ninjas">${D.shinobi.slice().sort(byName).map((c) => `<option value="${esc(c.name)}">`).join('')}</datalist>
      <div class="calc"><div class="cslots" id="cslots">${slots.map(calcSlotHtml).join('')}</div>
        <div class="cside"><div class="box cres" id="cres" aria-live="polite"><p class="intro">Pick a shinobi to start.</p></div>
          <button type="button" class="btn main" id="cadd">Add a place</button> <button type="button" class="btn" id="cclear">Start over</button></div></div>
      <button type="button" class="cbar" id="cbar" hidden></button>`;
  }
  function calcWire(q) {
    const slots = calcParse(q.s);
    if (!slots.length) slots.push(calcSlot());
    const names = new Map(D.shinobi.map((c) => [c.name.toLowerCase(), c.id]));
    const list = $('#cslots'), res = $('#cres');
    let timer = 0, ask = 0;
    const save = () => { const str = calcStr(slots); history.replaceState(null, '', '#/calculator' + (str ? '?s=' + str : '')); return str; };
    const rng = (a) => (a[0] === a[1] ? fmt(a[0]) : `${fmt(a[0])}-${fmt(a[1])}`);
    const setName = (id) => (D.sets.find((x) => x.id === id) || {}).name || 'Set ' + id;
    const run = () => {
      const str = save();
      if (!str) { res.innerHTML = '<p class="intro">Pick a shinobi to start.</p>'; return; }
      const mine = ++ask;
      res.innerHTML = '<p class="intro">Working it out…</p>';
      fetch('/api/calc?s=' + encodeURIComponent(str)).then((r) => (r.ok ? r.json() : Promise.reject(r.status))).then((d) => {
        if (mine !== ask) return;
        const bar = $('#cbar'); bar.hidden = false; bar.innerHTML = `<b>ATK</b> ${rng(d.total.atk)} <b>DEF</b> ${rng(d.total.def)} <span aria-hidden="true">↓</span>`;
        res.innerHTML = `<h2>Team</h2><dl class="ctot"><div><dt>Attack</dt><dd>${rng(d.total.atk)}</dd></div><div><dt>Defence</dt><dd>${rng(d.total.def)}</dd></div><div><dt>Chakra</dt><dd>${rng(d.total.ckr)}</dd></div></dl>` +
          d.slots.map((x) => { const c = by.shinobi.get(x.id); return `<div class="cone"><h3>${c ? icon(c.icon, 30, c.name) : ''}${esc(c ? c.name : x.name)} <small>Lv ${x.level}</small></h3>
            <p class="cst">ATK ${rng(x.atk)} · DEF ${rng(x.def)} · Chakra ${rng(x.ckr)}</p>
            ${x.chains.length ? `<ul class="con">${x.chains.map((ch) => `<li>${esc(ch.text || 'Chain ' + ch.id)}</li>`).join('')}</ul>` : '<p class="cno">No chains on.</p>'}
            ${x.sets.length ? `<p class="cset">${x.sets.map((st) => `${esc(setName(st.id))} set: ${st.num} pieces`).join(' · ')}</p>` : ''}</div>`; }).join('');
      }).catch(() => { if (mine === ask) res.innerHTML = '<p class="intro">The calculator needs the game server, and it does not answer right now. Try again in a minute.</p>'; });
    };
    const later = () => { clearTimeout(timer); timer = setTimeout(run, 350); };
    const redraw = () => { list.innerHTML = slots.map(calcSlotHtml).join(''); later(); };
    list.addEventListener('change', (ev) => {
      const el = ev.target, box = el.closest('.cslot'); if (!box) return;
      const o = slots[Number(box.dataset.i)], k = el.dataset.k;
      if (k === 'name') {
        const id = names.get(el.value.trim().toLowerCase()) || 0;
        const had = o.n; o.n = id;
        if (!id) { el.setCustomValidity('Pick a name from the list'); el.reportValidity(); return; }
        el.setCustomValidity('');
        if ((by.shinobi.get(id) || {}).stars >= 6 !== (by.shinobi.get(had) || {}).stars >= 6 || !had) { redraw(); return; } // breakthrough fields come and go
        box.querySelector('legend').innerHTML = `${icon(by.shinobi.get(id).icon, 34, '')}<span>Place ${Number(box.dataset.i) + 1}</span>`;
      } else if (/^j\d$/.test(k)) o.j[Number(k[1])] = Number(el.value) || 0;
      else if (k) { const n = Number(el.value) || 0; o[k] = el.type === 'number' ? Math.max(Number(el.min), Math.min(Number(el.max), n)) : n; if (el.type === 'number') el.value = o[k]; }
      later();
    });
    list.addEventListener('click', (ev) => { const b = ev.target.closest('[data-del]'); if (!b) return; slots.splice(Number(b.dataset.del), 1); if (!slots.length) slots.push(calcSlot()); redraw(); });
    $('#cadd').addEventListener('click', () => { if (slots.length >= CALC.slots) return; slots.push(calcSlot()); redraw(); list.lastElementChild.querySelector('input').focus(); });
    $('#cbar').addEventListener('click', () => res.scrollIntoView({ behavior: 'smooth', block: 'start' }));
    $('#cclear').addEventListener('click', () => { slots.splice(0, slots.length, calcSlot()); redraw(); });
    run();
  }

  // ---- router -------------------------------------------------------------------------------------------------------------------
  function route() {
    const raw = decodeURIComponent(location.hash.replace(/^#\/?/, ''));
    const [p, qs] = raw.split('?');
    const q = Object.fromEntries(new URLSearchParams(qs || ''));
    const [a, b] = p.split('/');
    const id = Number(b);
    let html;
    document.title = 'Ninja Online Wiki';
    if (!a) html = home();
    else if (a === 'shinobi') html = b ? shinobiPage(id) : shinobiList();
    else if (a === 'gear') html = b ? gearPage(id) : gearList();
    else if (a === 'ninjutsu') html = b ? jutsuPage(id) : jutsuList();
    else if (a === 'seals') html = b ? sealPage(id) : sealList();
    else if (a === 'pets') html = b ? petPage(id) : petList();
    else if (a === 'items') html = b ? itemPage(id) : itemList();
    else if (a === 'sets') html = setsPage();
    else if (a === 'training') html = b ? chapterPage(id, q) : trainingList();
    else if (a === 'guides') html = guidesPage(b && GROUPS[b] ? b : '');
    else if (a === 'guide') html = guidePage(b);
    else if (a === 'calculator') html = calcPage(q);
    else html = notFound();
    if (!b && a && document.title === 'Ninja Online Wiki') document.title = `${(KIND[Object.keys(KIND).find((k) => KIND[k].path === a)] || {}).label || 'Guides'} · Ninja Online Wiki`;
    $('#main').innerHTML = html;
    sideMenu(p);
    tabs(p);
    document.body.classList.remove('nav-open');
    $('#menu').setAttribute('aria-expanded', 'false');
    if (a === 'calculator') calcWire(q);
    if (!q.r && !(a === 'calculator' && window.scrollY)) window.scrollTo(0, 0);
  }

  // ---- start --------------------------------------------------------------------------------------------------------------------
  $('#menu').addEventListener('click', () => { const open = document.body.classList.toggle('nav-open'); $('#menu').setAttribute('aria-expanded', String(open)); });
  fetch('data.json').then((r) => { if (!r.ok) throw new Error(r.status); return r.json(); }).then((data) => {
    D = data;
    for (const k of Object.keys(KIND)) by[k] = new Map(D[k].map((e) => [e.id, e]));
    for (const c of D.chapters) for (const p of c.parts) for (const r of p.rounds) roundIndex.set(r.id, { chap: c.id });
    buildIndex();
    wireSearch();
    $('#built').textContent = `Data built ${D.built}.`;
    window.addEventListener('hashchange', route);
    route();
  }).catch((e) => { $('#main').innerHTML = `<section class="box lead"><h1>Could not load the wiki</h1><p class="intro">The data file did not load (${esc(e.message)}). Try again in a minute.</p></section>`; });
})();
