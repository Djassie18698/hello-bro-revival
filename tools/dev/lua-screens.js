// Opens the game's own Lua screens in the rewritten game (server/webclient) one after another in headless Chrome and reports, per
// screen, the Lua errors and the C++ names the script asked for that are not there yet; saves a picture of each in re/lua/.
//   node tools/dev/lua-screens.js [filter] [--device=<guest>] [--press = also press every button of each screen]     (dev server on :18081 must run: bash tools/dev/restart.sh)
// A screen = act:<script> (the Event screen runs that script), sub:<function> (the empty sub menu calls that helper function),
// run:<script> (just runs it), js:<expression>.
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const PRESS = process.argv.includes('--press'), TAP = process.argv.includes('--tap');
const args = process.argv.slice(2), filter = args.find((a) => !a.startsWith('--')) || '', device = (args.find((a) => a.startsWith('--device=')) || '--device=hdt1').slice(9);
const SCREENS = [
  'act:loginPackActivity', 'act:upradePackActivity', 'act:monthCardActivity', 'act:lotteryActivity', 'act:payhistorydrop', 'act:collectCardActivity', 'act:ScratchCardActivity',
  'act:business_proxy/firstMoneyAward', 'act:business_proxy/levelRank_business', 'act:business_proxy/fightRank_business', 'act:business_proxy/accumulateMoney_business', 'act:fightBossView',
  'act:business_proxy/limitedGroupBuy_business', 'act:keepLoginView', 'act:business_proxy/nvshen_business', 'act:boxOpenActivityView', 'act:business_proxy/growthfund_b',
  'act:business_proxy/lotteryTicket_business', 'act:business_proxy/dailyPay_business', 'act:business_proxy/keepPay_business', 'act:business_proxy/limitDiscount_business',
  'act:business_proxy/dailyRestriction_business', 'act:business_proxy/randPay_business', 'act:business_proxy/diligenceGift_business', 'act:business_proxy/consumption_business',
  'act:business_proxy/monthSign_business', 'act:business_proxy/hotTreasure_business', 'act:business_proxy/festival_business', 'act:business_proxy/godRecruit_business', 'act:business_proxy/sevenDay_business',
  'sub:ShowMoraView', 'sub:ShowRouletteView', 'sub:ShowMonopolyView', 'sub:ShowBorderWarView', 'sub:ShowSecretShopView', 'sub:ShowTrainSoulView', 'sub:ShowColorSuitView', 'sub:ShowLevelSuitView',
  'sub:ShowMultiBattleView', 'sub:ShowHallOfFame', 'sub:ShowSuperNinjaView', 'sub:ShowGrowthFundView', 'sub:ShowAttributeDanView', 'sub:ShowGodCardSyntheticView', 'sub:ShowNinjaTreasureView',
  'sub:ShowNinjaInheritView', 'sub:ShowLimitTrainView', 'sub:ShowOrgListLayer', 'sub:ShowAdvanceEquipView', 'sub:ShowSlotMachine', 'sub:doShowBase',
  'run:business_proxy/dailyTask_business', 'run:business_proxy/saveTime_business', 'run:business_proxy/purchase_business',
  'sub:ShowOrgMapLayer', 'sub:ShowOrgMainView', 'sub:ShowOrgRankings', 'sub:ShowOrgHall', 'sub:ShowOrgDonate', 'sub:ShowOrgShop', 'sub:ShowCrossRouletteView', 'sub:ShowCrossMonopolyView', 'sub:ShowCrossSuperNinjaView', 'sub:ShowLimitTrainSoulView',
  "js:HB.game.changeToActivitySubMenu('doShowBase').then(() => HB.luaCall(HB.L.load('local v = createObj(ui_petMainLayer, nil) AddViewToActivitySubMenu(v.node_)')))",
  "js:HB.game.changeToActivitySubMenu('doShowBase').then(() => HB.luaCall(HB.L.load('local v = createObj(ui_ninjaTestMain, nil) AddViewToActivitySubMenu(v.node_)')))",
  "js:HB.game.changeToActivitySubMenu('doShowBase').then(() => HB.luaCall(HB.L.load('local v = createObj(ui_tupoLayer, nil) AddViewToActivitySubMenu(v.node_)')))",
  "js:HB.game.luaHomeButton('BtnAwardCenter')", "js:HB.game.luaHomeButton('BtnOrg')", "js:HB.luaCall(HB.L.load('createStageGiftLayer()'))",
].filter((s) => s.includes(filter));
const CHROME = ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find((p) => fs.existsSync(p));
const port = 9300 + Math.floor(Math.random() * 500), dir = fs.mkdtempSync(path.join(os.tmpdir(), 'luascr-'));
const ch = spawn(CHROME, ['--headless=new', '--mute-audio', `--remote-debugging-port=${port}`, `--user-data-dir=${dir}`, '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  let targets = [];
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await wait(200); }
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r));
  let id = 0; const pending = new Map(); let errs = [];
  ws.addEventListener('message', (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
    if (m.method === 'Runtime.exceptionThrown') errs.push('PAGE ERROR ' + ((m.params.exceptionDetails.exception || {}).description || m.params.exceptionDetails.text || '').slice(0, 400));
    if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') errs.push(m.params.args.map((x) => x.value ?? x.description).join(' ').slice(0, 500));
  });
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const ev = async (expression) => { const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }); return r.result && r.result.result ? r.result.result.value : undefined; };
  await send('Emulation.setDeviceMetricsOverride', { width: 760, height: 1350, deviceScaleFactor: 1, mobile: false });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Page.navigate', { url: `http://127.0.0.1:18081/play/?auto=1&device=${device}&stage=0&preload=0` });
  await wait(14000);
  fs.mkdirSync('re/lua', { recursive: true });
  const report = [];
  const missingNow = async () => JSON.parse((await ev('JSON.stringify(HB.luaMissing ? (HB.luaMissing instanceof Set || Array.isArray(HB.luaMissing) ? [...HB.luaMissing] : Object.keys(HB.luaMissing)) : [])')) || '[]');
  for (const s of SCREENS) {
    const kind = s.slice(0, 3), what = s.slice(s.indexOf(':') + 1);
    errs = [];
    const before = new Set(await missingNow());
    const js = kind === 'act' ? `HB.game.changeToActivity(${JSON.stringify(what)})` : kind === 'sub' ? `HB.game.changeToActivitySubMenu(${JSON.stringify(what)})` : kind === 'run' ? `HB.luaRun(${JSON.stringify(what + '.lua')})` : what;
    await ev(`(async () => { try { await ${js}; } catch (e) { console.error('JS ' + (e && e.stack || e)); } })()`);
    await wait(Number(process.env.LS_WAIT) || 2600);
    const missing = (await missingNow()).filter((m) => !before.has(m));
    const file = 're/lua/' + what.replace(/[^A-Za-z0-9_]+/g, '_').slice(-48) + '.png';
    const shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(file, Buffer.from(shot.result.data, 'base64'));
    const uniq = [...new Set(errs)];
    report.push({ s, errors: uniq, missing, file });
    console.log((uniq.length ? 'ERR ' : missing.length ? 'mis ' : 'ok  ') + s + (uniq.length ? '\n      ' + uniq.slice(0, 3).join('\n      ') : '') + (missing.length ? '\n      missing: ' + missing.join(', ') : ''));
    const home = async () => { await ev('(async () => { try { HB.scene.children.filter((c) => c.z >= 500).forEach((c) => { HB.luaLeave && HB.luaLeave(c); c.removeSelf(); }); HB.loading(false); await HB.game.goHome(); } catch (e) {} })()'); await wait(700); };
    // --press: every button of the screen, one press each on a freshly opened screen (a press may leave the screen)
    if (PRESS && !uniq.length) {
      const LIST = `(() => { const out = []; const walk = (n) => { if (!n.visible) return; if (n instanceof HB.Button && n.enabled !== false) out.push(n); (n.children || []).forEach(walk); }; walk(HB.game.subContent); HB.scene.children.filter((c) => c.z >= 500).forEach(walk); return out; })()`;
      const names = JSON.parse((await ev(`JSON.stringify(${LIST}.map((b) => b.name || b.selector || (b.titles && b.titles[1]) || '?'))`)) || '[]');
      const bad = [];
      for (let i = 0; i < names.length && i < 24; i++) {
        await home();
        await ev(`(async () => { try { await ${js}; } catch (e) {} })()`);
        await wait(1700);
        errs = [];
        const b4 = new Set(await missingNow());
        await ev(`(() => { try { const b = ${LIST}[${i}]; if (b) HB.tapNode(b); } catch (e) { console.error('JS ' + (e && e.stack || e)); } })()`);
        await wait(1300);
        const mis = (await missingNow()).filter((m) => !b4.has(m)), er = [...new Set(errs)];
        if (er.length || mis.length) { bad.push({ button: names[i], errors: er, missing: mis }); console.log('      press ' + names[i] + ': ' + er.slice(0, 2).join(' | ').slice(0, 300) + (mis.length ? ' missing: ' + mis.join(', ') : '')); }
      }
      report[report.length - 1].buttons = names; report[report.length - 1].pressFailed = bad;
      console.log('      ' + names.length + ' buttons, ' + bad.length + ' with a problem');
    }
    // --tap: real taps (mouse events at the place on the page) on the button-like parts of the first rows of every list of the screen:
    // list rows get their taps through the table view (cellTouchBegan / cellTouched with the touch point), not through a button
    if (TAP && !uniq.length) {
      const SPOTS = `(() => { const out = []; const r = HB.canvas ? HB.canvas.getBoundingClientRect() : document.querySelector('canvas').getBoundingClientRect();
        const seen = (t) => { for (const cell of (t.cells || []).slice(0, 2)) { const walk = (n) => { if (!n.visible) return;
          if (n !== cell && n.name && /^(node_btn|sprite_btn|btn_|ctrl_|spr_btn|sprite_get|btn)/i.test(n.name) && n.w > 20 && n.h > 20 && n.shown()) { const m = n.world(); const cx = m[4] + m[0] * n.w / 2, cy = m[5] + m[3] * n.h / 2;
            if (cx > 0 && cy > 0 && cx < HB.size[0] && cy < HB.size[1]) out.push({ name: n.name, x: r.left + cx / HB.size[0] * r.width, y: r.top + (1 - cy / HB.size[1]) * r.height }); }
          (n.children || []).forEach(walk); }; walk(cell); } };
        const find = (n) => { if (!n.visible) return; if (n.cells && n.ask) seen(n); (n.children || []).forEach(find); };
        find(HB.game.subContent); HB.scene.children.filter((c) => c.z >= 500).forEach(find); return out.slice(0, 8); })()`;
      const spots = JSON.parse((await ev(`JSON.stringify(${SPOTS})`)) || '[]');
      const bad = [];
      for (let i = 0; i < spots.length; i++) {
        await home();
        await ev(`(async () => { try { await ${js}; } catch (e) {} })()`);
        await wait(1900);
        const now = JSON.parse((await ev(`JSON.stringify(${SPOTS})`)) || '[]')[i];
        if (!now) continue;
        errs = [];
        const b4 = new Set(await missingNow());
        await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: now.x, y: now.y, button: 'left', clickCount: 1 });
        await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: now.x, y: now.y, button: 'left', clickCount: 1 });
        await wait(1500);
        const mis = (await missingNow()).filter((m) => !b4.has(m)), er = [...new Set(errs)];
        if (er.length || mis.length) { bad.push({ spot: now.name, errors: er, missing: mis }); console.log('      tap ' + now.name + ': ' + er.slice(0, 2).join(' | ').slice(0, 300) + (mis.length ? ' missing: ' + mis.join(', ') : '')); }
      }
      report[report.length - 1].taps = spots.map((x) => x.name); report[report.length - 1].tapFailed = bad;
      console.log('      ' + spots.length + ' list taps, ' + bad.length + ' with a problem');
    }
    // back to Home, closing what the screen left open over it
    await home();
  }
  fs.writeFileSync('re/lua/report.json', JSON.stringify(report, null, 1));
  console.log('C++ names asked for and not there: ' + ((await missingNow()).join(', ') || 'none'));
  console.log(report.filter((r) => !r.errors.length).length + ' of ' + report.length + ' open without an error');
  ws.close(); ch.kill();
  setTimeout(() => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} process.exit(0); }, 500);
})().catch((e) => { console.error(e); ch.kill(); process.exit(1); });
