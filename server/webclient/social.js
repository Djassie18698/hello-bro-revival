// News and Friends (the Home middle row; C++ on the phone).
//   News    -> CMessageListView (social/MessageListView.ccbi), three tabs with their own rows:
//              Battle  rl_r_msg Cmd 1800 -> FightMsgView  (who attacked you, spar or plunder, won or lost, silver; Ignore = rl_w_msg
//                      Cmd 2901 Op 1 Index <id>, Revenge = a spar against him, rl_w_pvp Cmd 2701 ToUid)
//              Friend  rl_r_msg Cmd 1801 -> FriendMsgView (messages left for you; Reply writes one back, rl_w_msg Cmd 2902 marks it read)
//              System  rl_r_msg Cmd 1802 -> SystemMsgView (the server's announcement)
//   Friends -> CFriendMainView (social/FriendMainView.ccbi) holding FriendListView with a FriendInfoView per player: rl_r_friend
//              (every player of the server, strongest first); the chat button leaves a message: rl_w_friend ToUid Msg.
// Ours for now: a message is typed in the browser's own input box (the phone has its own window, LeaveMessageDialogView), and
// "Add friend" searches the list by name.
'use strict';
(function () {
  const HB = window.HB;
  HB.screens = HB.screens || {};
  const tap = (node, fn) => { if (!node) return; node.onTouch = (ev, tx, ty) => { if (ev === 'down') node._d = [tx, ty]; if (ev === 'up' && node._d && Math.hypot(tx - node._d[0], ty - node._d[1]) < 14) fn(); }; };
  const set = (n, k, t) => { if (n[k]) n[k].setText(String(t)); };
  const obj = (e) => Object.fromEntries([...e.children].map((c) => [c.nodeName, c.textContent]));
  function ago(ts) {
    const s = Math.max(0, Math.floor(Date.now() / 1000) - Number(ts || 0));
    if (s < 60) return 'just now';
    if (s < 3600) return Math.floor(s / 60) + ' min ago';
    if (s < 86400) return Math.floor(s / 3600) + ' h ago';
    return Math.floor(s / 86400) + ' d ago';
  }
  async function send(cgi, params, quiet) {
    const ui = HB.ui;
    if (!quiet) ui.loading(true);
    let r;
    try { r = await HB.api(cgi, params); } catch (e) { ui.loading(false); ui.tip('Cannot reach the server'); return null; }
    ui.loading(false);
    if (r.code) { ui.tip(ui.errorText(r), 2.2); return null; }
    return r;
  }
  function face(m, ninja, star) {
    for (const k of ['node_inlay_frame', 'node_shadow_back', 'node_shadow_front']) if (m[k]) m[k].visible = false;
    const inf = HB.info(1, ninja);
    const frame = HB.qualityFrame('ninjaSmall', Math.max(inf.quality, Math.min(6, Number(star) || 1)));
    if (frame && m.sprite_ninjaicon) m.sprite_ninjaicon.setFrame(frame);
    const pic = HB.iconFrame(1, inf.icon), holder = m.node_icon || m.sprite_ninjaicon;
    if (pic && holder) { const sp = new HB.Sprite(pic); const k = Math.min((holder.w - (m.node_icon ? 0 : 16)) / (pic.sw || 1), (holder.h - (m.node_icon ? 0 : 16)) / (pic.sh || 1)); sp.sx = sp.sy = k; sp.x = holder.w / 2; sp.y = holder.h / 2; sp.z = 1; holder.add(sp); }
  }
  function list(box, size, rows, layout, fill) {
    const scroll = new HB.ScrollView(); scroll.dir = 1; scroll.w = box.w; scroll.h = box.h;
    const col = new HB.Node(); col.w = box.w; col.h = Math.max(1, rows.length) * size.h;
    rows.forEach((r, i) => {
      const co = {};
      const cell = HB.build(layout, co, [size.w, size.h]);
      cell.ignoreAnchor = true; cell.x = (box.w - size.w) / 2; cell.y = col.h - (i + 1) * size.h; cell.w = size.w; cell.h = size.h;
      fill(co.n, r);
      col.add(cell);
    });
    scroll.setContent(col); col.y = scroll.h - col.h;
    box.add(scroll);
  }
  // a message to another player: typed in the browser's own box (ours)
  async function writeTo(uid, nick) {
    const text = (window.prompt('Message to ' + nick + ':', '') || '').trim();
    if (!text) return false;
    if (!(await send('rl_w_friend', { Cmd: 1, ToUid: uid, Msg: text.slice(0, 200) }))) return false;
    HB.ui.tip('Message sent to ' + nick, 1.6);
    return true;
  }

  // ---------------------------------------------------------------- News
  const TABS = [['btn_fight', 'Battle', 1800, 'social/FightMsgView', 'fight_msg_item_content'], ['btn_friend', 'Friend', 1801, 'social/FriendMsgView', 'friend_msg_item_content'], ['btn_system', 'System', 1802, 'social/SystemMsgView', 'system_msg_item_content']];
  HB.screens.news = async function news(tab = 0) {
    const ui = HB.ui, x = ui.x, T = TABS[tab] || TABS[0];
    ui.loading(true);
    let reply;
    try { [reply] = await Promise.all([HB.api('rl_r_msg', { Cmd: T[2], Page: 1 }), HB.data.tables(), HB.loadCCB('social/MessageListView'), ...TABS.map((t) => HB.loadCCB(t[3]))]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const o = {};
    HB.game.showSub('social/MessageListView', o);
    const n = o.n;
    const tabOn = HB.frameByName('com_tab_02'), tabOff = HB.frameByName('com_tab_01');
    TABS.forEach(([name, title], i) => { const b = n[name]; if (b) { if (tabOff) b.frames[1] = i === tab ? tabOn || tabOff : tabOff; b.titles[1] = title; b.layout(); } });
    o.onButton = (sel) => { const i = ['clickFightMsgButton', 'clickFriendMsgButton', 'clickSystemMsgButton'].indexOf(sel); if (i >= 0) return news(i); if (sel === 'clickBack' || sel === 'BtnBack') return HB.game.goHome(); };
    const rows = x.all(reply, 'msg').map(obj).filter((r) => tab !== 2 || String(r.text || '').trim());
    if (n.label_no_message_tip) { n.label_no_message_tip.visible = !rows.length; n.label_no_message_tip.setText('No messages yet'); }
    const size = n[T[4]];
    list(n.node_tablecontent, size, rows, T[3], (m, r) => {
      set(m, 'label_timestamp', ago(r.iTime));
      if (tab === 0) {
        face(m, r.fromninja, r.firstninjastar);
        set(m, 'label_level', r.fromlevel); set(m, 'label_player_name', r.fromnick);
        // result: 0 = the other player won (you lost), 1 = "has been defeated by you" (server/notices.js; until 24 Nov 2026 this was read
        // the wrong way round and every report said the opposite of the phone)
        const plunder = Number(r.subtype) === 1, lost = Number(r.result) === 0;
        set(m, 'label_fight_type', plunder ? 'Plunder' : 'Spar');
        set(m, 'label_pk_msg', plunder ? (lost ? 'plundered you and won' + (Number(r.iTakeRes) ? ': a seal fragment is gone' : '') : 'tried to plunder you and lost') : (lost ? 'sparred with you and won' : 'sparred with you and lost'));
        set(m, 'label_win', lost ? 'You lost' : 'You win');
        // the box behind those words (CFightMsgCellView: the yellow com_bk_frame_24 for a win, the red com_bk_frame_26 for a loss, in node_frame_container)
        { const box = m.node_frame_container, fr = HB.frameByName(lost ? 'com_bk_frame_26' : 'com_bk_frame_24'); if (box && fr) { const bg = new HB.Scale9(fr); bg.ax = bg.ay = 0; bg.w = box.w; bg.h = box.h; box.add(bg); } }
        const coin = Number(r.iCoin) || 0;
        // a spar shows its silver with a sign ("+%d" won, "-%d" lost), also when it is 0; a plunder shows none
        set(m, 'label_coin', (lost ? '-' : '+') + Math.abs(coin)); if (m.sprite_silver_icon) m.sprite_silver_icon.visible = !plunder; if (m.label_coin) m.label_coin.visible = !plunder;
        set(m, 'label_ignore_tip', 'Ignore'); set(m, 'label_FightMsgView0', 'Revenge');
        // the green + writes that player a message (CFightMsgCellView::addFriend opens the invite window: rl_w_friend ToUid Msg)
        if (m.btn_addfriend) tap(m.btn_addfriend, () => writeTo(r.fromuid, r.fromnick));
        tap(m.btn_ignore, async () => { if (await send('rl_w_msg', { Cmd: 2901, Op: 1, Index: r.ID })) news(0); });
        tap(m.btn_revenge, async () => {
          if (!(await HB.confirm('Spar with ' + r.fromnick + ' to take revenge?', { ok: 'Revenge' }))) return;
          const f = await send('rl_w_pvp', { Cmd: 2701, ToUid: r.fromuid });
          if (!f) return;
          await HB.fight.play(f, { kind: 'spar', exp: 0, silver: 0, energy: 0 });
          await HB.game.refresh();
          news(0);
        });
      } else if (tab === 1) {
        face(m, r.fromninja, r.firstninjastar);
        set(m, 'label_level', r.fromlevel); if (m.label_friend_request_type) m.label_friend_request_type.size = 18; set(m, 'label_friend_request_type', 'Friend');
        if (m.label_friend_request) { m.label_friend_request.dims = [Math.max(200, (size.w || 600) - 300), 0]; m.label_friend_request.setText(r.text || ''); }
        const read = Number(r.iStatus) === 1;
        if (m.labelMsgDone) { m.labelMsgDone.visible = read; m.labelMsgDone.setText('[read]'); }
        if (m.btn_handle_friend_msg) {
          const l = new HB.Label('Reply', 'Arial-BoldMT', 24, [0, 0], 1, 1); l.color = [255, 255, 255]; l.stroke = ['#2a1505', 3]; l.x = m.btn_handle_friend_msg.w / 2; l.y = m.btn_handle_friend_msg.h / 2; m.btn_handle_friend_msg.add(l);
          tap(m.btn_handle_friend_msg, async () => { if (!Number(r.fromuid)) return ui.tip('This message cannot be answered', 1.6); await send('rl_w_msg', { Cmd: 2902, Op: 2, Index: r.ID }, true); if (await writeTo(r.fromuid, r.fromnick)) news(1); });
        }
      } else {
        if (m.label_friend_request_type) m.label_friend_request_type.size = 18;
        set(m, 'label_friend_request_type', 'System'); // the red tag is 100 wide: 'System message' hung out of it on both sides
        if (m.label_system_msg) { m.label_system_msg.dims = [Math.max(200, (size.w || 670) - 280), 0]; /* up to the Manage button: it ran under it and out of the row */ m.label_system_msg.setText(r.text || ''); }
        if (m.btn_handle_system_msg) m.btn_handle_system_msg.visible = false; if (m.labelMsgDone) m.labelMsgDone.visible = false;
      }
    });
  };

  // ---------------------------------------------------------------- Friends
  HB.screens.friends = async function friends(find = '') {
    const ui = HB.ui, x = ui.x;
    ui.loading(true);
    let reply;
    try { [reply] = await Promise.all([HB.api('rl_r_friend', { Cmd: 1 }), HB.data.tables(), HB.loadCCB('social/FriendMainView'), HB.loadCCB('social/FriendListView'), HB.loadCCB('social/FriendInfoView')]); } catch (e) { ui.loading(false); return ui.tip('Cannot reach the server'); }
    ui.loading(false);
    if (reply.code) return ui.tip(ui.errorText(reply));
    const o = {};
    HB.game.showSub('social/FriendMainView', o);
    const holder = o.n.node_content, p = {};
    const view = HB.build('social/FriendListView', p, [holder.w, holder.h]);
    view.x = view.ignoreAnchor ? 0 : view.ax * view.w; view.y = view.ignoreAnchor ? 0 : view.ay * view.h;
    holder.add(view);
    const n = p.n;
    set(n, 'label_FriendListView0', find ? 'Players named "' + find + '"' : 'Players');
    if (n.btn_more_friends) n.btn_more_friends.setTitle(find ? 'Show everyone' : 'Refresh');
    if (n.btn_make_friend) n.btn_make_friend.setTitle('Search');
    o.onButton = (sel) => { if (sel === 'clickBack' || sel === 'BtnBack') return HB.game.goHome(); };
    p.onButton = (sel) => {
      if (sel === 'clickMoreFriends') return friends('');
      if (sel === 'clickMakeFriend') { const name = (window.prompt('Find a player by name:', find) || '').trim(); return friends(name); }
    };
    const rows = x.all(reply, 'user').map(obj).filter((r) => !find || String(r.nick).toLowerCase().includes(find.toLowerCase()));
    if (!rows.length) ui.tip(find ? 'No player with that name' : 'No other players yet', 1.8);
    list(n.node_tablecontent, n.node_cardcontent, rows, 'social/FriendInfoView', (m, r) => {
      face(m, r.firstninja, r.firstninjastar);
      set(m, 'label_player_name', r.nick); set(m, 'label_level', r.level);
      if (m.label_level) { m.label_level.color = [255, 255, 255]; m.label_level.stroke = ['#2a1505', 3]; } // it was dark brown on the dark card picture
      set(m, 'label_attack', r.attacklow + '-' + r.attackhigh); set(m, 'label_defense', r.defenselow + '-' + r.defenseHigh); set(m, 'label_chakara', '-');
      tap(m.btn_chat, () => writeTo(r.id, r.nick));
    });
  };
})();
