"""Icon sheets for the wiki (server/wiki): decodes the game's own icons (re/obb, .pvr.ccz + .plist, see tools/pvrccz.py) for every
shinobi, pet, gear, ninjutsu, seal and item the wiki lists, scales each to CELL x CELL and packs them into one PNG per kind
(server/wiki/img/<kind>.png) plus server/wiki/img/icons.json = {kind: {cols, cell, count}, names: {"<kind>/<icon>": index}}.
One picture per kind instead of ~600 small files: the game server's flood guard allows 300 requests per 10 s per visitor.
Needs re/obb (python -I tools/setup_re.py). Pure Python, no PIL. Then run: node tools/build_wiki.js
usage: python -I tools/build_wiki_icons.py"""
import json, os, re, struct, sys, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import pvrccz  # noqa: E402

OBB = os.path.join(ROOT, 're', 'obb')
DATA = os.path.join(ROOT, 'server', 'data')
OUT = os.path.join(ROOT, 'server', 'wiki', 'img')
CELL, COLS = 80, 16


def rows(name):
    return json.load(open(os.path.join(DATA, name + '.json'), encoding='utf-8'))['rows']


def plist_frame(path):
    """(frame x, y, w, h, rotated, source x, y, source w, h) of a one-frame TexturePacker plist."""
    t = open(path, encoding='utf-8', errors='replace').read()
    nums = lambda key: [int(v) for v in re.findall(r'-?\d+', re.search(r'<key>' + key + r'</key>\s*<string>([^<]*)</string>', t).group(1))]
    fx, fy, fw, fh = nums('frame')
    rot = re.search(r'<key>rotated</key>\s*<(true|false)/>', t)
    sx, sy, _, _ = nums('sourceColorRect')
    sw, sh = nums('sourceSize')
    return fx, fy, fw, fh, bool(rot and rot.group(1) == 'true'), sx, sy, sw, sh


def load_icon(base):
    """RGBA rows (premultiplied floats) of the icon at its full source size, or None when the game has no such picture."""
    pvr_path, pl_path = os.path.join(OBB, base + '.pvr.ccz'), os.path.join(OBB, base + '.plist')
    if not (os.path.exists(pvr_path) and os.path.exists(pl_path)):
        return None
    pvr, _ = pvrccz.read(pvr_path)
    tw, th, rgba = pvrccz.to_rgba(pvr)
    fx, fy, fw, fh, rot, sx, sy, sw, sh = plist_frame(pl_path)
    canvas = [[(0.0, 0.0, 0.0, 0.0)] * sw for _ in range(sh)]
    for y in range(fh):
        for x in range(fw):
            # a rotated frame is stored turned 90 degrees clockwise: (x, y) of the picture sits at (fx + fh-1-y, fy + x) of the sheet
            px, py = (fx + fh - 1 - y, fy + x) if rot else (fx + x, fy + y)
            if px >= tw or py >= th:
                continue
            i = (py * tw + px) * 4
            r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
            if a and 0 <= sy + y < sh and 0 <= sx + x < sw:
                f = a / 255.0
                canvas[sy + y][sx + x] = (r * f, g * f, b * f, float(a))
    return canvas


def scale(src, size):
    """Area-average (box) resample of a premultiplied picture to size x size (keeps the aspect, centred)."""
    sh, sw = len(src), len(src[0])
    k = size / max(sw, sh)
    ow, oh = max(1, round(sw * k)), max(1, round(sh * k))
    ox, oy = (size - ow) // 2, (size - oh) // 2
    out = [[(0, 0, 0, 0)] * size for _ in range(size)]
    for y in range(oh):
        y0, y1 = y / k, (y + 1) / k
        for x in range(ow):
            x0, x1 = x / k, (x + 1) / k
            acc = [0.0, 0.0, 0.0, 0.0]
            area = 0.0
            for yy in range(int(y0), min(sh, int(y1 + 0.9999))):
                wy = min(y1, yy + 1) - max(y0, yy)
                if wy <= 0:
                    continue
                row = src[yy]
                for xx in range(int(x0), min(sw, int(x1 + 0.9999))):
                    wx = min(x1, xx + 1) - max(x0, xx)
                    if wx <= 0:
                        continue
                    w = wx * wy
                    p = row[xx]
                    acc[0] += p[0] * w; acc[1] += p[1] * w; acc[2] += p[2] * w; acc[3] += p[3] * w
                    area += w
            if area <= 0:
                continue
            a = acc[3] / area
            if a < 0.5:
                continue
            f = 255.0 / a
            out[oy + y][ox + x] = tuple(min(255, round(v / area * f)) for v in acc[:3]) + (min(255, round(a)),)
    return out


