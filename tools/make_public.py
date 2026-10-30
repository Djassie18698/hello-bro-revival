"""Build the PUBLIC release folder from this private repo: server code + setup tools + docs only.
Never copies game files (APK/OBB/Lua/data tables), saves, keys or personal addresses.
usage: python -I tools/make_public.py <out-dir>"""
import os, re, shutil, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.abspath(sys.argv[1])
CODE = ['server.js', 'handlers.js', 'game.js', 'guild.js', 'mora.js', 'slot.js', 'rankings.js', 'boss.js', 'country.js', 'war.js', 'seals.js', 'border.js', 'tear.js', 'sudoku.js', 'sevenday.js', 'vip.js', 'wheel.js',
        'signin.js', 'drops.js', 'admin.js', 'schema.js', 'OPEN-FIREWALL.bat']
TOOLS = ['tools/mbs.py', 'tools/patch_apk.py', 'tools/setup_from_xapk.py', 'tools/build_cdn.py', 'tools/dev/smoke.js']
DATA = ['data/activity_packs.json']  # made by us, not extracted from the game

# keep .git if the folder is already a clone of the public repo
if os.path.isdir(out):
    for n in os.listdir(out):
        if n == '.git':
            continue
        p = os.path.join(out, n)
        shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
os.makedirs(out, exist_ok=True)

def put(rel, src=None):
    dst = os.path.join(out, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src or os.path.join(root, rel), dst)

for f in CODE + TOOLS + DATA:
    put(f)
tmpl = os.path.join(root, 'public-template')
for d, _, files in os.walk(tmpl):
    for f in files:
        full = os.path.join(d, f)
        put(os.path.relpath(full, tmpl), full)
put('docs/ROADMAP.md', os.path.join(root, 'docs', 'MASTER-PLAN.md'))
put('docs/HOT-UPDATE.md')

# safety net: refuse if anything private slipped in
BAD = re.compile(rb'192\.168\.178\.111|100\.111\.115\.0|22079117|22078671|nellessen|dj199', re.I)
for d, _, files in os.walk(out):
    if '.git' in d.split(os.sep):
        continue
    for f in files:
        p = os.path.join(d, f)
        assert not re.search(r'\.(apk|xapk|obb|keystore|db)$', f), 'private file: ' + p
        hit = BAD.search(open(p, 'rb').read())
        assert not hit, 'private text %r in %s' % (hit.group(0), p)
print('public folder ready:', out)
