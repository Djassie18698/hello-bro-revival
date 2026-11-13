// The game's music and sound effects (on Android: Cocos2dxMusic / Cocos2dxSound in Java). The app only names a file
// ("sound/beijingmain.mp3", sometimes with a folder in front); the page plays assets/emu/sound/<name>.mp3 with Web Audio.
// Phones only allow sound after the player has touched the page: unlock() is called on every touch.
//   const a = EmuAudio(base); a.playMusic(path, loop); a.playEffect(path, loop) -> id; a.stopEffect(id); a.setMusicVolume(v) ...
'use strict';
(function (root) {
  function EmuAudio(base) {
    const AC = root.AudioContext || root.webkitAudioContext;
    if (!AC) return null;
    // iPhone: play even when the ring switch is on silent, like the game's own app did (iOS 17+)
    try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch { /* older browsers */ }
    const ctx = new AC();
    const musicGain = ctx.createGain(), fxGain = ctx.createGain();
    musicGain.connect(ctx.destination); fxGain.connect(ctx.destination);
    const buffers = new Map(); // file name -> Promise<AudioBuffer|null>
    const name = (p) => { p = String(p || ''); const i = p.lastIndexOf('/'); let n = i >= 0 ? p.slice(i + 1) : p; n = n.replace(/\.(wav|aif|aiff|ogg|caf|m4a)$/i, '.mp3'); return n; };
    const load = (p) => {
      const n = name(p);
      if (!n) return Promise.resolve(null);
      if (!buffers.has(n)) {
        buffers.set(n, fetch(base + encodeURIComponent(n)).then((r) => (r.ok ? r.arrayBuffer() : null))
          .then((b) => (b ? new Promise((ok) => ctx.decodeAudioData(b, ok, () => ok(null))) : null)).catch(() => null));
      }
      return buffers.get(n);
    };
    let music = null, musicFile = '', musicLoop = false, musicPaused = false, musicWanted = false;
    const startMusic = () => {
      const file = musicFile, loop = musicLoop;
      load(file).then((buf) => {
        if (!buf || file !== musicFile || !musicWanted) return;
        if (music) { try { music.stop(); } catch { /* ended */ } }
        const s = ctx.createBufferSource(); s.buffer = buf; s.loop = loop; s.connect(musicGain); s.start();
        s.onended = () => { if (music === s && !s.loop) { music = null; musicWanted = false; } };
        music = s;
      });
    };
    const effects = new Map(); let nextId = 1;
    const a = {
      unlock() { if (ctx.state !== 'running') ctx.resume().catch(() => {}); },
      preload(p) { load(p); },
      playMusic(p, loop) { musicFile = name(p); musicLoop = !!loop; musicWanted = true; musicPaused = false; if (ctx.state === 'suspended') ctx.resume().catch(() => {}); startMusic(); },
      stopMusic() { musicWanted = false; if (music) { try { music.stop(); } catch { /* ended */ } music = null; } },
      pauseMusic() { if (music && !musicPaused) { musicPaused = true; try { music.stop(); } catch { /* ended */ } music = null; } },
      resumeMusic() { if (musicPaused && musicWanted) { musicPaused = false; startMusic(); } },
      rewindMusic() { if (musicWanted) startMusic(); },
      isMusicPlaying() { return !!music && musicWanted && !musicPaused; },
      musicVolume: 1, effectsVolume: 1,
      setMusicVolume(v) { a.musicVolume = Math.max(0, Math.min(1, +v || 0)); musicGain.gain.value = a.musicVolume; },
      setEffectsVolume(v) { a.effectsVolume = Math.max(0, Math.min(1, +v || 0)); fxGain.gain.value = a.effectsVolume; },
      playEffect(p, loop) {
        const id = nextId++;
        if (ctx.state !== 'running') return id; // no sound before the first touch (the browser would not play it anyway)
        load(p).then((buf) => {
          if (!buf) return;
          const s = ctx.createBufferSource(); s.buffer = buf; s.loop = !!loop; s.connect(fxGain); s.start();
          effects.set(id, s); s.onended = () => effects.delete(id);
        });
        return id;
      },
      stopEffect(id) { const s = effects.get(id); if (s) { try { s.stop(); } catch { /* ended */ } effects.delete(id); } },
      stopAllEffects() { for (const id of [...effects.keys()]) a.stopEffect(id); },
      pauseAll() { ctx.suspend().catch(() => {}); },
      resumeAll() { ctx.resume().catch(() => {}); },
    };
    return a;
  }
  root.EmuAudio = EmuAudio;
})(typeof window !== 'undefined' ? window : globalThis);
