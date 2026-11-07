# Write docs/TABLE-COLUMNS.md: the column names of every table in the client's tables.bin, read from the game code
# (Struct_<Table>::InitMemberNames in re/all.txt, made by tools/setup_re.py), with sample values from server/data/<table>.json.
# JSON index N = column name N (index 0 is the row key). Usage: python -I tools/table_columns.py   (from the repo folder)
import json, os, re, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
lines = open(os.path.join(root, 're', 'all.txt'), encoding='utf-8', errors='replace').read().split('\n')
structs, cur = {}, None
for ln in lines:
    if ln.startswith('===== '):
        m = re.match(r'===== _ZN\d+(Struct_\w+?)15InitMemberNamesEv ', ln)
        cur = m.group(1) if m else None
        if cur: structs[cur] = []
        continue
    if cur:
        m = re.search(r"-> 0x[0-9a-f]+ '([^']*)'", ln)
        if m: structs[cur].append(m.group(1))
data = os.path.join(root, 'server', 'data')
tables = {f[:-5]: f for f in os.listdir(data) if f.endswith('.json')}
code = ''
for d in [os.path.join(root, 'server'), os.path.join(root, 'tools')]:
    for dp, dn, fn in os.walk(d):
        if 'cdn' in dp: continue
        for f in fn:
            if f.endswith('.js'): code += open(os.path.join(dp, f), encoding='utf-8', errors='replace').read() + '\n'
out = ['# Game table columns', '',
       "Column names of every table in the client's tables.bin, read from the game code (`Struct_<Table>::InitMemberNames` in libgame.so).",
       'Index = position in `server/data/<table>.json` rows (index 0 is the row key, index N = name N). Made by `tools/table_columns.py`.',
       '"NOT read by the server" = no server or tool code names the table. normalconfig is one value per row: see its rows (Chinese descriptions) in the json.', '']
for s, names in sorted(structs.items()):
    key = s[len('Struct_'):].lower().replace('_', '')
    t = next((tn for tn in tables if tn.lower().replace('_', '') == key), None)
    if not t: continue
    rows = json.load(open(os.path.join(data, tables[t]), encoding='utf-8'))['rows']
    used = re.search(r"'" + re.escape(t) + r"'", code)
    out += [f"## {t} ({len(rows)} rows){'' if used else ' — NOT read by the server'}", '', '| # | column | distinct | examples |', '|---|---|---|---|']
    for i, n in enumerate(names, start=1):
        dist = []
        for r in rows:
            if i < len(r) and r[i] not in dist: dist.append(r[i])
        ex = ', '.join(str(x).replace('|', '/').replace('\n', ' ')[:40] for x in dist[:6])
        out.append(f"| {i} | {n} | {len(dist)} | {ex} |")
    out.append('')
open(os.path.join(root, 'docs', 'TABLE-COLUMNS.md'), 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('written docs/TABLE-COLUMNS.md,', len(structs), 'tables')
