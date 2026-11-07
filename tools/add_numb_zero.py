"""Give the "+N" font characters/NumB.fnt a 0 and a gold 1 (it has only "+" and 1-9, so Breakthrough 10 showed as "+1" on every screen: card
detail, lists, the Breakthrough screen). Copies the gold "0" of characters/number_40.fnt, scales it to the NumB digit height,
puts it in the free bottom-right corner of NumB_0.png and adds `char id=48` to NumB.fnt. Pure Python (no PIL): reads the palette
PNG / RGBA PNG and writes an RGBA PNG. Output goes to server/cdn/src/characters/ (hot update).
usage: python -I tools/add_numb_zero.py"""
import os, struct, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OBB = os.path.join(ROOT, 're', 'obb', 'characters')
OUT = os.path.join(ROOT, 'server', 'cdn', 'src', 'characters')


def read_png(path):
    d = open(path, 'rb').read()
    assert d[:8] == b'\x89PNG\r\n\x1a\n'
    pos, idat, plte, trns = 8, b'', None, None
    while pos < len(d):
        n, typ = struct.unpack('>I4s', d[pos:pos + 8])
        body = d[pos + 8:pos + 8 + n]
        if typ == b'IHDR':
            w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', body)
        elif typ == b'PLTE':
            plte = body
        elif typ == b'tRNS':
            trns = body
        elif typ == b'IDAT':
            idat += body
        pos += 12 + n
    assert bd == 8 and il == 0 and ct in (3, 6), (bd, ct, il)
    bpp = 1 if ct == 3 else 4
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line); prev = line
    px = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y in range(h):
        r = rows[y]
        for x in range(w):
            if ct == 6:
                px[y][x] = tuple(r[x * 4:x * 4 + 4])
            else:
                k = r[x]
                al = trns[k] if trns is not None and k < len(trns) else 255
                px[y][x] = (plte[k * 3], plte[k * 3 + 1], plte[k * 3 + 2], al)
    return w, h, px


def write_png(path, w, h, px):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw.extend(px[y][x])
    def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    data = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(data)


def glyph(fnt, cid):
    for line in open(fnt, encoding='utf-8', errors='replace'):
        if line.startswith('char ') and f'id={cid} ' in line.replace('  ', ' ') + ' ':
            kv = dict(p.split('=') for p in line.split()[1:])
            if int(kv['id']) == cid:
                return {k: int(v) for k, v in kv.items() if v.lstrip('-').isdigit()}
    raise SystemExit(f'no char {cid} in {fnt}')


def main():
    os.makedirs(OUT, exist_ok=True)
    W, H, numb = read_png(os.path.join(OBB, 'NumB_0.png'))
    _, _, gold = read_png(os.path.join(OBB, 'number_40_0.png'))
    one = glyph(os.path.join(OBB, 'NumB.fnt'), 49)
    th = one['height']  # same height as NumB's "1"
    X, Y = 70, 97  # free corner (right of "+", below "5"/"7"/"9")
    placed = {}
    # the gold "0" (NumB has none) and a gold "1" (owner, 7 Nov 2026: a white 1 next to a gold 0 looked odd), side by side in the corner
    for cid in (48, 49):
        g = glyph(os.path.join(OBB, 'number_40.fnt'), cid)
        sc = th / g['height']
        tw = max(1, round(g['width'] * sc))
        assert X + tw <= W and Y + th <= H, ('no room for', cid)
        for y in range(Y, Y + th):  # the corner must really be empty
            for x in range(X, X + tw):
                assert numb[y][x][3] == 0, ('not empty at', x, y)
        for y in range(th):  # bilinear scale of the gold digit into the corner
            sy = min(g['height'] - 1.0, (y + 0.5) / sc - 0.5)
            y0 = int(max(0, sy)); y1 = min(g['height'] - 1, y0 + 1); fy = max(0.0, sy - y0)
            for x in range(tw):
                sx = min(g['width'] - 1.0, (x + 0.5) / sc - 0.5)
                x0 = int(max(0, sx)); x1 = min(g['width'] - 1, x0 + 1); fx = max(0.0, sx - x0)
                q4 = [gold[g['y'] + yy][g['x'] + xx] for yy, xx in ((y0, x0), (y0, x1), (y1, x0), (y1, x1))]
                wts = ((1 - fy) * (1 - fx), (1 - fy) * fx, fy * (1 - fx), fy * fx)
                a = sum(q[3] * wt for q, wt in zip(q4, wts))
                if a <= 0:
                    continue
                rgb = [round(sum(q[c] * q[3] * wt for q, wt in zip(q4, wts)) / a) for c in range(3)]
                numb[Y + y][X + x] = (rgb[0], rgb[1], rgb[2], round(a))
        placed[cid] = (X, tw, sc)
        X += tw + 4
    write_png(os.path.join(OUT, 'NumB_0.png'), W, H, numb)
    def line_for(cid):
        x, tw, _ = placed[cid]
        return (f'char id={cid}   x={x}    y={Y}    width={tw}    height={th}    xoffset={one["xoffset"] - (tw - one["width"]) // 2}    '
                f'yoffset={one["yoffset"]}     xadvance={one["xadvance"]}    page=0  chnl=15')
    lines = open(os.path.join(OBB, 'NumB.fnt'), encoding='utf-8', errors='replace').read().splitlines()
    out = []
    for line in lines:
        if line.startswith('chars count='):
            line = 'chars count=11'
        if line.startswith('char id=49 '):
            line = line_for(49)  # the gold 1 replaces the white one
        out.append(line)
        if line.startswith('char id=43 '):
            out.append(line_for(48))
    open(os.path.join(OUT, 'NumB.fnt'), 'w', encoding='utf-8', newline='\n').write('\n'.join(out) + '\n')
    print('gold 0 and 1 added:', {k: (v[0], v[1], round(v[2], 2)) for k, v in placed.items()}, '->', OUT)

main()
