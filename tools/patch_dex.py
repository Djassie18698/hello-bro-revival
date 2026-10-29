"""Neutralise Google Play Billing queries that crash the game when Play Billing is unavailable.
usage: python patch_dex.py <classes.dex> <out.dex>"""
import sys, struct, hashlib, zlib
src, out = sys.argv[1:3]
d = bytearray(open(src, 'rb').read())
u32 = lambda o: struct.unpack_from('<I', d, o)[0]
def uleb(o):
    r = s = 0
    while True:
        b = d[o]; o += 1; r |= (b & 0x7f) << s; s += 7
        if not b & 0x80: return r, o
strs_n, strs_o = u32(56), u32(60); types_o = u32(68)
meth_n, meth_o = u32(88), u32(92); cls_n, cls_o = u32(96), u32(100)
def sstr(i):
    o = u32(strs_o + 4 * i); _, o = uleb(o); e = d.index(0, o); return d[o:e].decode('utf8', 'replace')
tname = lambda t: sstr(u32(types_o + 4 * t))
TARGET = 'Lcom/xckoo/renlong/sdk/util/IabHelper;'
WANT = {'queryInventoryAsync', 'checkSetupDone'}
patched = []
for c in range(cls_n):
    base = cls_o + 32 * c
    if tname(u32(base)) != TARGET: continue
    cd = u32(base + 24); sf, cd = uleb(cd); inf, cd = uleb(cd); dm, cd = uleb(cd); vm, cd = uleb(cd)
    for _ in range(sf + inf): _, cd = uleb(cd); _, cd = uleb(cd)
    for count in (dm, vm):
        idx = 0
        for _ in range(count):
            diff, cd = uleb(cd); idx += diff; _, cd = uleb(cd); code, cd = uleb(cd)
            name = sstr(u32(meth_o + 8 * idx + 4))
            if name in WANT and code:
                insns = code + 16
                size = struct.unpack_from('<I', d, code + 12)[0]     # insns_size in 16-bit units
                struct.pack_into('<H', d, insns, 0x000e)             # return-void
                for k in range(1, size): struct.pack_into('<H', d, insns + 2 * k, 0)   # nop out the rest
                patched.append((name, hex(code)))
print('patched', patched)
assert patched, 'IabHelper methods not found'
d[12:32] = hashlib.sha1(bytes(d[32:])).digest()
struct.pack_into('<I', d, 8, zlib.adler32(bytes(d[12:])) & 0xffffffff)
open(out, 'wb').write(d)
