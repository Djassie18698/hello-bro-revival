"""Decode / encode the game's encrypted sprite sheets (.pvr.ccz with 'CCZp' header, cocos2d-x ZipUtils).

python -I tools/pvrccz.py topng <file.pvr.ccz> <out.png>
python -I tools/pvrccz.py frompng <in.png> <original.pvr.ccz> <out.pvr.ccz>   (keeps the original's pixel format)
WARNING: frompng output broke the pop-up in game (28.0.18 showed a dark purple box), so only topng (reading) is trusted.
Key = the four numbers libgame.so passes to ZipUtils::ccSetPvrEncryptionKey at 0x265b96.
"""
import struct, sys, zlib

KEY = [0xf013c6ef, 0x5ca560ce, 0x01471215, 0xca9bada1]
M = 0xffffffff


def keystream():
    k = [0] * 1024
    s, z, rounds = 0, k[1023], 6
    mx = lambda y, z, p, e: ((((z >> 5) ^ (y << 2) & M) + ((y >> 3) ^ (z << 4) & M)) ^ ((s ^ y) + (KEY[(p & 3) ^ e] ^ z))) & M
    while rounds:
        s = (s + 0x9e3779b9) & M
        e = (s >> 2) & 3
        for p in range(1023):
            y = k[p + 1]
            k[p] = (k[p] + mx(y, z, p, e)) & M
            z = k[p]
        y = k[0]
        k[1023] = (k[1023] + mx(y, z, 1023, e)) & M
        z = k[1023]
        rounds -= 1
    return k


def crypt(buf):
    """XOR in place from offset 12 (the same operation decrypts and encrypts)."""
    k, n = keystream(), (len(buf) - 12) // 4
    words = list(struct.unpack_from('<%dI' % n, buf, 12))
    b, i = 0, 0
    while i < n and i < 512:
        words[i] ^= k[b]; b = (b + 1) % 1024; i += 1
    while i < n:
        words[i] ^= k[b]; b = (b + 1) % 1024; i += 64
    struct.pack_into('<%dI' % n, buf, 12, *words)


def read(path):
    buf = bytearray(open(path, 'rb').read())
    assert buf[:4] == b'CCZp', 'not an encrypted ccz'
    crypt(buf)
    return zlib.decompress(bytes(buf[16:])), bytes(buf[:12])


def pvr_info(pvr):
    if pvr[:4] == b'PVR\x03':
        fmt = struct.unpack_from('<Q', pvr, 8)[0]
        h, w = struct.unpack_from('<II', pvr, 24)
        start = 52 + struct.unpack_from('<I', pvr, 48)[0]
        return fmt, w, h, start, 3
    hdr = struct.unpack_from('<13I', pvr, 0)  # v2: headerLength, height, width, mipmaps, flags, ...
    return hdr[4] & 0xff, hdr[2], hdr[1], hdr[0], 2


def to_rgba(pvr):
    fmt, w, h, start, v = pvr_info(pvr)
    px = pvr[start:]
    out = bytearray(w * h * 4)
    if (v == 2 and fmt == 0x12) or (v == 3 and fmt == 0x0808080861626772):  # RGBA8888
        out[:] = px[:w * h * 4]
    elif (v == 2 and fmt == 0x10) or (v == 3 and fmt == 0x0404040461626772):  # RGBA4444
        for i in range(w * h):
            c = px[2 * i] | px[2 * i + 1] << 8
            out[4 * i:4 * i + 4] = bytes(((c >> s & 15) * 17) for s in (12, 8, 4, 0))
    else:
        raise ValueError('pixel format %x not handled' % fmt)
    return w, h, bytes(out)


def from_rgba(pvr, rgba):
    fmt, w, h, start, v = pvr_info(pvr)
    if (v == 2 and fmt == 0x12) or (v == 3 and fmt == 0x0808080861626772):
        px = rgba
    else:
        px = bytearray(w * h * 2)
        for i in range(w * h):
            r, g, b, a = (round(x / 17) for x in rgba[4 * i:4 * i + 4])
            struct.pack_into('<H', px, 2 * i, r << 12 | g << 8 | b << 4 | a)
    return pvr[:start] + bytes(px) + pvr[start + len(px):]


def write(path, pvr, head):
    body = zlib.compress(pvr, 9)
    buf = bytearray(head[:12] + struct.pack('>I', len(pvr)) + body)
    crypt(buf)
    open(path, 'wb').write(bytes(buf))


if __name__ == '__main__':
    from PIL import Image
    if sys.argv[1] == 'topng':
        pvr, _ = read(sys.argv[2])
        w, h, rgba = to_rgba(pvr)
        print('format', hex(pvr_info(pvr)[0]), w, h)
        Image.frombytes('RGBA', (w, h), rgba).save(sys.argv[3])
    elif sys.argv[1] == 'frompng':
        pvr, head = read(sys.argv[3])
        img = Image.open(sys.argv[2]).convert('RGBA')
        write(sys.argv[4], from_rgba(pvr, img.tobytes()), head)
