// Boots the original app's code (re/libgame.so) inside the web client's ARM emulator, in Node, without graphics: a fast way
// to see how far it gets and which system function it wants next. node tools/dev/emu-boot.js [frames=3] [-v]
'use strict';
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..', '..');
const E = path.join(ROOT, 'server', 'webclient', 'emu');
const Cpu = require(path.join(E, 'cpu.js')), loadElf = require(path.join(E, 'elf.js')), makeSys = require(path.join(E, 'sys.js')), makeJni = require(path.join(E, 'jni.js')), hookCurl = require(path.join(E, 'net.js'));
const { spawnSync } = require('child_process');
const SERVER = process.env.HB_SERVER || 'http://127.0.0.1:18081';
const verbose = process.argv.includes('-v');
const frames = Number(process.argv.find((a) => /^\d+$/.test(a)) || 3);

const MEM = 448 << 20, BASE = 0x10000;
const cpu = new Cpu(MEM);
// the phone's files: the game's data folder (re/obb), the apk, and a folder the app may write to
const APK = '/data/app/com.hello.bro.yo.apk', OBB = '/sdcard/Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb', FILES = '/data/data/com.hello.bro.yo/files';
const written = new Map(), cache = new Map();
const apkFile = path.join(ROOT, 'release', 'HelloBro-for-127.0.0.1-18081.apk'), obbFile = path.join(ROOT, 're', 'emu', 'main.28.com.hello.bro.yo.obb'); // the obb: unpacked from the .xapk into re/emu
const real = (p) => {
  if (written.has(p)) return null;
  if (p === APK) return apkFile || null;
  if (p === OBB) return obbFile;
  return null;
};
// the apk and the data file are read in 512 KB pieces like in the browser (main.js), counting the pieces the app needs
const pieceSeen = new Set(), pieceReads = { n: 0 };
const lazy = (p) => {
  const file = p === APK ? apkFile : p === OBB ? obbFile : null;
  if (!file) return null;
  const data = vfs.read(p);
  return { size: data.length, read(pos, n) { n = Math.max(0, Math.min(n, data.length - pos)); pieceReads.n++; for (let i = pos >> 19; i <= (pos + n - 1) >> 19; i++) pieceSeen.add(p + i); return data.slice(pos, pos + n); } };
};
const vfs = {
  openLazy: lazy,
  read(p) { if (written.has(p)) return written.get(p); if (cache.has(p)) return cache.get(p); const f = real(p); try { const d = f && fs.statSync(f).isFile() ? new Uint8Array(fs.readFileSync(f)) : null; if (d) cache.set(p, d); return d; } catch { return null; } },
  write(p, data) { if (data === null) written.delete(p); else written.set(p, new Uint8Array(data)); },
  exists(p) { return written.has(p) || (() => { const f = real(p); return !!f && fs.existsSync(f); })(); },
  isDir(p) { const f = real(p); try { return !!f && fs.statSync(f).isDirectory(); } catch { return false; } },
  list() { return []; },
};
const glCalls = new Map();
let glId = 100;
const GL = new Proxy({}, { get: (t, name) => t[name], has: () => false });
const gl = (name, fn) => { GL[name] = (c, a, b, x, y) => { glCalls.set(name, (glCalls.get(name) || 0) + 1); return fn ? fn(c, a, b, x, y) : 0; }; };
let sys;
const str = {};
const cstrOf = (s) => (str[s] = str[s] || sys.strdup(s));
for (const n of 'ActiveTexture AttachShader BindAttribLocation BindBuffer BindFramebuffer BindRenderbuffer BindTexture BlendEquation BlendFunc BufferData BufferSubData Clear ClearColor ClearDepthf ClearStencil CompileShader CompressedTexImage2D DeleteBuffers DeleteFramebuffers DeleteProgram DeleteRenderbuffers DeleteShader DeleteTextures DepthFunc DepthMask Disable DisableVertexAttribArray DrawArrays DrawElements Enable EnableVertexAttribArray FramebufferRenderbuffer FramebufferTexture2D GenerateMipmap GetBooleanv GetFloatv GetProgramInfoLog GetShaderInfoLog GetShaderSource IsEnabled LinkProgram PixelStorei ReadPixels RenderbufferStorage Scissor ShaderSource StencilFunc StencilMask StencilOp TexImage2D TexParameteri Uniform1f Uniform1i Uniform2f Uniform2fv Uniform2i Uniform2iv Uniform3f Uniform3fv Uniform3i Uniform3iv Uniform4f Uniform4fv Uniform4i Uniform4iv UniformMatrix4fv UseProgram VertexAttribPointer Viewport'.split(' ')) gl('gl' + n);
// a fingerprint of every picture the app hands to the graphics card (the same with and without fast.js = nothing changed)
let texHash = 0x811c9dc5 | 0, texBytes = 0;
gl('glTexImage2D', (c, target, level, ifmt, w) => {
  const h = sys.arg(4), format = sys.arg(6), type = sys.arg(7), p = sys.arg(8) >>> 0;
  if (!p) return 0;
  const bpp = type === 0x1401 ? (format === 0x1908 ? 4 : format === 0x1907 ? 3 : format === 0x190a ? 2 : 1) : 2, n = w * h * bpp, u = cpu.u8;
  for (let i = p, e = p + n; i < e; i++) texHash = Math.imul(texHash ^ u[i], 16777619);
  texBytes += n;
  return 0;
});
gl('glCreateProgram', () => glId++); gl('glCreateShader', () => glId++); gl('glGetUniformLocation', () => glId++); gl('glGetError', () => 0); gl('glCheckFramebufferStatus', () => 0x8cd5);
for (const n of ['Textures', 'Buffers', 'Framebuffers', 'Renderbuffers']) gl('glGen' + n, (c, count, out) => { for (let i = 0; i < count; i++) cpu.w32(out + i * 4, glId++); });
gl('glGetShaderiv', (c, s, pname, out) => { cpu.w32(out, pname === 0x8b81 ? 1 : 0); }); gl('glGetProgramiv', (c, s, pname, out) => { cpu.w32(out, pname === 0x8b82 ? 1 : 0); });
gl('glGetIntegerv', (c, pname, out) => { cpu.w32(out, pname === 0x0d33 ? 4096 : pname === 0x8872 ? 8 : 0); });
gl('glGetString', (c, name) => cstrOf(name === 0x1f03 ? 'GL_OES_rgb8_rgba8 GL_OES_depth24 GL_OES_packed_depth_stencil' : name === 0x1f02 ? 'OpenGL ES 2.0' : 'Web'));

