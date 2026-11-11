// The website's extra pages, made from the home page's own head, header and footer (server/site/index.html), so they always match it:
//   p.html                          the player page shell (/p/<name>, live.js fills it; not for search engines)
//   hello-bro-apk/index.html        "Hello Bro APK download"       \
//   hello-bro-private-server/...    "Hello Bro private server"      > pages for what people search (owner, 11 Nov 2026: "build search pages")
//   ninja-online-game/index.html    "Ninja Online, the 2015 game"  /
// Titles and descriptions never say Naruto or Konoha (owner's rule). Used by tools/build_wiki.js (writes them, --check compares them, and
// lists the search pages in sitemap.xml). Plain words, only true facts (server/PRODUCT.md).
const SITE = 'https://ninjaonlinereborn.com';
const XAPK = 'https://github.com/Djassie18698/hello-bro-revival/releases/download/tailscale-play/HelloBro-ninjaonline.xapk';
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const PAGES = [
  {
    dir: 'hello-bro-apk',
    title: 'Hello Bro APK download (Ninja Online, 2015): free, works on new phones',
    desc: 'Download the Hello Bro / Ninja Online game file for Android and play the 2015 ninja card game again on our free server. Install it on a phone, on Android 14 and up, or in BlueStacks on a PC.',
    ld: { '@type': 'SoftwareApplication', name: 'Ninja Online (Hello Bro)', alternateName: ['Hello Bro', 'Ninja Online'], operatingSystem: 'Android', applicationCategory: 'GameApplication',
      downloadUrl: XAPK, fileSize: '127 MB', offers: { '@type': 'Offer', price: '0', priceCurrency: 'EUR' } },
    body: (c) => `<h1>Hello Bro APK download</h1>
<p class="lede">The game file for <b>Hello Bro</b>, also called <b>Ninja Online</b>, the ninja card game from 2015. It connects to our free server by itself, so you can play again right away.</p>
<p class="cta"><a class="btn green" href="${XAPK}"><svg aria-hidden="true"><use href="#i-down"/></svg>Download the game</a> <small>HelloBro-ninjaonline.xapk · 127 MB · free</small></p>
<h2>What you get</h2>
<p>The original 2015 app with its own cards, story and events, on a server rebuilt by players. ${c.shinobi} shinobi, ${c.stages} story stages, and top-ups cost nothing.</p>
<h2>How to install it</h2>
<ol>
  <li><b>On a PC:</b> install BlueStacks 5, then drag the downloaded file onto its window.</li>
  <li><b>On an Android phone:</b> the file is an .xapk (the app plus its game data). Install it from a PC with a USB cable and our installer, <code>INSTALL-WITH-USB.bat</code>. This also works on new phones with Android 14 and up.</li>
  <li>Open Hello Bro, tap PLAY, pick your nation and your first ninja.</li>
</ol>
<p>The full steps with pictures: <a href="/install">install guide</a>. Stuck? Ask on <a href="/discord">Discord</a>.</p>
<h2>Questions</h2>
<h3>Is it safe?</h3>
<p>It is the original app, changed only so it talks to our server, and built in the open: all the code is on <a href="https://github.com/Djassie18698/hello-bro-revival">GitHub</a>.</p>
<h3>Does it work on an iPhone?</h3>
<p>No. The game only exists for Android. On a computer you can play it in BlueStacks.</p>
<h3>My phone only runs 64-bit apps</h3>
<p>The game is a 32-bit app. Players run it inside a virtual Android phone (VPhoneOS); the <a href="/install">install guide</a> explains how.</p>
<h3>Can I get my old account back?</h3>
<p>No. The old accounts were kept on the official servers, and those are gone, so everyone starts a new character.</p>`,
  },
  {
    dir: 'hello-bro-private-server',
    title: 'Hello Bro private server: play Ninja Online again, free',
    desc: 'A free private server for Hello Bro / Ninja Online, the 2015 ninja card game, rebuilt by its players: the same cards, story, events and prices as the original. Join the public server or host your own.',
    body: (c) => `<h1>Hello Bro private server</h1>
<p class="lede">The official <b>Hello Bro / Ninja Online</b> servers went offline years ago. We rebuilt the server, so the game can be played again, exactly like the original.</p>
<p class="cta"><a class="btn green" href="/hello-bro-apk/"><svg aria-hidden="true"><use href="#i-play"/></svg>Play on our server</a> <a class="btn blue" href="/discord"><svg aria-hidden="true"><use href="#i-discord"/></svg>Join Discord</a></p>
<h2>Our public server</h2>
<p>Anyone can join. It runs day and night, and it is free: top-ups cost nothing. You play with other players in the Arena, the Country War and Akatsuki guilds.</p>
<ul>
  <li>The same ${c.shinobi} shinobi, ${c.chapters} story chapters and ${c.stages} stages as the original</li>
  <li>The original events: Lucky Wheel, Millionaire, Ninja Treasure, Limited Super Ninja, the festivals and more</li>
  <li>The strongest players are on the <a href="/#live">home page</a>, live from the server</li>
</ul>
<h2>Host your own server</h2>
<p>Want to play alone or only with friends? The server runs on a normal Windows PC. Download it from <a href="https://github.com/Djassie18698/hello-bro-revival">GitHub</a> and double-click <code>HOST-MY-SERVER.bat</code>: it sets everything up and makes a game file for your own server.</p>
<h2>Is this the official game?</h2>
<p>No. It is a free fan revival of Hello Bro / Ninja Online (2015), made by its players. The game itself is the original app.</p>`,
  },
  {
    dir: 'ninja-online-game',
    title: 'Ninja Online (Hello Bro): the 2015 ninja card game, playable again',
    desc: 'Ninja Online, also known as Hello Bro, is a ninja card RPG for Android from 2015: collect shinobi cards, fight through 19 story chapters, and battle other players. Its servers closed; it runs again for free.',
    ld: { '@type': 'VideoGame', name: 'Ninja Online', alternateName: ['Hello Bro'], gamePlatform: 'Android', operatingSystem: 'Android', genre: ['Card game', 'Role-playing game'],
      datePublished: '2015', image: SITE + '/img/og.jpg', url: SITE + '/ninja-online-game/', offers: { '@type': 'Offer', price: '0', priceCurrency: 'EUR' } },
    body: (c) => `<h1>Ninja Online, the 2015 ninja card game</h1>
<p class="lede"><b>Ninja Online</b>, also known as <b>Hello Bro</b>, is a ninja card RPG for Android that came out in 2015. Its servers went offline years ago. Now it runs again on a server rebuilt by its players.</p>
<p class="cta"><a class="btn green" href="/hello-bro-apk/"><svg aria-hidden="true"><use href="#i-down"/></svg>Download it</a> <a class="btn blue" href="/wiki/"><svg aria-hidden="true"><use href="#i-book"/></svg>Open the wiki</a></p>
<h2>What you do in the game</h2>
<ul>
  <li><b>Collect shinobi.</b> ${c.shinobi} cards, from 1 star up to God cards. Level them up, give them gear, seals and ninjutsu.</li>
  <li><b>Play the story.</b> ${c.chapters} chapters and ${c.stages} stages, from the Shinobi Exams to the final war, and every boss brings its own team.</li>
  <li><b>Fight other players</b> in the Arena and the Country War, and plunder seals.</li>
  <li><b>Join an Akatsuki guild</b> with friends and take on the world boss together.</li>
  <li><b>Grow stronger</b> with Breakthrough, the Eight Gates, pets, rebirth and sage growth.</li>
</ul>
<p>Every card, piece of gear and stage is in the <a href="/wiki/">wiki</a>, and the <a href="/wiki/#/calculator">team calculator</a> works out your team's attack.</p>
<h2>One game, more than one name</h2>
<p>Most players know it as Hello Bro or Ninja Online. It is the same app: the package name is <code>com.hello.bro.yo</code>.</p>
<h2>Play it now</h2>
<p>It is free and works on Android phones and in BlueStacks on a PC. Download the game file on the <a href="/hello-bro-apk/">download page</a>, or read <a href="/hello-bro-private-server/">how the server works</a>.</p>`,
  },
];