def write_png(path, w, h, px):
    """RGBA PNG with a per-row filter (the one with the smallest sum, as libpng does): about half the size of unfiltered rows."""
    raw, prev = bytearray(), bytes(w * 4)
    for y in range(h):
        line = bytes(v for p in px[y] for v in p)
        sub = bytes((line[i] - (line[i - 4] if i >= 4 else 0)) & 255 for i in range(len(line)))
        up = bytes((line[i] - prev[i]) & 255 for i in range(len(line)))
        def paeth(i):
            a = line[i - 4] if i >= 4 else 0
            b = prev[i]
            c = prev[i - 4] if i >= 4 else 0
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            return (line[i] - (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        pae = bytes(paeth(i) for i in range(len(line)))
        cost = lambda bs: sum(v if v < 128 else 256 - v for v in bs)
        best = min(((0, line), (1, sub), (2, up), (4, pae)), key=lambda t: cost(t[1]))
        raw.append(best[0])
        raw.extend(best[1])
        prev = line
    chunk = lambda t, b: struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) +
                           chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b''))


def wanted():
    """kind -> ordered icon names, from the same rows the wiki lists (tools/build_wiki.js)."""
    n = []
    for r in rows('ninjainfo'):
        if r[4] == 1 and (r[19] or 0) > 0 and r[3]:
            n.append(r[3])
    for r in rows('petinfo'):
        n.append(r[3])
    ninja = {r[0]: r for r in rows('ninjainfo')}
    for r in rows('roundinfo'):  # the story bosses' enemies (the Training pages show them)
        for nid in r[7:22]:
            if nid and nid in ninja and ninja[nid][3]:
                n.append(ninja[nid][3])
    kinds = {
        'n': ('icon/icon_', n),
        'e': ('equip/small_', [r[4] for r in rows('equipmentinfo') if r[4]]),
        'j': ('skill/small_', [r[28] for r in rows('ninjutsuinfo') if r[28]]),
        's': ('mark/small_', [r[4] for r in rows('markinfo') if r[4]]),
        'p': ('props/', [r[3] for r in rows('consumeinfo') if r[3]] + ['props_036']),
    }
    out = {}
    for k, (prefix, names) in kinds.items():
        seen = []
        for name in names:
            if name not in seen:
                seen.append(name)
        out[k] = (prefix, seen)
    return out


def ffmpeg():
    import glob, shutil
    found = shutil.which('ffmpeg')
    if found:
        return found
    hits = glob.glob(os.path.expandvars(r'%LOCALAPPDATA%\Microsoft\WinGet\Packages\*FFmpeg*\*\bin\ffmpeg.exe'))
    return hits[0] if hits else None


def to_webp(png):
    """WebP (quality 85, alpha kept) is ~6x smaller than the PNG for these painted icons; keeps the PNG when ffmpeg is missing."""
    import subprocess
    exe = ffmpeg()
    if not exe:
        return 'png'
    webp = png[:-4] + '.webp'
    r = subprocess.run([exe, '-loglevel', 'error', '-y', '-i', png, '-c:v', 'libwebp', '-pix_fmt', 'yuva420p', '-quality', '85',
                        '-compression_level', '6', webp])
    if r.returncode or not os.path.exists(webp):
        return 'png'
    os.remove(png)
    return 'webp'


def main():
    if not os.path.isdir(OBB):
        raise SystemExit('re/obb is missing: run python -I tools/setup_re.py first')
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):  # old sheets (a kind may switch between png and webp)
        if f.endswith(('.png', '.webp')):
            os.remove(os.path.join(OUT, f))
    meta = {'cell': CELL, 'cols': COLS, 'sheets': {}, 'names': {}}
    for kind, (prefix, names) in wanted().items():
        cells = []
        for name in names:
            pic = load_icon(prefix + name)
            if pic is None:
                print('  no picture:', prefix + name)
                continue
            meta['names'][kind + '/' + name] = len(cells)
            cells.append(scale(pic, CELL))
        rows_n = (len(cells) + COLS - 1) // COLS
        W, H = COLS * CELL, max(1, rows_n) * CELL
        sheet = [[(0, 0, 0, 0)] * W for _ in range(H)]
        for i, c in enumerate(cells):
            cx, cy = (i % COLS) * CELL, (i // COLS) * CELL
            for y in range(CELL):
                sheet[cy + y][cx:cx + CELL] = c[y]
        png = os.path.join(OUT, kind + '.png')
        write_png(png, W, H, sheet)
        ext = to_webp(png)
        import hashlib  # the page asks for <file>?v=<hash>: browsers keep pictures a day, a rebuilt sheet gets a new address
        ver = hashlib.sha1(open(os.path.join(OUT, f'{kind}.{ext}'), 'rb').read()).hexdigest()[:10]
        meta['sheets'][kind] = {'count': len(cells), 'rows': rows_n, 'file': f'{kind}.{ext}?v={ver}'}
        print(f'{kind}: {len(cells)} icons -> img/{kind}.{ext} ({os.path.getsize(os.path.join(OUT, kind + "." + ext)) // 1024} KB)')
    json.dump(meta, open(os.path.join(OUT, 'icons.json'), 'w', encoding='utf-8'), separators=(',', ':'))


main()
