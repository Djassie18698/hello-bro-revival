// Runs the original Android app (libgame.so, ARM code) in the browser: the emulator (cpu.js), Android's linker (elf.js), the
// system functions (sys.js), the Java side (jni.js + the Java methods below) and OpenGL on WebGL (gl.js).
// Files it needs (made by tools/build_webclient.js, not in git): assets/emu/libgame.dat, game-apk.dat, main-obb.dat.
'use strict';
(async function () {
  const Cpu = window.EmuCpu, status = (t) => { const m = document.getElementById('msg'); m.textContent = t || ''; m.style.display = t ? '' : 'none'; };
  const q = new URLSearchParams(location.search);
  const logLines = (window.emuLog = []);
  const log = (s) => { logLines.push(s); if (logLines.length > 3000) logLines.shift(); if (q.get('log')) console.log('[app] ' + s); };
  const get = async (name) => { const r = await fetch('../assets/emu/' + name); if (!r.ok) throw new Error(name + ' is missing: run node tools/build_webclient.js --emu'); return new Uint8Array(await r.arrayBuffer()); };
  status('Loading the game files…');
  let so, apk, obb;
  try { so = await get('libgame.dat'); apk = await get('game-apk.dat'); obb = await get('main-obb.dat'); } catch (e) { status(e.message); return; }

  console.log('files: code ' + so.length + ', apk ' + apk.length + ', data ' + obb.length + ' bytes');
  const canvas = document.getElementById('game');
  const fit = () => { let w = innerWidth, h = innerHeight; if (h / w < 1.5) w = Math.round(h / 1.78); canvas.style.width = w + 'px'; canvas.style.height = h + 'px'; return [w, h]; };
  const [cw, ch] = fit();
  const dpr = Math.min(devicePixelRatio || 1, 2);
  canvas.width = Math.round(cw * dpr); canvas.height = Math.round(ch * dpr);
  const gl = canvas.getContext('webgl', { alpha: false, antialias: false, stencil: true, depth: true, preserveDrawingBuffer: !!q.get('keep') });
  if (!gl) { status('This browser has no WebGL'); return; }

  const MEM = (Number(q.get('mem')) || 384) << 20, BASE = 0x10000;
  const cpu = new Cpu(MEM);
  const APK = '/data/app/com.hello.bro.yo.apk', OBB = '/sdcard/Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb', FILES = '/data/data/com.hello.bro.yo/files';
  // the phone's files: the two big ones from the server, the rest (settings, downloads) kept in the browser
  const mem = new Map();
  const store = { get: (k) => { try { return localStorage.getItem(k); } catch { return null; } }, set: (k, v) => { try { if (v === null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch { /* private window */ } } };
  const b64 = (u) => { let s = ''; for (let i = 0; i < u.length; i += 8192) s += String.fromCharCode.apply(null, u.subarray(i, i + 8192)); return btoa(s); };
  const unb64 = (s) => { const b = atob(s), u = new Uint8Array(b.length); for (let i = 0; i < b.length; i++) u[i] = b.charCodeAt(i); return u; };
  const vfs = {
    read(p) { if (p === APK) return apk; if (p === OBB) return obb; if (mem.has(p)) return mem.get(p); const s = store.get('emu.file.' + p); if (s === null) return null; const u = unb64(s); mem.set(p, u); return u; },
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

  // ---------------------------------------------------------------- the Java side
  const prefs = (k) => 'emu.pref.' + k;
  const textCanvas = document.createElement('canvas'), tctx = textCanvas.getContext('2d', { willReadFrequently: true });
  const java = {
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
  try {
    for (const f of lib.init) cpu.call(f, []);
    cpu.call(sym('JNI_OnLoad'), [jni.vm, 0]);
    cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetApkPath'), [jni.env, 0, jni.ref(APK)]);
    cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetObbPath'), [jni.env, 0, jni.ref(OBB)]);
    cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeInit'), [jni.env, 0, canvas.width, canvas.height]);
  } catch (e) { status('The game stopped while starting: ' + e.message); console.error(e); return; }
  console.log(`app started: ${(cpu.steps / 1e6).toFixed(0)} M instructions in ${((performance.now() - t0) / 1000).toFixed(1)} s`);
  status('');
  const render = sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeRender');
  let dead = false, frames = 0;
  const frame = () => {
    if (dead) return;
    try { cpu.call(render, [jni.env, 0]); frames++; } catch (e) { dead = true; status('The game stopped: ' + e.message); console.error(e); return; }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
  window.emu.frames = () => frames;
  // touches: Cocos2dxRenderer.nativeTouchesBegin(id, x, y) / nativeTouchesEnd / nativeTouchesMove(int[] ids, float[] xs, float[] ys)
  const pos = (e) => { const r = canvas.getBoundingClientRect(); return [(e.clientX - r.left) / r.width * canvas.width, (e.clientY - r.top) / r.height * canvas.height]; };
  const touch = (name, e) => { if (dead) return; const [x, y] = pos(e); try { cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_' + name), [jni.env, 0, 0, sys.retF(x), sys.retF(y)]); } catch (err) { console.error(err); } };
  canvas.addEventListener('pointerdown', (e) => { canvas.setPointerCapture(e.pointerId); touch('nativeTouchesBegin', e); });
  canvas.addEventListener('pointerup', (e) => touch('nativeTouchesEnd', e));
})();