function build(index, home) {
  const cut = (a, b) => { const i = index.indexOf(a), j = b ? index.indexOf(b, i) : index.length; if (i < 0 || j < 0) throw new Error('site_pages: home page layout changed near ' + a); return index.slice(i, j); };
  const head = index.slice(0, index.indexOf('<main id="main">'));
  const foot = cut('</main>').replace(/^<\/main>\n*/, '');
  if (!head || !foot) throw new Error('site_pages: no <main> in index.html');
  // header and footer links that pointed at the home page's own parts now lead there; the page's own symbols (<use href="#i-...">) stay
  const fix = (h) => h.replace(/<a class="mark" href="#"/g, '<a class="mark" href="/"').replace(/<a href="#/g, '<a href="/#').replace('aria-label="Back to the top"', 'aria-label="Home page"')
    .replace('href="site.css"', 'href="/site.css"').replace('<script src="site.js"></script>', '<script src="/site.js"></script>');
  const strip = (h) => h.replace(/<script type="application\/ld\+json">[^\n]*<\/script>\n/g, '').replace(/<meta property="og:[^>]*>\n/g, '').replace(/<meta name="twitter:card"[^>]*>\n/, '').replace(/<link rel="canonical"[^>]*>\n/, '');
  const out = new Map();
  // the player page: not for search engines (one page per player is made by live.js from the address)
  let p = strip(fix(head)).replace(/<title>[^<]*<\/title>/, '<title>Player · Ninja Online Reborn</title>')
    .replace(/<meta name="description" content="[^"]*">/, '<meta name="description" content="A player on the Ninja Online Reborn server: level, team and power.">\n<meta name="robots" content="noindex">');
  out.set('p.html', p + '<main id="main" class="ppage">\n  <div class="wrap">\n    <a class="back" href="/#live">← Top players</a>\n    <article class="player" id="player" aria-live="polite"><p class="wait">Loading…</p></article>\n  </div>\n</main>\n\n' +
    fix(foot).replace('<script src="live.js"></script>', '<script src="/live.js"></script>'));
  const counts = (home && home.counts) || {};
  const c = { shinobi: counts.shinobi || 0, stages: Number(counts.stages || 0).toLocaleString('en-US').replace(/,/g, '&#8239;'), chapters: counts.chapters || 0 };
  for (const pg of PAGES) {
    const url = `${SITE}/${pg.dir}/`;
    const ld = pg.ld ? `<script type="application/ld+json">${JSON.stringify({ '@context': 'https://schema.org', ...pg.ld })}</script>\n` : '';
    const h = strip(fix(head)).replace(/<title>[^<]*<\/title>/, `<title>${esc(pg.title)} · Ninja Online Reborn</title>`)
      .replace(/<meta name="description" content="[^"]*">/, `<meta name="description" content="${esc(pg.desc)}">\n${ld}<meta property="og:title" content="${esc(pg.title)}">\n<meta property="og:description" content="${esc(pg.desc)}">\n<meta property="og:type" content="website">\n<meta property="og:url" content="${url}">\n<meta property="og:image" content="${SITE}/img/og.jpg">\n<meta name="twitter:card" content="summary_large_image">\n<link rel="canonical" href="${url}">`);
    if (/naruto|konoha/i.test(pg.title + pg.desc)) throw new Error('site_pages: ' + pg.dir + ' title says Naruto/Konoha');
    out.set(`${pg.dir}/index.html`, h + `<main id="main" class="ppage">\n  <div class="wrap">\n    <a class="back" href="/">← Home</a>\n    <article class="read">\n${pg.body(c)}\n    </article>\n  </div>\n</main>\n\n` +
      fix(foot).replace('<script src="live.js"></script>\n', ''));
  }
  return out;
}

module.exports = { build, PAGES: PAGES.map((p) => p.dir) };