const logLines = [];
const log = (s) => { logLines.push(s); if (verbose || !/^fopen|^open/.test(s)) console.log('  | ' + String(s).slice(0, 300)); };
sys = makeSys(cpu, { heapStart: 0x01000000, heapEnd: MEM - (8 << 20), vfs, log, extra: GL, traceFiles: true });
const t0 = Date.now();
const lib = loadElf(cpu, new Uint8Array(fs.readFileSync(path.join(ROOT, 're', 'libgame.so'))), BASE, sys.resolve);
sys.exidx = lib.exidx;
cpu.r[13] = MEM - 0x1000;
cpu.tls = sys.calloc(1, 64);
// the app's requests go to the dev server with curl (in the browser: a synchronous request to the page's own server)
const requests = [];
hookCurl(cpu, sys, lib, (q) => {
  const u = new URL(q.url), target = SERVER + u.pathname + u.search;
  const args = ['-s', '-m', '20', '-w', '\n%{http_code}', '-X', q.method, target];
  if (q.body) args.push('--data-binary', '@-', '-H', 'Content-Type: application/x-www-form-urlencoded');
  const r = spawnSync('curl', args, { input: q.body ? Buffer.from(q.body) : undefined, maxBuffer: 256 << 20 });
  if (r.status !== 0) { requests.push(q.method + ' ' + u.pathname + ' -> failed'); return null; }
  const i = r.stdout.lastIndexOf(10), status = Number(r.stdout.subarray(i + 1).toString()) || 0, body = new Uint8Array(r.stdout.subarray(0, i));
  requests.push(q.method + ' ' + u.pathname + (q.body ? ' [' + Buffer.from(q.body).toString().slice(0, 60) + ']' : '') + ' -> ' + status + ', ' + body.length + ' bytes');
  return { status, body };
}, log);
// the app's busiest library functions in fast JavaScript (fast.js); HB_FAST=0 runs the original code, HB_FASTCHECK=1 runs
// both for every call and stops at the first difference
if (process.env.HB_FAST !== '0') {
  const hookFast = require(path.join(E, 'fast.js'));
  console.log('fast functions: ' + hookFast(cpu, lib, log));
  if (process.env.HB_FASTCHECK) require('./emu-fastcheck.js')(cpu, lib);
}
console.log(`loaded: image ${(lib.end - BASE) >> 10} KB, ${lib.init.length} start-up functions, ${sys.missing.size} of the imports not written yet`);

