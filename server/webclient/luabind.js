// The bridge between the game's own Lua scripts (run by lua.js) and the web client (engine.js): it gives the scripts the names
// the phone's C++ gave them (tolua++ bindings in libgame.so): cocos2d-x 2 classes (CCSprite, CCLabelTTF, CCControlButton,
// CCTableView, actions, CCSpriteFrameCache ...), the game's helpers (CCBProxy, LuaTableView, LuaEventHandler, CPlayerDataMgr,
// CGameObjElement, CNetUser, CServerListMgr, CSoundMgr, GetMainMenu ...), CCHttpRequest (the server) and the LuaXML library.
// The list of what the scripts use was made with the Lua parser (172 globals, 851 method names): see server/webclient/README.md.
// Anything not done yet answers with a "missing" stand-in that logs its name once (HB.luaMissing), so a screen still opens.
'use strict';
(function () {
  const HB = window.HB, Lua = window.Lua;
  const { LuaTable, toBytes: B, fromBytes: S, call, first } = Lua;
  const R = Lua.R;
  const T = (v) => v !== undefined && v !== false && v !== null;
  const num = (v, d = 0) => (typeof v === 'number' ? v : v === undefined || v === null ? d : Number(v) || d);
  const txt = (v) => (v === undefined || v === null ? '' : typeof v === 'string' ? S(v) : typeof v === 'number' ? Lua.numToStr(v) : S(R.tostring(v)));

  // ---------------------------------------------------------------- binding helpers
  // a JavaScript class becomes a Lua userdata: obj:method(...) looks in the class's method table (and its parents'); fields set
  // from Lua go into a per-object "peer" table (like tolua++), which is looked at first
  const METHODS = new Map(); // constructor -> { luaName: fn(self, ...args) -> value | array }
  const methods = (cls, fns) => { METHODS.set(cls, Object.assign(METHODS.get(cls) || {}, fns)); };
  function lookupMethod(obj, k) {
    for (let c = obj.constructor; c && c !== Object; c = Object.getPrototypeOf(c)) {
      const m = METHODS.get(c);
      if (m && Object.prototype.hasOwnProperty.call(m, k)) return m[k];
    }
    return undefined;
  }
  const wrapped = new Map(); // method fn -> Lua function (results always as an array)
  const asLua = (fn) => {
    let w = wrapped.get(fn);
    if (!w) { w = (...a) => { const r = fn(...a); return Array.isArray(r) ? r : r === undefined ? Lua.R.EMPTY : [r]; }; wrapped.set(fn, w); }
    return w;
  };
  function luaGet(k) {
    if (this.__peer) { const v = this.__peer.get(k); if (v !== undefined) return v; }
    const key = typeof k === 'string' ? S(k) : k;
    if (this.__fields && Object.prototype.hasOwnProperty.call(this.__fields, key)) return this.__fields[key].call(this);
    const m = lookupMethod(this, key);
    if (m) return asLua(m);
    return undefined;
  }
  function luaSet(k, v) {
    const key = typeof k === 'string' ? S(k) : k;
    if (this.__setters && Object.prototype.hasOwnProperty.call(this.__setters, key)) return this.__setters[key].call(this, v);
    (this.__peer || (this.__peer = new LuaTable())).set(k, v);
  }
  const userdata = (cls) => { cls.prototype.luaGet = luaGet; cls.prototype.luaSet = luaSet; };
  // fields of a struct-like userdata: obj.x, obj.width ... (get + set)
  const fields = (cls, names) => {
    const g = {}, st = {};
    for (const n of names) { g[n] = function () { return typeof this[n] === 'string' ? B(this[n]) : this[n]; }; st[n] = function (v) { this[n] = typeof v === 'string' ? S(v) : v; }; }
    cls.prototype.__fields = Object.assign({}, cls.prototype.__fields || {}, g);
    cls.prototype.__setters = Object.assign({}, cls.prototype.__setters || {}, st);
  };
  // a Lua class table (CCSprite, CPlayerDataMgr ...): CCSprite:create(...) calls fns.create(...) without the table itself
  const G = () => HB.L.G;
  function luaClass(name, fns, callable) {
    const t = new LuaTable();
    for (const [k, f] of Object.entries(fns || {})) t.set(B(k), (self, ...a) => { const r = f(...a); return Array.isArray(r) ? r : r === undefined ? Lua.R.EMPTY : [r]; });
    if (callable) { const mt = new LuaTable(); mt.set('__call', (self, ...a) => [callable(...a)]); t.mt = mt; }
    G().set(B(name), t);
    return t;
  }
  const gfn = (name, f) => G().set(B(name), (...a) => { const r = f(...a); return Array.isArray(r) ? r : r === undefined ? Lua.R.EMPTY : [r]; });
  const gval = (name, v) => G().set(B(name), typeof v === 'string' ? B(v) : v);

  // ---------------------------------------------------------------- value types: points, sizes, rects, colours
  class CCPoint { constructor(x = 0, y = 0) { this.x = num(x); this.y = num(y); } }
  class CCSize { constructor(w = 0, h = 0) { this.width = num(w); this.height = num(h); } }
  class CCRect { constructor(x = 0, y = 0, w = 0, h = 0) { this.origin = new CCPoint(x, y); this.size = new CCSize(w, h); } }
  class ccColor3B { constructor(r = 255, g = 255, b = 255) { this.r = num(r); this.g = num(g); this.b = num(b); } }
  class ccColor4B extends ccColor3B { constructor(r, g, b, a = 255) { super(r, g, b); this.a = num(a); } }
  for (const c of [CCPoint, CCSize, CCRect, ccColor3B, ccColor4B]) userdata(c);
  fields(CCPoint, ['x', 'y']); fields(CCSize, ['width', 'height']); fields(CCRect, ['origin', 'size']); fields(ccColor3B, ['r', 'g', 'b']); fields(ccColor4B, ['a']);
  methods(CCPoint, { equals: (p, q) => p.x === q.x && p.y === q.y });
  methods(CCSize, { equals: (a, b) => a.width === b.width && a.height === b.height });
  methods(CCRect, {
    containsPoint: (r, p) => p.x >= r.origin.x && p.x <= r.origin.x + r.size.width && p.y >= r.origin.y && p.y <= r.origin.y + r.size.height,
    intersectsRect: (a, b) => !(a.origin.x + a.size.width < b.origin.x || b.origin.x + b.size.width < a.origin.x || a.origin.y + a.size.height < b.origin.y || b.origin.y + b.size.height < a.origin.y),
    getMinX: (r) => r.origin.x, getMaxX: (r) => r.origin.x + r.size.width, getMidX: (r) => r.origin.x + r.size.width / 2,
    getMinY: (r) => r.origin.y, getMaxY: (r) => r.origin.y + r.size.height, getMidY: (r) => r.origin.y + r.size.height / 2,
  });
  const P = (p) => (p instanceof CCPoint ? p : p instanceof LuaTable ? new CCPoint(p.get('x'), p.get('y')) : new CCPoint());
  const SZ = (s) => (s instanceof CCSize ? s : s instanceof LuaTable ? new CCSize(s.get('width'), s.get('height')) : new CCSize());
  const COL = (c) => (c instanceof ccColor3B ? [c.r, c.g, c.b] : c instanceof LuaTable ? [num(c.get('r')), num(c.get('g')), num(c.get('b'))] : [255, 255, 255]);
  HB.lua = { CCPoint, CCSize, CCRect, ccColor3B, P, SZ, COL, methods, userdata, fields, luaClass, gfn, gval, txt, B, S };

  // ---------------------------------------------------------------- nodes (CCNode and everything drawn)
  const N = HB.Node;
  userdata(N);
  const childByTag = (n, tag) => n.children.find((c) => c.tag === tag);
  const boundingBox = (n) => { // in the parent's space, like CCNode::boundingBox
    const m = n.local();
    const pts = [[0, 0], [n.w, 0], [0, n.h], [n.w, n.h]].map(([x, y]) => HB.M.apply(m, x, y));
    const xs = pts.map((q) => q[0]), ys = pts.map((q) => q[1]);
    return new CCRect(Math.min(...xs), Math.min(...ys), Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys));
  };
  const scheduled = new Set(); // nodes with a Lua update function
  HB.luaScheduled = scheduled;
  methods(N, {
    addChild: (n, c, z, tag) => { if (!c) return; n.add(c, z === undefined ? c.z || 0 : num(z)); if (tag !== undefined) c.tag = num(tag); enter(c); },
    removeChild: (n, c) => { if (c && c.parent === n) { n.remove(c); leave(c); } },
    removeFromParentAndCleanup: (n) => { if (n.parent) { n.removeSelf(); leave(n); } },
    removeFromParent: (n) => { if (n.parent) { n.removeSelf(); leave(n); } },
    removeAllChildrenWithCleanup: (n) => { const k = n.children.slice(); n.removeAll(); k.forEach(leave); },
    removeAllChildren: (n) => { const k = n.children.slice(); n.removeAll(); k.forEach(leave); },
    removeChildByTag: (n, tag) => { const c = childByTag(n, num(tag)); if (c) { n.remove(c); leave(c); } },
    getChildByTag: (n, tag) => childByTag(n, num(tag)),
    getChildren: (n) => new CCArray(n.children.slice()),
    getChildrenCount: (n) => n.children.length,
    getParent: (n) => n.parent || undefined,
    setPosition: (n, a, b) => { if (a instanceof CCPoint || a instanceof LuaTable) { const p = P(a); n.x = p.x; n.y = p.y; } else { n.x = num(a); n.y = num(b); } },
    getPosition: (n) => new CCPoint(n.x, n.y), // tolua returns a point
    getPositionX: (n) => n.x, getPositionY: (n) => n.y,
    setPositionX: (n, x) => { n.x = num(x); }, setPositionY: (n, y) => { n.y = num(y); },
    setAnchorPoint: (n, p) => { p = P(p); n.ax = p.x; n.ay = p.y; },
    getAnchorPoint: (n) => new CCPoint(n.ax, n.ay),
    setContentSize: (n, s) => { s = SZ(s); n.setSize(s.width, s.height); if (n.onResize) n.onResize(); },
    getContentSize: (n) => new CCSize(n.w, n.h),
    setScale: (n, s) => { n.sx = n.sy = num(s, 1); }, setScaleX: (n, s) => { n.sx = num(s, 1); }, setScaleY: (n, s) => { n.sy = num(s, 1); },
    getScale: (n) => n.sx, getScaleX: (n) => n.sx, getScaleY: (n) => n.sy,
    setRotation: (n, r) => { n.rot = num(r); }, getRotation: (n) => n.rot,
    setVisible: (n, v) => { n.visible = T(v); }, isVisible: (n) => n.visible,
    setTag: (n, t) => { n.tag = num(t); }, getTag: (n) => n.tag,
    setZOrder: (n, z) => { n.z = num(z); }, getZOrder: (n) => n.z,
    reorderChild: (n, c, z) => { if (c) c.z = num(z); },
    boundingBox: (n) => boundingBox(n),
    convertToNodeSpace: (n, p) => { p = P(p); const [x, y] = n.toLocal(p.x, p.y); return new CCPoint(x, y); },
    convertToNodeSpaceAR: (n, p) => { p = P(p); const [x, y] = n.toLocal(p.x, p.y); return new CCPoint(x - n.ax * n.w, y - n.ay * n.h); },
    convertToWorldSpace: (n, p) => { p = P(p); const [x, y] = HB.M.apply(n.world(), p.x, p.y); return new CCPoint(x, y); },
    convertToWorldSpaceAR: (n, p) => { p = P(p); const [x, y] = HB.M.apply(n.world(), p.x + n.ax * n.w, p.y + n.ay * n.h); return new CCPoint(x, y); },
    convertTouchToNodeSpace: (n, t) => { const [x, y] = n.toLocal(t.x, t.y); return new CCPoint(x, y); },
    runAction: (n, a) => { if (a) HB.runAction(n, a); return a; },
    stopAllActions: (n) => HB.stopActions(n), stopAction: (n, a) => HB.stopActions(n, a),
    stopActionByTag: (n, tag) => HB.stopActions(n, null, num(tag)),
    getActionByTag: (n, tag) => HB.actionByTag(n, num(tag)),
    numberOfRunningActions: (n) => HB.actionCount(n),
    setColor: (n, c) => { n.color = COL(c); if (n.layout) n.layout(); }, getColor: (n) => new ccColor3B(...n.color),
    setOpacity: (n, o) => { n.opacity = num(o, 255); }, getOpacity: (n) => n.opacity,
    setCascadeOpacityEnabled: (n, on) => { n.cascade = T(on); }, setCascadeColorEnabled: () => {},
    ignoreAnchorPointForPosition: (n, on) => { n.ignoreAnchor = T(on); }, isIgnoreAnchorPointForPosition: (n) => n.ignoreAnchor,
    retain: () => {}, release: () => {}, autorelease: (n) => n, retainCount: () => 1,
    scheduleUpdateWithPriorityLua: (n, fn) => { n.luaUpdate = fn; scheduled.add(n); },
    unscheduleUpdate: (n) => { n.luaUpdate = null; scheduled.delete(n); },
    scheduleUpdate: () => {},
    registerScriptHandler: (n, fn) => { n.luaNodeEvent = fn; if (n.inScene) call(fn, B('enter')); },
    unregisterScriptHandler: (n) => { n.luaNodeEvent = null; },
    setTouchEnabled: (n, on) => { n.touchOn = T(on); }, isTouchEnabled: (n) => !!n.touchOn,
    setTouchPriority: (n, p) => { n.touchPriority = num(p); }, getTouchPriority: (n) => n.touchPriority || 0,
    setTouchMode: (n, m) => { n.touchMode = num(m); },
    registerScriptTouchHandler: (n, fn, multi, prio, swallow) => { n.luaTouch = { fn, multi: T(multi), prio: num(prio), swallow: T(swallow) }; HB.luaTouchLayers.add(n); },
    unregisterScriptTouchHandler: (n) => { n.luaTouch = null; HB.luaTouchLayers.delete(n); },
    setKeypadEnabled: () => {}, registerScriptKeypadHandler: () => {}, setAccelerometerEnabled: () => {},
    setShaderProgram: (n, prog) => { n.grey = !!(prog && prog.grey); }, getShaderProgram: (n) => (n.grey ? GREY : NORMAL),
    isRunning: (n) => !!n.inScene,
    setSkewX: () => {}, setSkewY: () => {}, setVertexZ: () => {}, setGrid: () => {}, getCamera: () => undefined,
    getScheduler: () => SCHEDULER, getActionManager: () => undefined,
    setUserObject: (n, o) => { n.userObject = o; }, getUserObject: (n) => n.userObject,
    setUserData: (n, d) => { n.userData = d; }, getUserData: (n) => n.userData,
    isNodeRunning: (n) => !!n.inScene,
    getContentSizeInPixels: (n) => new CCSize(n.w, n.h),
  });
  // onEnter / onExit for nodes with registerScriptHandler (cocos sends "enter" when a node joins the running scene)
  function enter(n) {
    if (!n || !inScene(n.parent)) return;
    const walk = (x) => { if (!x.inScene) { x.inScene = true; if (x.luaNodeEvent) safe(x.luaNodeEvent, B('enter')); } x.children.forEach(walk); };
    walk(n);
  }
  function leave(n) {
    const walk = (x) => { if (x.inScene) { x.inScene = false; if (x.luaNodeEvent) safe(x.luaNodeEvent, B('exit')); if (x.luaNodeEvent) safe(x.luaNodeEvent, B('cleanup')); } HB.stopActions(x); scheduled.delete(x); HB.luaTouchLayers.delete(x); x.children.forEach(walk); };
    walk(n);
  }
  const inScene = (n) => { for (let x = n; x; x = x.parent) if (x === HB.scene) return true; return false; };
  HB.luaEnter = enter; HB.luaLeave = leave;
  // a Lua function called from JavaScript: errors go to the console with the script line, the game goes on
  function safe(fn, ...a) {
    try { return call(fn, ...a); } catch (e) { HB.luaError(e); return Lua.R.EMPTY; }
  }
  HB.luaCall = safe;
  HB.luaError = (e) => {
    const msg = e instanceof Lua.LuaError ? S(String(e.value)) : (e && e.stack) || String(e);
    console.error('LUA ERROR: ' + msg);
    (HB.luaErrors = HB.luaErrors || []).push(msg);
  };

  methods(HB.Sprite, {
    setDisplayFrame: (s, f) => { if (f) s.setFrame(f instanceof SpriteFrame ? f.frame : f); },
    displayFrame: (s) => (s.frame ? new SpriteFrame(s.frame) : undefined),
    setDisplayFrameWithAnimationName: () => {},
    setFlipX: (s, on) => { s.flipX = T(on); }, setFlipY: (s, on) => { s.flipY = T(on); }, isFlipX: (s) => s.flipX, isFlipY: (s) => s.flipY,
    getTexture: (s) => new Texture(s.frame ? s.frame.img : null), setTexture: (s, t) => { if (t && t.img) s.setFrame(HB.frameOfImage(t.path)); },
    setTextureRect: (s, r) => { if (s.frame && r) { s.frame = Object.assign({}, s.frame, { x: s.frame.x + r.origin.x, y: s.frame.y + r.origin.y, w: r.size.width, h: r.size.height, sw: r.size.width, sh: r.size.height, ox: 0, oy: 0 }); s.w = r.size.width; s.h = r.size.height; } },
    getTextureRect: (s) => new CCRect(0, 0, s.w, s.h),
    setBlendFunc: (s, src, dst) => { s.blend = num(dst) === 1 ? 'lighter' : ''; },
  });
  class SpriteFrame { constructor(frame) { this.frame = frame; } }
  class Texture { constructor(img, path) { this.img = img; this.path = path; } }
  userdata(SpriteFrame); userdata(Texture);
  HB.lua.SpriteFrame = SpriteFrame;
  methods(SpriteFrame, { getRect: (f) => new CCRect(f.frame.x, f.frame.y, f.frame.w, f.frame.h), getOriginalSize: (f) => new CCSize(f.frame.sw, f.frame.sh), retain: () => {}, release: () => {} });
  methods(Texture, { getContentSize: (t) => new CCSize(t.img ? t.img.naturalWidth : 0, t.img ? t.img.naturalHeight : 0), retain: () => {}, release: () => {} });
  const frameOf = (name) => { const f = HB.frameByName(txt(name)); return f ? new SpriteFrame(f) : undefined; };
  const newSprite = (f) => { const s = new HB.Sprite(f || null); return s; };

  methods(HB.Label, {
    setString: (l, s) => { l.setText(txt(s)); }, getString: (l) => B(l.text),
    setFontSize: (l, s) => { l.size = num(s); l.setText(l.text); }, getFontSize: (l) => l.size,
    setFontName: (l, f) => { l.font = txt(f); l.setText(l.text); }, getFontName: (l) => B(l.font),
    setDimensions: (l, s) => { s = SZ(s); l.dims = [s.width, s.height]; l.setText(l.text); }, getDimensions: (l) => new CCSize(l.dims[0], l.dims[1]),
    setHorizontalAlignment: (l, a) => { l.ha = num(a); }, setVerticalAlignment: (l, a) => { l.va = num(a); },
    enableStroke: (l, c, w) => { const k = COL(c); l.stroke = [`rgb(${k[0]},${k[1]},${k[2]})`, num(w, 1)]; }, disableStroke: (l) => { l.stroke = null; },
    enableShadow: (l) => { l.shadow = 'rgba(0,0,0,0.6)'; }, disableShadow: (l) => { l.shadow = null; },
    setFontFillColor: (l, c) => { l.color = COL(c); },
  });
  methods(HB.BMLabel, {
    setString: (l, s) => { l.setText(txt(s)); }, getString: (l) => B(l.text),
    setFntFile: (l, f) => { l.fnt = txt(f); HB.loadFntNow(l.fnt); l.setText(l.text); },
    setAlignment: (l, a) => { l.align = num(a); }, setWidth: () => {}, setLineBreakWithoutSpace: () => {},
  });
  methods(HB.Scale9, {
    setPreferredSize: (s, a, b) => { const z = a instanceof CCSize || a instanceof LuaTable ? SZ(a) : new CCSize(a, b); s.w = z.width; s.h = z.height; },
    getPreferredSize: (s) => new CCSize(s.w, s.h),
    setSpriteFrame: (s, f) => { if (f) s.frame = f.frame; },
    setCapInsets: (s, r) => { if (r) s.insets = [r.origin.x, r.origin.y, s.frame ? s.frame.w - r.origin.x - r.size.width : 0, s.frame ? s.frame.h - r.origin.y - r.size.height : 0]; },
    setInsetLeft: (s, v) => { s.insets[0] = num(v); }, setInsetTop: (s, v) => { s.insets[1] = num(v); }, setInsetRight: (s, v) => { s.insets[2] = num(v); }, setInsetBottom: (s, v) => { s.insets[3] = num(v); },
    getOriginalSize: (s) => new CCSize(s.frame ? s.frame.w : 0, s.frame ? s.frame.h : 0),
  });
  // CCControlButton: Lua handlers per control event (addHandleOfControlEvent / tolua's registerControlEventHandler)
  const EV = { TouchDown: 1, TouchDragInside: 2, TouchDragOutside: 4, TouchDragEnter: 8, TouchDragExit: 16, TouchUpInside: 32, TouchUpOutside: 64, TouchCancel: 128, ValueChanged: 256 };
  const STATE = { Normal: 1, Highlighted: 2, Disabled: 4, Selected: 8 };
  const stateIdx = (st) => ({ 1: 1, 2: 2, 4: 3, 8: 2 }[num(st, 1)] || 1);
  methods(HB.Button, {
    addHandleOfControlEvent: (b, fn, ev) => { (b.luaHandlers = b.luaHandlers || []).push({ fn, ev: num(ev, EV.TouchUpInside) }); },
    registerControlEventHandler: (b, fn, ev) => { (b.luaHandlers = b.luaHandlers || []).push({ fn, ev: num(ev, EV.TouchUpInside) }); },
    removeHandleOfControlEvent: (b, ev) => { b.luaHandlers = (b.luaHandlers || []).filter((h) => h.ev !== num(ev)); },
    setTitleForState: (b, t, st) => { b.titles[stateIdx(st)] = txt(t); b.layout(); }, getTitleForState: (b, st) => B(b.titles[stateIdx(st)] ?? b.titles[1] ?? ''),
    setTitleColorForState: (b, c, st) => { b.titleColors[stateIdx(st)] = COL(c); b.layout(); },
    setTitleTTFForState: (b, f) => { b.titleFont = txt(f); b.layout(); }, setTitleTTFSizeForState: (b, s) => { b.titleSize = num(s); b.layout(); },
    setBackgroundSpriteForState: (b, sp, st) => { if (sp) { b.frames[stateIdx(st)] = sp.frame; if (sp.insets) b.insets = sp.insets; if (stateIdx(st) === 1 && sp.rot) b.bg.rot = sp.rot; b.layout(); } },
    setBackgroundSpriteFrameForState: (b, f, st) => { if (f) { b.frames[stateIdx(st)] = f.frame; b.layout(); } },
    setPreferredSize: (b, a, c) => { const z = a instanceof CCSize || a instanceof LuaTable ? SZ(a) : new CCSize(a, c); b.pref = [z.width, z.height]; b.layout(); },
    getPreferredSize: (b) => new CCSize(b.pref[0], b.pref[1]),
    setEnabled: (b, on) => b.setEnabled(T(on)), isEnabled: (b) => b.enabled,
    setSelected: (b, on) => { b.selected = T(on); b.layout(); }, isSelected: (b) => !!b.selected,
    setHighlighted: (b, on) => { b.pressed = T(on); b.layout(); }, isHighlighted: (b) => !!b.pressed,
    setZoomOnTouchDown: (b, on) => { b.zoom = T(on); }, setLabelAnchorPoint: (b, p) => { p = P(p); b.labelAnchor = [p.x, p.y]; b.layout(); },
    setAdjustBackgroundImage: () => {}, needsLayout: (b) => b.layout(),
    getTitleLabel: (b) => b.label, getBackgroundSprite: (b) => b.bg,
    setMargins: () => {}, sendActionsForControlEvents: (b, ev) => HB.buttonEvent(b, num(ev)),
  });
  HB.buttonEvent = (b, ev) => {
    for (const h of b.luaHandlers || []) if (h.ev & ev) safe(h.fn, b, ev);
  };
  methods(HB.LayerColor, { setColor: (l, c) => { l.color = COL(c); }, changeWidth: (l, w) => { l.w = num(w); }, changeHeight: (l, h) => { l.h = num(h); } });

  // CCArray (CCArray:create(), :addObject, :count, :objectAtIndex)
  class CCArray { constructor(a = []) { this.a = a; } }
  userdata(CCArray);
  methods(CCArray, {
    addObject: (r, o) => { r.a.push(o); }, count: (r) => r.a.length, objectAtIndex: (r, i) => r.a[num(i)], lastObject: (r) => r.a[r.a.length - 1],
    removeObjectAtIndex: (r, i) => { r.a.splice(num(i), 1); }, removeAllObjects: (r) => { r.a.length = 0; }, retain: () => {}, release: () => {},
    containsObject: (r, o) => r.a.includes(o), indexOfObject: (r, o) => r.a.indexOf(o), removeObject: (r, o) => { const i = r.a.indexOf(o); if (i >= 0) r.a.splice(i, 1); },
  });
  HB.CCArray = CCArray;

  // ---------------------------------------------------------------- shaders (grey pictures for locked things), scheduler
  const NORMAL = { grey: false }, GREY = { grey: true };
  class Shader { constructor(grey) { this.grey = grey; } }
  userdata(Shader);
  const SCHEDULER = { luaGet: (k) => ({ scheduleScriptFunc: asLua((self, fn, interval, paused) => HB.schedule(fn, num(interval), T(paused))), unscheduleScriptEntry: asLua((self, id) => HB.unschedule(num(id))) })[S(k)] };
  const timers = new Map(); let timerId = 1;
  HB.schedule = (fn, interval) => { const id = timerId++; timers.set(id, { fn, interval, t: 0 }); return id; };
  HB.unschedule = (id) => { timers.delete(id); };
  HB.luaTick = (dt) => {
    for (const n of [...scheduled]) if (n.luaUpdate) safe(n.luaUpdate, dt);
    for (const [id, tm] of [...timers]) { tm.t += dt; if (tm.t >= tm.interval) { const d = tm.t; tm.t = 0; if (timers.has(id)) safe(tm.fn, d); } }
  };
  HB.luaTouchLayers = new Set();
  // Lua touch layers (registerScriptTouchHandler(fn, multi, priority, swallow)): asked before the buttons, lowest priority number
  // first; fn("began", x, y) returning true takes the touch, then it gets "moved" and "ended" (cocos2d-x 2 single-touch handler)
  let touchOwner = null;
  HB.luaTouchBegan = (x, y) => {
    const layers = [...HB.luaTouchLayers].filter((n) => n.luaTouch && n.touchOn !== false && n.shown() && inScene(n)).sort((a, b) => a.luaTouch.prio - b.luaTouch.prio);
    for (const n of layers) {
      const t = n.luaTouch;
      const r = t.multi ? safe(t.fn, B('began'), new LuaTable()) : safe(t.fn, B('began'), x, y);
      if (T(first(r))) { touchOwner = n; return true; }
    }
    return false;
  };
  HB.luaTouchMoved = (x, y) => { if (touchOwner && touchOwner.luaTouch) safe(touchOwner.luaTouch.fn, B('moved'), x, y); };
  HB.luaTouchEnded = (x, y, cancel) => { const n = touchOwner; touchOwner = null; if (n && n.luaTouch) safe(n.luaTouch.fn, B(cancel ? 'cancelled' : 'ended'), x, y); };

  // ---------------------------------------------------------------- actions (CCSequence, CCMoveTo, CCCallFunc ...)
  // an action: { dur, start(node), update(t 0..1), done } ; instant ones have dur 0
  class Action { constructor(o) { Object.assign(this, { dur: 0, tag: -1 }, o); } }
  userdata(Action);
  methods(Action, { setTag: (a, t) => { a.tag = num(t); }, getTag: (a) => a.tag, retain: () => {}, release: () => {}, isDone: (a) => !!a.finished, getDuration: (a) => a.dur, reverse: (a) => (a.rev ? a.rev() : a) });
  const running = new Set(); // { node, action, t }
  function startAction(node, a) {
    const st = { node, a: clone(a), t: 0 };
    st.a.begin && st.a.begin(node);
    running.add(st);
    return st;
  }
  const clone = (a) => (a.make ? a.make() : a);
  HB.runAction = (node, a) => { startAction(node, a); };
  HB.stopActions = (node, a, tag) => { for (const st of [...running]) if (st.node === node && (!a || st.a === a || st.src === a) && (tag === undefined || st.a.tag === tag)) running.delete(st); };
  HB.actionByTag = (node, tag) => { for (const st of running) if (st.node === node && st.a.tag === tag) return st.a; return undefined; };
  HB.actionCount = (node) => { let n = 0; for (const st of running) if (st.node === node) n++; return n; };
  HB.actionTick = (dt) => {
    for (const st of [...running]) {
      if (!running.has(st)) continue;
      st.t += dt;
      const a = st.a;
      const f = a.dur > 0 ? Math.min(1, st.t / a.dur) : 1;
      a.update && a.update(f, st.node);
      if (f >= 1 && !a.forever) { running.delete(st); a.finished = true; }
    }
  };
  // a "make" function gives a fresh copy each time an action runs (one action object may run on many nodes)
  const act = (make) => { const a = make(); a.make = make; return a; };
  const interval = (dur, begin, upd) => act(() => { const x = new Action({ dur: Math.max(0, num(dur)) }); x.begin = function (n) { this.ctx = begin(n); }; x.update = function (t, n) { upd(t, n, this.ctx); }; return x; });
  const ease = (a, fn) => act(() => { const inner = clone(a); const x = new Action({ dur: inner.dur }); x.begin = (n) => inner.begin && inner.begin(n); x.update = (t, n) => inner.update && inner.update(fn(t), n); return x; });
  function sequence(list) {
    list = list.filter(Boolean);
    return act(() => {
      const parts = list.map(clone);
      const total = parts.reduce((s, p) => s + p.dur, 0);
      const x = new Action({ dur: total });
      let idx = -1, node = null;
      x.begin = (n) => { node = n; idx = -1; };
      x.update = (t, n) => {
        const now = t * total;
        let acc = 0;
        for (let i = 0; i < parts.length; i++) {
          const p = parts[i], endT = acc + p.dur;
          if (i > idx && now >= acc) { // start (and for instant ones, run) each part once, in order
            if (i > idx + 1) { for (let j = idx + 1; j < i; j++) { const q = parts[j]; if (j > idx) { q.begin && q.begin(n); q.update && q.update(1, n); } } }
            idx = i; p.begin && p.begin(n);
          }
          if (i === idx) {
            const f = p.dur > 0 ? Math.min(1, (now - acc) / p.dur) : 1;
            p.update && p.update(f, n);
            if (f < 1) break;
          }
          acc = endT;
          if (now < acc) break;
        }
      };
      return x;
    });
  }
  function spawn(list) {
    list = list.filter(Boolean);
    return act(() => {
      const parts = list.map(clone);
      const total = Math.max(0, ...parts.map((p) => p.dur));
      const x = new Action({ dur: total });
      x.begin = (n) => parts.forEach((p) => p.begin && p.begin(n));
      x.update = (t, n) => parts.forEach((p) => p.update && p.update(p.dur > 0 ? Math.min(1, (t * total) / p.dur) : 1, n));
      return x;
    });
  }
  const arrayArgs = (a) => (a.length === 1 && a[0] instanceof CCArray ? a[0].a : a.length === 1 && a[0] instanceof LuaTable ? a[0].arr : a);
  const lerp = (a, b, t) => a + (b - a) * t;
  function openActions() {
    luaClass('CCSequence', { create: (...a) => sequence(arrayArgs(a)), createWithTwoActions: (a, b) => sequence([a, b]) });
    luaClass('CCSpawn', { create: (...a) => spawn(arrayArgs(a)), createWithTwoActions: (a, b) => spawn([a, b]) });
    luaClass('CCDelayTime', { create: (d) => interval(d, () => null, () => {}) });
    luaClass('CCMoveTo', { create: (d, p) => { p = P(p); return interval(d, (n) => [n.x, n.y], (t, n, c) => { n.x = lerp(c[0], p.x, t); n.y = lerp(c[1], p.y, t); }); } });
    luaClass('CCMoveBy', { create: (d, p) => { p = P(p); return interval(d, (n) => [n.x, n.y], (t, n, c) => { n.x = c[0] + p.x * t; n.y = c[1] + p.y * t; }); } });
    luaClass('CCScaleTo', { create: (d, s, s2) => { const sx = num(s, 1), sy = s2 === undefined ? sx : num(s2, 1); return interval(d, (n) => [n.sx, n.sy], (t, n, c) => { n.sx = lerp(c[0], sx, t); n.sy = lerp(c[1], sy, t); }); } });
    luaClass('CCScaleBy', { create: (d, s, s2) => { const sx = num(s, 1), sy = s2 === undefined ? sx : num(s2, 1); return interval(d, (n) => [n.sx, n.sy], (t, n, c) => { n.sx = c[0] * lerp(1, sx, t); n.sy = c[1] * lerp(1, sy, t); }); } });
    luaClass('CCRotateTo', { create: (d, r) => interval(d, (n) => n.rot, (t, n, c) => { n.rot = lerp(c, num(r), t); }) });
    luaClass('CCRotateBy', { create: (d, r) => interval(d, (n) => n.rot, (t, n, c) => { n.rot = c + num(r) * t; }) });
    luaClass('CCFadeTo', { create: (d, o) => interval(d, (n) => n.opacity, (t, n, c) => { n.opacity = lerp(c, num(o), t); }) });
    luaClass('CCFadeIn', { create: (d) => interval(d, () => 0, (t, n) => { n.opacity = 255 * t; }) });
    luaClass('CCFadeOut', { create: (d) => interval(d, (n) => n.opacity, (t, n, c) => { n.opacity = c * (1 - t); }) });
    luaClass('CCTintTo', { create: (d, r, g, b) => interval(d, (n) => n.color.slice(), (t, n, c) => { n.color = [lerp(c[0], num(r), t), lerp(c[1], num(g), t), lerp(c[2], num(b), t)].map(Math.round); }) });
    luaClass('CCBlink', { create: (d, times) => interval(d, () => null, (t, n) => { const k = num(times, 1); n.visible = t >= 1 || Math.floor(t * k * 2) % 2 === 0; }) });
    luaClass('CCJumpBy', { create: (d, p, hgt, jumps) => { p = P(p); return interval(d, (n) => [n.x, n.y], (t, n, c) => { const k = (t * num(jumps, 1)) % 1; n.x = c[0] + p.x * t; n.y = c[1] + p.y * t + 4 * num(hgt) * k * (1 - k); }); } });
    luaClass('CCShow', { create: () => interval(0, () => null, (t, n) => { n.visible = true; }) });
    luaClass('CCHide', { create: () => interval(0, () => null, (t, n) => { n.visible = false; }) });
    luaClass('CCToggleVisibility', { create: () => interval(0, () => null, (t, n) => { n.visible = !n.visible; }) });
    luaClass('CCPlace', { create: (p) => { p = P(p); return interval(0, () => null, (t, n) => { n.x = p.x; n.y = p.y; }); } });
    luaClass('CCRemoveSelf', { create: () => interval(0, () => null, (t, n) => { if (n.parent) { n.removeSelf(); leave(n); } }) });
    const callOnce = (fn, withNode) => act(() => { const x = new Action({ dur: 0 }); let done = false; x.begin = () => { done = false; }; x.update = (t, n) => { if (!done) { done = true; safe(fn, ...(withNode ? [n] : [])); } }; return x; });
    luaClass('CCCallFunc', { create: (fn) => callOnce(fn, false) });
    luaClass('CCCallFuncN', { create: (fn) => callOnce(fn, true) });
    luaClass('CCRepeatForever', { create: (a) => act(() => { const inner = clone(a); const x = new Action({ dur: Math.max(0.0001, inner.dur), forever: true }); let k = 0; x.begin = (n) => { k = 0; inner.begin && inner.begin(n); }; x.update = (t, n) => { const loops = Math.floor(t); if (loops > k) { inner.update && inner.update(1, n); k = loops; inner.begin && inner.begin(n); } inner.update && inner.update(t - loops, n); }; x.dur = Math.max(0.0001, inner.dur); x.loopUpdate = true; return x; }) });
    luaClass('CCRepeat', { create: (a, times) => act(() => { const inner = clone(a); const k = Math.max(1, num(times, 1)); const x = new Action({ dur: inner.dur * k }); let done = 0; x.begin = (n) => { done = 0; inner.begin && inner.begin(n); }; x.update = (t, n) => { const at = t * k; while (done < Math.floor(at) && done < k) { inner.update && inner.update(1, n); done++; if (done < k) inner.begin && inner.begin(n); } if (done < k) inner.update && inner.update(at - done, n); }; return x; }) });
    const easeCls = (name, fn) => luaClass(name, { create: (a, rate) => ease(a, (t) => fn(t, num(rate, 2))) });
    easeCls('CCEaseIn', (t, r) => Math.pow(t, r)); easeCls('CCEaseOut', (t, r) => Math.pow(t, 1 / r));
    easeCls('CCEaseInOut', (t, r) => ((t *= 2) < 1 ? 0.5 * Math.pow(t, r) : 1 - 0.5 * Math.pow(2 - t, r)));
    easeCls('CCEaseSineIn', (t) => 1 - Math.cos(t * Math.PI / 2)); easeCls('CCEaseSineOut', (t) => Math.sin(t * Math.PI / 2)); easeCls('CCEaseSineInOut', (t) => -0.5 * (Math.cos(Math.PI * t) - 1));
    easeCls('CCEaseExponentialOut', (t) => (t === 1 ? 1 : 1 - Math.pow(2, -10 * t))); easeCls('CCEaseExponentialIn', (t) => (t === 0 ? 0 : Math.pow(2, 10 * (t - 1))));
    easeCls('CCEaseBackOut', (t) => { t -= 1; return t * t * (2.70158 * t + 1.70158) + 1; }); easeCls('CCEaseBackIn', (t) => t * t * (2.70158 * t - 1.70158));
    easeCls('CCEaseBounceOut', (t) => (t < 1 / 2.75 ? 7.5625 * t * t : t < 2 / 2.75 ? 7.5625 * (t -= 1.5 / 2.75) * t + 0.75 : t < 2.5 / 2.75 ? 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375 : 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375));
    easeCls('CCEaseElasticOut', (t) => (t === 0 || t === 1 ? t : Math.pow(2, -10 * t) * Math.sin((t - 0.075) * (2 * Math.PI) / 0.3) + 1));
    // frame animations: CCAnimation:createWithSpriteFrames(array, delay) + CCAnimate:create(animation)
    luaClass('CCAnimation', { createWithSpriteFrames: (arr, delay) => ({ frames: (arr instanceof CCArray ? arr.a : []).map((f) => f.frame), delay: num(delay, 0.1), luaGet: (k) => (S(k) === 'setRestoreOriginalFrame' || S(k) === 'setLoops' || S(k) === 'setDelayPerUnit' ? () => Lua.R.EMPTY : undefined) }), create: () => ({ frames: [], delay: 0.1 }) });
    luaClass('CCAnimate', { create: (anim) => interval(anim.frames.length * anim.delay, (n) => n.frame, (t, n) => { const i = Math.min(anim.frames.length - 1, Math.floor(t * anim.frames.length)); if (anim.frames[i]) n.setFrame(anim.frames[i]); }) });
  }

  // ---------------------------------------------------------------- the game's layouts from Lua: CCBProxy (readCCBFromFile + getNode)
  class CCBProxy extends HB.Node {
    constructor() { super(); this.owner = { n: {}, all: {} }; this.isLayer = true; this.ignoreAnchor = true; }
    read(file, size) {
      const doc = HB.loadCCBNow(txt(file));
      if (!doc) return new HB.Node();
      const name = txt(file).replace(/\.ccbi?$/i, '');
      const owner = this.owner;
      owner.onButton = (sel, btn) => this.selector(sel, btn);
      const root = HB.build(name, owner, size ? [size.width, size.height] : HB.size);
      this.lastRoot = root;
      return root;
    }
    selector(sel, btn) {
      const h = this.handlers && (this.handlers[sel] || this.handlers['*']);
      if (h) safe(h, btn);
    }
  }
  userdata(CCBProxy);
  methods(CCBProxy, {
    readCCBFromFile: (p, file) => p.read(file),
    readCCBFromFileBySize: (p, file, size) => p.read(file, size ? SZ(size) : null),
    getNode: (p, name) => p.owner.n[txt(name)],
    SetClearPlist: () => {},
    // handleButtonEvent(button, function): the button's tap calls the function (CCBProxy::addHandler + handleEvent)
    handleButtonEvent: (p, btn, fn, ev) => { if (btn && btn.luaGet) (btn.luaHandlers = btn.luaHandlers || []).push({ fn, ev: num(ev, EV.TouchUpInside) }); },
    handleControlEvent: (p, btn, fn, ev) => { if (btn && btn.luaGet) (btn.luaHandlers = btn.luaHandlers || []).push({ fn, ev: num(ev, EV.TouchUpInside) }); },
    handleMenuEvent: (p, item, fn) => { if (item) (item.luaHandlers = item.luaHandlers || []).push({ fn, ev: EV.TouchUpInside }); },
    setSelectorHandler: (p, h) => { p.handlers = { '*': h && h.fn ? h.fn : h }; },
    handleAnimationEvent: () => {}, removeHandler: () => {}, releaseMembers: () => {},
    getMemberName: () => undefined,
  });
  HB.CCBProxy = CCBProxy;
  // a CCB layout's nodes that Lua gets back: getNode(name) in the layout read last
  HB.lua.buttonTap = (b) => { if (b.luaHandlers && b.luaHandlers.length) { HB.buttonEvent(b, EV.TouchUpInside); return true; } return false; };

  // ---------------------------------------------------------------- the game's table view (LuaTableView + LuaEventHandler)
  class LuaEventHandler { constructor(fn) { this.fn = fn; } }
  userdata(LuaEventHandler);
  methods(LuaEventHandler, { retain: () => {}, release: () => {} });
  class TableViewCell extends HB.Node { constructor() { super(); this.idx = 0; } }
  userdata(TableViewCell);
  methods(TableViewCell, { getIdx: (c) => c.idx, setIdx: (c, i) => { c.idx = num(i); }, reset: () => {} });
  HB.TableViewCell = TableViewCell;
  class LuaTableView extends HB.ScrollView {
    constructor(handler, size) { super(); this.handler = handler; this.w = size.width; this.h = size.height; this.dir = 1; this.fill = 0; this.cells = []; this.content.ignoreAnchor = true; this.onTouch = (ev, x, y) => this.touch(ev, x, y); this.swallowOnly = true; }
    ask(fn, a1, a2) { return first(safe(this.handler.fn, B(fn), this, a1, a2)); }
    cellSize(i) { const s = this.ask('cellSize', i); return s instanceof CCSize ? s : s instanceof LuaTable ? SZ(s) : new CCSize(this.w, 40); }
    reload() {
      const keep = this.content.y, keepX = this.content.x;
      this.content.removeAll(); this.cells = [];
      const n = num(this.ask('numberOfCells'));
      let total = 0;
      const sizes = [];
      for (let i = 0; i < n; i++) { const s = this.cellSize(i); sizes.push(s); total += this.dir === 0 ? s.width : s.height; }
      if (this.dir === 0) { this.content.w = total; this.content.h = this.h; } else { this.content.w = this.w; this.content.h = total; }
      let at = 0;
      for (let i = 0; i < n; i++) {
        let cell = this.ask('cellAtIndex', i, undefined);
        if (!cell) continue;
        cell.idx = i;
        const s = sizes[i];
        if (this.dir === 0) { cell.x = at; cell.y = 0; }
        else { cell.x = 0; cell.y = this.fill === 0 ? total - at - s.height : at; } // fill top-down (0) or bottom-up (1)
        cell.w = s.width; cell.h = s.height;
        at += this.dir === 0 ? s.width : s.height;
        this.content.add(cell); enter(cell);
        this.cells.push(cell);
      }
      if (this.loaded) { this.content.x = keepX; this.content.y = keep; this.scrollBy(0, 0); } else this.toTop();
      this.loaded = true;
    }
    toTop() { const c = this.content; c.x = 0; c.y = this.dir === 0 ? 0 : Math.min(0, this.h - c.h); }
    cellAt(x, y) { for (const c of this.cells) if (c.hit(x, y)) return c; return null; }
    touch(ev, x, y) {
      if (ev === 'down') { this.downCell = this.cellAt(x, y); this.moved = false; this.start = [x, y]; if (this.downCell) { const t = new Touch(x, y); this.ask('cellTouchBegan', this.downCell, t); this.ask('cellHighlight', this.downCell); } }
      else if (ev === 'move') { if (this.start && Math.hypot(x - this.start[0], y - this.start[1]) > 12) { if (!this.moved && this.downCell) this.ask('cellUnhighlight', this.downCell); this.moved = true; } }
      else if (ev === 'up' || ev === 'cancel') {
        const c = this.downCell; this.downCell = null;
        if (c && !this.moved) { this.ask('cellUnhighlight', c); this.ask('cellTouchEnded', c, new Touch(x, y)); if (ev === 'up') this.ask('cellTouched', c); }
        if (this.onScrolled) this.onScrolled();
        safe(this.handler.fn, B('scroll'), this);
      }
    }
  }
  userdata(LuaTableView);
  methods(LuaTableView, {
    reloadData: (t) => t.reload(),
    setDirection: (t, d) => { t.dir = num(d); }, getDirection: (t) => t.dir,
    setVerticalFillOrder: (t, f) => { t.fill = num(f); }, getVerticalFillOrder: (t) => t.fill,
    setViewSize: (t, s) => { s = SZ(s); t.w = s.width; t.h = s.height; }, getViewSize: (t) => new CCSize(t.w, t.h),
    setContentOffset: (t, p) => { p = P(p); t.content.x = p.x; t.content.y = p.y; },
    setContentOffsetInDuration: (t, p, d) => { p = P(p); HB.tween(t.content, { x: p.x, y: p.y }, Math.max(0.01, num(d))); },
    getContentOffset: (t) => new CCPoint(t.content.x, t.content.y),
    minContainerOffset: (t) => new CCPoint(Math.min(0, t.w - t.content.w), Math.min(0, t.h - t.content.h)),
    maxContainerOffset: (t) => new CCPoint(0, 0),
    getContainer: (t) => t.content, getContentSize: (t) => new CCSize(t.content.w, t.content.h),
    cellAtIndex: (t, i) => t.cells.find((c) => c.idx === num(i)),
    updateCellAtIndex: (t) => t.reload(), insertCellAtIndex: (t) => t.reload(), removeCellAtIndex: (t) => t.reload(),
    dequeueCell: () => undefined, setBounceable: (t, on) => { t.bounce = T(on); }, isDragging: (t) => !!t.moved,
    setTouchEnabled: (t, on) => { t.touchOn = T(on); }, scrollToCell: () => {},
    setClippingToBounds: (t, on) => { t.clip = T(on); },
  });
  HB.LuaTableView = LuaTableView;
  class Touch { constructor(x, y) { this.x = x; this.y = y; } }
  userdata(Touch);
  methods(Touch, { getLocation: (t) => new CCPoint(t.x, t.y), getPreviousLocation: (t) => new CCPoint(t.x, t.y), getLocationInView: (t) => new CCPoint(t.x, HB.size[1] - t.y), getDelta: () => new CCPoint(0, 0), getID: () => 0 });
  HB.Touch = Touch;

  // ---------------------------------------------------------------- the server (CCHttpRequest), the same requests the phone sends
  class HttpRequest { constructor(url, method, body) { this.url = url; this.method = method; this.body = body; } }
  userdata(HttpRequest);
  const sameOrigin = (url) => { // the scripts build http://<server>/<cgi>?...; in the browser it goes to the page's own server
    const u = txt(url);
    const m = /^https?:\/\/[^/]+(\/.*)?$/i.exec(u);
    return m ? (m[1] || '/') : u;
  };
  methods(HttpRequest, {
    sendWithHandler: (r, fn) => {
      const path = sameOrigin(r.url), q = path.indexOf('?');
      const target = q >= 0 ? path.slice(0, q) : path, params = q >= 0 ? path.slice(q + 1) : '';
      // the phone sends the parameters as POST data (its URL text); %20 and raw spaces both work on the server
      HB.luaPending = (HB.luaPending || 0) + 1;
      fetch(target, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: params.replace(/ /g, '%20') + (r.body ? '&' + txt(r.body) : '') })
        .then((res) => res.text().then((t) => [res.status, t]))
        .then(([status, t]) => { HB.luaPending--; const resp = new HttpResponse(status === 200 ? 200 : status, t, r); safe(fn, resp, r); })
        .catch(() => { HB.luaPending--; safe(fn, new HttpResponse(-1, '', r), r); });
      return r;
    },
    send: (r) => { methods; return r; },
    setUserData: (r, d) => { r.userData = d; }, getUserData: (r) => r.userData, retain: () => {}, release: () => {},
    setTimeout: () => {},
  });
  class HttpResponse { constructor(code, data, req) { this.code = code; this.data = data; this.req = req; } }
  userdata(HttpResponse);
  methods(HttpResponse, {
    getResponseCode: (r) => r.code,
    getResponseData: (r) => B(r.data.replace(/^<RENLONG/, '<root').replace(/<\/RENLONG>\s*$/, '</root>').replace(/^<root/, '<RENLONG').replace(/<\/root>\s*$/, '</RENLONG>')),
    getHttpRequest: (r) => r.req, getUserData: (r) => r.req.userData, isSucceed: (r) => r.code === 200,
  });

  // ---------------------------------------------------------------- LuaXML (the C part of LuaXml: xml.eval / xml.load)
  function xmlToLua(el, xmlMeta) {
    const t = new LuaTable();
    t.mt = xmlMeta;
    t.set(0, B(el.nodeName));
    for (const a of el.attributes) t.set(B(a.name), B(a.value));
    let i = 1;
    for (const c of el.childNodes) {
      if (c.nodeType === 1) t.set(i++, xmlToLua(c, xmlMeta));
      else if ((c.nodeType === 3 || c.nodeType === 4) && c.nodeValue.trim() !== '') t.set(i++, B(c.nodeValue));
    }
    return t;
  }
  // io.open for the few small files the scripts keep (ActivityData.xml in the "writable path"): kept in the browser's storage
  const fileStore = {
    get: (p) => { try { return localStorage.getItem('hb.file.' + p); } catch { return fileStore.mem[p] ?? null; } },
    set: (p, v) => { try { localStorage.setItem('hb.file.' + p, v); } catch { fileStore.mem[p] = v; } },
    mem: {},
  };
  HB.fileStore = fileStore;
  function openIo() {
    const io = new LuaTable();
    const fileMeta = new LuaTable();
    const fileMethods = new LuaTable();
    fileMeta.set('__index', fileMethods);
    fileMethods.set('read', (f, fmt) => {
      const data = f.get('data'), pos = f.get('pos');
      const what = fmt === undefined ? '*l' : typeof fmt === 'number' ? fmt : txt(fmt);
      if (what === '*a') { f.set('pos', data.length); return [data.slice(pos)]; }
      if (typeof what === 'number') { if (pos >= data.length) return [undefined]; f.set('pos', pos + what); return [data.slice(pos, pos + what)]; }
      if (pos >= data.length) return [undefined];
      let e = data.indexOf('\n', pos); if (e < 0) e = data.length;
      f.set('pos', e + 1);
      return [data.slice(pos, e)];
    });
    fileMethods.set('write', (f, ...parts) => { f.set('data', f.get('data') + parts.map((x) => (typeof x === 'number' ? Lua.numToStr(x) : x)).join('')); return [f]; });
    fileMethods.set('lines', (f) => [() => call(fileMethods.get('read'), f)]);
    fileMethods.set('seek', (f) => [f.get('pos')]);
    fileMethods.set('flush', (f) => { if (f.get('w')) fileStore.set(f.get('path'), f.get('data')); return Lua.R.EMPTY; });
    fileMethods.set('close', (f) => { if (f.get('w')) fileStore.set(f.get('path'), f.get('data')); return [true]; });
    io.set('open', (path, mode) => {
      const p = txt(path), m = mode === undefined ? 'r' : txt(mode);
      const have = fileStore.get(p);
      if (m.startsWith('r') && have === null) return [undefined, B(p + ': No such file or directory'), 2];
      const f = new LuaTable(); f.mt = fileMeta;
      f.set('path', p); f.set('w', m.startsWith('w') || m.startsWith('a') || m.includes('+'));
      f.set('data', m.startsWith('w') ? '' : have ?? ''); f.set('pos', m.startsWith('a') ? (have ?? '').length : 0);
      return [f];
    });
    io.set('close', (f) => call(fileMethods.get('close'), f));
    io.set('write', (...a) => { console.log('[lua io] ' + a.map(txt).join('')); return Lua.R.EMPTY; });
    io.set('lines', (path) => { const d = fileStore.get(txt(path)) ?? ''; const lines = d.split('\n'); let i = 0; return [() => [i < lines.length ? lines[i++] : undefined]]; });
    HB.L.G.set('io', io);
  }
  function openXml() {
    const L = HB.L;
    const xml = new LuaTable();
    L.G.set('xml', xml);
    const meta = () => { const m = new LuaTable(); m.set('__index', xml); const str = xml.get('str'); if (str) m.set('__tostring', str); return m; };
    xml.set('eval', (s) => {
      const doc = new DOMParser().parseFromString(txt(s), 'text/xml');
      if (!doc.documentElement || doc.getElementsByTagName('parsererror').length) return [undefined];
      return [xmlToLua(doc.documentElement, meta())];
    });
    xml.set('load', (file) => {
      const f = txt(file);
      let t = fileStore.get(f) || ''; // a file the scripts saved (io.open), else one of the game's files
      if (!t) try { const x = new XMLHttpRequest(); x.open('GET', HB.ASSETS + f.replace(/^\/+/, ''), false); x.send(); if (x.status === 200) t = x.responseText; } catch (e) { /* none */ }
      if (!t) return [undefined];
      const doc = new DOMParser().parseFromString(t, 'text/xml');
      return [doc.documentElement ? xmlToLua(doc.documentElement, meta()) : undefined];
    });
    xml.set('registerCode', () => Lua.R.EMPTY);
    xml.set('parse', xml.get('eval')); // libgame.so registers load, parse, eval, encode, registerCode
    xml.set('encode', (s) => [B(txt(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;'))]);
    xml.set('decode', (s) => [B(txt(s).replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&'))]);
  }

  // ---------------------------------------------------------------- cocos singletons and constants
  function openCocos() {
    const winSize = () => new CCSize(HB.size[0], HB.size[1]);
    gfn('ccp', (x, y) => new CCPoint(x, y)); gfn('CCPointMake', (x, y) => new CCPoint(x, y));
    gfn('CCSizeMake', (w, h) => new CCSize(w, h)); gfn('CCRectMake', (x, y, w, h) => new CCRect(x, y, w, h));
    gfn('ccc3', (r, g, b) => new ccColor3B(r, g, b)); gfn('ccc4', (r, g, b, a) => new ccColor4B(r, g, b, a)); gfn('ccc4f', (r, g, b, a) => new ccColor4B(r * 255, g * 255, b * 255, a * 255));
    gfn('ccpAdd', (a, b) => new CCPoint(a.x + b.x, a.y + b.y)); gfn('ccpSub', (a, b) => new CCPoint(a.x - b.x, a.y - b.y));
    gfn('ccpDistance', (a, b) => Math.hypot(a.x - b.x, a.y - b.y)); gfn('ccpMult', (a, k) => new CCPoint(a.x * k, a.y * k));
    luaClass('CCPoint', { new: (x, y) => new CCPoint(x, y) }, (x, y) => new CCPoint(x, y));
    luaClass('CCSize', { new: (w, h) => new CCSize(w, h) }, (w, h) => new CCSize(w, h));
    luaClass('CCRect', { new: (x, y, w, h) => new CCRect(x, y, w, h) }, (x, y, w, h) => new CCRect(x, y, w, h));
    gfn('CCLuaLog', (s) => { if (HB.luaLog) console.log('[lua] ' + txt(s)); });
    luaClass('tolua', { cast: (o) => o, type: (o) => B(Lua.typeOf(o)), isnull: (o) => o === undefined || o === null, getpeer: (o) => o && o.__peer, setpeer: (o, p) => { if (o) o.__peer = p; } });
    // tolua.cast is called as tolua.cast(obj, "Type") (not with ':'): plain functions, not class methods
    const tl = G().get('tolua');
    tl.set('cast', (o) => [o]); tl.set('type', (o) => [B(Lua.typeOf(o))]); tl.set('isnull', (o) => [o === undefined || o === null]);
    const director = { luaGet: (k) => DIRECTOR[S(k)] };
    const DIRECTOR = {};
    for (const [k, f] of Object.entries({
      getWinSize: () => winSize(), getVisibleSize: () => winSize(), getVisibleOrigin: () => new CCPoint(0, 0), getWinSizeInPixels: () => winSize(),
      getRunningScene: () => HB.scene, getScheduler: () => SCHEDULER, convertToGL: (p) => new CCPoint(p.x, HB.size[1] - p.y), convertToUI: (p) => new CCPoint(p.x, HB.size[1] - p.y),
      getContentScaleFactor: () => 1, getAnimationInterval: () => 1 / 60, setAnimationInterval: () => {}, pause: () => {}, resume: () => {},
      getTouchDispatcher: () => ({ luaGet: () => asLua(() => {}) }), getKeypadDispatcher: () => ({ luaGet: () => asLua(() => {}) }),
      replaceScene: () => {}, pushScene: () => {}, popScene: () => {}, end: () => {},
    })) DIRECTOR[k] = asLua((self, ...a) => f(...a));
    luaClass('CCDirector', { sharedDirector: () => director });
    luaClass('CCSpriteFrameCache', { sharedSpriteFrameCache: () => FRAMECACHE });
    const FRAMECACHE = { luaGet: (k) => FC[S(k)] };
    const FC = {
      spriteFrameByName: asLua((self, name) => frameOf(name)),
      addSpriteFramesWithFile: asLua((self, plist) => { HB.loadSheetNow(txt(plist)); }),
      removeSpriteFramesFromFile: asLua(() => {}), removeUnusedSpriteFrames: asLua(() => {}), addSpriteFrame: asLua(() => {}),
    };
    luaClass('CCTextureCache', { sharedTextureCache: () => TEXCACHE });
    const TEXCACHE = { luaGet: (k) => ({ addImage: asLua((self, p) => new Texture(HB.imageNow(txt(p)), txt(p))), removeUnusedTextures: asLua(() => {}), removeTextureForKey: asLua(() => {}), removeAllTextures: asLua(() => {}), textureForKey: asLua((self, p) => new Texture(HB.imageNow(txt(p)), txt(p))) })[S(k)] };
    luaClass('CCShaderCache', { sharedShaderCache: () => SHADERS });
    const SHADERS = { luaGet: (k) => ({ programForKey: asLua((self, key) => (/gray|grey|Gray/.test(txt(key)) ? GREY : NORMAL)), addProgram: asLua(() => {}) })[S(k)] };
    luaClass('CCGLProgram', { create: () => GREY, new: () => GREY });
    luaClass('CCFileUtils', { sharedFileUtils: () => ({ luaGet: (k) => ({ fullPathForFilename: asLua((s, p) => p), getWritablePath: asLua(() => B('')), isFileExist: asLua(() => true), addSearchPath: asLua(() => {}), getFileData: asLua(() => undefined) })[S(k)] }) });
    const ud = {}; try { Object.assign(ud, JSON.parse(localStorage.getItem('hb.userdefault') || '{}')); } catch { /* private window */ }
    const udSave = () => { try { localStorage.setItem('hb.userdefault', JSON.stringify(ud)); } catch { /* private window */ } };
    const UD = { luaGet: (k) => ({
      getStringForKey: asLua((s, key, d) => B(ud[txt(key)] ?? txt(d ?? ''))), setStringForKey: asLua((s, key, v) => { ud[txt(key)] = txt(v); }),
      getIntegerForKey: asLua((s, key, d) => num(ud[txt(key)], num(d))), setIntegerForKey: asLua((s, key, v) => { ud[txt(key)] = num(v); }),
      getBoolForKey: asLua((s, key, d) => (txt(key) in ud ? !!ud[txt(key)] : T(d))), setBoolForKey: asLua((s, key, v) => { ud[txt(key)] = T(v); }),
      getFloatForKey: asLua((s, key, d) => num(ud[txt(key)], num(d))), setFloatForKey: asLua((s, key, v) => { ud[txt(key)] = num(v); }),
      getDoubleForKey: asLua((s, key, d) => num(ud[txt(key)], num(d))), setDoubleForKey: asLua((s, key, v) => { ud[txt(key)] = num(v); }),
      flush: asLua(() => udSave()),
    })[S(k)] };
    luaClass('CCUserDefault', { sharedUserDefault: () => UD });
    // node classes
    luaClass('CCNode', { create: () => new HB.Node() });
    luaClass('CCLayer', { create: () => { const l = new HB.Node(); l.isLayer = true; l.w = HB.size[0]; l.h = HB.size[1]; l.ignoreAnchor = true; return l; } });
    luaClass('CCScene', { create: () => new HB.Node() });
    luaClass('CCLayerColor', { create: (c, w, h) => { const l = new HB.LayerColor(); const k = COL(c); l.color = k; l.opacity = c instanceof ccColor4B ? c.a : 255; l.w = w === undefined ? HB.size[0] : num(w); l.h = h === undefined ? HB.size[1] : num(h); l.ignoreAnchor = true; return l; } });
    luaClass('CCSprite', {
      create: (file) => { if (file === undefined) return newSprite(null); const f = HB.frameByName(txt(file)); return newSprite(f); },
      createWithSpriteFrame: (f) => newSprite(f ? f.frame : null),
      createWithSpriteFrameName: (name) => { const f = HB.frameByName(txt(name)); if (!f) console.warn('no sprite frame', txt(name)); return newSprite(f); },
      createWithTexture: (t) => newSprite(t && t.path ? HB.frameOfImage(t.path) : null),
    });
    luaClass('CCScale9Sprite', {
      createWithSpriteFrameName: (name, r) => { const s = new HB.Scale9(HB.frameByName(txt(name))); return s; },
      createWithSpriteFrame: (f) => new HB.Scale9(f ? f.frame : null),
      create: (file) => new HB.Scale9(HB.frameByName(txt(file))),
    });
    luaClass('CCLabelTTF', { create: (s, font, size, dims, ha, va) => { const d = dims instanceof CCSize ? [dims.width, dims.height] : [0, 0]; return new HB.Label(txt(s), txt(font) || 'Helvetica', num(size, 20), d, num(ha), num(va)); } });
    luaClass('CCLabelBMFont', { create: (s, fnt) => { HB.loadFntNow(txt(fnt)); return new HB.BMLabel(txt(fnt), txt(s)); } });
    luaClass('CCControlButton', {
      create: (a, b, c) => {
        const btn = new HB.Button();
        if (a instanceof HB.Scale9) { btn.frames[1] = a.frame; btn.insets = a.insets; if (a.rot) btn.bg.rot = a.rot; }
        else if (a instanceof HB.Label) { btn.titles[1] = a.text; btn.titleFont = a.font; btn.titleSize = a.size; if (b instanceof HB.Scale9) { btn.frames[1] = b.frame; btn.insets = b.insets; } }
        else if (typeof a === 'string') { btn.titles[1] = txt(a); btn.titleFont = txt(b) || 'Helvetica'; btn.titleSize = num(c, 12); }
        btn.layout();
        return btn;
      },
    });
    luaClass('CCMenu', { create: () => new HB.Node() });
    luaClass('CCMenuItemImage', { create: (n, s) => { const b = new HB.Button(); b.frames[1] = HB.frameByName(txt(n)); b.frames[2] = HB.frameByName(txt(s)) || b.frames[1]; b.layout(); return b; } });
    luaClass('CCTableViewCell', { create: () => new TableViewCell(), new: () => new TableViewCell() });
    luaClass('LuaTableView', { createWithHandler: (h, size) => new LuaTableView(h, SZ(size)) });
    luaClass('LuaEventHandler', { create: (fn) => new LuaEventHandler(fn) });
    luaClass('CCBProxy', { create: () => new CCBProxy() });
    luaClass('CCArray', { create: () => new CCArray(), createWithCapacity: () => new CCArray() });
    luaClass('CCHttpRequest', {
      open: (url, method, body) => new HttpRequest(url, method, body),
      openWithUserData: (url, method, data, body) => { const r = new HttpRequest(url, method, body); r.userData = data; return r; },
    });
    luaClass('CCEditBox', { create: (size, bg) => { const s = SZ(size); const b = new EditBox(s); return b; } });
    luaClass('SimpleAudioEngine', { sharedEngine: () => ({ luaGet: () => asLua(() => {}) }) });
    // constants (cocos2d-x 2 values)
    const K = {
      kCCMenuHandlerPriority: -128, kHttpGet: 0, kHttpPost: 1,
      CCControlEventTouchDown: EV.TouchDown, CCControlEventTouchDragInside: EV.TouchDragInside, CCControlEventTouchDragOutside: EV.TouchDragOutside,
      CCControlEventTouchDragEnter: EV.TouchDragEnter, CCControlEventTouchDragExit: EV.TouchDragExit, CCControlEventTouchUpInside: EV.TouchUpInside,
      CCControlEventTouchUpOutside: EV.TouchUpOutside, CCControlEventTouchCancel: EV.TouchCancel, CCControlEventValueChanged: EV.ValueChanged,
      CCControlStateNormal: STATE.Normal, CCControlStateHighlighted: STATE.Highlighted, CCControlStateDisabled: STATE.Disabled, CCControlStateSelected: STATE.Selected,
      kCCScrollViewDirectionHorizontal: 0, kCCScrollViewDirectionVertical: 1, kCCScrollViewDirectionBoth: 2,
      kCCTableViewFillTopDown: 0, kCCTableViewFillBottomUp: 1,
      kCCTextAlignmentLeft: 0, kCCTextAlignmentCenter: 1, kCCTextAlignmentRight: 2,
      kCCVerticalTextAlignmentTop: 0, kCCVerticalTextAlignmentCenter: 1, kCCVerticalTextAlignmentBottom: 2,
      kCCTouchesAllAtOnce: 0, kCCTouchesOneByOne: 1,
      kEditBoxInputModeAny: 0, kEditBoxInputModeEmailAddr: 1, kEditBoxInputModeNumeric: 2, kEditBoxInputModePhoneNumber: 3, kEditBoxInputModeUrl: 4, kEditBoxInputModeDecimal: 5, kEditBoxInputModeSingleLine: 6,
      kEditBoxInputFlagPassword: 0, kEditBoxInputFlagSensitive: 1, kEditBoxInputFlagInitialCapsWord: 2, kEditBoxInputFlagInitialCapsSentence: 3, kEditBoxInputFlagInitialCapsAllCharacters: 4,
      kKeyboardReturnTypeDefault: 0, kKeyboardReturnTypeDone: 1, kKeyboardReturnTypeSend: 2, kKeyboardReturnTypeSearch: 3, kKeyboardReturnTypeGo: 4,
      kCCRepeatForever: 0xfffffffe, kCCPositionTypeFree: 0, kCCPositionTypeRelative: 1, kCCPositionTypeGrouped: 2,
      kCCShader_PositionTextureColor: 'ShaderPositionTextureColor', kCCShader_PositionTextureColorAlphaTest: 'ShaderPositionTextureColorAlphaTest',
      kCCProgressTimerTypeRadial: 0, kCCProgressTimerTypeBar: 1,
    };
    for (const [k, v] of Object.entries(K)) gval(k, v);
  }
  // text input (CCEditBox): an HTML input over the canvas while it is being typed in
  class EditBox extends HB.Node {
    constructor(size) { super(); this.w = size.width; this.h = size.height; this.ax = this.ay = 0.5; this.value = ''; this.label = this.add(new HB.Label('', 'Helvetica', 22)); this.label.ax = 0; this.label.x = 6; this.label.y = this.h / 2; this.placeholder = ''; this.maxLen = 0; this.onTouch = (ev) => { if (ev === 'up') this.edit(); }; }
    show() { this.label.setText(this.value || this.placeholder); this.label.color = this.value ? this.fontColor || [255, 255, 255] : [160, 160, 160]; }
    edit() {
      const v = window.prompt(this.placeholder || 'Text', this.value);
      if (v === null) return;
      this.value = this.maxLen ? v.slice(0, this.maxLen) : v; this.show();
      if (this.luaHandler) { safe(this.luaHandler, B('changed'), this); safe(this.luaHandler, B('ended'), this); safe(this.luaHandler, B('return'), this); }
    }
  }
  userdata(EditBox);
  methods(EditBox, {
    setText: (e, t) => { e.value = txt(t); e.show(); }, getText: (e) => B(e.value),
    setPlaceHolder: (e, t) => { e.placeholder = txt(t); e.show(); }, setPlaceholderFontColor: () => {}, setFontColor: (e, c) => { e.fontColor = COL(c); e.show(); },
    setFontSize: (e, s) => { e.label.size = num(s); e.show(); }, setFont: () => {}, setMaxLength: (e, n) => { e.maxLen = num(n); },
    setInputMode: () => {}, setInputFlag: () => {}, setReturnType: () => {}, registerScriptEditBoxHandler: (e, fn) => { e.luaHandler = fn; },
  });

  // ---------------------------------------------------------------- start a Lua state with the game's scripts
  HB.startLua = async (game) => {
    const files = (await HB.json('lua.json')) || {};
    const L = new Lua.State({
      // cocos2d-x's Lua loader: "a.b" and "a.lua" both mean a/b.lua, found under script/ (AppDelegate adds script/ to the search path)
      files: (p) => files[p] ?? files['script/' + p],
      print: (s) => console.log('[lua] ' + s),
    });
    HB.L = L;
    const pkg = L.G.get('package');
    pkg.set('path', B('?.lua;script/?.lua'));
    const req = L.G.get('require');
    L.G.set('require', (name) => req(B(txt(name).replace(/\.lua$/i, ''))));
    openCocos(); openActions(); openIo(); openXml();
    if (game && game.openGame) game.openGame(HB.lua);
    return L;
  };
  // run a script file now (CCLuaEngine::executeScriptFile), errors to the console
  HB.luaRun = (path) => {
    try { HB.L.dofile(path.startsWith('script/') ? path : 'script/' + path); return true; }
    catch (e) { HB.luaError(e); return false; }
  };
  // wait until the scripts' own server requests have all answered (the phone's loading screen did this before Home), at most ms
  HB.luaSettle = async (ms = 6000) => { const t0 = Date.now(); await new Promise((ok) => setTimeout(ok, 50)); while ((HB.luaPending || 0) > 0 && Date.now() - t0 < ms) await new Promise((ok) => setTimeout(ok, 50)); };
  HB.luaGlobal = (name, ...a) => { const f = HB.L.get(name); if (f === undefined) { console.warn('Lua has no ' + name); return Lua.R.EMPTY; } return safe(f, ...a); };
})();
