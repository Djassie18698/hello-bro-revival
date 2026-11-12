// A Lua 5.1 engine in plain JavaScript for the web client: it runs the game's own Lua scripts (re/obb/script) unchanged.
// How: each Lua chunk is parsed and turned into JavaScript source once (new Function), then runs at JavaScript speed.
// Same as Lua 5.1: numbers are doubles (3 prints "3", 3.5 prints "3.5"), strings are byte strings (UTF-8 bytes, so string.len
// and string.sub count bytes like the phone), tables keep an array part, metatables (__index, __newindex, __call, arithmetic,
// __eq, __lt, __le, __concat, __unm, __tostring), varargs, multiple results, module(name, package.seeall), require, loadstring,
// pcall/xpcall/error, string patterns (find, match, gmatch, gsub), string.format, table.*, math.*, os.time / os.date.
// Not here (the game's scripts never use them): coroutines, goto, setfenv/getfenv, weak tables, string.dump, io.
// Works in the browser (window.Lua) and in Node (module.exports) for the checks in tools/dev/lua-test.js.
'use strict';
(function (root) {
  // ---------------------------------------------------------------- values
  class LuaError extends Error {
    // raw = the message already says where (error(), parse errors); otherwise "chunk:line: " is put in front, like Lua's runtime errors
    constructor(value, raw) {
      if (!raw && typeof value === 'string' && R.p) value = R.where() + ': ' + value;
      super(typeof value === 'string' ? value : 'Lua error'); this.value = value;
    }
  }
  let nextId = 1;
  class LuaTable {
    constructor() { this.arr = []; this.hash = new Map(); this.mt = undefined; this.id = 0; }
    get(k) {
      if (typeof k === 'number') {
        const a = this.arr;
        if (k >= 1 && k <= a.length && (k | 0) === k) return a[k - 1];
        if (k !== k) return undefined;
      }
      return this.hash.get(k);
    }
    set(k, v) {
      if (typeof k === 'number') {
        if (k !== k) throw new LuaError('table index is NaN');
        const a = this.arr;
        if ((k | 0) === k && k >= 1) {
          if (k <= a.length) {
            if (v === undefined && k === a.length) { a.pop(); while (a.length && a[a.length - 1] === undefined) a.pop(); }
            else a[k - 1] = v; // a nil inside stays a hole
            return;
          }
          if (k === a.length + 1 && v !== undefined) {
            a.push(v);
            this.hash.delete(k);
            // pull following keys out of the hash part
            const h = this.hash;
            if (h.size) { let n = a.length + 1; while (h.has(n)) { a.push(h.get(n)); h.delete(n); n++; } }
            return;
          }
        }
      } else if (k === undefined) throw new LuaError('table index is nil');
      if (v === undefined) this.hash.delete(k); else this.hash.set(k, v);
    }
    len() { // the border, found the way Lua 5.1's luaH_getn finds it
      const a = this.arr;
      let j = a.length;
      if (j > 0 && a[j - 1] === undefined) { // binary search for a border in the array part
        let i = 0;
        while (j - i > 1) { const m = (i + j) >> 1; if (a[m - 1] === undefined) j = m; else i = m; }
        return i;
      }
      if (!this.hash.size) return j;
      while (this.hash.get(j + 1) !== undefined) j++;
      return j;
    }
  }
  const T = (v) => v !== undefined && v !== false && v !== null; // Lua truth (null may come from JS)
  const EMPTY = Object.freeze([]);

  // ---------------------------------------------------------------- number <-> string, like Lua 5.1 (%.14g)
  function fmtG(n, prec = 14) {
    if (n !== n) return n > 0 ? 'nan' : (Object.is(n, NaN) ? 'nan' : '-nan');
    if (n === Infinity) return 'inf';
    if (n === -Infinity) return '-inf';
    if (n === 0) return Object.is(n, -0) ? '-0' : '0';
    const e = Math.floor(Math.log10(Math.abs(n)));
    let s;
    if (e < -4 || e >= prec) {
      s = n.toExponential(prec - 1);
      let [m, ex] = s.split('e');
      if (m.includes('.')) m = m.replace(/0+$/, '').replace(/\.$/, '');
      const sign = ex[0] === '-' ? '-' : '+';
      ex = ex.replace(/^[+-]/, '');
      if (ex.length < 2) ex = '0' + ex;
      return m + 'e' + sign + ex;
    }
    s = n.toFixed(Math.max(0, prec - 1 - e));
    if (s.includes('.')) s = s.replace(/0+$/, '').replace(/\.$/, '');
    return s;
  }
  const numToStr = (n) => (Number.isInteger(n) && Math.abs(n) < 1e15 ? String(n) : fmtG(n));
  function strToNum(s, base) {
    s = String(s).trim();
    if (base !== undefined && base !== 10) {
      if (!/^-?[0-9a-zA-Z]+$/.test(s)) return undefined;
      const neg = s[0] === '-'; if (neg) s = s.slice(1);
      let n = 0;
      for (const c of s.toLowerCase()) { const d = parseInt(c, 36); if (d >= base) return undefined; n = n * base + d; }
      return neg ? -n : n;
    }
    if (/^[-+]?0[xX][0-9a-fA-F]+$/.test(s)) return (s[0] === '-' ? -1 : 1) * parseInt(s.replace(/^[-+]/, ''), 16);
    if (!/^[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$/.test(s)) {
      if (/^[-+]?(inf|nan)$/i.test(s)) return undefined;
      return undefined;
    }
    return Number(s);
  }
  const tonum = (v) => (typeof v === 'number' ? v : typeof v === 'string' ? strToNum(v) : undefined);

  // ---------------------------------------------------------------- byte strings (Lua) <-> text (JavaScript)
  const enc = new TextEncoder(), dec = new TextDecoder('utf-8');
  const toBytes = (s) => { const b = enc.encode(String(s)); let o = ''; for (let i = 0; i < b.length; i += 8192) o += String.fromCharCode.apply(null, b.subarray(i, i + 8192)); return o; };
  const fromBytes = (s) => { if (!/[\x80-\xff]/.test(s)) return s; const b = new Uint8Array(s.length); for (let i = 0; i < s.length; i++) b[i] = s.charCodeAt(i) & 255; return dec.decode(b); };

  // ---------------------------------------------------------------- the runtime the compiled code calls
  const R = {};
  R.T = T; R.EMPTY = EMPTY; R.LuaTable = LuaTable; R.LuaError = LuaError; R.p = 0;
  R.chunks = []; // chunk names, for "file:line:" in errors
  R.where = () => { const c = Math.floor(R.p / 1e6), l = R.p % 1e6; return (R.chunks[c] || '?') + ':' + l; };
  const typeOf = (v) => {
    if (v === undefined || v === null) return 'nil';
    const t = typeof v;
    if (t === 'number' || t === 'string' || t === 'boolean') return t;
    if (t === 'function') return 'function';
    if (v instanceof LuaTable) return 'table';
    return 'userdata';
  };
  R.typeOf = typeOf;
  R.stringMeta = undefined; // set below: strings index the string library
  // userdata (JavaScript objects from the engine): obj.__lua = { get(obj, key) -> value } or a class with a static luaIndex
  function getmeta(v) {
    if (v instanceof LuaTable) return v.mt;
    if (typeof v === 'string') return R.stringMeta;
    if (v && typeof v === 'object' && v.__luamt) return v.__luamt;
    if (v && (typeof v === 'object' || typeof v === 'function') && v.constructor && v.constructor.__luamt) return v.constructor.__luamt;
    return undefined;
  }
  R.getmeta = getmeta;
  const metaOf = (v, ev) => { const m = getmeta(v); return m ? m.get(ev) : undefined; };
  function idx(o, k) {
    for (let loop = 0; loop < 100; loop++) {
      let h;
      if (o instanceof LuaTable) {
        const v = o.get(k);
        if (v !== undefined) return v;
        if (!o.mt || (h = o.mt.get('__index')) === undefined) return undefined;
      } else if (typeof o === 'string') {
        h = R.stringMeta.get('__index');
      } else if (o !== undefined && o !== null && (typeof o === 'object' || typeof o === 'function') && o.luaGet) {
        return o.luaGet(k);
      } else {
        h = metaOf(o, '__index');
        if (h === undefined) throw new LuaError(`attempt to index a ${typeOf(o)} value${k !== undefined ? " (field '" + fromBytes(String(k)) + "')" : ''}`);
      }
      if (typeof h === 'function') return first(h(o, k));
      o = h;
    }
    throw new LuaError("'__index' chain too long; possible loop");
  }
  function setidx(o, k, v) {
    for (let loop = 0; loop < 100; loop++) {
      let h;
      if (o instanceof LuaTable) {
        if (!o.mt || (h = o.mt.get('__newindex')) === undefined || o.get(k) !== undefined) { o.set(k, v); return; }
      } else if (o !== undefined && o !== null && (typeof o === 'object' || typeof o === 'function') && o.luaSet) { o.luaSet(k, v); return; }
      else {
        h = metaOf(o, '__newindex');
        if (h === undefined) throw new LuaError(`attempt to index a ${typeOf(o)} value${k !== undefined ? " (field '" + fromBytes(String(k)) + "')" : ''}`);
      }
      if (typeof h === 'function') { h(o, k, v); return; }
      o = h;
    }
    throw new LuaError("'__newindex' chain too long; possible loop");
  }
  R.idx = idx; R.setidx = setidx;
  const first = (r) => (r === undefined ? undefined : Array.isArray(r) ? r[0] : r);
  R.first = first;
  function call(f, ...a) {
    if (typeof f === 'function') { const r = f(...a); return r === undefined ? EMPTY : r; }
    const h = metaOf(f, '__call');
    if (h === undefined) throw new LuaError(`attempt to call a ${typeOf(f)} value`);
    return call(h, f, ...a);
  }
  R.call = call;
  R.callf = (f, name, ...a) => { // like call, with the name in the error (attempt to call global 'x' (a nil value))
    if (typeof f === 'function') { const r = f(...a); return r === undefined ? EMPTY : r; }
    if (metaOf(f, '__call') === undefined) throw new LuaError(`attempt to call ${name} (a ${typeOf(f)} value)`);
    return call(f, ...a);
  };
  R.callm = (o, k, ...a) => { // o:k(...)
    const f = idx(o, k);
    if (typeof f === 'function') { const r = f(o, ...a); return r === undefined ? EMPTY : r; }
    if (f === undefined) throw new LuaError(`attempt to call method '${fromBytes(String(k))}' (a nil value)`);
    return call(f, o, ...a);
  };
  function arith(ev, a, b) {
    const x = tonum(a), y = tonum(b);
    if (x !== undefined && y !== undefined) {
      switch (ev) {
        case '__add': return x + y; case '__sub': return x - y; case '__mul': return x * y; case '__div': return x / y;
        case '__mod': return x - Math.floor(x / y) * y; case '__pow': return Math.pow(x, y); case '__unm': return -x;
      }
    }
    const h = metaOf(a, ev) ?? metaOf(b, ev);
    if (h === undefined) {
      const bad = x === undefined ? a : b;
      throw new LuaError(`attempt to perform arithmetic on a ${typeOf(bad)} value`);
    }
    return first(call(h, a, b));
  }
  R.add = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a + b : arith('__add', a, b));
  R.sub = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a - b : arith('__sub', a, b));
  R.mul = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a * b : arith('__mul', a, b));
  R.div = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a / b : arith('__div', a, b));
  R.mod = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a - Math.floor(a / b) * b : arith('__mod', a, b));
  R.pow = (a, b) => (typeof a === 'number' && typeof b === 'number' ? Math.pow(a, b) : arith('__pow', a, b));
  R.unm = (a) => (typeof a === 'number' ? -a : arith('__unm', a, a));
  R.concat = (a, b) => {
    const ta = typeof a, tb = typeof b;
    if ((ta === 'string' || ta === 'number') && (tb === 'string' || tb === 'number')) return (ta === 'number' ? numToStr(a) : a) + (tb === 'number' ? numToStr(b) : b);
    const h = metaOf(a, '__concat') ?? metaOf(b, '__concat');
    if (h === undefined) throw new LuaError(`attempt to concatenate a ${typeOf(ta === 'string' || ta === 'number' ? b : a)} value`);
    return first(call(h, a, b));
  };
  R.len = (a) => {
    if (typeof a === 'string') return a.length;
    if (a instanceof LuaTable) return a.len();
    const h = metaOf(a, '__len');
    if (h === undefined) throw new LuaError(`attempt to get length of a ${typeOf(a)} value`);
    return first(call(h, a));
  };
  R.eq = (a, b) => {
    if (a === b) return true;
    if (a === null) a = undefined; if (b === null) b = undefined;
    if (a === b) return true;
    if (typeof a !== 'object' || typeof b !== 'object' || typeOf(a) !== typeOf(b)) return false;
    const h = metaOf(a, '__eq');
    return h !== undefined && h === metaOf(b, '__eq') && T(first(call(h, a, b)));
  };
  const cmpErr = (a, b) => new LuaError(typeOf(a) === typeOf(b) ? `attempt to compare two ${typeOf(a)} values` : `attempt to compare ${typeOf(a)} with ${typeOf(b)}`);
  R.lt = (a, b) => {
    const ta = typeof a;
    if (ta === typeof b && (ta === 'number' || ta === 'string')) return a < b;
    const h = metaOf(a, '__lt');
    if (h === undefined || h !== metaOf(b, '__lt')) throw cmpErr(a, b);
    return T(first(call(h, a, b)));
  };
  R.le = (a, b) => {
    const ta = typeof a;
    if (ta === typeof b && (ta === 'number' || ta === 'string')) return a <= b;
    let h = metaOf(a, '__le');
    if (h !== undefined && h === metaOf(b, '__le')) return T(first(call(h, a, b)));
    h = metaOf(a, '__lt');
    if (h !== undefined && h === metaOf(b, '__lt')) return !T(first(call(h, b, a)));
    throw cmpErr(a, b);
  };
  // table constructor: positional values (the last may be several), then key/value pairs
  R.tbl = (pos, kv) => {
    const t = new LuaTable();
    if (pos) { let n = pos.length; while (n > 0 && pos[n - 1] === undefined) n--; for (let i = 0; i < n; i++) t.arr.push(pos[i]); } // holes stay in the array part, like Lua's constructor
    if (kv) for (let i = 0; i < kv.length; i += 2) { if (kv[i] === undefined) throw new LuaError('table index is nil'); if (kv[i + 1] !== undefined) t.set(kv[i], kv[i + 1]); }
    return t;
  };
  R.forPrep = (a, b, c) => {
    const x = tonum(a), y = tonum(b), z = tonum(c);
    if (x === undefined) throw new LuaError("'for' initial value must be a number");
    if (y === undefined) throw new LuaError("'for' limit must be a number");
    if (z === undefined) throw new LuaError("'for' step must be a number");
    return [x, y, z];
  };

  // ---------------------------------------------------------------- lexer
  const KEYWORDS = new Set(['and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while']);
  function lex(src, name) {
    const toks = [];
    let i = 0, line = 1;
    const n = src.length;
    const err = (m) => { throw new LuaError(`${name}:${line}: ${m}`, true); };
    const longBracket = () => { // at '[', returns level or -1
      let j = i + 1, lv = 0;
      while (src[j] === '=') { lv++; j++; }
      return src[j] === '[' ? lv : -1;
    };
    const readLong = (lv) => {
      i += lv + 2;
      if (src[i] === '\r') { i++; if (src[i] === '\n') i++; line++; } else if (src[i] === '\n') { i++; if (src[i] === '\r') i++; line++; }
      const close = ']' + '='.repeat(lv) + ']';
      const end = src.indexOf(close, i);
      if (end < 0) err('unfinished long string');
      const s = src.slice(i, end);
      for (const c of s) if (c === '\n') line++;
      i = end + close.length;
      return s;
    };
    while (i < n) {
      const c = src[i];
      if (c === '\n') { line++; i++; continue; }
      if (c === ' ' || c === '\t' || c === '\r' || c === '\f' || c === '\v') { i++; continue; }
      if (c === '-' && src[i + 1] === '-') {
        i += 2;
        if (src[i] === '[') { const lv = longBracket(); if (lv >= 0) { readLong(lv); continue; } }
        while (i < n && src[i] !== '\n') i++;
        continue;
      }
      const tl = line;
      if (/[A-Za-z_]/.test(c)) {
        let j = i + 1; while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
        const w = src.slice(i, j); i = j;
        toks.push(KEYWORDS.has(w) ? { t: w, line: tl } : { t: 'name', v: w, line: tl });
        continue;
      }
      if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1]))) {
        let j = i;
        if (c === '0' && (src[i + 1] === 'x' || src[i + 1] === 'X')) { j += 2; while (j < n && /[0-9a-fA-F]/.test(src[j])) j++; }
        else {
          while (j < n && /[0-9.]/.test(src[j])) j++;
          if (src[j] === 'e' || src[j] === 'E') { j++; if (src[j] === '+' || src[j] === '-') j++; while (j < n && /[0-9]/.test(src[j])) j++; }
        }
        while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
        const s = src.slice(i, j), v = strToNum(s);
        if (v === undefined) err(`malformed number near '${s}'`);
        toks.push({ t: 'number', v, line: tl }); i = j;
        continue;
      }
      if (c === '"' || c === "'") {
        let j = i + 1, out = '';
        for (;;) {
          if (j >= n) err('unfinished string');
          const d = src[j];
          if (d === c) { j++; break; }
          if (d === '\n') err('unfinished string');
          if (d === '\\') {
            const e = src[j + 1];
            j += 2;
            switch (e) {
              case 'n': out += '\n'; break; case 't': out += '\t'; break; case 'r': out += '\r'; break; case 'a': out += '\x07'; break;
              case 'b': out += '\b'; break; case 'f': out += '\f'; break; case 'v': out += '\v'; break;
              case '\\': out += '\\'; break; case '"': out += '"'; break; case "'": out += "'"; break;
              case '\n': out += '\n'; line++; break;
              case '\r': out += '\n'; line++; if (src[j] === '\n') j++; break;
              default:
                if (/[0-9]/.test(e)) { let k = j - 1, num = ''; while (num.length < 3 && /[0-9]/.test(src[k])) num += src[k++]; j = k; const v = Number(num); if (v > 255) err('escape sequence too large'); out += String.fromCharCode(v); }
                else out += e; // Lua 5.1 keeps unknown escapes' character
            }
            continue;
          }
          out += d; j++;
        }
        toks.push({ t: 'string', v: out, line: tl }); i = j;
        continue;
      }
      if (c === '[') { const lv = longBracket(); if (lv >= 0) { const s = readLong(lv); toks.push({ t: 'string', v: s, line: tl }); continue; } }
      const three = src.substr(i, 3), two = src.substr(i, 2);
      if (three === '...') { toks.push({ t: '...', line: tl }); i += 3; continue; }
      if (['==', '~=', '<=', '>=', '..'].includes(two)) { toks.push({ t: two, line: tl }); i += 2; continue; }
      if ('+-*/%^#<>=(){}[];:,.'.includes(c)) { toks.push({ t: c, line: tl }); i++; continue; }
      err(`unexpected symbol near '${c}'`);
    }
    toks.push({ t: '<eof>', line });
    return toks;
  }

  // ---------------------------------------------------------------- parser (Lua 5.1 grammar) -> tree
  const BIN = { or: [1, 1], and: [2, 2], '<': [3, 3], '>': [3, 3], '<=': [3, 3], '>=': [3, 3], '~=': [3, 3], '==': [3, 3], '..': [5, 4], '+': [6, 6], '-': [6, 6], '*': [7, 7], '/': [7, 7], '%': [7, 7], '^': [10, 9] };
  const UNARY = 8;
  function parse(toks, name) {
    let p = 0;
    const peek = () => toks[p], next = () => toks[p++];
    const err = (m, tk = toks[p]) => { throw new LuaError(`${name}:${tk.line}: ${m} near '${tk.t === 'name' ? tk.v : tk.t === 'string' ? '"' + fromBytes(tk.v).slice(0, 20) + '"' : tk.t}'`, true); };
    const check = (t) => { if (toks[p].t !== t) err(`'${t}' expected`); return toks[p++]; };
    const test = (t) => { if (toks[p].t === t) { p++; return true; } return false; };
    const blockEnd = () => ['return', 'end', 'else', 'elseif', 'until', '<eof>'].includes(peek().t);
    function block() {
      const body = [];
      while (!blockEnd()) {
        const s = statement();
        if (s) body.push(s);
        test(';');
      }
      if (peek().t === 'return') {
        const line = next().line;
        const exps = blockEnd() || peek().t === ';' ? [] : exprList();
        test(';');
        body.push({ k: 'Return', exps, line });
      }
      return body;
    }
    function statement() {
      const tk = peek(), line = tk.line;
      switch (tk.t) {
        case ';': next(); return null;
        case 'if': {
          next(); const clauses = [];
          const c = expr(); check('then'); clauses.push([c, block()]);
          let els = null;
          for (;;) {
            if (test('elseif')) { const c2 = expr(); check('then'); clauses.push([c2, block()]); }
            else if (test('else')) { els = block(); check('end'); break; }
            else { check('end'); break; }
          }
          return { k: 'If', clauses, els, line };
        }
        case 'while': { next(); const c = expr(); check('do'); const b = block(); check('end'); return { k: 'While', c, b, line }; }
        case 'do': { next(); const b = block(); check('end'); return { k: 'Do', b, line }; }
        case 'for': {
          next();
          const n1 = check('name').v;
          if (test('=')) {
            const a = expr(); check(','); const b = expr(); const c = test(',') ? expr() : null;
            check('do'); const body = block(); check('end');
            return { k: 'NumFor', v: n1, a, b, c, body, line };
          }
          const names = [n1];
          while (test(',')) names.push(check('name').v);
          check('in'); const exps = exprList(); check('do'); const body = block(); check('end');
          return { k: 'GenFor', names, exps, body, line };
        }
        case 'repeat': { next(); const b = block(); check('until'); const c = expr(); return { k: 'Repeat', b, c, line }; }
        case 'function': {
          next();
          let target = { k: 'Name', v: check('name').v };
          let method = false;
          while (peek().t === '.' || peek().t === ':') {
            const sep = next().t;
            const key = { k: 'Str', v: check('name').v };
            target = { k: 'Index', o: target, key };
            if (sep === ':') { method = true; break; }
          }
          const f = funcBody(method, line);
          return { k: 'Assign', targets: [target], exps: [f], line };
        }
        case 'local': {
          next();
          if (test('function')) { const nm = check('name').v; const f = funcBody(false, line); return { k: 'LocalFunc', name: nm, f, line }; }
          const names = [check('name').v];
          while (test(',')) names.push(check('name').v);
          const exps = test('=') ? exprList() : [];
          return { k: 'Local', names, exps, line };
        }
        case 'return': err("'return' must be the last statement"); break;
        case 'break': next(); return { k: 'Break', line };
        default: {
          const e = suffixed();
          if (peek().t === '=' || peek().t === ',') {
            const targets = [e];
            while (test(',')) targets.push(suffixed());
            check('=');
            const exps = exprList();
            for (const t of targets) if (t.k !== 'Name' && t.k !== 'Index') err('syntax error');
            return { k: 'Assign', targets, exps, line };
          }
          if (e.k !== 'Call' && e.k !== 'Method') err('syntax error');
          return { k: 'CallStat', e, line };
        }
      }
      return null;
    }
    function funcBody(method, line) {
      check('(');
      const params = method ? ['self'] : [];
      let vararg = false;
      if (!test(')')) {
        do {
          if (test('...')) { vararg = true; break; }
          params.push(check('name').v);
        } while (test(','));
        check(')');
      }
      const body = block();
      check('end');
      return { k: 'Func', params, vararg, body, line };
    }
    function exprList() { const l = [expr()]; while (test(',')) l.push(expr()); return l; }
    function primary() {
      const tk = peek();
      if (tk.t === 'name') { next(); return { k: 'Name', v: tk.v, line: tk.line }; }
      if (tk.t === '(') { next(); const e = expr(); check(')'); return { k: 'Paren', e }; }
      err('unexpected symbol');
    }
    function callArgs() {
      const tk = peek();
      if (tk.t === 'string') { next(); return [{ k: 'Str', v: tk.v }]; }
      if (tk.t === '{') return [table()];
      check('(');
      if (test(')')) return [];
      const a = exprList(); check(')'); return a;
    }
    function suffixed() {
      let e = primary();
      for (;;) {
        const tk = peek();
        if (tk.t === '.') { next(); e = { k: 'Index', o: e, key: { k: 'Str', v: check('name').v }, line: tk.line }; }
        else if (tk.t === '[') { next(); const key = expr(); check(']'); e = { k: 'Index', o: e, key, line: tk.line }; }
        else if (tk.t === ':') { next(); const m = check('name').v; e = { k: 'Method', o: e, m, args: callArgs(), line: tk.line }; }
        else if (tk.t === '(' || tk.t === 'string' || tk.t === '{') { e = { k: 'Call', f: e, args: callArgs(), line: tk.line }; }
        else return e;
      }
    }
    function table() {
      check('{');
      const items = [];
      while (peek().t !== '}') {
        if (peek().t === '[') { next(); const key = expr(); check(']'); check('='); items.push({ key, v: expr() }); }
        else if (peek().t === 'name' && toks[p + 1].t === '=') { const key = { k: 'Str', v: next().v }; next(); items.push({ key, v: expr() }); }
        else items.push({ v: expr() });
        if (!test(',') && !test(';')) break;
      }
      check('}');
      return { k: 'Table', items };
    }
    function simple() {
      const tk = peek();
      switch (tk.t) {
        case 'number': next(); return { k: 'Num', v: tk.v };
        case 'string': next(); return { k: 'Str', v: tk.v };
        case 'nil': next(); return { k: 'Nil' };
        case 'true': next(); return { k: 'True' };
        case 'false': next(); return { k: 'False' };
        case '...': next(); return { k: 'Vararg' };
        case '{': return table();
        case 'function': next(); return funcBody(false, tk.line);
        default: return suffixed();
      }
    }
    function expr(limit = 0) {
      let e;
      const tk = peek();
      if (tk.t === 'not' || tk.t === '-' || tk.t === '#') { next(); e = { k: 'Unop', op: tk.t, e: expr(UNARY), line: tk.line }; }
      else e = simple();
      for (;;) {
        const op = peek().t, pr = BIN[op];
        if (!pr || pr[0] <= limit) return e;
        const line = next().line;
        e = { k: 'Binop', op, a: e, b: expr(pr[1]), line };
      }
    }
    const body = block();
    if (peek().t !== '<eof>') err("'<eof>' expected");
    return body;
  }

  // ---------------------------------------------------------------- tree -> JavaScript source
  function compileChunk(tree, chunkId) {
    let uid = 0;
    const out = [];
    const fresh = (base) => `${base.replace(/[^A-Za-z0-9_]/g, '_')}$${++uid}`;
    // scopes: arrays of maps name -> js name; fn: { temps, vararg }
    function gen(body, scope, fn, ind) {
      const lines = [];
      const emit = (s) => lines.push(ind + s);
      const lookup = (name) => { for (let i = scope.length - 1; i >= 0; i--) if (scope[i].has(name)) return scope[i].get(name); return null; };
      const temp = () => { const t = `t$${++uid}`; fn.temps.push(t); return t; };
      const S = (s) => JSON.stringify(s);
      // an expression that gives one value
      function ex(e) {
        switch (e.k) {
          case 'Nil': return 'undefined';
          case 'True': return 'true';
          case 'False': return 'false';
          case 'Num': return Object.is(e.v, -0) ? '-0' : e.v === Infinity ? 'Infinity' : String(e.v);
          case 'Str': return S(e.v);
          case 'Vararg': return 'VA[0]';
          case 'Func': return func(e);
          case 'Name': { const l = lookup(e.v); return l || `R.idx(ENV,${S(e.v)})`; }
          case 'Index': return `R.idx(${ex(e.o)},${ex(e.key)})`;
          case 'Call': case 'Method': return `R.first(${multi(e)})`;
          case 'Paren': return ex(e.e);
          case 'Table': {
            const pos = [], kv = [];
            e.items.forEach((it, i) => {
              if (it.key) kv.push(ex(it.key), ex(it.v));
              else if (i === e.items.length - 1 && (it.v.k === 'Call' || it.v.k === 'Method' || it.v.k === 'Vararg')) pos.push('...' + multi(it.v));
              else pos.push(ex(it.v));
            });
            return `R.tbl(${pos.length ? '[' + pos.join(',') + ']' : 'null'},${kv.length ? '[' + kv.join(',') + ']' : 'null'})`;
          }
          case 'Unop':
            if (e.op === 'not') return `!R.T(${ex(e.e)})`;
            if (e.op === '-') { if (e.e.k === 'Num') return String(-e.e.v); return `R.unm(${ex(e.e)})`; }
            return `R.len(${ex(e.e)})`;
          case 'Binop': {
            const a = ex(e.a), b = ex(e.b);
            switch (e.op) {
              case 'and': { const t = temp(); return `(R.T(${t}=${a})?${b}:${t})`; }
              case 'or': { const t = temp(); return `(R.T(${t}=${a})?${t}:${b})`; }
              case '+': return `R.add(${a},${b})`; case '-': return `R.sub(${a},${b})`; case '*': return `R.mul(${a},${b})`;
              case '/': return `R.div(${a},${b})`; case '%': return `R.mod(${a},${b})`; case '^': return `R.pow(${a},${b})`;
              case '..': return `R.concat(${a},${b})`;
              case '==': return `R.eq(${a},${b})`; case '~=': return `!R.eq(${a},${b})`;
              case '<': return `R.lt(${a},${b})`; case '<=': return `R.le(${a},${b})`;
              case '>': return `R.lt(${b},${a})`; case '>=': return `R.le(${b},${a})`;
            }
          }
        }
        throw new Error('cannot compile ' + e.k);
      }
      // an expression that may give several values: a JS array
      function multi(e) {
        if (e.k === 'Vararg') return 'VA';
        if (e.k === 'Call') {
          const nm = e.f.k === 'Name' ? (lookup(e.f.v) ? `local '${e.f.v}'` : `global '${e.f.v}'`) : e.f.k === 'Index' && e.f.key.k === 'Str' ? `field '${e.f.key.v}'` : '';
          return nm ? `R.callf(${ex(e.f)},${S(fromBytes(nm))}${args(e.args)})` : `R.call(${ex(e.f)}${args(e.args)})`;
        }
        if (e.k === 'Method') return `R.callm(${ex(e.o)},${S(e.m)}${args(e.args)})`;
        return `[${ex(e)}]`;
      }
      function args(list) {
        if (!list.length) return '';
        return ',' + list.map((a, i) => (i === list.length - 1 && (a.k === 'Call' || a.k === 'Method' || a.k === 'Vararg') ? '...' + multi(a) : ex(a))).join(',');
      }
      // the values of an expression list as a JS array (multi at the end spreads)
      function list(exps) {
        if (!exps.length) return 'R.EMPTY';
        if (exps.length === 1 && (exps[0].k === 'Call' || exps[0].k === 'Method' || exps[0].k === 'Vararg')) return multi(exps[0]);
        return '[' + args(exps).slice(1) + ']';
      }
      function func(f) {
        const sc = new Map();
        const ps = f.params.map((pn) => { const j = fresh(pn); sc.set(pn, j); return j; });
        const fnInfo = { temps: [], vararg: f.vararg };
        const inner = gen(f.body, [...scope, sc], fnInfo, ind + '  ');
        const head = f.vararg ? `(${ps.join(',')}${ps.length ? ',' : ''}...VA)` : `(${ps.join(',')})`;
        return `(function${head}{${fnInfo.temps.length ? 'let ' + fnInfo.temps.join(',') + ';' : ''}\n${inner}\n${ind}return R.EMPTY;})`;
      }
      function assignTo(t, v) {
        if (t.k === 'Name') { const l = lookup(t.v); return l ? `${l}=${v};` : `R.setidx(ENV,${S(t.v)},${v});`; }
        return `R.setidx(${ex(t.o)},${ex(t.key)},${v});`;
      }
      const P = (line) => `R.p=${chunkId * 1e6 + (line || 0)};`;
      for (const s of body) {
        switch (s.k) {
          case 'Local': {
            if (s.exps.length === 1 && s.names.length === 1 && s.exps[0].k !== 'Vararg') {
              const v = ex(s.exps[0]);
              const j = fresh(s.names[0]); emit(`${P(s.line)}let ${j}=${v};`); scope[scope.length - 1].set(s.names[0], j);
            } else if (s.exps.length === 0) {
              const js = s.names.map((nm) => fresh(nm));
              emit(`let ${js.join(',')};`);
              s.names.forEach((nm, i) => scope[scope.length - 1].set(nm, js[i]));
            } else {
              const t = temp();
              emit(`${P(s.line)}${t}=${list(s.exps)};`);
              const js = s.names.map((nm) => fresh(nm));
              emit(`let ${js.map((j, i) => `${j}=${t}[${i}]`).join(',')};`);
              s.names.forEach((nm, i) => scope[scope.length - 1].set(nm, js[i]));
            }
            break;
          }
          case 'LocalFunc': {
            const j = fresh(s.name); scope[scope.length - 1].set(s.name, j);
            emit(`let ${j};${j}=${func(s.f)};`);
            break;
          }
          case 'Assign': {
            if (s.targets.length === 1 && s.exps.length === 1) { emit(P(s.line) + assignTo(s.targets[0], ex(s.exps[0]))); break; }
            const t = temp();
            // evaluate the targets' objects and keys first, then the values, then assign
            const pre = s.targets.map((tg) => (tg.k === 'Index' ? [temp(), temp()] : null));
            emit(P(s.line) + s.targets.map((tg, i) => (pre[i] ? `${pre[i][0]}=${ex(tg.o)};${pre[i][1]}=${ex(tg.key)};` : '')).join(''));
            emit(`${t}=${list(s.exps)};`);
            emit(s.targets.map((tg, i) => (pre[i] ? `R.setidx(${pre[i][0]},${pre[i][1]},${t}[${i}]);` : assignTo(tg, `${t}[${i}]`))).join(''));
            break;
          }
          case 'CallStat': {
            const c = s.e;
            // module(name, ...) changes this chunk's globals (Lua 5.1 setfenv on the calling function)
            if (c.k === 'Call' && c.f.k === 'Name' && c.f.v === 'module' && !lookup('module')) { emit(`${P(s.line)}ENV=R.module(ENV${args(c.args)});`); break; }
            emit(`${P(s.line)}${multi(c)};`);
            break;
          }
          case 'Do': emit('{'); lines.push(gen(s.b, [...scope, new Map()], fn, ind + '  ')); emit('}'); break;
          case 'While': emit(`${P(s.line)}while(R.T(${ex(s.c)})){`); lines.push(gen(s.b, [...scope, new Map()], fn, ind + '  ')); emit('}'); break;
          case 'Repeat': {
            const sc = new Map();
            emit(`${P(s.line)}do{`);
            lines.push(gen(s.b, [...scope, sc], fn, ind + '  '));
            const sc2 = [...scope, sc];
            // `until` sees the body's locals
            const saved = scope; scope = sc2; const c = ex(s.c); scope = saved;
            emit(`if(R.T(${c}))break;}while(true);`);
            break;
          }
          case 'If': {
            s.clauses.forEach(([c, b], i) => {
              emit(`${i === 0 ? P(s.line) + 'if' : '}else if'}(R.T(${ex(c)})){`);
              lines.push(gen(b, [...scope, new Map()], fn, ind + '  '));
            });
            if (s.els) { emit('}else{'); lines.push(gen(s.els, [...scope, new Map()], fn, ind + '  ')); }
            emit('}');
            break;
          }
          case 'NumFor': {
            const f = temp(), i = temp();
            emit(`${P(s.line)}${f}=R.forPrep(${ex(s.a)},${ex(s.b)},${s.c ? ex(s.c) : '1'});`);
            emit(`for(${i}=${f}[0];${f}[2]>0?${i}<=${f}[1]:${i}>=${f}[1];${i}+=${f}[2]){`);
            const sc = new Map(); const j = fresh(s.v); sc.set(s.v, j);
            emit(`  let ${j}=${i};`);
            lines.push(gen(s.body, [...scope, sc], fn, ind + '  '));
            emit('}');
            break;
          }
          case 'GenFor': {
            const st = temp(), f = temp(), sv = temp(), cv = temp(), r = temp();
            emit(`${P(s.line)}${st}=${list(s.exps)};${f}=${st}[0];${sv}=${st}[1];${cv}=${st}[2];`);
            emit(`for(;;){${r}=R.call(${f},${sv},${cv});if(${r}[0]===undefined||${r}[0]===null)break;${cv}=${r}[0];`);
            const sc = new Map(); const js = s.names.map((nm) => { const j = fresh(nm); sc.set(nm, j); return j; });
            emit(`  let ${js.map((j, k) => `${j}=${r}[${k}]`).join(',')};`);
            lines.push(gen(s.body, [...scope, sc], fn, ind + '  '));
            emit('}');
            break;
          }
          case 'Return': {
            if (s.exps.length === 1 && (s.exps[0].k === 'Call' || s.exps[0].k === 'Method')) { emit(`${P(s.line)}return ${multi(s.exps[0])};`); break; }
            emit(`${P(s.line)}return ${list(s.exps)};`);
            break;
          }
          case 'Break': emit('break;'); break;
          default: throw new Error('cannot compile ' + s.k);
        }
      }
      return lines.join('\n');
    }
    const fn = { temps: [], vararg: true };
    const body = gen(tree, [new Map()], fn, '  ');
    out.push(`return function(...VA){${fn.temps.length ? 'let ' + fn.temps.join(',') + ';' : ''}\n${body}\n  return R.EMPTY;};`);
    return out.join('\n');
  }

  // ---------------------------------------------------------------- a Lua state
  function compile(src, name) {
    const id = R.chunks.length; R.chunks.push(name);
    const js = compileChunk(parse(lex(src, name), name), id);
    return { js, id };
  }

  class State {
    constructor(opts = {}) {
      this.G = new LuaTable();
      this.files = opts.files || ((path) => undefined); // path -> byte-string source or undefined
      this.print = opts.print || ((s) => console.log(s));
      this.cache = new Map(); // compiled JS per chunk name
      openLibs(this);
    }
    // load(source, name) -> a Lua function (like loadstring)
    load(src, name = '=(load)', env) {
      let c = this.cache.get(name + '\0' + src.length);
      if (!c || c.src !== src) {
        const { js } = compile(src, name);
        c = { src, factory: new Function('R', 'ENV', js) };
        if (!name.startsWith('=(load')) this.cache.set(name + '\0' + src.length, c);
      }
      return c.factory(R, env || this.G);
    }
    // run a file by name (require uses this)
    dofile(path) {
      const src = this.files(path);
      if (src === undefined) throw new LuaError(`cannot open ${path}`);
      return call(this.load(src, path));
    }
    get(name) { return this.G.get(toBytes(name)); }
    set(name, v) { this.G.set(toBytes(name), v); }
    callGlobal(name, ...a) { return call(this.get(name), ...a); }
  }

  // ---------------------------------------------------------------- the standard library
  function openLibs(S) {
    const G = S.G;
    const lib = (t, name, fns) => { const tb = t || new LuaTable(); for (const [k, f] of Object.entries(fns)) tb.set(k, f); if (name) G.set(name, tb); return tb; };
    const str = (v) => tostring(v);
    function tostring(v) {
      const h = metaOf(v, '__tostring');
      if (h !== undefined) return first(call(h, v));
      switch (typeOf(v)) {
        case 'nil': return 'nil';
        case 'boolean': return v ? 'true' : 'false';
        case 'number': return numToStr(v);
        case 'string': return v;
        case 'table': if (!v.id) v.id = nextId++; return 'table: 0x' + (0x8000000 + v.id * 32).toString(16).padStart(8, '0');
        case 'function': if (!v.luaId) v.luaId = nextId++; return 'function: 0x' + (0x9000000 + v.luaId * 32).toString(16).padStart(8, '0');
        default: if (!v.luaId) v.luaId = nextId++; return 'userdata: 0x' + (0xa000000 + v.luaId * 32).toString(16).padStart(8, '0');
      }
    }
    R.tostring = tostring;
    const argErr = (n, fname, msg) => new LuaError(`bad argument #${n} to '${fname}' (${msg})`);
    const checkTable = (t, n, fname) => { if (!(t instanceof LuaTable)) throw argErr(n, fname, `table expected, got ${typeOf(t) === 'nil' ? 'no value' : typeOf(t)}`); return t; };
    const checkNum = (v, n, fname) => { const x = tonum(v); if (x === undefined) throw argErr(n, fname, `number expected, got ${typeOf(v) === 'nil' ? 'no value' : typeOf(v)}`); return x; };
    const checkStr = (v, n, fname) => { if (typeof v === 'string') return v; if (typeof v === 'number') return numToStr(v); throw argErr(n, fname, `string expected, got ${typeOf(v) === 'nil' ? 'no value' : typeOf(v)}`); };
    // iteration in insertion order: the array part, then the hash part
    function nextKey(t, k) {
      const a = t.arr;
      let i = 0;
      if (k !== undefined && k !== null) {
        if (typeof k === 'number' && (k | 0) === k && k >= 1 && k <= a.length) i = k;
        else {
          let found = false;
          for (const [hk, hv] of t.hash) { if (found) return [hk, hv]; if (hk === k || (hk !== hk && k !== k)) found = true; }
          if (!found) throw new LuaError("invalid key to 'next'");
          return [undefined];
        }
      }
      for (; i < a.length; i++) if (a[i] !== undefined) return [i + 1, a[i]];
      for (const [hk, hv] of t.hash) return [hk, hv];
      return [undefined];
    }
    const next = (t, k) => nextKey(checkTable(t, 1, 'next'), k);
    function pairsIter(t) { // a fast iterator that does not search for the last key every step
      let i = 0, it = null;
      return () => {
        const a = t.arr;
        while (i < a.length) { const v = a[i++]; if (v !== undefined) return [i, v]; }
        if (!it) it = t.hash.entries();
        for (;;) { const r = it.next(); if (r.done) return [undefined]; if (r.value[1] !== undefined && t.hash.has(r.value[0])) return r.value; }
      };
    }
    lib(G, null, {
      print: (...a) => { S.print(fromBytes(a.map(str).join('\t'))); return EMPTY; },
      type: (...a) => { if (!a.length) throw argErr(1, 'type', 'value expected'); return [typeOf(a[0])]; },
      tostring: (v) => [tostring(v)],
      tonumber: (v, base) => { if (base === undefined) return [tonum(v)]; return [strToNum(checkStr(v, 1, 'tonumber'), checkNum(base, 2, 'tonumber'))]; },
      rawget: (t, k) => [checkTable(t, 1, 'rawget').get(k)],
      rawset: (t, k, v) => { checkTable(t, 1, 'rawset').set(k, v); return [t]; },
      rawequal: (a, b) => [a === b],
      setmetatable: (t, m) => { checkTable(t, 1, 'setmetatable'); if (m !== undefined && !(m instanceof LuaTable)) throw argErr(2, 'setmetatable', 'nil or table expected'); t.mt = m; return [t]; },
      getmetatable: (v) => { const m = getmeta(v); if (m && m.get('__metatable') !== undefined) return [m.get('__metatable')]; return [m]; },
      next,
      pairs: (t) => { checkTable(t, 1, 'pairs'); return [pairsIter(t), t, undefined]; },
      ipairs: (t) => { if (t === undefined) throw argErr(1, 'ipairs', 'table expected, got no value'); return [(tt, i) => { const v = idx(tt, i + 1); return v === undefined ? [undefined] : [i + 1, v]; }, t, 0]; },
      select: (n, ...a) => { if (n === '#') return [a.length]; const i = checkNum(n, 1, 'select'); if (i < 0) return a.slice(a.length + i); if (i < 1) throw argErr(1, 'select', 'index out of range'); return a.slice(i - 1); },
      unpack: (t, i, j) => { checkTable(t, 1, 'unpack'); i = i === undefined ? 1 : checkNum(i); j = j === undefined ? t.len() : checkNum(j); const r = []; for (let k = i; k <= j; k++) r.push(t.get(k)); return r; },
      error: (msg, level) => {
        if (typeof msg === 'string' && (level === undefined || level > 0)) msg = R.where() + ': ' + msg;
        throw new LuaError(msg, true);
      },
      assert: (v, msg, ...rest) => { if (!T(v)) throw new LuaError(msg === undefined ? 'assertion failed!' : msg, msg !== undefined); return [v, msg, ...rest]; },
      pcall: (f, ...a) => {
        try { return [true, ...call(f, ...a)]; } catch (e) { return [false, errValue(e)]; }
      },
      xpcall: (f, h) => {
        try { return [true, ...call(f)]; } catch (e) { return [false, ...call(h, errValue(e))]; }
      },
      loadstring: (s, chunk) => { try { return [S.load(checkStr(s, 1, 'loadstring'), chunk ? '=(load)' + chunk : '=(load)')]; } catch (e) { return [undefined, errValue(e)]; } },
      load: (f, chunk) => {
        let s = '';
        if (typeof f === 'string') s = f;
        else for (;;) { const piece = first(call(f)); if (piece === undefined || piece === '') break; s += piece; }
        try { return [S.load(s, '=(load)' + (chunk || ''))]; } catch (e) { return [undefined, errValue(e)]; }
      },
      dofile: (path) => S.dofile(checkStr(path, 1, 'dofile')),
      collectgarbage: () => [0],
      gcinfo: () => [0],
    });
    G.set('_G', G);
    G.set('_VERSION', 'Lua 5.1');
    function errValue(e) {
      if (e instanceof LuaError) return e.value;
      if (e instanceof RangeError) return toBytes(R.where() + ': stack overflow');
      return toBytes(R.where() + ': ' + (e && e.message ? e.message : String(e)));
    }
    R.errValue = errValue;

    // package / require / module
    const pkg = lib(null, 'package', {});
    const loaded = new LuaTable(); pkg.set('loaded', loaded); pkg.set('preload', new LuaTable());
    pkg.set('path', '?.lua;script/?.lua');
    loaded.set('_G', G);
    pkg.set('seeall', (m) => { checkTable(m, 1, 'seeall'); const mt = m.mt || (m.mt = new LuaTable()); mt.set('__index', G); return EMPTY; });
    const findPath = (name) => {
      const p = String(fromBytes(name)).replace(/\./g, '/');
      for (const pat of String(pkg.get('path')).split(';')) { const f = pat.replace('?', p); if (S.files(f) !== undefined) return f; }
      return null;
    };
    G.set('require', (name) => {
      name = checkStr(name, 1, 'require');
      const have = loaded.get(name);
      if (have !== undefined) return [have];
      const pre = pkg.get('preload').get(name);
      let f;
      if (pre !== undefined) f = pre;
      else {
        const path = findPath(name);
        if (!path) throw new LuaError(`module '${fromBytes(name)}' not found`);
        f = S.load(S.files(path), path);
      }
      loaded.set(name, true); // guards loops, like Lua's sentinel
      const r = first(call(f, name));
      if (r !== undefined) loaded.set(name, r);
      if (loaded.get(name) === true && r === undefined) loaded.set(name, true);
      return [loaded.get(name)];
    });
    R.module = (env, name, ...opts) => {
      name = checkStr(name, 1, 'module');
      let m = loaded.get(name);
      if (!(m instanceof LuaTable)) {
        // find or make the table along a.b.c in _G
        m = G;
        for (const part of name.split('.')) { let t = m.get(part); if (t === undefined) { t = new LuaTable(); m.set(part, t); } m = t; }
        loaded.set(name, m);
      }
      if (m.get('_NAME') === undefined) { m.set('_M', m); m.set('_NAME', name); m.set('_PACKAGE', name.includes('.') ? name.replace(/[^.]*$/, '') : ''); }
      for (const o of opts) call(o, m);
      return m;
    };
    G.set('module', (name, ...opts) => { R.module(G, name, ...opts); return EMPTY; }); // called indirectly: no chunk to change

    // string
    const string = lib(null, 'string', {
      len: (s) => [checkStr(s, 1, 'len').length],
      sub: (s, i, j) => {
        s = checkStr(s, 1, 'sub'); const l = s.length;
        i = i === undefined ? 1 : checkNum(i, 2, 'sub'); j = j === undefined ? -1 : checkNum(j, 3, 'sub');
        i = Math.trunc(i); j = Math.trunc(j);
        if (i < 0) i = Math.max(l + i + 1, 1); else if (i === 0) i = 1;
        if (j < 0) j = l + j + 1; else if (j > l) j = l;
        return [i > j ? '' : s.slice(i - 1, j)];
      },
      upper: (s) => [checkStr(s, 1, 'upper').replace(/[a-z]/g, (c) => c.toUpperCase())],
      lower: (s) => [checkStr(s, 1, 'lower').replace(/[A-Z]/g, (c) => c.toLowerCase())],
      rep: (s, n) => [checkStr(s, 1, 'rep').repeat(Math.max(0, Math.trunc(checkNum(n, 2, 'rep'))))],
      reverse: (s) => [checkStr(s, 1, 'reverse').split('').reverse().join('')],
      byte: (s, i, j) => {
        s = checkStr(s, 1, 'byte'); const l = s.length;
        i = i === undefined ? 1 : Math.trunc(checkNum(i)); j = j === undefined ? i : Math.trunc(checkNum(j));
        if (i < 0) i = l + i + 1; if (j < 0) j = l + j + 1; if (i < 1) i = 1; if (j > l) j = l;
        const r = []; for (let k = i; k <= j; k++) r.push(s.charCodeAt(k - 1)); return r;
      },
      char: (...a) => [String.fromCharCode(...a.map((c, k) => { const x = checkNum(c, k + 1, 'char'); if (x < 0 || x > 255) throw argErr(k + 1, 'char', 'invalid value'); return x; }))],
      format: (fmt, ...a) => [format(checkStr(fmt, 1, 'format'), a)],
      find: (s, p, init, plain) => find(checkStr(s, 1, 'find'), checkStr(p, 2, 'find'), init, plain, true),
      match: (s, p, init) => find(checkStr(s, 1, 'match'), checkStr(p, 2, 'match'), init, false, false),
      gmatch: (s, p) => {
        s = checkStr(s, 1, 'gmatch'); p = checkStr(p, 2, 'gmatch');
        let pos = 0;
        return [() => {
          while (pos <= s.length) {
            const m = matchAt(s, p, pos);
            if (m) { pos = m.end > pos ? m.end : pos + 1; return m.caps.length ? m.caps : [s.slice(m.start, m.end)]; }
            pos++;
          }
          return [undefined];
        }];
      },
      gsub: (s, p, repl, max) => {
        s = checkStr(s, 1, 'gsub'); p = checkStr(p, 2, 'gsub');
        const lim = max === undefined ? Infinity : checkNum(max, 4, 'gsub');
        let out = '', pos = 0, n = 0;
        const anchor = p[0] === '^';
        while (n < lim) {
          const m = matchAt(s, p, pos);
          if (m) {
            n++;
            const whole = s.slice(m.start, m.end), caps = m.caps.length ? m.caps : [whole];
            let r;
            if (typeof repl === 'string' || typeof repl === 'number') {
              r = String(typeof repl === 'number' ? numToStr(repl) : repl).replace(/%([0-9%])/g, (all, d) => (d === '%' ? '%' : d === '0' ? whole : (caps[Number(d) - 1] === undefined ? (() => { throw new LuaError('invalid capture index'); })() : typeof caps[Number(d) - 1] === 'number' ? numToStr(caps[Number(d) - 1]) : caps[Number(d) - 1])));
            } else if (repl instanceof LuaTable) r = idx(repl, caps[0]);
            else r = first(call(repl, ...caps));
            if (r === undefined || r === false) r = whole;
            else if (typeof r === 'number') r = numToStr(r);
            else if (typeof r !== 'string') throw new LuaError('invalid replacement value (a ' + typeOf(r) + ')');
            out += s.slice(pos, m.start) + r;
            if (m.end > pos) pos = m.end;
            else { if (pos < s.length) out += s[pos]; pos++; }
          } else { if (pos < s.length) out += s[pos]; pos++; }
          if (pos > s.length || anchor) break;
        }
        if (pos < s.length) out += s.slice(pos);
        return [out, n];
      },
    });
    const smt = new LuaTable(); smt.set('__index', string); R.stringMeta = smt;

    // Lua patterns (lstrlib.c), on byte strings
    const isClass = (cl, c) => {
      const code = c.charCodeAt(0);
      let r;
      switch (cl.toLowerCase()) {
        case 'a': r = /[A-Za-z]/.test(c); break;
        case 'c': r = code < 32 || code === 127; break;
        case 'd': r = code >= 48 && code <= 57; break;
        case 'l': r = code >= 97 && code <= 122; break;
        case 'p': r = /[!-\/:-@\[-`{-~]/.test(c); break;
        case 's': r = c === ' ' || (code >= 9 && code <= 13); break;
        case 'u': r = code >= 65 && code <= 90; break;
        case 'w': r = /[A-Za-z0-9]/.test(c); break;
        case 'x': r = /[0-9A-Fa-f]/.test(c); break;
        case 'z': r = code === 0; break;
        default: return cl === c;
      }
      return cl === cl.toUpperCase() && /[A-Z]/.test(cl) ? !r : r;
    };
    function classEnd(p, i) {
      if (i >= p.length) throw new LuaError('malformed pattern (ends with \'%\')');
      const c = p[i++];
      if (c === '%') { if (i >= p.length) throw new LuaError("malformed pattern (ends with '%')"); return i + 1; }
      if (c === '[') {
        if (p[i] === '^') i++;
        do { if (i >= p.length) throw new LuaError("malformed pattern (missing ']')"); const cc = p[i++]; if (cc === '%') i++; } while (p[i] !== ']');
        return i + 1;
      }
      return i;
    }
    function matchBracket(c, p, pi, ep) { // p[pi] = '[', ep = index of ']'
      let sig = true; pi++;
      if (p[pi] === '^') { sig = false; pi++; }
      while (pi < ep) {
        if (p[pi] === '%') { pi++; if (isClass(p[pi], c)) return sig; pi++; }
        else if (p[pi + 1] === '-' && pi + 2 < ep) { if (p[pi] <= c && c <= p[pi + 2]) return sig; pi += 3; }
        else { if (p[pi] === c) return sig; pi++; }
      }
      return !sig;
    }
    function singleMatch(s, si, p, pi, ep) {
      if (si >= s.length) return false;
      const c = s[si];
      switch (p[pi]) {
        case '.': return true;
        case '%': return isClass(p[pi + 1], c);
        case '[': return matchBracket(c, p, pi, ep - 1);
        default: return p[pi] === c;
      }
    }
    function doMatch(ms, si, pi) {
      const s = ms.s, p = ms.p;
      for (;;) {
        if (pi >= p.length) return si;
        switch (p[pi]) {
          case '(':
            if (p[pi + 1] === ')') { ms.caps.push({ start: si, len: -2 }); const r = doMatch(ms, si, pi + 2); if (r === -1) ms.caps.pop(); return r; }
            ms.caps.push({ start: si, len: -1 });
            { const r = doMatch(ms, si, pi + 1); if (r === -1) ms.caps.pop(); return r; }
          case ')': {
            let l = ms.caps.length - 1; while (l >= 0 && ms.caps[l].len !== -1) l--;
            if (l < 0) throw new LuaError('invalid pattern capture');
            ms.caps[l].len = si - ms.caps[l].start;
            const r = doMatch(ms, si, pi + 1);
            if (r === -1) ms.caps[l].len = -1;
            return r;
          }
          case '$':
            if (pi + 1 === p.length) return si === s.length ? si : -1;
            break;
          case '%': {
            const nx = p[pi + 1];
            if (nx === 'b') {
              if (si >= s.length || s[si] !== p[pi + 2]) return -1;
              const b = p[pi + 2], e = p[pi + 3]; let cont = 1, k = si + 1;
              while (k < s.length) { const ch = s[k]; if (ch === e) { if (--cont === 0) break; } else if (ch === b) cont++; k++; }
              if (k >= s.length) return -1;
              si = k + 1; pi += 4; continue;
            }
            if (nx === 'f') {
              pi += 2; const ep = classEnd(p, pi);
              const prev = si === 0 ? '\0' : s[si - 1], cur = si < s.length ? s[si] : '\0';
              if (!matchBracket(prev, p, pi, ep - 1) && matchBracket(cur, p, pi, ep - 1)) { pi = ep; continue; }
              return -1;
            }
            if (/[0-9]/.test(nx)) {
              const c = ms.caps[Number(nx) - 1];
              if (!c || c.len < 0) throw new LuaError('invalid capture index');
              const cap = s.substr(c.start, c.len);
              if (s.startsWith(cap, si)) { si += cap.length; pi += 2; continue; }
              return -1;
            }
            break;
          }
        }
        const ep = classEnd(p, pi);
        const m = singleMatch(s, si, p, pi, ep);
        const op = p[ep];
        if (op === '?') { if (m) { const r = doMatch(ms, si + 1, ep + 1); if (r !== -1) return r; } pi = ep + 1; continue; }
        if (op === '*' || op === '+') {
          let k = 0;
          while (singleMatch(s, si + k, p, pi, ep)) k++;
          if (op === '+' && k === 0) return -1;
          while (k >= (op === '+' ? 1 : 0)) { const r = doMatch(ms, si + k, ep + 1); if (r !== -1) return r; k--; }
          return -1;
        }
        if (op === '-') {
          for (;;) { const r = doMatch(ms, si, ep + 1); if (r !== -1) return r; if (singleMatch(s, si, p, pi, ep)) si++; else return -1; }
        }
        if (!m) return -1;
        si++; pi = ep;
      }
    }
    function matchAt(s, p, init) { // first match at or after init: { start, end, caps }
      const anchor = p[0] === '^';
      const pat = anchor ? p.slice(1) : p;
      for (let i = init; i <= s.length; i++) {
        const ms = { s, p: pat, caps: [] };
        const e = doMatch(ms, i, 0);
        if (e !== -1) return { start: i, end: e, caps: ms.caps.map((c) => (c.len === -2 ? c.start + 1 : s.substr(c.start, c.len))) };
        if (anchor) break;
      }
      return null;
    }
    function find(s, p, init, plain, isFind) {
      let i = init === undefined ? 1 : Math.trunc(checkNum(init));
      if (i < 0) i = Math.max(s.length + i + 1, 1); else if (i === 0) i = 1;
      if (i > s.length + 1) return [undefined];
      if (isFind && (T(plain) || !/[\^$*+?.()[\]%-]/.test(p))) {
        const k = s.indexOf(p, i - 1);
        return k < 0 ? [undefined] : [k + 1, k + p.length];
      }
      const m = matchAt(s, p, i - 1);
      if (!m) return [undefined];
      if (isFind) return [m.start + 1, m.end, ...m.caps];
      return m.caps.length ? m.caps : [s.slice(m.start, m.end)];
    }
    function toFixedC(x, p) { // like C printf: an exact half rounds to the even digit (2.25 -> 2.2), JavaScript rounds it up
      const k = Math.pow(10, p), y = x * k;
      if (Number.isFinite(y) && Math.abs(y) < 1e15 && Math.abs(y % 1) === 0.5 && y / k === x) { const f = Math.floor(y), r = f % 2 === 0 ? f : f + 1; return (r / k).toFixed(p); }
      return x.toFixed(p);
    }
    function format(fmt, a) {
      let out = '', ai = 0;
      for (let i = 0; i < fmt.length; i++) {
        const c = fmt[i];
        if (c !== '%') { out += c; continue; }
        if (fmt[i + 1] === '%') { out += '%'; i++; continue; }
        const m = /^%([-+ #0]*)(\d*)(?:\.(\d*))?([diouxXeEfgGqsc])/.exec(fmt.slice(i));
        if (!m) throw new LuaError(`invalid option '${fmt.slice(i, i + 2)}' to 'format'`);
        i += m[0].length - 1;
        const [, flags, width, prec, conv] = m;
        const v = a[ai++];
        let s;
        const n = () => checkNum(v, ai + 1, 'format');
        switch (conv) {
          case 'd': case 'i': { let x = Math.trunc(n()); s = String(Math.abs(x)); if (prec !== undefined) s = s.padStart(Number(prec), '0'); s = (x < 0 ? '-' : flags.includes('+') ? '+' : flags.includes(' ') ? ' ' : '') + s; break; }
          case 'u': s = String(Math.trunc(n()) >>> 0); break;
          case 'o': s = (Math.trunc(n()) >>> 0).toString(8); break;
          case 'x': s = (Math.trunc(n()) >>> 0).toString(16); if (flags.includes('#') && s !== '0') s = '0x' + s; break;
          case 'X': s = (Math.trunc(n()) >>> 0).toString(16).toUpperCase(); if (flags.includes('#') && s !== '0') s = '0X' + s; break;
          case 'c': s = String.fromCharCode(n()); break;
          case 'f': case 'e': case 'E': {
            const x = n(), p2 = prec === undefined ? 6 : Number(prec || 0);
            if (!isFinite(x)) s = x !== x ? 'nan' : x > 0 ? 'inf' : '-inf';
            else if (conv === 'f') s = toFixedC(x, p2);
            else { s = x.toExponential(p2).replace(/e([+-])(\d)$/, 'e$10$2'); if (conv === 'E') s = s.toUpperCase(); }
            if (x >= 0 && flags.includes('+')) s = '+' + s; else if (x >= 0 && flags.includes(' ')) s = ' ' + s;
            break;
          }
          case 'g': case 'G': { const x = n(); s = fmtG(x, prec === undefined ? 6 : Math.max(1, Number(prec || 0))); if (conv === 'G') s = s.toUpperCase(); if (x >= 0 && flags.includes('+')) s = '+' + s; break; }
          case 'q': { const t = checkStr(v, ai, 'format'); s = '"' + t.replace(/[\\"\n\r\0]/g, (ch) => (ch === '\n' ? '\\\n' : ch === '\r' ? '\\r' : ch === '\0' ? '\\000' : '\\' + ch)) + '"'; break; }
          case 's': { s = typeof v === 'string' ? v : tostring(v); if (v === undefined && ai > a.length) throw argErr(ai, 'format', 'string expected, got no value'); if (prec !== undefined) s = s.slice(0, Number(prec)); break; }
        }
        const w = Number(width || 0);
        if (s.length < w) {
          if (flags.includes('-')) s = s.padEnd(w);
          else if (flags.includes('0') && /[diouxXeEfgG]/.test(conv)) { const neg = /^[-+ ]/.test(s) ? s[0] : ''; s = neg + s.slice(neg.length).padStart(w - neg.length, '0'); }
          else s = s.padStart(w);
        }
        out += s;
      }
      return out;
    }
    R.format = format;

    // table
    lib(null, 'table', {
      insert: (t, ...rest) => {
        checkTable(t, 1, 'insert');
        const n = t.len();
        if (rest.length < 2) { if (!rest.length) throw new LuaError("wrong number of arguments to 'insert'"); t.set(n + 1, rest[0]); return EMPTY; }
        const [a, b] = rest;
        const pos = checkNum(a, 2, 'insert');
        for (let i = n; i >= pos; i--) t.set(i + 1, t.get(i));
        t.set(pos, b);
        return EMPTY;
      },
      remove: (t, pos) => {
        checkTable(t, 1, 'remove');
        const n = t.len();
        if (pos === undefined) pos = n; else pos = checkNum(pos, 2, 'remove');
        if (n === 0) return [undefined];
        const v = t.get(pos);
        for (let i = pos; i < n; i++) t.set(i, t.get(i + 1));
        t.set(n, undefined);
        return [v];
      },
      concat: (t, sep = '', i, j) => {
        checkTable(t, 1, 'concat');
        i = i === undefined ? 1 : checkNum(i); j = j === undefined ? t.len() : checkNum(j);
        const parts = [];
        for (let k = i; k <= j; k++) { const v = t.get(k); if (typeof v === 'number') parts.push(numToStr(v)); else if (typeof v === 'string') parts.push(v); else throw new LuaError(`invalid value (at index ${k}) in table for 'concat'`); }
        return [parts.join(typeof sep === 'number' ? numToStr(sep) : sep)];
      },
      sort: (t, cmp) => {
        checkTable(t, 1, 'sort');
        const n = t.len(), a = [];
        for (let k = 1; k <= n; k++) a.push(t.get(k));
        const less = cmp === undefined ? (x, y) => R.lt(x, y) : (x, y) => T(first(call(cmp, x, y)));
        a.sort((x, y) => (less(x, y) ? -1 : less(y, x) ? 1 : 0));
        for (let k = 0; k < n; k++) t.set(k + 1, a[k]);
        return EMPTY;
      },
      getn: (t) => [checkTable(t, 1, 'getn').len()],
      maxn: (t) => { checkTable(t, 1, 'maxn'); let m = t.arr.length; for (const k of t.hash.keys()) if (typeof k === 'number' && k > m) m = k; return [m]; },
      foreach: (t, f) => { const it = pairsIter(checkTable(t, 1, 'foreach')); for (;;) { const [k, v] = it(); if (k === undefined) return EMPTY; const r = first(call(f, k, v)); if (r !== undefined) return [r]; } },
      foreachi: (t, f) => { const n = checkTable(t, 1, 'foreachi').len(); for (let k = 1; k <= n; k++) { const r = first(call(f, k, t.get(k))); if (r !== undefined) return [r]; } return EMPTY; },
      setn: () => EMPTY,
    });

    // math
    let seed = 0x2545f491;
    const rnd = () => { seed ^= seed << 13; seed ^= seed >>> 17; seed ^= seed << 5; return ((seed >>> 0) % 2147483647) / 2147483647; };
    const math = lib(null, 'math', {
      abs: (x) => [Math.abs(checkNum(x, 1, 'abs'))], ceil: (x) => [Math.ceil(checkNum(x, 1, 'ceil'))], floor: (x) => [Math.floor(checkNum(x, 1, 'floor'))],
      sqrt: (x) => [Math.sqrt(checkNum(x, 1, 'sqrt'))], sin: (x) => [Math.sin(checkNum(x))], cos: (x) => [Math.cos(checkNum(x))], tan: (x) => [Math.tan(checkNum(x))],
      asin: (x) => [Math.asin(checkNum(x))], acos: (x) => [Math.acos(checkNum(x))], atan: (x) => [Math.atan(checkNum(x))], atan2: (y, x) => [Math.atan2(checkNum(y), checkNum(x))],
      exp: (x) => [Math.exp(checkNum(x))], log: (x) => [Math.log(checkNum(x))], log10: (x) => [Math.log10(checkNum(x))], pow: (x, y) => [Math.pow(checkNum(x), checkNum(y))],
      deg: (x) => [checkNum(x) * 180 / Math.PI], rad: (x) => [checkNum(x) * Math.PI / 180],
      fmod: (x, y) => [checkNum(x) % checkNum(y)], mod: (x, y) => [checkNum(x) % checkNum(y)],
      modf: (x) => { x = checkNum(x, 1, 'modf'); const i = x < 0 ? Math.ceil(x) : Math.floor(x); return [i, x - i]; },
      frexp: (x) => { x = checkNum(x); if (x === 0) return [0, 0]; const e = Math.floor(Math.log2(Math.abs(x))) + 1; return [x / Math.pow(2, e), e]; },
      ldexp: (m, e) => [checkNum(m) * Math.pow(2, checkNum(e))],
      max: (...a) => { let m = checkNum(a[0], 1, 'max'); for (let i = 1; i < a.length; i++) m = Math.max(m, checkNum(a[i], i + 1, 'max')); return [m]; },
      min: (...a) => { let m = checkNum(a[0], 1, 'min'); for (let i = 1; i < a.length; i++) m = Math.min(m, checkNum(a[i], i + 1, 'min')); return [m]; },
      random: (m, n) => {
        const r = rnd();
        if (m === undefined) return [r];
        m = Math.floor(checkNum(m, 1, 'random'));
        if (n === undefined) { if (m < 1) throw argErr(1, 'random', 'interval is empty'); return [Math.floor(r * m) + 1]; }
        n = Math.floor(checkNum(n, 2, 'random'));
        if (m > n) throw argErr(2, 'random', 'interval is empty');
        return [Math.floor(r * (n - m + 1)) + m];
      },
      randomseed: (s) => { seed = (Math.floor(checkNum(s)) | 0) || 1; return EMPTY; },
    });
    math.set('pi', Math.PI); math.set('huge', Infinity);

    // os
    const pad = (n, w = 2) => String(n).padStart(w, '0');
    const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    lib(null, 'os', {
      time: (t) => {
        if (t === undefined) return [Math.floor(Date.now() / 1000)];
        checkTable(t, 1, 'time');
        const g = (k, d) => { const v = t.get(k); if (v === undefined) { if (d === undefined) throw new LuaError(`field '${k}' missing in date table`); return d; } return tonum(v); };
        const d = new Date(g('year'), g('month') - 1, g('day'), g('hour', 12), g('min', 0), g('sec', 0));
        return [Math.floor(d.getTime() / 1000)];
      },
      clock: () => [performance.now() / 1000],
      date: (fmt = '%c', t) => {
        fmt = checkStr(fmt, 1, 'date');
        let utc = false;
        if (fmt[0] === '!') { utc = true; fmt = fmt.slice(1); }
        const d = new Date((t === undefined ? Date.now() / 1000 : checkNum(t, 2, 'date')) * 1000);
        const get = (f) => (utc ? d['getUTC' + f]() : d['get' + f]());
        if (fmt.startsWith('*t')) {
          const r = new LuaTable();
          const jan1 = new Date(get('FullYear'), 0, 1);
          for (const [k, v] of [['year', get('FullYear')], ['month', get('Month') + 1], ['day', get('Date')], ['hour', get('Hours')], ['min', get('Minutes')], ['sec', get('Seconds')], ['wday', get('Day') + 1], ['yday', Math.floor((d - jan1) / 864e5) + 1]]) r.set(k, v);
          r.set('isdst', false);
          return [r];
        }
        return [fmt.replace(/%(.)/g, (all, c) => {
          switch (c) {
            case 'Y': return String(get('FullYear')); case 'y': return pad(get('FullYear') % 100); case 'm': return pad(get('Month') + 1); case 'd': return pad(get('Date'));
            case 'H': return pad(get('Hours')); case 'M': return pad(get('Minutes')); case 'S': return pad(get('Seconds'));
            case 'p': return get('Hours') < 12 ? 'AM' : 'PM'; case 'I': return pad(((get('Hours') + 11) % 12) + 1);
            case 'A': return DAYS[get('Day')]; case 'a': return DAYS[get('Day')].slice(0, 3); case 'B': return MONTHS[get('Month')]; case 'b': return MONTHS[get('Month')].slice(0, 3);
            case 'w': return String(get('Day')); case 'j': return pad(Math.floor((d - new Date(get('FullYear'), 0, 1)) / 864e5) + 1, 3);
            case 'c': return `${DAYS[get('Day')].slice(0, 3)} ${MONTHS[get('Month')].slice(0, 3)} ${pad(get('Date'))} ${pad(get('Hours'))}:${pad(get('Minutes'))}:${pad(get('Seconds'))} ${get('FullYear')}`;
            case 'x': return `${pad(get('Month') + 1)}/${pad(get('Date'))}/${pad(get('FullYear') % 100)}`;
            case 'X': return `${pad(get('Hours'))}:${pad(get('Minutes'))}:${pad(get('Seconds'))}`;
            case '%': return '%';
            default: return all;
          }
        })];
      },
      difftime: (a, b) => [checkNum(a) - (b === undefined ? 0 : checkNum(b))],
      getenv: () => [undefined],
      exit: () => EMPTY,
    });
    lib(null, 'debug', { traceback: (m) => [m === undefined ? 'stack traceback:' : m], getinfo: () => [new LuaTable()] });
  }

  const Lua = { State, LuaTable, LuaError, R, T, toBytes, fromBytes, numToStr, compile, lex, parse, typeOf, first, call };
  if (typeof module !== 'undefined' && module.exports) module.exports = Lua;
  else root.Lua = Lua;
})(typeof window !== 'undefined' ? window : globalThis);
