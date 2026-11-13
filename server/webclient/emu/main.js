// Runs the original Android app (libgame.so, ARM code) in the browser: the emulator (cpu.js), Android's linker (elf.js), the
// system functions (sys.js), the Java side (jni.js + the Java methods below) and OpenGL on WebGL (gl.js).
// Files it needs (made by tools/build_webclient.js, not in git): assets/emu/libgame.dat, game-apk.dat, main-obb.dat.
'use strict';
(async function () {
  const Cpu = window.EmuCpu, status = (t) => { const m = document.getElementById('msg'); m.textContent = t || ''; m.style.display = t ? '' : 'none'; };
  const q = new URLSearchParams(location.search);
  const diag = { stage: 'loading', frames: 0, err: '', lost: false, ms: 0 };
  // how fast this browser runs plain JavaScript: about 3 ms on a phone or PC with the browser's fast compiler on, 50+ ms when
  // it is off (iPhone Lockdown Mode turns it off; Low Power Mode slows it too)
  { const b0 = performance.now(); let x = 0; for (let i = 0; i < 3e6; i++) x = (Math.imul(x, 31) + i) | 0; diag.js = performance.now() - b0 + (x & 0); }
  window.emuDiag = diag;
  if (q.get('diag') !== '0') {
    const d = document.createElement('div');
    d.style.cssText = 'position:fixed;left:4px;top:4px;right:4px;z-index:9;color:#9f9;font:11px/1.3 monospace;background:rgba(0,0,0,.55);padding:3px 5px;pointer-events:none;white-space:pre-wrap;word-break:break-all';
    document.body.appendChild(d);
    setInterval(() => {
      const mb = performance.memory ? ' js ' + (performance.memory.usedJSHeapSize >> 20) + ' MB' : '';
      const last = (window.emuLog || []).filter((l) => !/GETTING FILE|CCTextureCache|no node/.test(l)).slice(-2).join(' | ').slice(0, 160);
      d.textContent = 'v7 ' + diag.stage + ' · frames ' + diag.frames + (window.emuCpu && window.emuCpu.jitCount ? ' · blocks ' + window.emuCpu.jitCount : '') + ' · pieces ' + (diag.pieces || 0) + (diag.ms ? ' · ' + diag.ms.toFixed(1) + ' ms' : '') + mb + ' · js ' + diag.js.toFixed(0) + ' ms' + (diag.js > 60 ? ' (slow: Lockdown/Low Power Mode?)' : '') + (diag.lost ? ' · GL LOST' : '') + (diag.err ? '\nERROR: ' + diag.err : '') + '\n' + last;
    }, 500);
  }
  window.addEventListener('error', (e) => { diag.err = String(e.message || e.error).slice(0, 300); });
  window.addEventListener('unhandledrejection', (e) => { diag.err = String((e.reason && (e.reason.message || e.reason)) || e.reason).slice(0, 300); });
  const logLines = (window.emuLog = []);
  const log = (s) => { logLines.push(s); if (logLines.length > 3000) logLines.shift(); if (q.get('log')) console.log('[app] ' + s); };
  const get = async (name) => { const r = await fetch('../assets/emu/' + name); if (!r.ok) throw new Error(name + ' is missing: run node tools/build_webclient.js --emu'); return new Uint8Array(await r.arrayBuffer()); };
  status('Loading the game files…');
  let so, apk, obb;
  let parts;
  try { so = await get('libgame.dat'); parts = JSON.parse(new TextDecoder().decode(await get('parts.json'))); } catch (e) { status(e.message); return; }
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
    x.open('GET', '../assets/emu/' + name + '/' + String(i).padStart(4, '0') + '.dat', false);
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
  const vfs = {
    openLazy(p) { return p === APK ? pieces('apk', parts.apk) : p === OBB ? pieces('obb', parts.obb) : null; },
    read(p) { if (p === APK || p === OBB) return null; if (mem.has(p)) return mem.get(p); const s = store.get('emu.file.' + p); if (s === null) return null; const u = unb64(s); mem.set(p, u); return u; },
    write(p, data) { if (data === null) { mem.delete(p); store.set('emu.file.' + p, null); return; } const u = new Uint8Array(data); mem.set(p, u); if (u.length < 300000) store.set('emu.file.' + p, b64(u)); },
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
    x.open(rq.method, cdn ? '../assets/emu/cdn/' + u.pathname.slice(5, -4) + '.dat' : u.pathname + u.search, false);
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
  const form = (path, data) => { const x = new XMLHttpRequest(); x.open('POST', path, false); x.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded'); x.send(new URLSearchParams({ appId: 10015, ...data }).toString()); try { return JSON.parse(x.responseText); } catch { return null; } };
  const deviceId = () => { if (q.get('device')) return 'web-test-' + q.get('device'); let d = store.get('hb.device'); if (!d) { d = 'web-' + Array.from(crypto.getRandomValues(new Uint8Array(12)), (b) => b.toString(16).padStart(2, '0')).join(''); store.set('hb.device', d); } return d; };
  const guestLogin = () => {
    const dev = deviceId(), pw = store.get('hb.guestpw');
    let r = pw ? form('/quick/login.do', { deviceId: dev, passwd: pw }) : null;
    if (!r || r.code !== 100000) { r = form('/quick/reg.do', { deviceId: dev, appkey: '' }); if (r && r.passwd) store.set('hb.guestpw', r.passwd); }
    if (r && r.code === 100000) { account.uid = String(r.userId); account.session = r.sessionKey; account.nick = r.nick || ''; return true; }
    return false;
  };
  const java = {
    'org/cocos2dx/lib/Cocos2dxBitmap.getFontSizeAccordingHeight': (j, [h]) => Math.max(1, Math.round(h / 1.17)),
    // the opening video after creating a character: skipped, the app is told it has finished
    'com/xckoo/renlong/CustomDialog.playGameStartVideo': () => { later.push(() => cpu.call(sym('Java_com_xckoo_renlong_RLVideoActivity_playRLVideoComplete'), [jni.env, 0])); },
    'org/cocos2dx/lib/Cocos2dxHelper.stopAllEffects': () => {}, 'org/cocos2dx/lib/Cocos2dxHelper.pauseBackgroundMusic': () => {}, 'org/cocos2dx/lib/Cocos2dxHelper.resumeBackgroundMusic': () => {},
    'com/xckoo/renlong/sdk/SDKHelper.setRoleInfo': () => {}, 'org/cocos2dx/lib/Cocos2dxHelper.isBackgroundMusicPlaying': () => false,
    'com/xckoo/renlong/sdk/SDKHelper.isLogined': () => !!account.session,
    'com/xckoo/renlong/sdk/SDKHelper.userId': () => account.uid,
    'com/xckoo/renlong/sdk/SDKHelper.session': () => account.session,
    'com/xckoo/renlong/sdk/SDKHelper.nickName': () => account.nick,
    'org/cocos2dx/lib/Cocos2dxHelper.playBackgroundMusic': () => {}, 'org/cocos2dx/lib/Cocos2dxHelper.playEffect': () => 0, 'org/cocos2dx/lib/Cocos2dxHelper.stopBackgroundMusic': () => {},
    'com/xckoo/renlong/FileHelper.deleteFolder': () => true,
    'com/xckoo/renlong/sdk/SDKHelper.login': () => { const ok = guestLogin(); later.push(() => cpu.call(sym('Java_com_xckoo_renlong_sdk_SDKCallbacks_' + (ok ? 'didLogined' : 'loginCancel')), [jni.env, 0])); },
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
  canvas.addEventListener('pointerdown', (e) => { canvas.setPointerCapture(e.pointerId); touch('nativeTouchesBegin', e); });
  canvas.addEventListener('pointerup', (e) => touch('nativeTouchesEnd', e));
  canvas.addEventListener('pointercancel', (e) => touch('nativeTouchesEnd', e));
  canvas.addEventListener('pointermove', (e) => { if (dead || !(e.buttons & 1) && e.pointerType === 'mouse') return; const [x, y] = pos(e); try { cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesMove'), [jni.env, 0, jni.ref(new Int32Array([0])), jni.ref(new Float32Array([x])), jni.ref(new Float32Array([y]))]); } catch (err) { console.error(err); } });
})();
