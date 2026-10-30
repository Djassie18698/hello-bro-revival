"""Make the game file (XAPK) that connects to YOUR server.
usage: python -I tools/make_game_for.py <address>        e.g. 100.64.12.34  or  myname.duckdns.org:18080
Looks for a Hello Bro .xapk in this folder or in Downloads (the one from the Releases page), points its app at
<address>, signs it with release/revival.keystore (needs a JDK) and writes HelloBro-for-<address>.xapk here."""
import glob, os, subprocess, sys, zipfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
addr = sys.argv[1].strip()
if ':' not in addr:
    addr += ':18080'
safe = addr.replace(':18080', '').replace(':', '-')

cands = glob.glob(os.path.join(root, '*.xapk')) + glob.glob(os.path.join(os.path.expanduser('~'), 'Downloads', '*.xapk'))
cands = [c for c in cands if 'hellobro' in os.path.basename(c).lower() and not os.path.basename(c).startswith('HelloBro-for-')]
if not cands:
    sys.exit('No Hello Bro .xapk found. Download HelloBro-Tailscale-....xapk from the Releases page into this folder or Downloads.')
src = max(cands, key=os.path.getmtime)
print('using', src)

rel = os.path.join(root, 'release')
os.makedirs(rel, exist_ok=True)
base = os.path.join(rel, '_base.apk')
apk = os.path.join(rel, f'HelloBro-for-{safe}.apk')  # the keystore next to it (release/revival.keystore) signs it
with zipfile.ZipFile(src) as z:
    open(base, 'wb').write(z.read('com.hello.bro.yo.apk'))
subprocess.check_call([sys.executable, '-I', os.path.join(root, 'tools', 'patch_apk.py'), base, apk, addr])
os.remove(base)

out = os.path.join(root, f'HelloBro-for-{safe}.xapk')
with zipfile.ZipFile(src) as zi, zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as zo:
    for i in zi.infolist():
        zo.writestr(i, open(apk, 'rb').read() if i.filename == 'com.hello.bro.yo.apk' else zi.read(i.filename))
print('\nDONE:', out)
print('Give this file to everyone who plays on your server (drag it onto BlueStacks).')
