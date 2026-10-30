"""One-time research setup for a new session. Makes re/ (git-ignored):
  re/libgame.so   the game's native code (all C++ screens/parsers)
  re/all.txt      full disassembly of it with string and symbol hints (~44 MB, grep it)
  re/obb/         the original OBB unpacked (Lua scripts, ccbi, home/userguideConfig.xml, images)
It needs a Hello Bro .xapk (Desktop, Downloads, repo root, or downloaded from the tailscale-play release with gh).
usage: python -I tools/setup_re.py     (needs: pip install pyelftools capstone)"""
import glob, io, os, subprocess, sys, zipfile
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
re_dir = os.path.join(root, 're'); os.makedirs(re_dir, exist_ok=True)
home = os.path.expanduser('~')
cands = [c for d in (os.path.join(home, 'Desktop'), os.path.join(home, 'Downloads'), root)
         for c in glob.glob(os.path.join(d, '*.xapk')) if 'hellobro' in os.path.basename(c).lower()]
if not cands:
    print('no xapk found, downloading it from the release ...')
    subprocess.check_call(['gh', 'release', 'download', 'tailscale-play', '-R', 'Djassie18698/hello-bro-revival',
                           '-p', 'HelloBro-Tailscale-100.111.115.0.xapk', '-D', re_dir, '--clobber'])
    cands = glob.glob(os.path.join(re_dir, '*.xapk'))
src = max(cands, key=os.path.getmtime)
print('using', src)
x = zipfile.ZipFile(src)
apk = zipfile.ZipFile(io.BytesIO(x.read('com.hello.bro.yo.apk')))
open(os.path.join(re_dir, 'libgame.so'), 'wb').write(apk.read('lib/armeabi/libgame.so'))
obb = zipfile.ZipFile(io.BytesIO(x.read('Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb')))
obb.extractall(os.path.join(re_dir, 'obb'))
print('unpacked OBB to re/obb, disassembling (takes a few minutes) ...')
with open(os.path.join(re_dir, 'all.txt'), 'w', encoding='utf8') as out:
    subprocess.check_call([sys.executable, os.path.join(root, 'tools', 'armdis.py'), '.', '100000'], stdout=out,
                          env={**os.environ, 'HB_SO': os.path.join(re_dir, 'libgame.so')})
print('done: re/all.txt')
