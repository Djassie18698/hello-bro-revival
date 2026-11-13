// Runs the original Android app (libgame.so, ARM code) in the browser: the emulator (cpu.js), Android's linker (elf.js), the
// system functions (sys.js), the Java side (jni.js + the Java methods below) and OpenGL on WebGL (gl.js).
// Files it needs (made by tools/build_webclient.js, not in git): assets/emu/libgame.dat, game-apk.dat, main-obb.dat.
'use strict';
(async function () {
  const Cpu = window.EmuCpu, status = (t) => { const m = document.getElementById('msg'); m.textContent = t || ''; m.style.display = t ? '' : 'none'; };
  const q = new URLSearchParams(location.search);
  // the public server's plain http address -> the secure website: iPhones only run JavaScript with the browser's fast compiler on
  // https pages (iOS 27: 50x slower on http). ?stay=1 keeps the http page (for tests)
  if (location.protocol === 'http:' && /(^|\.)ninjaonline\.duckdns\.org$/.test(location.hostname) && q.get('stay') !== '1') { location.replace('https://ninjaonlinereborn.com/play/emu/' + location.search); return; }
  // on the website (no port in the address) the game's requests go through /game/ (tools/vps/wiki-site.sh); on a game server straight
  const API = location.port ? '' : '/game';
  const diag = { stage: 'loading', frames: 0, err: '', lost: false, ms: 0 };
  // how fast this browser runs plain JavaScript: about 3 ms on a phone or PC with the browser's fast compiler on, 50+ ms when
  // it is off (iPhone Lockdown Mode turns it off; Low Power Mode slows it too)
  { const b0 = performance.now(); let x = 0; for (let i = 0; i < 3e6; i++) x = (Math.imul(x, 31) + i) | 0; diag.js = performance.now() - b0 + (x & 0); }
  window.emuDiag = diag;
  // where the game files come from: the server next to this page, or (?files=) the iPhone app's own little web server on 127.0.0.1
  // that has them all inside the app (tools/ios-game): then nothing big is downloaded
  const appFiles = /^http:\/\/127\.0\.0\.1:\d+\/[\w/.-]*$/.test(q.get('files') || '') ? q.get('files') : '';
  let ASSETS = appFiles || '../assets/emu/';
  // in the iPhone app the page itself comes from 127.0.0.1 (?app=1). If the phone runs JavaScript slowly there (iPhones turn the fast
  // compiler off on pages that are not secure), use the website's page with the app's files instead; remembered
  if (q.get('app') === '1' && location.hostname === '127.0.0.1' && q.get('local') !== '1') {
    let site = false; try { site = localStorage.getItem('hb.app.site') === '1'; } catch { /* */ }
    if (!site && diag.js > 30) { site = true; try { localStorage.setItem('hb.app.site', '1'); } catch { /* */ } }
    if (site) { location.replace('https://ninjaonlinereborn.com/play/emu/?app=1&files=' + encodeURIComponent(location.origin + '/play/assets/emu/')); return; }
  }
  if (q.get('diag') === '1') {
    const d = document.createElement('div');
    d.style.cssText = 'position:fixed;left:4px;top:4px;right:4px;z-index:9;color:#9f9;font:11px/1.3 monospace;background:rgba(0,0,0,.55);padding:3px 5px;pointer-events:none;white-space:pre-wrap;word-break:break-all';
    document.body.appendChild(d);
    setInterval(() => {
      const mb = performance.memory ? ' js ' + (performance.memory.usedJSHeapSize >> 20) + ' MB' : '';
      const last = (window.emuLog || []).filter((l) => !/GETTING FILE|CCTextureCache|no node/.test(l)).slice(-2).join(' | ').slice(0, 160);
      d.textContent = 'v13 ' + diag.stage + ' · frames ' + diag.frames + (window.emuCpu && window.emuCpu.jitCount ? ' · blocks ' + window.emuCpu.jitCount : '') + ' · pieces ' + (diag.pieces || 0) + (diag.ms ? ' · ' + diag.ms.toFixed(1) + ' ms' : '') + mb + ' · js ' + diag.js.toFixed(0) + ' ms' + (diag.js > 60 ? ' (slow: Lockdown/Low Power Mode?)' : '') + (diag.lost ? ' · GL LOST' : '') + (diag.err ? '\nERROR: ' + diag.err : '') + '\n' + last;
    }, 500);
  }
  window.addEventListener('error', (e) => { diag.err = String(e.message || e.error).slice(0, 300); });
  window.addEventListener('unhandledrejection', (e) => { diag.err = String((e.reason && (e.reason.message || e.reason)) || e.reason).slice(0, 300); });
  const logLines = (window.emuLog = []);
  const log = (s) => { logLines.push(s); if (logLines.length > 3000) logLines.shift(); if (q.get('log')) console.log('[app] ' + s); };
  const get = async (name) => { const r = await fetch(ASSETS + name); if (!r.ok) throw new Error(name + ' is missing: run node tools/build_webclient.js --emu'); return new Uint8Array(await r.arrayBuffer()); };
  status('Loading the game files…');
  let so, apk, obb;
  let parts;
  try { so = await get('libgame.dat'); } catch (e) { if (!appFiles) { status(e.message); return; } ASSETS = '../assets/emu/'; } // the app's files out of reach: download them like the website
  try { if (!so) so = await get('libgame.dat'); parts = JSON.parse(new TextDecoder().decode(await get('parts.json'))); } catch (e) { status(e.message); return; }
  apk = { length: parts.apk.size }; obb = { length: parts.obb.size };

  const canvas = document.getElementById('game');
  const fit = () => { let w = innerWidth, h = innerHeight; if (h / w < 1.5) w = Math.round(h / 1.78); canvas.style.width = w + 'px'; canvas.style.height = h + 'px'; return [w, h]; };
  const [cw, ch] = fit();
  const dpr = Math.min(devicePixelRatio || 1, 2);
  canvas.width = Math.round(cw * dpr); canvas.height = Math.round(ch * dpr);
  canvas.addEventListener('webglcontextlost', (e) => { diag.lost = true; e.preventDefault(); });
  diag.stage = 'code loaded, screen ' + canvas.width + 'x' + canvas.height;
  const gl = canvas.getContext('webgl', { alpha: false, antialias: false, stencil: true, depth: true, preserveDrawingBuffer: !!q.get('keep') });
  if (!gl) { status('This browser has no WebGL'); return; }

  const MEM = (Number(q.get('mem')) || 128) << 20, BASE = 0x10000;
  let cpu;
  try { cpu = new Cpu(MEM); } catch (e) { status('Not enough memory for the game (' + (MEM >> 20) + ' MB): ' + e.message); diag.err = 'memory ' + e.message; return; }
  diag.stage = 'memory ok ' + (MEM >> 20) + ' MB';
  const APK = '/data/app/com.hello.bro.yo.apk', OBB = '/sdcard/Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb', FILES = '/data/data/com.hello.bro.yo/files';
  // the phone's files: the two big ones from the server, the rest (settings, downloads) kept in the browser
  const mem = new Map();
  const store = { get: (k) => { try { return localStorage.getItem(k); } catch { return null; } }, set: (k, v) => { try { if (v === null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch { /* private window */ } } };
  const b64 = (u) => { let s = ''; for (let i = 0; i < u.length; i += 8192) s += String.fromCharCode.apply(null, u.subarray(i, i + 8192)); return btoa(s); };
  const unb64 = (s) => { const b = atob(s), u = new Uint8Array(b.length); for (let i = 0; i < b.length; i++) u[i] = b.charCodeAt(i); return u; };
  // a big file in pieces (tools/build_webclient.js --emu writes assets/emu/<name>/<n>.dat, each 512 KB): fetched when first read,
  // the last 48 pieces kept (24 MB); the app's reads wait for the piece like a phone waits for its storage
  const PIECE = 512 << 10, kept = new Map();
  diag.pieces = 0;
  const piece = (name, i) => {
    const key = name + i;
    if (kept.has(key)) { const v = kept.get(key); kept.delete(key); kept.set(key, v); return v; }
    const x = new XMLHttpRequest();
    x.open('GET', ASSETS + name + '/' + String(i).padStart(4, '0') + '.dat', false);
    x.overrideMimeType('text/plain; charset=x-user-defined');
    x.send();
    if (x.status !== 200) throw new Error('game file piece ' + name + ' ' + i + ' missing (' + x.status + ')');
    const t = x.responseText, b = new Uint8Array(t.length);
    for (let k = 0; k < t.length; k++) b[k] = t.charCodeAt(k) & 255;
    kept.set(key, b); diag.pieces++;
    if (kept.size > 48) kept.delete(kept.keys().next().value);
    return b;
  };
  const pieces = (name, info) => ({ size: info.size, read(pos, n) {
    n = Math.max(0, Math.min(n, info.size - pos));
    const out = new Uint8Array(n);
    let done = 0;
    while (done < n) { const p = pos + done, i = Math.floor(p / PIECE), off = p - i * PIECE, b = piece(name, i), k = Math.min(n - done, b.length - off); out.set(b.subarray(off, off + k), done); done += k; }
    return out;
  } });
  // files the app writes (the hot update it downloads and unpacks, its settings) are kept in the browser's IndexedDB, so the
  // next visit does not download the update again (localStorage holds only ~5 MB). All of them are read into memory before the
  // start; writes are saved in the background. ?fresh=1 starts with none.
  const db = await new Promise((ok) => { try { const r = indexedDB.open('emu-files', 1); r.onupgradeneeded = () => r.result.createObjectStore('f'); r.onsuccess = () => ok(r.result); r.onerror = () => ok(null); } catch { ok(null); } });
  const dbDo = (fn) => { if (!db) return; try { const t = db.transaction('f', 'readwrite'); fn(t.objectStore('f')); } catch { /* storage full or blocked */ } };
  if (db && q.get('fresh') === '1') dbDo((s) => s.clear());
  else if (db) await new Promise((ok) => { try { const t = db.transaction('f', 'readonly'), s = t.objectStore('f'), c = s.openCursor(); c.onsuccess = () => { const cur = c.result; if (!cur) return ok(); mem.set(cur.key, new Uint8Array(cur.value)); cur.continue(); }; c.onerror = () => ok(); } catch { ok(); } });
  const vfs = {
    openLazy(p) { return p === APK ? pieces('apk', parts.apk) : p === OBB ? pieces('obb', parts.obb) : null; },
    read(p) { if (p === APK || p === OBB) return null; if (mem.has(p)) return mem.get(p); const s = store.get('emu.file.' + p); if (s === null) return null; const u = unb64(s); mem.set(p, u); return u; },
    write(p, data) {
      if (data === null) { mem.delete(p); store.set('emu.file.' + p, null); dbDo((s) => s.delete(p)); return; }
      const u = new Uint8Array(data); mem.set(p, u);
      if (db) dbDo((s) => s.put(u.slice().buffer, p)); else if (u.length < 300000) store.set('emu.file.' + p, b64(u));
    },
    exists(p) { return this.read(p) !== null; }, isDir: () => false, list: () => [],
  };
  let sys, jni, lib;
  const GLF = {};
  sys = window.EmuMakeSys(cpu, { heapStart: 0x01000000, heapEnd: MEM - (8 << 20), vfs, log, extra: GLF });
  Object.assign(GLF, window.EmuMakeGl(cpu, sys, gl, log));
  status('Starting the game…');
  await new Promise((ok) => setTimeout(ok, 30));
  lib = window.EmuLoadElf(cpu, so, BASE, sys.resolve);
  sys.exidx = lib.exidx;
  cpu.r[13] = MEM - 0x1000;
  cpu.tls = sys.calloc(1, 64);
  const sym = (n) => lib.sym(n);
  // the app's requests: sent to this page's own server, whatever address the app was built for (waits for the answer, like the app's own network thread did)
  const requests = (window.emuRequests = []);
  window.EmuHookFast(cpu, lib, (m) => console.log(m)); // the busiest library functions (pictures, zip) in fast JavaScript
  // often-used code turned into JavaScript blocks (jit.js); ?jit=0 runs every instruction through cpu.js
  if (q.get('jit') !== '0') { window.EmuAttachJit(Cpu); cpu.enableJit(lib.base, lib.end, Number(q.get('jit')) || 64); window.emuCpu = cpu; }
  window.EmuHookCurl(cpu, sys, lib, (rq) => {
    const u = new URL(rq.url);
    const x = new XMLHttpRequest();
    // the hot-update zips also sit next to the other emulator files as .dat (tools/build_webclient.js --emu): some browsers
    // hand a script an empty answer for a .zip address (seen in headless Chrome: status 204)
    const cdn = rq.method === 'GET' && u.pathname.startsWith('/cdn/') && u.pathname.endsWith('.zip');
    x.open(rq.method, cdn ? ASSETS + 'cdn/' + u.pathname.slice(5, -4) + '.dat' : API + u.pathname + u.search, false);
    x.overrideMimeType('text/plain; charset=x-user-defined'); // the bytes as they are
    if (rq.body) x.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    x.send(rq.body || null);
    const t = x.responseText, body = new Uint8Array(t.length);
    for (let i = 0; i < t.length; i++) body[i] = t.charCodeAt(i) & 255;
    requests.push(rq.method + ' ' + u.pathname + ' -> ' + x.status + ', ' + body.length + ' bytes');
    if (q.get('log')) console.log('[request] ' + requests[requests.length - 1]);
    return { status: x.status, body };
  }, log);

  // ---------------------------------------------------------------- the Java side
  const prefs = (k) => 'emu.pref.' + k;
  const textCanvas = document.createElement('canvas'), tctx = textCanvas.getContext('2d', { willReadFrequently: true });
  // the account window (the Gumptech SDK's Java code on the phone): the same accounts on our server (server/gumplogin.js)
  const later = []; // things to do at the start of the next frame (never from inside a call of the app)
  const account = { uid: '', session: '', nick: '' };
  const form = (path, data) => { const x = new XMLHttpRequest(); x.open('POST', API + path, false); x.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded'); x.send(new URLSearchParams({ appId: 10015, ...data }).toString()); try { return JSON.parse(x.responseText); } catch { return null; } };
  const deviceId = () => { if (q.get('device')) return 'web-test-' + q.get('device'); let d = store.get('hb.device'); if (!d) { d = 'web-' + Array.from(crypto.getRandomValues(new Uint8Array(12)), (b) => b.toString(16).padStart(2, '0')).join(''); store.set('hb.device', d); } return d; };
  const guestLogin = () => {
    const dev = deviceId(), pw = store.get('hb.guestpw');
    let r = pw ? form('/quick/login.do', { deviceId: dev, passwd: pw }) : null;
    if (!r || r.code !== 100000) { r = form('/quick/reg.do', { deviceId: dev, appkey: '' }); if (r && r.passwd) store.set('hb.guestpw', r.passwd); }
    if (r && r.code === 100000) { account.uid = String(r.userId); account.session = r.sessionKey; account.nick = r.nick || ''; return true; }
    return false;
  };
  // the account window (on Android: the Gumptech SDK's window): Play as a guest, Log in or Sign up with a name and password
  // (server/gumplogin.js, the same accounts as the Android app). The login is kept in this browser (hb.login / hb.guestpw);
  // the game's "user center" buttons (login screen, game settings) open it again to sign up, switch or log out.
  const CODES = { 100010: 'Wrong password.', 100011: 'That name is already taken.', 100012: 'No account with that name.', 100013: 'Name or password too short (name 3+, password 4+ characters).' };
  const savedLogin = () => { try { return JSON.parse(store.get('hb.login') || 'null'); } catch { return null; } };
  const useAnswer = (r) => { account.uid = String(r.userId); account.session = r.sessionKey; account.nick = r.nick || ''; };
  const named = (email, pw, how) => {
    const r = form(how === 'reg' ? '/gump/reg.do' : '/gump/login.do', { deviceId: deviceId(), email, passwd: pw, appkey: '' });
    if (r && r.code === 100000) { store.set('hb.login', JSON.stringify({ email, pw })); useAnswer(r); return ''; }
    return (r && CODES[r.code]) || 'The server did not answer. Try again.';
  };
  const silentLogin = () => { const s = savedLogin(); if (s) return !named(s.email, s.pw, 'login'); return store.get('hb.guestpw') ? guestLogin() : false; };
  const loginForm = async (how, error) => {
    const reg = how === 'reg';
    const r = await window.EmuUI.dialog({
      title: reg ? 'Sign up' : 'Log in',
      text: reg ? (store.get('hb.guestpw') && !savedLogin() ? 'Your guest character gets this name and password, so you can play it on any device.' : 'Pick a name and a password for your account.') : 'Log in with the name and password of your account (the same as in the Android game).',
      fields: [{ name: 'email', label: 'Account name', autocomplete: 'username', max: 40 }, { name: 'pw', label: 'Password', type: 'password', autocomplete: reg ? 'new-password' : 'current-password', max: 40 }].concat(reg ? [{ name: 'pw2', label: 'Password again', type: 'password', autocomplete: 'new-password', max: 40 }] : []),
      buttons: [{ label: reg ? 'Sign up' : 'Log in', value: 'go' }, { label: 'Back', value: 'back', kind: 'grey' }].concat(reg ? [] : [{ label: 'Android player without a name? Read this', value: 'android', kind: 'link' }]),
      error,
    });
    if (r.button === 'android') { await androidHelp(); return loginForm(how, error); }
    if (r.button !== 'go') return false;
    const email = r.values.email.trim(), pw = r.values.pw;
    if (reg && pw !== r.values.pw2) return loginForm(how, 'The two passwords are not the same.');
    const err = named(email, pw, how);
    return err ? loginForm(how, err) : true;
  };
  const androidHelp = () => window.EmuUI.dialog({
    title: 'Your Android account',
    text: 'Log in here with the account name and password you use in the Android game.\n\n' +
      'Did you always tap PLAY on Android? Then your account has no name yet. Give it one first: open the game on your phone, ' +
      'tap "Login with Gumptech", then "Signup", and pick a name and password. Your character stays the same. ' +
      'After that, log in here with that name and play the same character.\n\nOne device at a time: the other one has to log in again.',
    buttons: [{ label: 'OK', value: 'ok' }],
  });
  const firstWindow = async () => {
    for (;;) {
      const r = await window.EmuUI.dialog({
        title: 'Ninja Online', text: 'Play right away as a guest, or log in to play your own account. A guest character is kept in this browser only: sign up later to keep it safe.',
        buttons: [{ label: 'Play as guest', value: 'guest' }, { label: 'Log in', value: 'login', kind: 'blue' }, { label: 'Sign up', value: 'reg', kind: 'blue' }, { label: 'I play on Android: how do I log in here?', value: 'android', kind: 'link' }],
      });
      if (r.button === 'guest') { if (guestLogin()) return true; continue; }
      if (r.button === 'android') { await androidHelp(); continue; }
      if (await loginForm(r.button)) return true;
    }
  };
  const userCenter = async () => {
    const s = savedLogin();
    const r = await window.EmuUI.dialog(s
      ? { title: 'Your account', text: 'Logged in as ' + s.email + '.', buttons: [{ label: 'Close', value: 'close' }, { label: 'Log out', value: 'out', kind: 'grey' }] }
      : { title: 'Your account', text: 'You play as a guest: this character is kept in this browser only. Sign up (free) to keep it safe and play it on other devices too.', buttons: [{ label: 'Sign up', value: 'reg' }, { label: 'Log in to another account', value: 'login', kind: 'blue' }, { label: 'Close', value: 'close', kind: 'grey' }] });
    if (r.button === 'out') { store.set('hb.login', null); store.set('hb.guestpw', null); store.set('hb.device', null); location.reload(); return; }
    if (r.button === 'reg') { await loginForm('reg'); return; } // the guest's own account gets the name: nothing else changes
    if (r.button === 'login') { if (await loginForm('login')) location.reload(); } // another account: start the game again with it
  };
  // typing (CCEditBox -> Cocos2dxHelper.showEditTextDialog): the page's own input box; the text goes back as UTF-8 bytes
  const editText = (title, message, inputMode, inputFlag, returnType, maxLength) => {
    window.EmuUI.dialog({
      title: title || '', fields: [{ name: 't', value: message || '', type: inputFlag === 0 ? 'password' : 'text', max: maxLength > 0 ? maxLength : 0, inputmode: inputMode === 2 || inputMode === 5 ? 'decimal' : inputMode === 3 ? 'tel' : inputMode === 1 ? 'email' : '' }],
      buttons: [{ label: 'OK', value: 'ok' }, { label: 'Cancel', value: 'cancel', kind: 'grey' }],
    }).then((r) => {
      const text = r.button === 'ok' ? r.values.t : (message || '');
      later.push(() => cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetEditTextDialogResult'), [jni.env, 0, jni.ref(new TextEncoder().encode(text))]));
    });
  };
  // music and sound effects (audio.js plays assets/emu/sound/<file>.mp3)
  const audio = window.EmuAudio ? window.EmuAudio(ASSETS + 'sound/') : null;
  const A = (fn, dflt) => (j, args) => (audio ? fn(...args) : dflt);
  const java = {
    'org/cocos2dx/lib/Cocos2dxHelper.showEditTextDialog': (j, args) => { editText(...args); },
    'com/xckoo/renlong/sdk/SDKHelper.openUserCenter': () => { userCenter(); },
    'com/xckoo/renlong/sdk/SDKHelper.logout': () => { store.set('hb.login', null); later.push(() => cpu.call(sym('Java_com_xckoo_renlong_sdk_SDKCallbacks_didLogouted'), [jni.env, 0])); },
    'org/cocos2dx/lib/Cocos2dxHelper.preloadBackgroundMusic': A((p) => audio.preload(p)),
    'org/cocos2dx/lib/Cocos2dxHelper.playBackgroundMusic': A((p, loop) => audio.playMusic(p, loop)),
    'org/cocos2dx/lib/Cocos2dxHelper.stopBackgroundMusic': A(() => audio.stopMusic()),
    'org/cocos2dx/lib/Cocos2dxHelper.pauseBackgroundMusic': A(() => audio.pauseMusic()),
    'org/cocos2dx/lib/Cocos2dxHelper.resumeBackgroundMusic': A(() => audio.resumeMusic()),
    'org/cocos2dx/lib/Cocos2dxHelper.rewindBackgroundMusic': A(() => audio.rewindMusic()),
    'org/cocos2dx/lib/Cocos2dxHelper.isBackgroundMusicPlaying': A(() => audio.isMusicPlaying(), false),
    'org/cocos2dx/lib/Cocos2dxHelper.getBackgroundMusicVolume': A(() => audio.musicVolume, 0),
    'org/cocos2dx/lib/Cocos2dxHelper.setBackgroundMusicVolume': A((v) => audio.setMusicVolume(v)),
    'org/cocos2dx/lib/Cocos2dxHelper.preloadEffect': A((p) => audio.preload(p)),
    'org/cocos2dx/lib/Cocos2dxHelper.playEffect': A((p, loop) => audio.playEffect(p, loop), 0),
    'org/cocos2dx/lib/Cocos2dxHelper.stopEffect': A((id) => audio.stopEffect(id)),
    'org/cocos2dx/lib/Cocos2dxHelper.pauseEffect': A((id) => audio.stopEffect(id)),
    'org/cocos2dx/lib/Cocos2dxHelper.resumeEffect': A(() => {}),
    'org/cocos2dx/lib/Cocos2dxHelper.stopAllEffects': A(() => audio.stopAllEffects()),
    'org/cocos2dx/lib/Cocos2dxHelper.pauseAllEffects': A(() => audio.stopAllEffects()),
    'org/cocos2dx/lib/Cocos2dxHelper.resumeAllEffects': A(() => {}),
    'org/cocos2dx/lib/Cocos2dxHelper.unloadEffect': A(() => {}),
    'org/cocos2dx/lib/Cocos2dxHelper.getEffectsVolume': A(() => audio.effectsVolume, 0),
    'org/cocos2dx/lib/Cocos2dxHelper.setEffectsVolume': A((v) => audio.setEffectsVolume(v)),
    'org/cocos2dx/lib/Cocos2dxHelper.end': A(() => { audio.stopMusic(); audio.stopAllEffects(); }),
    'org/cocos2dx/lib/Cocos2dxBitmap.getFontSizeAccordingHeight': (j, [h]) => Math.max(1, Math.round(h / 1.17)),
    // the opening video after creating a character: skipped, the app is told it has finished (its int argument is stored as
    // "still playing": 0 = done; the app set it to 1 and its CVideoPlayingScene waits for 0)
    'com/xckoo/renlong/CustomDialog.playGameStartVideo': () => { later.push(() => cpu.call(sym('Java_com_xckoo_renlong_RLVideoActivity_playRLVideoComplete'), [jni.env, 0, 0])); },
    'com/xckoo/renlong/sdk/SDKHelper.setRoleInfo': () => {},
    'com/xckoo/renlong/sdk/SDKHelper.isLogined': () => !!account.session,
    'com/xckoo/renlong/sdk/SDKHelper.userId': () => account.uid,
    'com/xckoo/renlong/sdk/SDKHelper.session': () => account.session,
    'com/xckoo/renlong/sdk/SDKHelper.nickName': () => account.nick,
    'com/xckoo/renlong/FileHelper.deleteFolder': () => true,
    'com/xckoo/renlong/sdk/SDKHelper.login': () => {
      const done = (ok) => later.push(() => cpu.call(sym('Java_com_xckoo_renlong_sdk_SDKCallbacks_' + (ok ? 'didLogined' : 'loginCancel')), [jni.env, 0]));
      if (q.get('device')) return done(guestLogin()); // tests: the same guest every time, no window
      if (silentLogin()) return done(true);
      firstWindow().then(done);
    },
    'org/cocos2dx/lib/Cocos2dxHelper.getCocos2dxPackageName': () => 'com.hello.bro.yo',
    'org/cocos2dx/lib/Cocos2dxHelper.getCurrentLanguage': () => 'en',
    'org/cocos2dx/lib/Cocos2dxHelper.getDeviceModel': () => 'Web',
    'org/cocos2dx/lib/Cocos2dxHelper.getCocos2dxWritablePath': () => FILES,
    'org/cocos2dx/lib/Cocos2dxHelper.getDPI': () => 320,
    'com/xckoo/renlong/AppInfo.getVersionName': () => '28.0',
    'org/cocos2dx/lib/Cocos2dxRenderer.setAnimationInterval': () => {},
    'org/cocos2dx/lib/Cocos2dxHelper.getStringForKey': (j, [k, d]) => store.get(prefs(k)) ?? d,
    'org/cocos2dx/lib/Cocos2dxHelper.setStringForKey': (j, [k, v]) => store.set(prefs(k), String(v)),
    'org/cocos2dx/lib/Cocos2dxHelper.getBoolForKey': (j, [k, d]) => { const v = store.get(prefs(k)); return v === null ? d : v === 'true'; },
    'org/cocos2dx/lib/Cocos2dxHelper.setBoolForKey': (j, [k, v]) => store.set(prefs(k), v ? 'true' : 'false'),
    'org/cocos2dx/lib/Cocos2dxHelper.getIntegerForKey': (j, [k, d]) => { const v = store.get(prefs(k)); return v === null ? d : Number(v) | 0; },
    'org/cocos2dx/lib/Cocos2dxHelper.setIntegerForKey': (j, [k, v]) => store.set(prefs(k), String(v)),
    'org/cocos2dx/lib/Cocos2dxHelper.getFloatForKey': (j, [k, d]) => { const v = store.get(prefs(k)); return v === null ? d : Number(v); },
    'org/cocos2dx/lib/Cocos2dxHelper.setFloatForKey': (j, [k, v]) => store.set(prefs(k), String(v)),
    'org/cocos2dx/lib/Cocos2dxHelper.getDoubleForKey': (j, [k, d]) => { const v = store.get(prefs(k)); return v === null ? d : Number(v); },
    'org/cocos2dx/lib/Cocos2dxHelper.setDoubleForKey': (j, [k, v]) => store.set(prefs(k), String(v)),
    // text: Android drew every label into a bitmap in Java; here a 2D canvas does it, then the pixels go back to the app
    // (Cocos2dxBitmap.createTextBitmapShadowStroke -> nativeInitBitmapDC(width, height, pixels))
    'org/cocos2dx/lib/Cocos2dxBitmap.createTextBitmapShadowStroke': (j, [text, font, size, r, g, b, align, w, h, shadow, sdx, sdy, sblur, stroke, sr, sg, sb, ssize]) => {
      text = String(text ?? '');
      const fontCss = `${Math.max(1, size)}px Roboto, "Helvetica Neue", "Segoe UI", Arial, sans-serif`;
      tctx.font = fontCss;
      const lh = Math.ceil(size * 1.17);
      const lines = [];
      for (const para of text.split('\n')) {
        if (!(w > 0)) { lines.push(para); continue; }
        let cur = '';
        for (const part of para.match(/\S+\s*|\s+/g) || ['']) {
          if (tctx.measureText(cur + part).width <= w || !cur) cur += part; else { lines.push(cur); cur = part; }
          while (tctx.measureText(cur).width > w && cur.length > 1) { let k = cur.length - 1; while (k > 1 && tctx.measureText(cur.slice(0, k)).width > w) k--; lines.push(cur.slice(0, k)); cur = cur.slice(k); }
        }
        lines.push(cur);
      }
      const pad = stroke ? Math.ceil(ssize) : 0;
      const tw = Math.ceil(Math.max(1, ...lines.map((l) => tctx.measureText(l).width))) + pad * 2;
      const W = Math.max(1, w > 0 ? w : tw), H = Math.max(1, h > 0 ? h : lines.length * lh + pad * 2);
      textCanvas.width = W; textCanvas.height = H;
      tctx.font = fontCss; tctx.textBaseline = 'top';
      const ha = align & 15, va = (align >> 4) & 15; // 1 left / 2 right / 3 centre; 1 top / 2 bottom / 3 centre
      tctx.textAlign = ha === 3 ? 'center' : ha === 2 ? 'right' : 'left';
      const x = ha === 3 ? W / 2 : ha === 2 ? W - pad : pad;
      let y = va === 3 ? (H - lines.length * lh) / 2 : va === 2 ? H - lines.length * lh - pad : pad;
      y += (lh - size) / 2;
      if (shadow) { tctx.shadowColor = 'rgba(0,0,0,0.6)'; tctx.shadowOffsetX = sdx; tctx.shadowOffsetY = -sdy; tctx.shadowBlur = sblur; }
      for (const l of lines) {
        if (stroke) { tctx.lineWidth = ssize * 2; tctx.lineJoin = 'round'; tctx.strokeStyle = `rgb(${sr * 255 | 0},${sg * 255 | 0},${sb * 255 | 0})`; tctx.strokeText(l, x, y); }
        tctx.fillStyle = `rgb(${r * 255 | 0},${g * 255 | 0},${b * 255 | 0})`; tctx.fillText(l, x, y); y += lh;
      }
      const px = tctx.getImageData(0, 0, W, H).data;
      for (let i = 0; i < px.length; i += 4) { const a = px[i + 3]; if (a < 255) { px[i] = px[i] * a / 255; px[i + 1] = px[i + 1] * a / 255; px[i + 2] = px[i + 2] * a / 255; } } // Android bitmaps are premultiplied
      cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxBitmap_nativeInitBitmapDC'), [jni.env, 0, W, H, jni.ref(new Uint8Array(px.buffer))]);
    },
  };
  jni = window.EmuMakeJni(cpu, sys, java, log);
  window.emu = { cpu, sys, jni, lib, java, log: logLines };

  // ---------------------------------------------------------------- boot, then one frame per screen refresh
  const t0 = performance.now();
  diag.stage = 'booting';
  try {
    // in slices, so the phone stays responsive and the green line shows how far the start is (about 350 M)
    const tick = () => { const s = (performance.now() - t0) / 1000; diag.stage = 'starting ' + Math.round(cpu.steps / 1e6) + ' M instructions, ' + s.toFixed(0) + ' s (' + (cpu.steps / 1e6 / Math.max(0.1, s)).toFixed(0) + ' M/s)'; status('Starting the game… ' + Math.min(99, Math.round(cpu.steps / 3.5e6)) + '%'); };
    for (const f of lib.init) await cpu.callAsync(f, [], 3e6, tick);
    await cpu.callAsync(sym('JNI_OnLoad'), [jni.vm, 0], 3e6, tick);
    await cpu.callAsync(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetApkPath'), [jni.env, 0, jni.ref(APK)], 3e6, tick);
    await cpu.callAsync(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetObbPath'), [jni.env, 0, jni.ref(OBB)], 3e6, tick);
    await cpu.callAsync(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeInit'), [jni.env, 0, canvas.width, canvas.height], 3e6, tick);
  } catch (e) { status('The game stopped while starting: ' + e.message); diag.err = 'start: ' + e.message; console.error(e); return; }
  diag.stage = 'running (start took ' + ((performance.now() - t0) / 1000).toFixed(1) + ' s)';
  console.log(`app started: ${(cpu.steps / 1e6).toFixed(0)} M instructions in ${((performance.now() - t0) / 1000).toFixed(1)} s`);
  status('');
  const render = sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeRender');
  let dead = false, frames = 0;
  const perf = (window.emu.perf = { ms: 0, steps: 0, n: 0 });
  const frame = () => {
    if (dead) return;
    const f0 = performance.now(), s0 = cpu.steps;
    try { while (later.length) later.shift()(); cpu.call(render, [jni.env, 0]); sys.runThreads(); frames++; diag.frames = frames; diag.ms = diag.ms * 0.95 + (performance.now() - f0) * 0.05; } catch (e) { dead = true; diag.err = 'frame: ' + e.message; status('The game stopped: ' + e.message); console.error(e); return; }
    // how heavy a frame is: time and instructions, averaged (window.emu.perf); logged every 10 s with &log=1
    perf.ms += performance.now() - f0; perf.steps += cpu.steps - s0; perf.n++;
    if (perf.n >= 600) { if (q.get('log')) console.log('[perf] ' + (perf.ms / perf.n).toFixed(1) + ' ms and ' + (perf.steps / perf.n / 1000).toFixed(0) + ' K instructions per frame'); perf.last = { ms: perf.ms / perf.n, steps: perf.steps / perf.n }; perf.ms = perf.steps = perf.n = 0; }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
  window.emu.frames = () => frames;
  // touches: Cocos2dxRenderer.nativeTouchesBegin(id, x, y) / nativeTouchesEnd / nativeTouchesMove(int[] ids, float[] xs, float[] ys)
  const pos = (e) => { const r = canvas.getBoundingClientRect(); return [(e.clientX - r.left) / r.width * canvas.width, (e.clientY - r.top) / r.height * canvas.height]; };
  const touch = (name, e) => { if (dead || cpu.busy) return; const [x, y] = pos(e); try { cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_' + name), [jni.env, 0, 0, sys.retF(x), sys.retF(y)]); } catch (err) { console.error(err); } };
  // test switch: &taps=0.5,0.86@12;0.5,0.6@20 = tap at that part of the screen (x,y from 0 to 1) so many seconds after the start
  const tapAt = (fx, fy) => { if (cpu.busy) return; for (const n of ['nativeTouchesBegin', 'nativeTouchesEnd']) cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_' + n), [jni.env, 0, 0, sys.retF(fx * canvas.width), sys.retF(fy * canvas.height)]); };
  for (const t of (q.get('taps') || '').split(';').filter(Boolean)) { const [xy, at] = t.split('@'), [fx, fy] = xy.split(',').map(Number); setTimeout(() => { try { tapAt(fx, fy); } catch (e) { console.error(e); } }, Number(at) * 1000); }
  window.emu.tap = tapAt;
  canvas.addEventListener('pointerdown', (e) => { if (audio) audio.unlock(); canvas.setPointerCapture(e.pointerId); touch('nativeTouchesBegin', e); });
  document.addEventListener('visibilitychange', () => { if (audio) { if (document.hidden) audio.pauseAll(); else audio.resumeAll(); } });
  canvas.addEventListener('pointerup', (e) => touch('nativeTouchesEnd', e));
  canvas.addEventListener('pointercancel', (e) => touch('nativeTouchesEnd', e));
  canvas.addEventListener('pointermove', (e) => { if (dead || !(e.buttons & 1) && e.pointerType === 'mouse') return; const [x, y] = pos(e); try { cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesMove'), [jni.env, 0, jni.ref(new Int32Array([0])), jni.ref(new Float32Array([x])), jni.ref(new Float32Array([y]))]); } catch (err) { console.error(err); } });
})();
