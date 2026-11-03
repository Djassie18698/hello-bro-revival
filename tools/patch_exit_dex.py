"""Makes the game really quit: com.xckoo.renlong.renlong.onDestroy becomes System.exit(0).
Why: renlong.onCreate skips its whole setup (AppInfo, UpdateManager, ...) when a static from an earlier run is still set. After
"Are you sure to quit? -> Ok" (or a swipe away) Android 14/15 keeps the process alive, so the next start reused it, skipped the setup
and stayed black until the app was force-stopped (clearing its cache does that). Ending the process when the game screen closes
makes every start a fresh one (owner's Galaxy Tab A9+, 3 Nov 2026). The old body (super.onDestroy + SDKHelper.onDestroy) is not
needed when the process ends. Same size: nop, nop, const/4 v0 0, invoke-static {v0} System.exit(I), return-void (7 code units).
usage: python -I tools/patch_exit_dex.py <classes.dex> <out.dex>"""
import sys, struct, hashlib, zlib
src, out = sys.argv[1:3]
d = bytearray(open(src, 'rb').read())
u32 = lambda o: struct.unpack_from('<I', d, o)[0]
u16 = lambda o: struct.unpack_from('<H', d, o)[0]
def uleb(o):
    r = s = 0
    while True:
        b = d[o]; o += 1; r |= (b & 0x7f) << s; s += 7
        if not b & 0x80: return r, o
strs_o, types_o = u32(60), u32(68); meth_n, meth_o = u32(88), u32(92); cls_n, cls_o = u32(96), u32(100)
def sstr(i):
    o = u32(strs_o + 4 * i); _, o = uleb(o); e = d.index(0, o); return d[o:e].decode('utf8', 'replace')
tname = lambda t: sstr(u32(types_o + 4 * t))
mref = lambda i: tname(u16(meth_o + 8 * i)) + '->' + sstr(u32(meth_o + 8 * i + 4))
exit_idx = next(i for i in range(meth_n) if mref(i) == 'Ljava/lang/System;->exit')
assert exit_idx <= 0xffff
code = None
for c in range(cls_n):
    base = cls_o + 32 * c
    if tname(u32(base)) != 'Lcom/xckoo/renlong/renlong;': continue
    cd = u32(base + 24); sf, cd = uleb(cd); inf, cd = uleb(cd); dm, cd = uleb(cd); vm, cd = uleb(cd)
    for _ in range(sf + inf): _, cd = uleb(cd); _, cd = uleb(cd)
    for count in (dm, vm):
        idx = 0
        for _ in range(count):
            diff, cd = uleb(cd); idx += diff; _, cd = uleb(cd); c_off, cd = uleb(cd)
            if sstr(u32(meth_o + 8 * idx + 4)) == 'onDestroy': code = c_off
assert code, 'renlong.onDestroy not found'
regs, ins, outs, tries, size = u16(code), u16(code + 2), u16(code + 4), u16(code + 6), u32(code + 12)
body = [0x0000, 0x0000, 0x0012, 0x1071, exit_idx, 0x0000, 0x000e]
if [u16(code + 16 + 2 * k) for k in range(size)] == body:
    print('already patched')
else:
    assert (regs, ins, tries, size) == (1, 1, 0, 7) and outs >= 1, (regs, ins, outs, tries, size)
    assert u16(code + 16) & 0xff == 0x6f and u16(code + 28) == 0x000e, 'unexpected onDestroy body'
    for k, w in enumerate(body): struct.pack_into('<H', d, code + 16 + 2 * k, w)
    print('patched renlong.onDestroy at', hex(code), '-> System.exit(0), method', exit_idx)
d[12:32] = hashlib.sha1(bytes(d[32:])).digest()
struct.pack_into('<I', d, 8, zlib.adler32(bytes(d[12:])) & 0xffffffff)
open(out, 'wb').write(d)
