// Talking to the game server exactly like the Android app does: POST /<endpoint> with Uid, Session, ServerID, GroupID, Cmd ...,
// the reply is XML <RENLONG code="0">...</RENLONG> (server.js). Accounts go through the same account window paths (gumplogin.js).
'use strict';
(() => {
  const HB = window.HB;
  const store = {
    get(k) { try { return localStorage.getItem('hb.' + k); } catch { return null; } },
    set(k, v) { try { if (v == null) localStorage.removeItem('hb.' + k); else localStorage.setItem('hb.' + k, v); } catch { /* private window */ } },
  };
  HB.store = store;
  const S = (HB.session = { uid: '', session: '', server: 1, group: 2 });
  const two = (n) => String(n).padStart(2, '0');
  const clientTime = () => { const d = new Date(); return `${d.getFullYear()}/${two(d.getMonth() + 1)}/${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())}:${two(d.getSeconds())} ${d.toLocaleDateString('en-US', { weekday: 'long' })}`; };

  // HB.api('rl_r_mainpage', { Cmd: 1301 }) -> the reply's root Element (attribute code); throws on network trouble
  HB.api = async (cgi, params = {}, opts = {}) => {
    const base = { Uid: S.uid, Session: S.session, Clinettime: clientTime(), Platform: 'android', Version: '28.0', Pt: 1062, ServerID: S.server, GroupID: S.group };
    const body = new URLSearchParams({ ...(opts.bare ? {} : base), ...params }).toString();
    let txt;
    for (let tries = 0; ; tries++) {
      try {
        const r = await fetch('/' + cgi, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
        txt = await r.text();
        break;
      } catch (e) {
        if (tries >= 2) throw new Error('network');
        await new Promise((ok) => setTimeout(ok, 800));
      }
    }
    const doc = new DOMParser().parseFromString(txt, 'text/xml');
    const root = doc.documentElement;
    if (!root || root.nodeName === 'parsererror') throw new Error('bad reply from ' + cgi);
    root.code = Number(root.getAttribute('code') || 0);
    return root;
  };
  // the account window (gumplogin.js): JSON answers, code 100000 = fine
  HB.account = async (path, form) => {
    const r = await fetch(path, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams({ appId: 10015, ...form }).toString() });
    return r.json();
  };
  // small XML helpers: x.t(el, 'name') = text of the first <name> anywhere inside, x.n = as a number, x.all = every <name>
  HB.x = {
    first: (el, tag) => (el ? el.getElementsByTagName(tag)[0] : null),
    t: (el, tag, def = '') => { const e = el && el.getElementsByTagName(tag)[0]; return e ? e.textContent : def; },
    n: (el, tag, def = 0) => { const e = el && el.getElementsByTagName(tag)[0]; return e ? Number(e.textContent) || 0 : def; },
    all: (el, tag) => (el ? [...el.getElementsByTagName(tag)] : []),
    a: (el, name, def = '') => (el && el.hasAttribute(name) ? el.getAttribute(name) : def),
  };
})();
