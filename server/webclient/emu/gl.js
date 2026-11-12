// The app's OpenGL ES 2.0 calls, passed on to the browser's WebGL (nearly the same functions). Numbers the app holds for
// textures, buffers, shaders and uniform places are indexes into tables here; pointers into the emulated memory become
// typed-array views. Vertex data the app keeps in its own memory ("client arrays", which WebGL does not have) is copied into
// a scratch buffer right before each draw call.
'use strict';
(function (root) {
  function makeGl(cpu, sys, gl, log) {
    const objs = [null]; // id -> WebGL object
    const add = (o) => { objs.push(o); return objs.length - 1; };
    const F = {};
    const arg = sys.arg, flt = sys.flt, u8 = cpu.u8;
    const f32 = (p, n) => (p & 3 ? new Float32Array(u8.slice(p, p + n * 4).buffer) : new Float32Array(cpu.buf, p, n));
    const i32 = (p, n) => (p & 3 ? new Int32Array(u8.slice(p, p + n * 4).buffer) : new Int32Array(cpu.buf, p, n));
    const strs = new Map();
    const cstr = (s) => { if (!strs.has(s)) strs.set(s, sys.strdup(s)); return strs.get(s); };
    let arrayBuf = 0, elemBuf = 0, program = 0;
    const attribs = []; // index -> { enabled, client: { size, type, norm, stride, ptr } | null }
    const at = (i) => attribs[i] || (attribs[i] = { enabled: false, client: null });
    const scratch = []; // one WebGL buffer per attribute index for client arrays
    const TYPE_SIZE = { 0x1400: 1, 0x1401: 1, 0x1402: 2, 0x1403: 2, 0x1406: 4, 0x1404: 4, 0x1405: 4 };
    // before a draw: upload the client arrays that are switched on, for vertices first .. first+count-1
    function feedClientArrays(first, count) {
      let used = false;
      for (let i = 0; i < attribs.length; i++) {
        const a = attribs[i];
        if (!a || !a.enabled || !a.client) continue;
        const c = a.client, elem = c.size * TYPE_SIZE[c.type], stride = c.stride || elem;
        const start = c.ptr + first * stride, bytes = (count - 1) * stride + elem;
        if (!scratch[i]) scratch[i] = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, scratch[i]);
        gl.bufferData(gl.ARRAY_BUFFER, u8.subarray(start, start + bytes), gl.STREAM_DRAW);
        gl.vertexAttribPointer(i, c.size, c.type, c.norm, stride, 0);
        used = true;
      }
      if (used) gl.bindBuffer(gl.ARRAY_BUFFER, objs[arrayBuf] || null);
      return used;
    }
    const uniforms = [null]; // id -> WebGLUniformLocation
    const def = (name, fn) => { F['gl' + name] = fn; };
    // plain pass-throughs: (name, how the arguments are read)  i = integer, f = float, o = object id
    const pass = (name, sig, method) => {
      const m = gl[method || name[0].toLowerCase() + name.slice(1)].bind(gl);
      def(name, () => { const a = []; for (let i = 0; i < sig.length; i++) { const v = arg(i); a.push(sig[i] === 'f' ? flt(v) : sig[i] === 'o' ? objs[v] || null : sig[i] === 'b' ? !!v : sig[i] === 'u' ? uniforms[v] || null : v); } m(...a); });
    };
    for (const [n, s] of [['ActiveTexture', 'i'], ['AttachShader', 'oo'], ['BlendEquation', 'i'], ['BlendFunc', 'ii'], ['Clear', 'i'], ['ClearColor', 'ffff'], ['ClearStencil', 'i'], ['CompileShader', 'o'],
      ['DeleteProgram', 'o'], ['DeleteShader', 'o'], ['DepthFunc', 'i'], ['DepthMask', 'b'], ['Disable', 'i'], ['Enable', 'i'], ['GenerateMipmap', 'i'], ['LinkProgram', 'o'], ['Scissor', 'iiii'],
      ['StencilFunc', 'iii'], ['StencilMask', 'i'], ['StencilOp', 'iii'], ['TexParameteri', 'iii'], ['Viewport', 'iiii'], ['FramebufferRenderbuffer', 'iiio'], ['FramebufferTexture2D', 'iiioi'], ['RenderbufferStorage', 'iiii'],
      ['Uniform1f', 'uf'], ['Uniform2f', 'uff'], ['Uniform3f', 'ufff'], ['Uniform4f', 'uffff'], ['Uniform1i', 'ui'], ['Uniform2i', 'uii'], ['Uniform3i', 'uiii'], ['Uniform4i', 'uiiii']]) pass(n, s);
    def('ClearDepthf', (c, d) => gl.clearDepth(flt(d)));
    def('PixelStorei', (c, pname, v) => { if (pname === 0x0cf5 || pname === 0x0d05) gl.pixelStorei(pname, v); });
    def('IsEnabled', (c, cap) => (gl.isEnabled(cap) ? 1 : 0));
    def('GetError', () => 0);
    def('CreateProgram', () => add(gl.createProgram()));
    def('CreateShader', (c, type) => add(gl.createShader(type)));
    def('ShaderSource', (c, sh, count, strings, lengths) => { let src = ''; for (let i = 0; i < count; i++) { const p = cpu.r32(strings + i * 4), l = lengths ? cpu.r32(lengths + i * 4) : -1; src += l >= 0 ? Cpu.dec.decode(u8.subarray(p, p + l)) : cpu.cstr(p); } gl.shaderSource(objs[sh], src); });
    def('GetShaderiv', (c, sh, pname, out) => { const v = pname === 0x8b84 ? (gl.getShaderInfoLog(objs[sh]) || '').length + 1 : pname === 0x8b88 ? (gl.getShaderSource(objs[sh]) || '').length + 1 : gl.getShaderParameter(objs[sh], pname); cpu.w32(out, v === true ? 1 : v === false ? 0 : v | 0); });
    def('GetProgramiv', (c, p, pname, out) => { const v = pname === 0x8b84 ? (gl.getProgramInfoLog(objs[p]) || '').length + 1 : gl.getProgramParameter(objs[p], pname); cpu.w32(out, v === true ? 1 : v === false ? 0 : v | 0); });
    def('GetShaderInfoLog', (c, sh, max, lenp, out) => { const n = sys.putStr(out, gl.getShaderInfoLog(objs[sh]) || '', max); if (lenp) cpu.w32(lenp, Math.min(n, max - 1)); });
    def('GetProgramInfoLog', (c, p, max, lenp, out) => { const n = sys.putStr(out, gl.getProgramInfoLog(objs[p]) || '', max); if (lenp) cpu.w32(lenp, Math.min(n, max - 1)); });
    def('GetShaderSource', (c, sh, max, lenp, out) => { const n = sys.putStr(out, gl.getShaderSource(objs[sh]) || '', max); if (lenp) cpu.w32(lenp, Math.min(n, max - 1)); });
    def('BindAttribLocation', (c, p, index, name) => gl.bindAttribLocation(objs[p], index, cpu.cstr(name)));
    def('GetUniformLocation', (c, p, name) => { const l = gl.getUniformLocation(objs[p], cpu.cstr(name)); if (!l) return -1; uniforms.push(l); return uniforms.length - 1; });
    def('UseProgram', (c, p) => { program = p; gl.useProgram(objs[p] || null); });
    for (const k of [1, 2, 3, 4]) {
      def('Uniform' + k + 'fv', (c, loc, count, p) => gl['uniform' + k + 'fv'](uniforms[loc] || null, f32(p, count * k)));
      def('Uniform' + k + 'iv', (c, loc, count, p) => gl['uniform' + k + 'iv'](uniforms[loc] || null, i32(p, count * k)));
    }
    def('UniformMatrix4fv', (c, loc, count, transpose, p) => gl.uniformMatrix4fv(uniforms[loc] || null, false, f32(p, count * 16)));
    const gen = (name, make) => def('Gen' + name, (c, n, out) => { for (let i = 0; i < n; i++) cpu.w32(out + i * 4, add(make())); });
    const del = (name, kill) => def('Delete' + name, (c, n, ids) => { for (let i = 0; i < n; i++) { const id = cpu.r32(ids + i * 4); if (objs[id]) { kill(objs[id]); objs[id] = null; } } });
    gen('Textures', () => gl.createTexture()); del('Textures', (o) => gl.deleteTexture(o));
    gen('Buffers', () => gl.createBuffer()); del('Buffers', (o) => gl.deleteBuffer(o));
    gen('Framebuffers', () => gl.createFramebuffer()); del('Framebuffers', (o) => gl.deleteFramebuffer(o));
    gen('Renderbuffers', () => gl.createRenderbuffer()); del('Renderbuffers', (o) => gl.deleteRenderbuffer(o));
    def('BindTexture', (c, target, id) => gl.bindTexture(target, objs[id] || null));
    def('BindBuffer', (c, target, id) => { if (target === 0x8892) arrayBuf = id; else elemBuf = id; gl.bindBuffer(target, objs[id] || null); });
    def('BindFramebuffer', (c, target, id) => gl.bindFramebuffer(target, objs[id] || null));
    def('BindRenderbuffer', (c, target, id) => gl.bindRenderbuffer(target, objs[id] || null));
    def('CheckFramebufferStatus', (c, target) => gl.checkFramebufferStatus(target));
    def('BufferData', (c, target, size, data, usage) => { if (data) gl.bufferData(target, u8.subarray(data, data + size), usage); else gl.bufferData(target, size, usage); });
    def('BufferSubData', (c, target, off, size, data) => gl.bufferSubData(target, off, u8.subarray(data, data + size)));
    const pixels = (w, h, format, type, p) => {
      if (!p) return null;
      if (type === 0x1401) { const bpp = { 0x1908: 4, 0x1907: 3, 0x1906: 1, 0x1909: 1, 0x190a: 2 }[format] || 4; const row = (w * bpp + 3) & ~3; return u8.subarray(p, p + (bpp === 4 ? w * h * 4 : row * h)); }
      return new Uint16Array(u8.slice(p, p + w * h * 2).buffer); // 4444, 5551, 565
    };
    def('TexImage2D', (c, target, level, ifmt, w) => { const h = arg(4), format = arg(6), type = arg(7), p = arg(8); gl.texImage2D(target, level, format, w, h, 0, format, type, pixels(w, h, format, type, p)); });
    def('CompressedTexImage2D', () => { log('compressed texture skipped'); });
    def('ReadPixels', (c, x, y, w, h) => { const p = arg(6); gl.readPixels(x, y, w, h, arg(4), arg(5), u8.subarray(p, p + w * h * 4)); });
    def('EnableVertexAttribArray', (c, i) => { at(i).enabled = true; gl.enableVertexAttribArray(i); });
    def('DisableVertexAttribArray', (c, i) => { at(i).enabled = false; gl.disableVertexAttribArray(i); });
    def('VertexAttribPointer', (c, index, size, type, norm) => {
      const stride = arg(4), ptr = arg(5) >>> 0;
      if (arrayBuf) { at(index).client = null; gl.vertexAttribPointer(index, size, type, !!norm, stride, ptr); }
      else at(index).client = { size, type, norm: !!norm, stride, ptr };
    });
    def('DrawArrays', (c, mode, first, count) => { if (feedClientArrays(first, count)) gl.drawArrays(mode, 0, count); else gl.drawArrays(mode, first, count); });
    let idxScratch = null;
    def('DrawElements', (c, mode, count, type, indices) => {
      if (elemBuf) { feedClientArrays(0, count); gl.drawElements(mode, count, type, indices); return; }
      const size = type === 0x1403 ? 2 : 1;
      let max = 0; for (let i = 0; i < count; i++) { const v = size === 2 ? cpu.r16(indices + i * 2) : u8[indices + i]; if (v > max) max = v; }
      feedClientArrays(0, max + 1);
      if (!idxScratch) idxScratch = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, idxScratch);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, u8.subarray(indices, indices + count * size), gl.STREAM_DRAW);
      gl.drawElements(mode, count, type, 0);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
    });
    def('GetString', (c, name) => cstr(name === 0x1f03 ? 'GL_OES_rgb8_rgba8 GL_OES_packed_depth_stencil' : name === 0x1f02 ? 'OpenGL ES 2.0 WebGL' : name === 0x8b8c ? 'OpenGL ES GLSL ES 1.00' : 'WebGL'));
    def('GetIntegerv', (c, pname, out) => { const v = gl.getParameter(pname); if (v && v.length) for (let i = 0; i < v.length; i++) cpu.w32(out + i * 4, v[i]); else cpu.w32(out, typeof v === 'number' ? v : v === true ? 1 : 0); });
    def('GetFloatv', (c, pname, out) => { const v = gl.getParameter(pname); if (v && v.length) for (let i = 0; i < v.length; i++) cpu.wf32(out + i * 4, v[i]); else cpu.wf32(out, Number(v) || 0); });
    def('GetBooleanv', (c, pname, out) => { cpu.w8(out, gl.getParameter(pname) ? 1 : 0); });
    return F;
  }
  const Cpu = typeof module !== 'undefined' && module.exports ? require('./cpu.js') : root.EmuCpu;
  if (typeof module !== 'undefined' && module.exports) module.exports = makeGl; else root.EmuMakeGl = makeGl;
})(typeof window !== 'undefined' ? window : globalThis);
