// Sounds and music (the phone's CSoundMgr on CocosDenshion): HB.sound(name) plays an effect, HB.music(name) the looping music.
// The game's own list (libgame.so, the table CSoundMgr::PlayEffect / PlayBackgroundSound index; files in assets/sound):
//    0 beijingmain  music: login, home and every screen without its own music     1 button6  every button tap
//    2 duobaojingji music: Spar and Plunder lists      3 fail  Defeat screen       4 fight    music: a fight
//    5 story        music: Training                    6 win   Victory screen      7 zhenguozhan music: country war (War tab)
//    8 zhuangbei    9 diaoqian  10 shengji (upgrade complete)   11 kaibaoxiang ("you got" window)   12 levelup (level-up window)
//   13 tianti       music: Arena                      14 jiaozhan (two cards clash)  15 rl_gotEXP  16 rl_RUN  17 chuchang (fight starts)
//   18 shangdian
// Which music a screen gets: the game's config/bgSoundConfig.lua (Arena = tianti, Spar / Plunder = duobaojingji, Training = story,
// War tab = zhenguozhan, everything else = beijingmain), CRoundFightView = fight, and after a fight the screen's own music again.
// The other screens are not edited for this: the hooks below listen to which layout is built (HB.build), HB.fight.play,
// HB.showCards and the card timelines.
// Switches: music and effects apart (the Settings screen), remembered in the browser (hb.music / hb.fx and the scripts' own
// switch_sound / switch_soundeffect); ?mute=1 starts silent without changing what is remembered. No sound before the first tap or
// key: browsers refuse it; the music asked for before that starts with that first tap.
'use strict';
(function () {
  const HB = window.HB;
  const FILES = ['beijingmain', 'button6', 'duobaojingji', 'fail', 'fight', 'story', 'win', 'zhenguozhan', 'zhuangbei', 'diaoqian', 'shengji', 'kaibaoxiang', 'levelup', 'tianti', 'jiaozhan', 'rl_gotEXP', 'rl_RUN', 'chuchang', 'shangdian'];
  const NAMES = { click: 'button6', button: 'button6', main: 'beijingmain', win: 'win', fail: 'fail', levelup: 'levelup', box: 'kaibaoxiang', upgrade: 'shengji', clash: 'jiaozhan', enter: 'chuchang', coin: 'diaoqian', equip: 'zhuangbei', exp: 'rl_gotEXP', run: 'rl_RUN', shop: 'shangdian', arena: 'tianti', spar: 'duobaojingji', story: 'story', war: 'zhenguozhan', fight: 'fight' };
  // the numbers gamebind.js gives the scripts' SOUND_ names (1-6, not the phone's own numbers above)
  const LUA_IDS = { 1: 'button6', 2: 'beijingmain', 3: 'duobaojingji', 4: 'story', 5: 'tianti', 6: 'zhenguozhan' };
  const fileOf = (name) => { if (typeof name === 'number') return FILES[name] || null; const k = String(name); return NAMES[k] || (FILES.includes(k) ? k : /^[\w-]+$/.test(k) ? k : null); };
  const url = (f) => (HB.ASSETS || 'assets/') + 'sound/' + f + '.mp3';

  const q = new URLSearchParams(location.search);
  const get = (k) => { try { return localStorage.getItem(k); } catch (e) { return null; } };
  const put = (k, v) => { try { localStorage.setItem(k, v); } catch (e) { /* private window */ } };
  const st = { music: get('hb.music') !== '0', fx: get('hb.fx') !== '0', muted: q.get('mute') === '1' || q.get('auto') === '1' /* test runs (auto=1) are always silent: owner, 21 Nov 2026 */, unlocked: false, want: null, playing: null, canChange: true, plays: 0 };
  // the scripts' own two switches (CCUserDefault, luabind.js keeps them in hb.userdefault): the Settings screen reads these
  const syncScripts = () => {
    try { const ud = JSON.parse(get('hb.userdefault') || '{}'); if (ud.switch_sound !== st.music || ud.switch_soundeffect !== st.fx) { ud.switch_sound = st.music; ud.switch_soundeffect = st.fx; put('hb.userdefault', JSON.stringify(ud)); } } catch (e) { /* keep */ }
  };
  syncScripts();

  // ---------------------------------------------------------------- effects
  const fx = new Map(); // file -> { base, last }
  function effect(name) {
    const f = fileOf(name);
    if (!f || !st.unlocked || st.muted || !st.fx) return false;
    let e = fx.get(f);
    if (!e) { e = { base: new Audio(url(f)), last: 0, live: [] }; e.base.preload = 'auto'; fx.set(f, e); }
    const now = performance.now();
    if (now - e.last < 70) return false; // the same sound twice in one moment (two cards hit at once) is one sound
    e.last = now;
    const a = e.live.find((x) => x.ended || x.paused) || (e.live.length < 4 ? e.live[e.live.push(e.base.cloneNode()) - 1] : e.live[0]);
    a.volume = 0.8;
    try { a.currentTime = 0; } catch (err) { /* not loaded yet */ }
    st.plays++;
    const p = a.play(); if (p && p.catch) p.catch(() => {});
    return true;
  }
  const stopEffects = () => { for (const e of fx.values()) for (const a of e.live) a.pause(); };

  // ---------------------------------------------------------------- music
  let bg = null;
  function music(name, loop = true) {
    const f = fileOf(name);
    if (!f) return;
    st.want = f; st.loop = loop;
    if (!st.unlocked || st.muted || !st.music) return;
    if (st.playing === f && bg && !bg.paused) return;
    if (!bg) { bg = new Audio(); bg.volume = 0.5; bg.preload = 'auto'; }
    if (st.playing !== f) { bg.src = url(f); st.playing = f; }
    bg.loop = loop;
    st.plays++;
    const p = bg.play(); if (p && p.catch) p.catch(() => {});
  }
  function stopMusic() { if (bg) bg.pause(); }
  const resume = () => { if (st.want) music(st.want, st.loop); };

  // the first tap or key lets the browser play: start the music that was asked for
  const unlock = () => {
    if (st.unlocked) return;
    st.unlocked = true;
    for (const ev of ['pointerdown', 'keydown', 'touchstart']) window.removeEventListener(ev, unlock, true);
    resume();
  };
  for (const ev of ['pointerdown', 'keydown', 'touchstart']) window.addEventListener(ev, unlock, true);
  // a hidden tab (phone locked, another app) is silent
  document.addEventListener('visibilitychange', () => { if (document.hidden) { stopMusic(); stopEffects(); } else resume(); });

  // ---------------------------------------------------------------- what the screens call
  const sound = (name) => effect(name);
  sound.play = effect;
  sound.music = music;
  sound.stopMusic = () => { st.want = null; stopMusic(); };
  sound.state = () => ({ music: st.music, fx: st.fx, muted: st.muted, unlocked: st.unlocked, playing: bg && !bg.paused ? st.playing : null, want: st.want, plays: st.plays });
  sound.setMusic = (on) => { st.music = !!on; st.muted = false; put('hb.music', on ? '1' : '0'); syncScripts(); if (on) resume(); else stopMusic(); };
  sound.setFx = (on) => { st.fx = !!on; st.muted = false; put('hb.fx', on ? '1' : '0'); syncScripts(); if (!on) stopEffects(); };
  sound.mute = (on) => { st.muted = !!on; if (on) { stopMusic(); stopEffects(); } else resume(); };
  HB.sound = sound;
  HB.music = music;

  // the scripts' CSoundMgr (gamebind.js): the names libgame.so has, on top of the functions above
  HB.soundMgr = () => {
    const id = (v) => LUA_IDS[Number(v)] || 'beijingmain';
    const truthy = (v) => v !== false && v !== undefined && v !== null && v !== 0;
    const m = {
      PlayEffect: (n) => { effect(id(n)); },
      PlayBackgroundSound: (n, loop) => { music(id(n), loop === undefined ? true : truthy(loop)); },
      StopBackgroundSound: () => { st.want = null; stopMusic(); }, PauseBackgroundSound: () => stopMusic(), ResumeBackgroundSound: () => resume(), RewindBackgroundSound: () => { if (bg) try { bg.currentTime = 0; } catch (e) { /* not loaded */ } },
      StopAllEffect: () => stopEffects(),
      SetBackSoundEnable: (on) => sound.setMusic(truthy(on)), SetSoundEffectEnable: (on) => sound.setFx(truthy(on)),
      SetBackSoundVolume: (v) => { if (bg) bg.volume = Math.max(0, Math.min(1, Number(v) || 0)); }, GetBackSoundVolume: () => (bg ? bg.volume : 0.5), SetEffectVolume: () => {},
      CanChangeBgSound: () => st.canChange, OpenBgSoundChange: () => { st.canChange = true; }, CloseBgSoundChange: () => { st.canChange = false; },
      GetPlayingBgSound: () => Number(Object.keys(LUA_IDS).find((k) => LUA_IDS[k] === st.want) || 0), IsBackgroundSoundPlaying: () => !!(bg && !bg.paused),
      PlayBgSoundByTypeId: () => music(screenMusic()),
    };
    // older names this file's first stub had
    m.PlayBgSound = m.PlayBackgroundSound; m.StopBgSound = m.StopBackgroundSound; m.SetEffectOn = m.SetSoundEffectEnable; m.SetMusicOn = m.SetBackSoundEnable;
    return m;
  };

  // ---------------------------------------------------------------- hooks: which screen is on, what just opened
  const MUSIC_OF = { 'sub_ui/ArenaViewNew': 'tianti', 'sub_ui/FightListView': 'duobaojingji', 'sub_ui/PlunderListView': 'duobaojingji', 'sub_ui/ChapterView': 'story', 'sub_ui/SubChapterListView': 'story' };
  const EFFECT_OF = { 'core_combat/NewFightResult_WinView': 'win', 'core_combat/NewFightResult_FailView': 'fail', 'dlg_ui/PlayerLevelUpDlg': 'levelup', 'upgrade/UpgradeCompleteView': 'shengji' };
  let current = 'beijingmain'; // the music of the screen that is open
  const screenMusic = () => current;
  sound.screen = (name) => { current = fileOf(name) || 'beijingmain'; music(current); }; // for screens with tabs of their own music (War)
  if (HB.build) {
    const build = HB.build;
    HB.build = function (file, ...rest) {
      const node = build.call(this, file, ...rest);
      try {
        if (file === 'LoginView' || file === 'sub_ui/DefaultMainMenu') { current = 'beijingmain'; music(current); }
        else if (file === 'sub_ui/RoundTeamView') { music('fight'); effect('chuchang'); }
        else if (EFFECT_OF[file]) effect(EFFECT_OF[file]);
      } catch (e) { /* never break a screen for a sound */ }
      return node;
    };
  }
  // two cards clash (CRoundTeamFightView::update)
  if (HB.play) { const play = HB.play; HB.play = function (root, seq, done) { if (seq === 'gethurt') effect('jiaozhan'); return play.call(this, root, seq, done); }; }
  // after a fight the screen's own music comes back (the result screens' closeThis -> PlayBgSoundByTypeId)
  if (HB.fight && HB.fight.play) { const play = HB.fight.play; HB.fight.play = async function (...a) { try { return await play.apply(this, a); } finally { music(current); } }; }
  // the "you got" window (CDialogShowBox::init)
  if (HB.showCards) { const show = HB.showCards; HB.showCards = function (...a) { effect('kaibaoxiang'); return show.apply(this, a); }; }
  // screens put into the main menu (CMainMenu::ChangeToPlaySound): HB.game's functions exist a moment after this file loads
  const hookGame = () => {
    const g = HB.game;
    if (!g || !g.showSub) return false;
    const showSub = g.showSub;
    g.showSub = function (file, ...rest) { const r = showSub.call(this, file, ...rest); current = MUSIC_OF[file] || 'beijingmain'; music(current); return r; };
    if (g.changeToActivitySubMenu) { const sub = g.changeToActivitySubMenu; g.changeToActivitySubMenu = function (...x) { current = 'beijingmain'; music(current); return sub.apply(this, x); }; }
    return true;
  };
  if (!hookGame()) { const t = setInterval(() => { if (hookGame()) clearInterval(t); }, 150); }
})();
