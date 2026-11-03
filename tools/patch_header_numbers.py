"""Home and training headers (sub_ui/DefaultMainMenu.ccbi, sub_ui/ChapterView.ccbi): the attack and defense ranges ("7833880-8264179")
ran over the next icon for strong teams (owner, 3 Nov 2026). Their labels are drawn at 80 % size (scale 1.0 -> 0.8), left edge unchanged.
usage: python -I tools/patch_header_numbers.py   (reads re/obb, writes server/cdn/src/sub_ui)"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ccbi
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCALE = 0.8
for name in ('DefaultMainMenu.ccbi', 'ChapterView.ccbi'):
    data = open(os.path.join(root, 're', 'obb', 'sub_ui', name), 'rb').read()
    n0 = ccbi.parse(data)
    kind = next(n['props']['scale'][2] for n, _ in ccbi.walk(n0) if n.get('name') == 'label_maxattack')
    data = ccbi.patch(data, {'label_maxattack': {'scale': (SCALE, SCALE, kind)}, 'label_maxdefense': {'scale': (SCALE, SCALE, kind)}})
    out = os.path.join(root, 'server', 'cdn', 'src', 'sub_ui', name)
    open(out, 'wb').write(data)
    print('wrote', out)
