// The app's internet requests. libgame.so carries its own copy of libcurl, which wants raw network sockets (a browser has
// none). So the few libcurl functions the app calls are replaced right at their start ("hooks"): the options the app sets are
// remembered, and curl_easy_perform sends the request with the browser (to the page's own server) and hands the answer to
// the app's own callback functions.
//   hookCurl(cpu, sys, lib, request)   request({ url, method, body: Uint8Array|null, headers: [..] }) -> { status, body: Uint8Array } | null
'use strict';
(function (root) {
  function hookCurl(cpu, sys, lib, request, log) {
    const handles = new Map();
    const hook = (name, fn) => { const a = lib.sym(name); if (!a) { log('no ' + name + ' in the app'); return; } cpu.hooks.set(a >>> 0, (c) => { const r = fn(c.r[0], c.r[1], c.r[2], c.r[3]); if (r !== undefined) c.r[0] = r; }); };
    hook('curl_global_init', () => 0);
    hook('curl_easy_init', () => { const h = sys.calloc(1, 16); handles.set(h, { headers: [] }); return h; });
    hook('curl_easy_cleanup', (h) => { handles.delete(h); sys.free(h); });
    hook('curl_easy_reset', (h) => { handles.set(h, { headers: [] }); });
    hook('curl_easy_setopt', (h, opt, v) => {
      const o = handles.get(h); if (!o) return 0;
      switch (opt) {
        case 10002: o.url = cpu.cstr(v); break; // CURLOPT_URL
        case 10015: o.post = v; break; // POSTFIELDS (a pointer; read when the request is sent)
        case 10165: o.post = v; break; // COPYPOSTFIELDS
        case 60: o.postSize = v; break; // POSTFIELDSIZE
        case 47: o.isPost = !!v; break; // POST
        case 80: if (v) o.isGet = true; break; // HTTPGET
        case 20011: o.write = v; break; // WRITEFUNCTION
        case 10001: o.writeData = v; break; // WRITEDATA
        case 20079: o.header = v; break; // HEADERFUNCTION
        case 10029: o.headerData = v; break; // HEADERDATA
        case 10023: o.slist = v; break; // HTTPHEADER (a list: { char* data; next })
        case 10010: o.errBuf = v; break; // ERRORBUFFER
        case 20056: o.progress = v; break; case 10057: o.progressData = v; break; case 43: o.noProgress = !!v; break;
        default: break; // time-outs, signals, redirects: nothing to do here
      }
      return 0;
    });
    hook('curl_easy_perform', (h) => {
      const o = handles.get(h); if (!o || !o.url) return 3;
      const headers = [];
      for (let p = o.slist; p; p = cpu.r32(p + 4)) headers.push(cpu.cstr(cpu.r32(p)));
      let body = null;
      if (o.post && !o.isGet) { const n = o.postSize !== undefined && o.postSize >= 0 ? o.postSize : cpu.cstr(o.post).length; body = cpu.u8.slice(o.post, o.post + n); }
      const method = body || o.isPost ? 'POST' : 'GET';
      let res;
      try { res = request({ url: o.url, method, body, headers }); } catch (e) { log('request failed: ' + o.url + ' ' + e.message); res = null; }
      if (!res) { if (o.errBuf) sys.putStr(o.errBuf, "couldn't connect to the server", 256); return 7; }
      o.status = res.status; o.size = res.body.length;
      const feed = (fn, data, bytes) => {
        const CH = 16384, buf = sys.malloc(Math.min(bytes.length, CH) + 1);
        for (let i = 0; i < bytes.length; i += CH) { const part = bytes.subarray(i, i + CH); cpu.u8.set(part, buf); cpu.call(fn, [buf, 1, part.length, data]); }
        sys.free(buf);
      };
      const enc = new TextEncoder();
      if (o.header) for (const line of [`HTTP/1.1 ${res.status} OK\r\n`, `Content-Length: ${res.body.length}\r\n`, '\r\n']) feed(o.header, o.headerData || 0, enc.encode(line));
      if (o.write && res.body.length) feed(o.write, o.writeData || 0, res.body);
      return 0;
    });
    hook('curl_easy_getinfo', (h, info, out) => {
      const o = handles.get(h) || {};
      if (info === 0x200002) cpu.w32(out, o.status || 0); // RESPONSE_CODE
      else if ((info & 0xf00000) === 0x300000) cpu.wf64(out, info === 0x300008 || info === 0x30000f ? o.size || 0 : 0); // doubles: sizes, times
      else if ((info & 0xf00000) === 0x200000) cpu.w32(out, 0);
      else cpu.w32(out, 0);
      return 0;
    });
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = hookCurl; else root.EmuHookCurl = hookCurl;
})(typeof window !== 'undefined' ? window : globalThis);
