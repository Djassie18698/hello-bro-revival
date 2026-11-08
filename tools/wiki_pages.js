// One real page per wiki entry (server/wiki/<kind>/<id>.html), for search engines: the wiki itself is one page with #/ links, which Google
// sees as a single page. Each page is the wiki's own index.html with its own title, description and canonical address, and the entry's
// facts already written into <main>; app.js then opens the same entry as usual (it reads the address when there is no #).
// Titles and descriptions never say "Naruto" or "Konoha" (owner, 8-9 Nov 2026, copyright caution); the page text keeps the game's names.
// Used by tools/build_wiki.js (which writes the files, removes stale ones, and checks them with --check) and lists every page in sitemap.xml.
const SITE = 'https://ninjaonlinereborn.com';
const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = (n) => Number(n || 0).toLocaleString('en-US');
const range = (a) => (Array.isArray(a) ? (a[0] === a[1] ? fmt(a[0]) : `${fmt(a[0])}-${fmt(a[1])}`) : fmt(a));
// no Naruto / Konoha in titles and descriptions
const plain = (s) => String(s || '').replace(/konohagakure/gi, 'Leaf Village').replace(/[^\s,.:;()]*(naruto|konoha)[^\s,.:;()]*/gi, '').replace(/\(\s+/g, '(').replace(/\s+\)/g, ')').replace(/\(\s*\)/g, '')
  .replace(/\s{2,}/g, ' ').replace(/^[\s,.:;-]+|[\s,:;-]+$/g, '').trim();
const titleName = (name, fallback) => { const t = plain(name); return t && !/^\(?god\)?$/i.test(t) ? t : fallback; };
const cut = (s, n) => { s = plain(s).replace(/\s+/g, ' '); return s.length > n ? s.slice(0, n - 1).replace(/\s+\S*$/, '') + '…' : s; };
const inline = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2" rel="noopener">$1</a>');
const starsTxt = (n) => (n >= 6 ? 'God' : n > 0 ? `${n}-star` : '');

