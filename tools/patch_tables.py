# Change numbers in the client's own data tables (tables.bin in the OBB) and write a new tables.bin for a hot update.
# tables.bin is a zip whose local-header magic is @B>R instead of PK; tables are MBS files (see mbs.py).
# usage: python -I tools/patch_tables.py <tables.bin in> <tables.bin out> table:rowid:col=value ...
#   col is 0-based over the row's columns as data/<table>.json shows them minus the leading id (json col 3 = col 2 here).
import io, struct, sys, zipfile

MAGIC, PK = b'@B>R\x14\x00', b'PK\x03\x04\x14\x00'

def patch_mbs(d, rowid, col, value):
    d = bytearray(d)
    rows, cols, idx_off, type_off, data_off = struct.unpack_from('<5I', d, 12)
    ids = struct.unpack_from('<%dI' % rows, d, idx_off)
    types = d[type_off:type_off + cols].decode()
    width = sum(4 if t in 'uf' else 6 for t in types)
    r = ids.index(rowid)
    assert types[col] == 'u', 'only number columns'
    p = data_off + r * width + sum(4 if t in 'uf' else 6 for t in types[:col])
    print('row %d col %d: %d -> %d' % (rowid, col, struct.unpack_from('<I', d, p)[0], value))
    struct.pack_into('<I', d, p, value)
    return bytes(d)

def main(src, dst, edits):
    zin = zipfile.ZipFile(io.BytesIO(open(src, 'rb').read().replace(MAGIC, PK)))
    files = {i.filename: zin.read(i.filename) for i in zin.infolist()}
    for e in edits:
        name, rowid, rest = e.split(':')
        col, value = rest.split('=')
        key = 'tables/%s.dbf' % name
        files[key] = patch_mbs(files[key], int(rowid), int(col), int(value))
    out = io.BytesIO()
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for i in zin.infolist():
            z.writestr(i.filename, files[i.filename])
    open(dst, 'wb').write(out.getvalue().replace(PK, MAGIC))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
