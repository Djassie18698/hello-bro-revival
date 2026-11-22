// Pictures of our own in place of the game's (ours; rewritten game only, the phone app and the game's files stay as they are).
// Some of the game's pictures have Chinese words drawn into them (the Lottery ticket's title and scrolls, three Home buttons, an
// Event bar icon). Their English versions are in ui/en/ (made by tools/make_webclient_en.js from the game's own pictures, at double
// size like the HD pictures). This table is the ONE place that says which picture is replaced:
//   a sprite frame's name (a frame of a sheet)        -> our picture, used wherever the engine looks that frame up (HB.frame)
//   a plain picture's path under assets/              -> our picture, loaded in its place (engine.js picture())
// and NO_HD below: pictures whose HD copy is wrong.
// ?pics=0 shows the originals. To add one: draw it (make_webclient_en.js), add a line here.
'use strict';
(function () {
  const HB = window.HB;
  const OURS = {
    // ---- Lottery ticket
    lottery_bg_title: 'lottery_bg_title.png',           // 第 n 期忍村彩票 -> "No. n  LOTTERY"
    lottery_bg_6: 'lottery_bg_6.png',                   // the two scrolls, 本期下注 -> "BETS"
    lottery_first: 'lottery_first.png',                 // 一等奖 -> "1st Prize"
    lottery_second: 'lottery_second.png',               // 二等奖
    lottery_third: 'lottery_third.png',                 // 三等奖
    lottery_open_time: 'lottery_open_time.png',         // 本期彩票开奖时间： -> "This draw is at:"
    lottery_get_time: 'lottery_get_time.png',           // 领奖截止时间： -> "Claim before:"
    lottery_end_time: 'lottery_end_time.png',           // 下注截止时间： -> "Bets close:"
    lottery_pre_winerList: 'lottery_pre_winerList.png', // 上期一等奖中奖名单 -> "Last 1st-prize winners"
    lottery_cur_myNums: 'lottery_cur_myNums.png',       // 本期投注号码 -> "This round"
    lottery_pre_myNums: 'lottery_pre_myNums.png',       // 上期投注号码 -> "Last round"
    // ---- Event bar icons
    activity21: 'activity21.png',                       // 忍村彩票 -> "Lottery"
    activity35: 'activity35.png',                       // 超忍挑战 -> "Challenge"
    activity45: 'activity45.png',                       // 翻牌充值 -> "Flip cards"
    // ---- Home buttons (plain pictures)
    'ccbResources/activity_icon_8.png': 'activity_icon_8.png', // 七日目标 -> "7-Day Goals"
    'ccbResources/activity_icon_6.png': 'activity_icon_6.png', // 榜 on the rank scroll -> "TOP"
    'ccbResources/activity_icon_2.png': 'activity_icon_2.png', // 30级 -> "Lv.30"
  };
  const DIR = 'ui/en/', V = '?2', off = /[?&]pics=0/.test(location.search); // V: raise it when a picture is drawn again (browsers keep the old one)
  // HD copies that came out wrong (tools/build_hd.js): the original picture is used instead.
  //   name_sparkle.png (the twinkle on a glowing name, our hot update): its HD copy is a picture of a seal card
  const NO_HD = new Set(['ccbResources/name_sparkle.png']);
  HB.ourPictures = off ? {} : OURS;
  // plain pictures: engine.js asks this before it loads a picture file; the answer is loaded instead (double size)
  HB.ourPicture = (file) => (NO_HD.has(file) ? { src: HB.ASSETS + file, hd: 1 } : HB.ourPictures[file] && file.includes('/') ? { src: DIR + HB.ourPictures[file] + V, hd: 2 } : null);
  // sprite frames: loaded once at the start; a frame that is asked for before its picture has arrived shows the original
  const ready = {};
  if (!off) for (const name of Object.keys(OURS)) { if (name.includes('/')) continue; const img = new Image(); img.hd = 2; img.onload = () => { ready[name] = img; }; img.src = DIR + OURS[name] + V; }
  const frame0 = HB.frame;
  HB.frame = function (plist, name, quiet) {
    const img = ready[name];
    if (img) { const w = img.naturalWidth / 2, h = img.naturalHeight / 2; return { img, x: 0, y: 0, w, h, rot: 0, ox: 0, oy: 0, sw: w, sh: h }; }
    return frame0.call(this, plist, name, quiet);
  };
})();
