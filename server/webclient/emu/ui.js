// The page's own windows over the game (what Android's Java code showed as native windows): a small dialog with a title, text,
// input fields and buttons. Used for the account window (Play / Log in / Sign up, see main.js) and for typing text into the
// game (Cocos2dxHelper.showEditTextDialog). Works with a phone keyboard: the first field gets the focus while the tap that
// opened the window is still going on (iPhones only open the keyboard then).
//   EmuUI.dialog({ title, text, fields: [{ name, label, type, value, max, placeholder }], buttons: [{ label, value, kind }],
//                  error }) -> Promise<{ button, values }>
'use strict';
(function (root) {
  const css = `
  .emu-ui { position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; background: rgba(0,0,0,.55);
    z-index: 10; padding: 16px; box-sizing: border-box; touch-action: manipulation; -webkit-user-select: text; user-select: text; }
  .emu-ui .box { width: min(420px, 100%); background: linear-gradient(#3b2a1c, #24170e); border: 3px solid #c8913c; border-radius: 14px;
    box-shadow: 0 8px 30px rgba(0,0,0,.6); color: #f4e6cc; font: 16px/1.4 "Trebuchet MS", Arial, sans-serif; padding: 18px 18px 14px; box-sizing: border-box; }
  .emu-ui h2 { margin: 0 0 8px; font-size: 22px; color: #ffd36b; text-align: center; text-shadow: 0 2px 0 #000; }
  .emu-ui p { margin: 0 0 12px; color: #e9d7b6; text-align: center; white-space: pre-line; }
  .emu-ui label { display: block; margin: 10px 0 4px; font-size: 14px; color: #d9c29a; }
  .emu-ui input { width: 100%; box-sizing: border-box; font-size: 17px; padding: 10px 12px; border-radius: 8px; border: 2px solid #8a6533;
    background: #fff8ea; color: #2a1a0c; outline: none; }
  .emu-ui input:focus { border-color: #ffb43a; }
  .emu-ui .err { color: #ff8a7a; min-height: 1.2em; margin-top: 8px; text-align: center; font-size: 14px; }
  .emu-ui .btns { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 14px; }
  .emu-ui button { flex: 1 1 120px; font: bold 17px "Trebuchet MS", Arial, sans-serif; padding: 12px 10px; border-radius: 10px; cursor: pointer;
    border: 2px solid #1d5e12; background: linear-gradient(#7fd04c, #3f9a22); color: #fff; text-shadow: 0 1px 0 #1a4a0c; }
  .emu-ui button.blue { border-color: #134a7a; background: linear-gradient(#5ab4f0, #2a73c0); text-shadow: 0 1px 0 #0c3058; }
  .emu-ui button.grey { border-color: #4b4036; background: linear-gradient(#8d8072, #5e5348); text-shadow: 0 1px 0 #2a241e; }
  .emu-ui button.link { flex-basis: 100%; background: none; border: none; color: #ffd36b; font-weight: normal; font-size: 15px; padding: 6px; text-decoration: underline; }`;
  let styled = false;
  const el = (tag, props, kids) => { const e = document.createElement(tag); Object.assign(e, props || {}); for (const k of kids || []) if (k) e.append(k); return e; };

  function dialog(o) {
    if (!styled) { document.head.append(el('style', { textContent: css })); styled = true; }
    return new Promise((done) => {
      const inputs = {};
      const fields = (o.fields || []).map((f) => {
        const inp = el('input', { type: f.type || 'text', value: f.value || '', placeholder: f.placeholder || '', autocomplete: f.autocomplete || 'off', autocapitalize: 'off', spellcheck: false });
        if (f.max > 0) inp.maxLength = f.max;
        if (f.inputmode) inp.inputMode = f.inputmode;
        inputs[f.name] = inp;
        return el('div', {}, [f.label ? el('label', { textContent: f.label }) : null, inp]);
      });
      const err = el('div', { className: 'err', textContent: o.error || '' });
      const close = (button) => { wrap.remove(); const values = {}; for (const k in inputs) values[k] = inputs[k].value; done({ button, values }); };
      const btns = (o.buttons || [{ label: 'OK', value: 'ok' }]).map((b) => el('button', { type: 'button', className: b.kind || '', textContent: b.label, onclick: () => close(b.value) }));
      const box = el('form', { className: 'box', onsubmit: (e) => { e.preventDefault(); close((o.buttons || [{ value: 'ok' }])[0].value); } },
        [o.title ? el('h2', { textContent: o.title }) : null, o.text ? el('p', { textContent: o.text }) : null, ...fields, err, el('div', { className: 'btns' }, btns)]);
      const wrap = el('div', { className: 'emu-ui' }, [box]);
      for (const ev of ['pointerdown', 'pointerup', 'pointermove', 'touchstart', 'touchmove', 'touchend']) wrap.addEventListener(ev, (e) => e.stopPropagation());
      document.body.append(wrap);
      const first = fields.length && inputs[o.fields[0].name];
      if (first) { first.focus(); try { first.setSelectionRange(first.value.length, first.value.length); } catch { /* number fields */ } }
    });
  }
  root.EmuUI = { dialog };
})(typeof window !== 'undefined' ? window : globalThis);
