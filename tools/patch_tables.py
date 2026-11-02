# Change numbers in the client's own data tables (tables.bin in the OBB) and write a new tables.bin for a hot update.
# tables.bin is a zip whose local-header magic is @B>R instead of PK; tables are MBS files (see mbs.py).
# usage: python -I tools/patch_tables.py <tables.bin in> <tables.bin out> table:rowid:col=value ... table:+[json row] ...
#   value is a number for number columns and any text for text columns (e.g. ninjainfo:100016:1=Golden Choji).
#   col is 0-based over the row's columns as data/<table>.json shows them minus the leading id (json col 3 = col 2 here).
#   table:+[...] appends a row written like a data/<table>.json row (leading index id first, then every column).
import io, json, struct, sys, zipfile

MAGIC, PK = b'@B>R\x14\x00', b'PK\x03\x04\x14\x00'

def patch_mbs(d, rowid, col, value):
    d = bytearray(d)
    rows, cols, idx_off, type_off, data_off = struct.unpack_from('<5I', d, 12)
    ids = struct.unpack_from('<%dI' % rows, d, idx_off)
    types = d[type_off:type_off + cols].decode()
    width = sum(4 if t in 'uf' else 6 for t in types)
    r = ids.index(rowid)
    p = data_off + r * width + sum(4 if t in 'uf' else 6 for t in types[:col])
    if types[col] == 's':  # text: the string pool is the last part of the file, so the new text is appended and the slot points to it
        b = str(value).encode('utf8')
        print('row %d col %d: text -> %s' % (rowid, col, ascii(value)))
        struct.pack_into('<IH', d, p, len(d), len(b))
        return bytes(d) + b + bytes(1)
    assert types[col] == 'u', 'only number and text columns'
    print('row %d col %d: %d -> %d' % (rowid, col, struct.unpack_from('<I', d, p)[0], value))
    struct.pack_into('<I', d, p, int(value))
    return bytes(d)

def add_row(d, row):
    """Append one row: header (12 bytes + rows, cols, idx, types, data, width, pool), id index, type string, rows, string pool."""
    rows, cols, idx_off, type_off, data_off, width, pool_off = struct.unpack_from('<7I', d, 12)
    types = d[type_off:type_off + cols].decode()
    ids = list(struct.unpack_from('<%dI' % rows, d, idx_off))
    assert len(row) == cols + 1 and row[0] not in ids, 'row must be [id, col0, ...] with a new id'
    assert ids == sorted(ids) and row[0] > ids[-1], 'new id must come after the last one'
    pool = bytearray(d[pool_off:])
    new_type, new_data = idx_off + 4 * (rows + 1), None
    new_data = new_type + cols + 1
    new_pool = new_data + (rows + 1) * width
    shift = new_pool - pool_off
    data = bytearray(d[data_off:data_off + rows * width])
    for r in range(rows):  # move every string offset along with the pool
        p = r * width
        for t in types:
            if t in 'uf': p += 4; continue
            off = struct.unpack_from('<I', data, p)[0]
            assert off >= pool_off
            struct.pack_into('<I', data, p, off + shift); p += 6
    for t, v in zip(types, row[1:]):
        if t == 'u': data += struct.pack('<I', v)
        elif t == 'f': data += struct.pack('<f', v)
        else:
            b = str(v).encode('utf8')
            data += struct.pack('<IH', new_pool + len(pool), len(b)); pool += b + b'\0'
    head = bytearray(d[:12]) + struct.pack('<7I', rows + 1, cols, idx_off, new_type, new_data, width, new_pool)
    head += d[len(head):idx_off]
    out = bytes(head) + struct.pack('<%dI' % (rows + 1), *ids, row[0]) + types.encode() + b'\0' + bytes(data) + bytes(pool)
    print('added row', row[0])
    return out

def main(src, dst, edits):
    zin = zipfile.ZipFile(io.BytesIO(open(src, 'rb').read().replace(MAGIC, PK)))
    files = {i.filename: zin.read(i.filename) for i in zin.infolist()}
    for e in edits:
        if ':+' in e:
            name, row = e.split(':+', 1)
            key = 'tables/%s.dbf' % name
            files[key] = add_row(files[key], json.loads(row))
            continue
        name, rowid, rest = e.split(':')
        col, value = rest.split('=', 1)
        key = 'tables/%s.dbf' % name
        files[key] = patch_mbs(files[key], int(rowid), int(col), value)
    out = io.BytesIO()
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for i in zin.infolist():
            z.writestr(i.filename, files[i.filename])
    open(dst, 'wb').write(out.getvalue().replace(PK, MAGIC))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
