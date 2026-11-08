"""Pictures for the home page (server/site, https://ninjaonlinereborn.com): cuts the game's own art out of re/obb into WebP files in
server/site/img. Which shinobi it cuts comes from server/site/home.json (made by node tools/build_wiki.js: "hero" and "featured" list
each card's big picture, npc/<name>.pvr.ccz). Backgrounds, story chapter banners, the original promo pictures and the Hello Bro logo
are fixed below. The screenshots (img/shot-*.webp) were taken on the Claude emulator and are not made here.
Needs re/obb (python -I tools/setup_re.py) and ffmpeg (WebP). usage: python -I tools/build_site_art.py"""
import glob, json, os, re, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import pvrccz  # noqa: E402

OBB = os.path.join(ROOT, 're', 'obb')
SITE = os.path.join(ROOT, 'server', 'site')
OUT = os.path.join(SITE, 'img')

# (output name, source in re/obb, frame name in its plist or None for the whole picture, max width, quality)
FIXED = [
    ('bg-moon', 'ccbResources/background/background_02.png', None, 768, 78),      # blue moon with crows (hero)
    ('bg-falls', 'level_bg/Emigrated_007.pvr.ccz', 'Emigrated_007', 687, 78),     # waterfall valley (how to play)
    ('bg-night', 'level_bg/level_16_01.png', 'level_16_01', 686, 74),             # misty night valley (shinobi)
    ('map', 'ccbResources/map001.png', None, 700, 70),                            # old paper map (news)
    ('logo-hellobro', 'ccbResources/logo.png', None, 562, 88),                    # the original logo
] + [(f'promo-{n}', 'ccbResources/advertise.pvr.ccz', f'advertise{n}', 420, 80) for n in range(1, 8)]  # original event posters
# story chapter banners: level_chapter_<n> lives on level_page1 (1-6), level_page2 (7-12), level_page3 (13-18), level_page4 (19-24)
FIXED += [(f'ch-{n}', f'ccbResources/level_background/level_page{(n - 1) // 6 + 1}.pvr.ccz', f'level_chapter_{n}', 690, 78) for n in range(1, 20)]


def ffmpeg():
    found = shutil.which('ffmpeg')
    if found:
        return found
    hits = glob.glob(os.path.expandvars(r'%LOCALAPPDATA%\Microsoft\WinGet\Packages\*FFmpeg*\*\bin\ffmpeg.exe'))
    if not hits:
        raise SystemExit('ffmpeg is missing (winget install ffmpeg)')
    return hits[0]


def frames(plist):
    """name -> (x, y, w, h, rotated) of every frame in a TexturePacker plist."""
    t = open(plist, encoding='utf-8', errors='replace').read()
    out = {}
    for m in re.finditer(r'<key>([^<]+?)(?:\.png)?</key>\s*<dict>\s*<key>frame</key>\s*<string>([^<]*)</string>(.*?)</dict>', t, re.S):
        x, y, w, h = [int(v) for v in re.findall(r'-?\d+', m.group(2))]
        rot = re.search(r'<key>rotated</key>\s*<(true|false)/>', m.group(3))
        out[m.group(1)] = (x, y, w, h, bool(rot and rot.group(1) == 'true'))
    return out


def cut(name, src, frame, width, quality):
    """Writes img/<name>.webp: the frame of src (or all of it), at most width pixels wide, alpha kept."""
    path = os.path.join(OBB, src)
    tmp = None
    if src.endswith('.pvr.ccz'):
        pvr, _ = pvrccz.read(path)
        tw, th, rgba = pvrccz.to_rgba(pvr)
        tmp = os.path.join(OUT, '.' + name.replace('/', '_') + '.rgba')
        open(tmp, 'wb').write(bytes(rgba))
        inp = ['-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', f'{tw}x{th}', '-i', tmp]
    else:
        inp = ['-i', path]
    vf = []
    if frame:
        plist = path.replace('.pvr.ccz', '.plist').replace('.png', '.plist')
        fr = frames(plist).get(frame)
        if not fr:
            raise SystemExit(f'{src}: no frame {frame}')
        x, y, w, h, rot = fr
        # a rotated frame is stored turned a quarter clockwise: cut h x w and turn it back
        vf += [f'crop={h}:{w}:{x}:{y}', 'transpose=2'] if rot else [f'crop={w}:{h}:{x}:{y}']
    vf.append(f"scale='min({width},iw)':-2:flags=lanczos")
    dst = os.path.join(OUT, name + '.webp')
    r = subprocess.run([ffmpeg(), '-loglevel', 'error', '-y', *inp, '-vf', ','.join(vf), '-c:v', 'libwebp', '-pix_fmt', 'yuva420p',
                        '-quality', str(quality), '-compression_level', '6', dst])
    if tmp:
        os.remove(tmp)
    if r.returncode or not os.path.exists(dst):
        raise SystemExit(f'could not make {dst}')
    return os.path.getsize(dst)


def main():
    if not os.path.isdir(OBB):
        raise SystemExit('re/obb is missing: run python -I tools/setup_re.py first')
    home = json.load(open(os.path.join(SITE, 'home.json'), encoding='utf-8'))
    os.makedirs(os.path.join(OUT, 'art'), exist_ok=True)
    total = 0
    for args in FIXED:
        total += cut(*args)
    arts = sorted({c['art'] for c in home['hero'] + home['featured']})
    for f in os.listdir(os.path.join(OUT, 'art')):  # pictures of cards no longer listed
        if f[:-5] not in arts:
            os.remove(os.path.join(OUT, 'art', f))
    for a in arts:
        frs = frames(os.path.join(OBB, 'npc', a + '.plist'))
        total += cut('art/' + a, f'npc/{a}.pvr.ccz', next(iter(frs)), 400, 86)
    print(f'{len(FIXED)} pictures + {len(arts)} shinobi -> server/site/img ({total // 1024} KB)')


main()
