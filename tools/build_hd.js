// HD pictures for the rewritten game (server/webclient; owner, 21 Nov 2026: "make it look modern and HD, with the same stuff").
// Every picture of the game (made in 2015 for 768-pixel-wide screens) is redrawn at double size by Real-ESRGAN's anime model
// (4x, then halved: cleaner than its 2x model) and saved as WebP next to the originals:
//   server/webclient/assets/<path>.png  ->  server/webclient/assets/hd/<path>.png.webp   (+ assets/hd.json: the list)
// engine.js draws the HD one in the same place and size as the original (?hd=0 shows the originals).
// Needs: node tools/build_webclient.js first; re/esrgan/realesrgan-ncnn-vulkan.exe (the Windows zip of release v0.2.5.0 of
// github.com/xinntao/Real-ESRGAN, unpacked there); ffmpeg; a graphics card. Finished pictures are skipped, so it can be run again.
//   node tools/build_hd.js [folder ...]     (no folder = all; about 340 megapixels)
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const { spawnSync, spawn } = require('child_process');
const ROOT = path.join(__dirname, '..'), A = path.join(ROOT, 'server', 'webclient', 'assets'), HD = path.join(A, 'hd');
const EXE = path.join(ROOT, 're', 'esrgan', 'realesrgan-ncnn-vulkan.exe');
const FF = (() => { const base = path.join(process.env.LOCALAPPDATA || '', 'Microsoft', 'WinGet', 'Packages'); try { for (const d of fs.readdirSync(base)) if (/FFmpeg/i.test(d)) for (const v of fs.readdirSync(path.join(base, d))) { const f = path.join(base, d, v, 'bin', 'ffmpeg.exe'); if (fs.existsSync(f)) return f; } } catch { /* */ } return 'ffmpeg'; })();
if (!fs.existsSync(EXE)) { console.error('missing ' + EXE); process.exit(1); }

const walk = (dir, out = []) => { for (const e of fs.readdirSync(dir, { withFileTypes: true })) { const p = path.join(dir, e.name); if (e.isDirectory()) { if (p !== HD && p !== path.join(A, 'emu')) walk(p, out); } else if (/\.png$/i.test(e.name)) out.push(path.relative(A, p).replace(/\\/g, '/')); } return out; };
const only = process.argv.slice(2);
const all = walk(A), todo = all.filter((r) => (!only.length || only.some((o) => r.startsWith(o.replace(/\/?$/, '/')))) && !fs.existsSync(path.join(HD, r + '.webp')));
console.log(all.length + ' pictures, ' + todo.length + ' to do');

const ffmpeg = (src, dst) => new Promise((ok) => { fs.mkdirSync(path.dirname(dst), { recursive: true }); const p = spawn(FF, ['-v', 'error', '-y', '-i', src, '-vf', 'scale=iw/2:ih/2:flags=lanczos', '-c:v', 'libwebp', '-quality', '92', '-compression_level', '4', dst + '.tmp.webp']); p.on('close', (c) => { if (c === 0) fs.renameSync(dst + '.tmp.webp', dst); ok(c === 0); }); });
(async () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'hbhd-')), tin = path.join(tmp, 'in'), tout = path.join(tmp, 'out');
  let done = 0, failed = [];
  const t0 = Date.now();
  const run = async (todo, per) => {
  for (let i = 0; i < todo.length; i += per) { // `per` pictures per run of the tool (it loads its model once per run)
    const batch = todo.slice(i, i + per);
    fs.rmSync(tin, { recursive: true, force: true }); fs.rmSync(tout, { recursive: true, force: true }); fs.mkdirSync(tin); fs.mkdirSync(tout);
    batch.forEach((r, k) => fs.copyFileSync(path.join(A, r), path.join(tin, k + '.png')));
    spawnSync(EXE, ['-i', tin, '-o', tout, '-n', 'realesrgan-x4plus-anime', '-s', '4', '-f', 'png'], { stdio: 'ignore', cwd: path.dirname(EXE) });
    let k = 0;
    const next = async () => { while (k < batch.length) { const j = k++, src = path.join(tout, j + '.png'); if (fs.existsSync(src) && fs.statSync(src).size > 200 && await ffmpeg(src, path.join(HD, batch[j] + '.webp'))) done++; else failed.push(batch[j]); } };
    await Promise.all(Array.from({ length: 8 }, next));
    console.log(Math.min(i + per, todo.length) + ' / ' + todo.length + '  (' + Math.round((Date.now() - t0) / 1000) + ' s, ' + failed.length + ' failed)');
  }
  };
  await run(todo, 40);
  // The tool sometimes writes an EMPTY picture without saying so (21 Nov 2026: one run of 40 came out blank on the RTX 5080, and the
  // Team screen lost its card frames). A blank picture is tiny next to its original: those are made again in small runs. One that
  // stays small with the same size twice really is that plain (a nearly empty sheet) and is kept.
  const small = () => walk(A).filter((r) => { const h = path.join(HD, r + '.webp'); if (!fs.existsSync(h)) return false; const a = fs.statSync(path.join(A, r)).size, b = fs.statSync(h).size; return b < 700 || b < a * 0.12; });
  const before = new Map(small().map((r) => [r, fs.statSync(path.join(HD, r + '.webp')).size]));
  if (before.size) {
    console.log(before.size + ' suspiciously small HD pictures: making them again');
    for (const r of before.keys()) fs.renameSync(path.join(HD, r + '.webp'), path.join(HD, r + '.webp.old'));
    await run([...before.keys()], 6);
    let fixed = 0;
    for (const [r, was] of before) { const h = path.join(HD, r + '.webp'); if (!fs.existsSync(h)) fs.renameSync(h + '.old', h); else { if (fs.statSync(h).size !== was) fixed++; fs.rmSync(h + '.old'); } }
    console.log(fixed + ' of them were blank and are right now; ' + (before.size - fixed) + ' are simply plain pictures');
  }
  fs.rmSync(tmp, { recursive: true, force: true });
  const have = walk(A).filter((r) => fs.existsSync(path.join(HD, r + '.webp')));
  fs.writeFileSync(path.join(A, 'hd.json'), JSON.stringify(have));
  console.log('HD pictures: ' + have.length + ' of ' + all.length + (failed.length ? '\nfailed: ' + failed.join(', ') : ''));
})();