function build(D, shell) {
  const by = {}; for (const k of ['shinobi', 'gear', 'jutsu', 'seals', 'pets', 'items']) by[k] = new Map(D[k].map((e) => [e.id, e]));
  const PATH = { shinobi: 'shinobi', gear: 'gear', jutsu: 'ninjutsu', seals: 'seals', pets: 'pets', items: 'items' };
  const url = (kind, id) => `/wiki/${PATH[kind]}/${id}.html`;
  const link = (kind, id) => { const e = by[kind] && by[kind].get(id); return e ? `<a href="${url(kind, id)}">${esc(e.name)}</a>` : ''; };
  const icon = (ref, size = 64) => {
    if (!ref) return '';
    const [k, n] = ref.split(':'), sh = D.icons.sheets[k], cols = D.icons.cols, i = Number(n);
    if (!sh) return '';
    return `<span class="ic" aria-hidden="true" style="width:${size}px;height:${size}px;background-image:url(img/${sh.file});background-size:${cols * size}px ${sh.rows * size}px;background-position:-${(i % cols) * size}px -${Math.floor(i / cols) * size}px"></span>`;
  };
  const getList = (g) => (g && g.length ? `<section class="box sec"><h2>Where to get it</h2><ul>${g.map((x) => `<li><b>${esc(x.how)}</b>${x.where ? ': ' + esc(String(x.where).split('|')[0]) : ''}</li>`).join('')}</ul></section>` : '');
  const table = (rows) => `<table class="facts"><tbody>${rows.filter((r) => r && r[1] !== '' && r[1] != null).map(([k, v]) => `<tr><th scope="row">${esc(k)}</th><td>${v}</td></tr>`).join('')}</tbody></table>`;
  const crumbs = (section, sectionHref, name) => `<nav class="crumbs" aria-label="You are here"><a href="/wiki/">Wiki</a> › <a href="${sectionHref}">${esc(section)}</a> › <span>${esc(name)}</span></nav>`;
  const head = (ic, name, sub) => `<section class="box lead"><h1>${ic}${esc(name)}</h1>${sub ? `<p class="intro">${sub}</p>` : ''}</section>`;
  const pages = new Map(); // relative path inside server/wiki -> { title, desc, body }
  const add = (rel, title, desc, body) => pages.set(rel, { title, desc, body });

  for (const c of D.shinobi) {
    const name = titleName(c.name, `Shinobi card ${c.id}`);
    const chains = (c.chains || []).map((ch) => `<li>${esc(ch.text)}</li>`).join('');
    const body = crumbs('Shinobi', '/wiki/#/shinobi', c.name) + head(icon(c.icon), c.name, [starsTxt(c.stars), c.kind ? c.kind.toLowerCase() : '', 'shinobi card'].filter(Boolean).join(' ')) +
      `<section class="box sec"><h2>Stats</h2>${table([['Stars', starsTxt(c.stars)], ['Type', esc(c.kind || '')], ['Attack at level 1', range(c.atk)], ['Defence at level 1', range(c.def)], ['Chakra at level 1', range(c.ckr)],
        c.grow ? ['Each level adds', `ATK ${range(c.grow.atk)}, DEF ${range(c.grow.def)}, Chakra ${range(c.grow.ckr)}`] : null, c.jutsu ? ['Built-in ninjutsu', link('jutsu', c.jutsu)] : null])}` +
      (c.desc ? `<p>${esc(c.desc)}</p>` : '') + (c.quote ? `<blockquote>${esc(c.quote)}</blockquote>` : '') + '</section>' +
      (chains ? `<section class="box sec"><h2>Chains</h2><ul>${chains}</ul></section>` : '') + getList(c.get);
    const how = [...new Set((c.get || []).map((g) => g.how))].slice(0, 3).join(', ');
    add(`shinobi/${c.id}.html`, `${name}: stats, chains and where to get it · Ninja Online wiki`,
      cut(`${name}, a ${[starsTxt(c.stars), c.kind ? c.kind.toLowerCase() : ''].filter(Boolean).join(' ')} shinobi card in Ninja Online (Hello Bro). Attack ${range(c.atk)} and defence ${range(c.def)} at level 1, ${(c.chains || []).length} chains.${how ? ' Get it: ' + how + '.' : ''}`, 158), body);
  }
  for (const g of D.gear) {
    const sets = (g.sets || []).map((id) => (D.sets.find((s) => s.id === id) || {}).name).filter(Boolean);
    const body = crumbs('Gear', '/wiki/#/gear', g.name) + head(icon(g.icon), g.name, [starsTxt(g.stars), String(g.slot || '').toLowerCase()].filter(Boolean).join(' ')) +
      `<section class="box sec"><h2>Stats</h2>${table([['Slot', esc(g.slot)], ['Stars', starsTxt(g.stars)], ['Attack', range(g.atk)], ['Defence', range(g.def)], ['Chakra', range(g.ckr)],
        g.grow ? ['Each level adds', `ATK ${range(g.grow.atk)}, DEF ${range(g.grow.def)}, Chakra ${range(g.grow.ckr)}`] : null, sets.length ? ['Set', esc(sets.join(', '))] : null,
        (g.chains || []).length ? ['Combo with', g.chains.map((id) => link('shinobi', id)).filter(Boolean).join(', ')] : null])}${g.desc ? `<p>${esc(g.desc)}</p>` : ''}</section>` + getList(g.get);
    add(`gear/${g.id}.html`, `${titleName(g.name, 'Gear ' + g.id)}: ${String(g.slot || 'gear').toLowerCase()} stats, sets and where to get it · Ninja Online wiki`,
      cut(`${titleName(g.name, 'Gear ' + g.id)}, a ${starsTxt(g.stars)} ${String(g.slot || '').toLowerCase()} in Ninja Online (Hello Bro): attack ${range(g.atk)}, defence ${range(g.def)}${sets.length ? ', part of the ' + sets[0] + ' set' : ''}. Where to get it and which shinobi it combos with.`, 158), body);
  }
  for (const j of D.jutsu) {
    const body = crumbs('Ninjutsu', '/wiki/#/ninjutsu', j.name) + head(icon(j.icon), j.name, `${starsTxt(j.stars)} ninjutsu`) +
      `<section class="box sec"><h2>Facts</h2>${table([['Stars', starsTxt(j.stars)], ['Trigger chance', j.rate != null ? j.rate + ' %' : ''], ['Targets', j.targets], ['Damage', j.damage != null ? j.damage + ' %' : ''],
        j.price ? ['Price', fmt(j.price)] : null])}${j.desc ? `<p>${esc(j.desc)}</p>` : ''}</section>` + getList(j.get);
    add(`ninjutsu/${j.id}.html`, `${titleName(j.name, 'Ninjutsu ' + j.id)}: ninjutsu trigger chance and damage · Ninja Online wiki`,
      cut(`${titleName(j.name, 'Ninjutsu ' + j.id)}, a ${starsTxt(j.stars)} ninjutsu in Ninja Online (Hello Bro): ${j.rate} % trigger chance, ${j.damage} % damage, ${j.targets} target${j.targets === 1 ? '' : 's'}. ${j.desc || ''}`, 158), body);
  }
  for (const s of D.seals.filter((x) => !x.fragment)) {
    const body = crumbs('Seals', '/wiki/#/seals', s.name) + head(icon(s.icon), s.name, `${starsTxt(s.stars)} seal`) +
      `<section class="box sec"><h2>Facts</h2>${table([['Stars', starsTxt(s.stars)], ['Effect', esc(s.effect || '')], s.sell ? ['Sells for', fmt(s.sell) + ' silver'] : null])}</section>` + getList(s.get);
    add(`seals/${s.id}.html`, `${titleName(s.name, 'Seal ' + s.id)}: seal effect and fragments · Ninja Online wiki`,
      cut(`${titleName(s.name, 'Seal ' + s.id)} in Ninja Online (Hello Bro): ${s.effect || ''}. How to get its fragments and make the seal.`, 158), body);
  }
  for (const p of D.pets) {
    const body = crumbs('Pets', '/wiki/#/pets', p.name) + head(icon(p.icon), p.name, `${starsTxt(p.stars)} pet`) +
      `<section class="box sec"><h2>Facts</h2>${table([['Stars', starsTxt(p.stars)], ['Attack', fmt(p.atk)], ['Defence', fmt(p.def)], ['Chakra', fmt(p.ckr)], ['Skill', esc([p.skill, p.skillDesc].filter(Boolean).join(': '))]])}${p.desc ? `<p>${esc(p.desc)}</p>` : ''}</section>` + getList(p.get);
    add(`pets/${p.id}.html`, `${titleName(p.name, 'Pet ' + p.id)}: pet stats and skill · Ninja Online wiki`,
      cut(`${titleName(p.name, 'Pet ' + p.id)}, a pet in Ninja Online (Hello Bro): attack ${fmt(p.atk)}, defence ${fmt(p.def)}, skill ${p.skill || ''}. ${p.skillDesc || ''}`, 158), body);
  }
  for (const it of D.items) {
    const body = crumbs('Items', '/wiki/#/items', it.name) + head(icon(it.icon), it.name, 'item') +
      `<section class="box sec"><h2>Facts</h2>${table([it.gold ? ['Price', fmt(it.gold) + ' gold'] : null])}${it.desc ? `<p>${esc(it.desc)}</p>` : ''}</section>` + getList(it.get);
    add(`items/${it.id}.html`, `${titleName(it.name, 'Item ' + it.id)}: what it does and where to get it · Ninja Online wiki`,
      cut(`${titleName(it.name, 'Item ' + it.id)} in Ninja Online (Hello Bro): ${it.desc || ''}`, 158), body);
  }
  for (const ch of D.chapters) {
    const rounds = ch.parts.flatMap((p) => p.rounds.map((r) => ({ ...r, part: p.name })));
    const body = crumbs('Training', '/wiki/#/training', ch.name) + head('', `Chapter ${ch.id}: ${ch.name}`, `${rounds.length} stages, ${rounds.filter((r) => r.boss).length} bosses`) +
      ch.parts.map((p) => `<section class="box sec"><h2>${esc(p.name)}</h2><table class="facts"><thead><tr><th>Stage</th><th>Energy</th><th>EXP</th><th>Silver</th></tr></thead><tbody>${p.rounds.map((r) =>
        `<tr><td>${esc(r.name)}${r.boss ? ' <b>(boss)</b>' : ''}</td><td>${fmt(r.energy)}</td><td>${fmt(r.exp)}</td><td>${fmt(r.silver)}</td></tr>`).join('')}</tbody></table></section>`).join('');
    add(`training/${ch.id}.html`, `Chapter ${ch.id}: ${plain(ch.name) || 'story'}, every stage, boss and reward · Ninja Online wiki`,
      cut(`Story chapter ${ch.id}, ${ch.name}, in Ninja Online (Hello Bro): all ${rounds.length} stages with energy, EXP, silver, enemies and boss rewards.`, 158), body);
  }
  for (const g of D.guides) {
    const html = String(g.body || '').split(/\n{2,}/).map((para) => {
      const lines = para.split('\n');
      if (lines.every((l) => /^\s*[•*-]\s/.test(l))) return `<ul>${lines.map((l) => `<li>${inline(l.replace(/^\s*[•*-]\s/, ''))}</li>`).join('')}</ul>`;
      return `<p>${lines.map(inline).join('<br>')}</p>`;
    }).join('');
    const body = crumbs(g.group || 'Guides', '/wiki/#/guides', g.title) + head('', g.title, esc(g.group || '')) + `<section class="box sec guide">${html}</section>`;
    add(`guide/${g.slug}.html`, `${plain(g.title)} · Ninja Online (Hello Bro) guide`, cut(`${g.title}: ${String(g.body || '').replace(/\*\*|[•]/g, '')}`, 158), body);
  }

  // the page itself: the wiki's index.html with this page's title, description, address and content
  const out = new Map();
  for (const [rel, p] of pages) {
    const addr = `${SITE}/wiki/${rel}`;
    let h = shell
      .replace('<meta charset="utf-8">', '<meta charset="utf-8">\n<base href="/wiki/">')
      .replace(/<title>[^<]*<\/title>/, `<title>${esc(p.title)}</title>`)
      .replace(/<meta name="description" content="[^"]*">/, `<meta name="description" content="${esc(p.desc)}">\n<meta property="og:title" content="${esc(p.title)}">\n<meta property="og:description" content="${esc(p.desc)}">\n<meta property="og:image" content="${SITE}/img/og.jpg">`)
      .replace(/<link rel="canonical" href="[^"]*">/, `<link rel="canonical" href="${addr}">`)
      .replace('<main id="main"><p class="loading">Loading the scrolls...</p></main>', `<main id="main">${p.body}</main>`);
    if (!h.includes(`href="${addr}"`) || !h.includes(p.body)) throw new Error('wiki page shell changed: ' + rel);
    out.set(rel, h);
  }
  return out;
}

module.exports = { build, plain, SITE };
