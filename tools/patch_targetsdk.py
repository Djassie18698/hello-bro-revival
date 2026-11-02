"""Raise targetSdkVersion in a binary AndroidManifest.xml (AXML).
Android 14 refuses to install apps that target below API 23, Android 15 below API 24 (INSTALL_FAILED_DEPRECATED_SDK_VERSION);
Hello Bro targets 19, so every installer fails on a new phone or tablet (Galaxy Tab A9+, Android 15, 2 Nov 2026).
usage (as a module): patch(axml_bytes, 24) -> new bytes. Only the number changes: the file keeps its size."""
import struct

TARGET_SDK_ATTR = 0x01010270    # android:targetSdkVersion


def patch(data, target=24):
    data = bytearray(data)
    res_ids, pos, done = [], 8, False
    while pos < len(data):
        ctype, hsize, csize = struct.unpack_from('<HHI', data, pos)
        if ctype == 0x0180:                               # resource map: string index -> attribute resource id
            res_ids = list(struct.unpack_from('<%dI' % ((csize - hsize) // 4), data, pos + hsize))
        elif ctype == 0x0102:                             # start element
            astart, asize, acount = struct.unpack_from('<HHH', data, pos + 16 + 8)
            for i in range(acount):
                a = pos + 16 + astart + i * asize
                name = struct.unpack_from('<I', data, a + 4)[0]
                if name < len(res_ids) and res_ids[name] == TARGET_SDK_ATTR:
                    old = struct.unpack_from('<I', data, a + 16)[0]
                    if old < target:
                        struct.pack_into('<I', data, a + 8, 0xFFFFFFFF)      # no raw string value
                        struct.pack_into('<HBBI', data, a + 12, 8, 0, 0x10, target)  # TYPE_INT_DEC
                    done = True
        pos += csize
    if not done:
        raise SystemExit('targetSdkVersion not found in AndroidManifest.xml')
    return bytes(data)
