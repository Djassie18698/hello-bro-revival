"""Read (and patch) Cocos2d-x 2 CCBReader v5 .ccbi layout files.

python -I tools/ccbi.py dump <file.ccbi> [name]   prints the node tree (only nodes whose member name contains `name`)
Used by the hot update to change label font sizes (e.g. long ninja names in the team screen).
"""
import struct, sys

PROPS = ['Position', 'Size', 'Point', 'PointLock', 'ScaleLock', 'Degrees', 'Integer', 'Float', 'FloatVar', 'Check',
         'SpriteFrame', 'Texture', 'Byte', 'Color3', 'Color4FVar', 'Flip', 'Blendmode', 'FntFile', 'Text', 'FontTTF',
         'IntegerLabeled', 'Block', 'Animation', 'CCBFile', 'String', 'BlockCCControl', 'FloatScale', 'FloatXY']


class Reader:
    def __init__(self, data):
        self.d, self.p, self.bit = data, 0, 0

    def getbit(self):
        b = (self.d[self.p] >> self.bit) & 1
        self.bit += 1
        if self.bit >= 8:
            self.bit, self.p = 0, self.p + 1
        return b

    def align(self):
        if self.bit:
            self.bit, self.p = 0, self.p + 1

    def int(self, signed):
        n = 0
        while not self.getbit():
            n += 1
        cur = 0
        for a in range(n - 1, -1, -1):
            if self.getbit():
                cur |= 1 << a
        cur |= 1 << n
        self.align()
        if signed:
            return cur // 2 if cur % 2 else -(cur // 2)
        return cur - 1

    def byte(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def float(self):
        start = self.p
        t = self.byte()
        if t < 4:
            v = [0.0, 1.0, -1.0, 0.5][t]
        elif t == 4:
            v = float(self.int(True))
        else:
            v = struct.unpack('<f', self.d[self.p:self.p + 4])[0]
            self.p += 4
        return v, (start, self.p)

    def utf8(self):
        n = (self.byte() << 8) | self.byte()
        s = self.d[self.p:self.p + n].decode('utf-8', 'replace')
        self.p += n
        return s

    def cstr(self):
        return self.strings[self.int(False)]


def parse(data):
    r = Reader(data)
    assert data[:4] == b'ibcc', 'not a ccbi'
    r.p = 4
    r.version = r.int(False)
    r.js = r.byte()
    r.strings = [r.utf8() for _ in range(r.int(False))]
    for _ in range(r.int(False)):  # sequences
        r.float(); r.cstr(); r.int(False); r.int(True)
        for _ in range(r.int(False)):  # callback keyframes
            r.float(); r.cstr(); r.int(False)
        for _ in range(r.int(False)):  # sound keyframes
            r.float(); r.cstr(); r.float(); r.float(); r.float()
    r.int(True)  # auto play sequence
    root = node(r)
    assert r.p == len(data), 'did not end at the end of the file (%d of %d)' % (r.p, len(data))
    return root


def value(r, t):
    f = lambda: r.float()[0]
    if t == 0 or t == 1: return (f(), f(), r.int(False))
    if t in (2, 3, 27): return (f(), f())
    if t == 4: return (f(), f(), r.int(False))
    if t in (5, 7): return f()
    if t in (6, 20): return r.int(True)
    if t == 8: return (f(), f())
    if t == 9: return bool(r.byte())
    if t == 10: return (r.cstr(), r.cstr())
    if t in (11, 17, 18, 19, 23, 24): return r.cstr()
    if t == 12: return r.byte()
    if t == 13: return (r.byte(), r.byte(), r.byte())
    if t == 14: return tuple(f() for _ in range(8))
    if t == 15: return (bool(r.byte()), bool(r.byte()))
    if t == 16: return (r.int(False), r.int(False))
    if t == 21: return (r.cstr(), r.int(False))
    if t == 22: return (r.cstr(), r.cstr())
    if t == 25: return (r.cstr(), r.int(False), r.int(False))
    if t == 26:
        v, span = r.float()
        return (v, r.int(False), span)
    raise ValueError('unknown property type %d' % t)


def keyframe(r, t):
    r.float()
    easing = r.int(False)
    if easing in (2, 3, 4, 5, 6, 7):
        r.float()
    if t == 9: r.byte()
    elif t == 12: r.byte()
    elif t == 13: r.byte(); r.byte(); r.byte()
    elif t == 5: r.float()
    elif t in (0, 4, 3): r.float(); r.float()
    elif t == 10: r.cstr(); r.cstr()
    else: raise ValueError('keyframe type %d' % t)


def node(r):
    n = {'class': r.cstr(), 'props': {}, 'children': []}
    if r.js:
        r.cstr()
    if r.int(False):
        n['name'] = r.cstr()
    for _ in range(r.int(False)):  # animated properties
        r.int(False)
        for _ in range(r.int(False)):
            r.cstr()
            t = r.int(False)
            for _ in range(r.int(False)):
                keyframe(r, t)
    count = r.int(False) + r.int(False)
    for _ in range(count):
        t = r.int(False)
        name = r.cstr()
        r.byte()  # platform
        start = r.p
        n['props'][name] = value(r, t)
        n.setdefault('spans', {})[name] = (t, start, r.p)
    for _ in range(r.int(False)):
        n['children'].append(node(r))
    return n


class Writer:
    def __init__(self):
        self.out, self.cur, self.bit = bytearray(), 0, 0

    def putbit(self, b):
        self.cur |= b << self.bit
        self.bit += 1
        if self.bit == 8:
            self.out.append(self.cur)
            self.cur, self.bit = 0, 0

    def int(self, v, signed):
        cur = (v * 2 + 1 if v > 0 else -v * 2) if signed else v + 1
        if signed and v == 0:
            cur = 1
        n = cur.bit_length() - 1
        for _ in range(n):
            self.putbit(0)
        self.putbit(1)
        for a in range(n - 1, -1, -1):
            self.putbit((cur >> a) & 1)
        if self.bit:
            self.out.append(self.cur)
            self.cur, self.bit = 0, 0
        return self

    def float(self, v):
        self.out += b'' + struct.pack('<f', v)
        return self


def encode(t, v):
    w = Writer()
    if t in (0, 1, 4): w.float(v[0]).float(v[1]).int(v[2], False)
    elif t in (6, 20): w.int(v, True)
    elif t == 26: w.float(v[0]).int(v[1], False)
    elif t in (5, 7): w.float(v)
    elif t == 9: w.out.append(1 if v else 0)  # Check (e.g. visible)
    else: raise ValueError('cannot write property type %d' % t)
    return bytes(w.out)


def patch(data, changes):
    """changes: {member name: {property: new value}} -> new file bytes (values as dump shows them; FloatScale = (size, type))."""
    root, edits = parse(data), []
    for n, _ in walk(root):
        for prop, v in {**changes.get(n['class'], {}), **changes.get(n.get('name'), {})}.items():  # key = member name or class
            t, a, b = n['spans'][prop]
            edits.append((a, b, encode(t, v)))
    assert len(edits) >= sum(len(c) for c in changes.values()), 'a node or property was not found'
    for a, b, new in sorted(edits, reverse=True):
        data = data[:a] + new + data[b:]
    parse(data)  # must still read back
    return data


def walk(n, depth=0):
    yield n, depth
    for c in n['children']:
        yield from walk(c, depth + 1)


if __name__ == '__main__':
    root = parse(open(sys.argv[2], 'rb').read())
    want = sys.argv[3] if len(sys.argv) > 3 else ''
    for n, d in walk(root):
        if want in n.get('name', ''):
            print('  ' * d + n['class'], n.get('name', ''), {k: v for k, v in n['props'].items()})
