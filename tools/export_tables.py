import sys, os, json, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mbs

base = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(base, 'tables', 'tables')
dst = os.path.join(base, 'json')
os.makedirs(dst, exist_ok=True)
ok = bad = 0
for f in sorted(glob.glob(os.path.join(src, '*.dbf'))):
    n = os.path.basename(f)[:-4]
    try:
        t, rows, p = mbs.parse(f)
        with open(os.path.join(dst, n + '.json'), 'w', encoding='utf8') as fh:
            json.dump({'types': t, 'rows': [[i] + r for i, r in rows]}, fh, ensure_ascii=False)
        ok += 1
    except Exception as e:
        print('FAIL', n, e)
        bad += 1
print(ok, 'ok', bad, 'failed')
for name, n in (('recruitinfo', 10), ('ninjainfo', 2)):
    d = json.load(open(os.path.join(dst, name + '.json'), encoding='utf8'))
    print(name, d['types'], len(d['rows']))
    for r in d['rows'][:n]:
        print(r)
