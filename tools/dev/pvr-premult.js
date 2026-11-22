// Which of the game's sprite sheets (re/obb/**/*.pvr.ccz) are stored with premultiplied alpha (PVR v3 flag 0x02), and which of
// those hold "glow" pixels (colour brighter than its alpha: the phone adds them to the screen). Used to decide how
// tools/build_webclient.js writes them.   node tools/dev/pvr-premult.js [filter]
const fs = require('fs'), path = require('path');
const { decryptCcz, pvrToRgba } = require('../build_webclient.js');
const ROOT = path.join(__dirname, '../../re/obb'), filter = process.argv[2] || '';
const walk = (d, out = []) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p, out); else if (/\.pvr\.ccz$/i.test(e.name)) out.push(p); } return out; };
let v3 = 0, pm = 0, glow = 0, n = 0;
for (const f of walk(ROOT)) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  if (filter && !rel.includes(filter)) continue;
  n++;
  let pvr; try { pvr = decryptCcz(Buffer.from(fs.readFileSync(f))); } catch (e) { console.log('ERR ' + rel + ' ' + e.message); continue; }
  const isV3 = pvr.toString('latin1', 0, 4) === 'PVR\x03', flag = isV3 ? pvr.readUInt32LE(4) : -1;
  if (isV3) v3++;
  if (flag & 2 && isV3) pm++;
  let over = 0, semi = 0;
  try { const { w, h, rgba } = pvrToRgba(pvr); for (let i = 0; i < w * h * 4; i += 4) { const a = rgba[i + 3]; if (a > 0 && a < 250) { semi++; if (Math.max(rgba[i], rgba[i + 1], rgba[i + 2]) > a + 24) over++; } } } catch (e) {}
  const g = semi > 200 && over / semi > 0.3;
  if (g) glow++;
  if (filter || g) console.log(`${rel}  v3=${isV3} flag=${flag} semi=${semi} brighterThanAlpha=${over}${g ? '  GLOW' : ''}`);
}
console.log(`${n} sheets, ${v3} PVR v3, ${pm} flagged premultiplied, ${glow} with glow pixels`);