const java = {
  'org/cocos2dx/lib/Cocos2dxHelper.getCocos2dxPackageName': () => 'com.hello.bro.yo',
  'org/cocos2dx/lib/Cocos2dxHelper.getCurrentLanguage': () => 'en',
  'org/cocos2dx/lib/Cocos2dxHelper.getDeviceModel': () => 'Web',
  'org/cocos2dx/lib/Cocos2dxHelper.getCocos2dxWritablePath': () => FILES,
  'org/cocos2dx/lib/Cocos2dxHelper.getDPI': () => 320,
};
const jni = makeJni(cpu, sys, java, log);
const sym = (n) => { const a = lib.sym(n); if (!a) throw new Error('no symbol ' + n); return a; };
const step = (label, fn) => {
  const s0 = cpu.steps, t = Date.now();
  try { fn(); } catch (e) {
    console.log(`STOPPED in "${label}" after ${((cpu.steps - s0) / 1e6).toFixed(1)} M instructions: ${e.message}`);
    if (!(e instanceof Cpu.EmuError)) console.log(e.stack.split('\n').slice(1, 6).join('\n'));
    console.log(`  pc=${(cpu.r[15] >>> 0).toString(16)} lr=${(cpu.r[14] >>> 0).toString(16)} (image base ${BASE.toString(16)}: pc-base=${((cpu.r[15] >>> 0) - BASE).toString(16)}, lr-base=${((cpu.r[14] >>> 0) - BASE).toString(16)})`);
    summary(); process.exit(1);
  }
  const n = cpu.steps - s0, ms = Date.now() - t;
  console.log(`${label}: ${(n / 1e6).toFixed(2)} M instructions in ${ms} ms${ms > 20 ? ' (' + (n / 1e3 / ms).toFixed(0) + ' MIPS)' : ''}`);
};
const summary = () => {
  console.log('game file pieces read: ' + pieceSeen.size + ' of 512 KB (' + pieceReads.n + ' reads)');
  if (texBytes) console.log('pictures: ' + (texBytes >> 20) + ' MB, fingerprint ' + (texHash >>> 0).toString(16));
  console.log(`total ${(cpu.steps / 1e6).toFixed(1)} M instructions, ${((Date.now() - t0) / 1000).toFixed(1)} s, heap ${(sys.heapUsed() >> 20)} MB, ${sys.threads.length} threads asked for`);
  const g = [...glCalls].sort((a, b) => b[1] - a[1]);
  if (g.length) console.log('GL calls: ' + g.slice(0, 14).map(([k, v]) => k.slice(2) + '×' + v).join(' '));
  const files = logLines.filter((l) => /^f?open /.test(l));
  if (files.length) console.log(`files asked for: ${files.length}, missing: ${[...new Set(files.filter((l) => l.endsWith('(missing)')).map((l) => l.split(' ')[1]))].slice(0, 12).join(', ')}`);
};
if (process.env.HB_PROFILE) require('./emu-profile.js')(cpu, BASE, ROOT); // HB_PROFILE=1: where the instructions go
step('start-up functions (C++ constructors)', () => { for (const f of lib.init) cpu.call(f, []); });
step('JNI_OnLoad', () => cpu.call(sym('JNI_OnLoad'), [jni.vm, 0]));
step('nativeSetApkPath', () => cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetApkPath'), [jni.env, 0, jni.ref(APK)]));
step('nativeSetObbPath', () => cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxHelper_nativeSetObbPath'), [jni.env, 0, jni.ref(OBB)]));
step('nativeInit 720x1280 (the app starts)', () => cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeInit'), [jni.env, 0, 720, 1280]));
step(frames + ' frames (with the other threads)', () => { for (let i = 0; i < frames; i++) { cpu.call(sym('Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeRender'), [jni.env, 0]); sys.runThreads(); } });
console.log('requests: ' + (requests.join(' | ') || 'none'));
summary();
