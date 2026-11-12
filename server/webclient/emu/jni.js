// The Java side of the app, faked: libgame.so talks to Android's Java code through JNI (a table of ~230 functions).
// makeJni(cpu, sys, java) builds a JavaVM and a JNIEnv in emulated memory; `java` holds the Java methods the C++ calls,
// written in JavaScript: java['org/cocos2dx/lib/Cocos2dxHelper.getCocos2dxPackageName'] = (jni, args) => 'com.hello.bro.yo'.
// A Java method nobody wrote is logged once and answers 0 / null.
'use strict';
(function (root) {
  const Cpu = typeof module !== 'undefined' && module.exports ? require('./cpu.js') : root.EmuCpu;
  const IDX = { FindClass: 6, ExceptionOccurred: 15, ExceptionDescribe: 16, ExceptionClear: 17, NewGlobalRef: 21, DeleteGlobalRef: 22, DeleteLocalRef: 23, NewObject: 28, GetObjectClass: 31,
    GetMethodID: 33, CallObjectMethod: 34, CallObjectMethodV: 35, CallBooleanMethod: 37, CallBooleanMethodV: 38, CallIntMethod: 49, CallIntMethodV: 50, CallFloatMethod: 55, CallVoidMethod: 61, CallVoidMethodV: 62,
    GetStaticMethodID: 113, CallStaticObjectMethod: 114, CallStaticObjectMethodV: 115, CallStaticBooleanMethod: 117, CallStaticBooleanMethodV: 118, CallStaticIntMethod: 129, CallStaticIntMethodV: 130,
    CallStaticFloatMethod: 135, CallStaticFloatMethodV: 136, CallStaticDoubleMethod: 138, CallStaticVoidMethod: 141, CallStaticVoidMethodV: 142,
    NewStringUTF: 167, GetStringUTFLength: 168, GetStringUTFChars: 169, ReleaseStringUTFChars: 170, GetArrayLength: 171, NewByteArray: 176, NewIntArray: 179,
    GetByteArrayElements: 184, GetIntArrayElements: 187, ReleaseByteArrayElements: 192, ReleaseIntArrayElements: 195, GetByteArrayRegion: 200, SetByteArrayRegion: 208, GetIntArrayRegion: 203, SetIntArrayRegion: 211,
    ExceptionCheck: 228 };

  function makeJni(cpu, sys, java, log) {
    const objs = [null]; // handle -> JavaScript value (strings, byte arrays, classes, method ids)
    const ref = (v) => { if (v === null || v === undefined) return 0; objs.push(v); return objs.length - 1; };
    const get = (h) => objs[h];
    const warned = new Set();
    const table = sys.malloc(232 * 4);
    for (let i = 0; i < 232; i++) cpu.w32(table + i * 4, cpu.trap(() => { throw new Cpu.EmuError('JNI function #' + i + ' is not written yet'); }, 'JNI#' + i));
    const env = sys.malloc(4); cpu.w32(env, table);
    const def = (name, fn) => cpu.w32(table + IDX[name] * 4, cpu.trap(fn, 'JNI.' + name));
    // read a Java call's arguments by the method's signature: "(ILjava/lang/String;F)V"
    const argTypes = (sig) => { const out = []; const s = sig.slice(1, sig.indexOf(')')); for (let i = 0; i < s.length; i++) { let t = s[i]; if (t === '[') { while (s[i] === '[') i++; if (s[i] === 'L') i = s.indexOf(';', i); t = '['; } else if (t === 'L') i = s.indexOf(';', i); out.push(t); } return out; };
    const readArgs = (sig, a) => argTypes(sig).map((t) => (t === 'F' || t === 'D' ? a.d() : t === 'J' ? a.q() : t === 'L' || t === '[' ? get(a.w()) : t === 'Z' ? !!a.w() : a.w()));
    const invoke = (m, self, a) => {
      const key = m.cls + '.' + m.name, fn = java[key];
      const args = readArgs(m.sig, a);
      if (!fn) { if (!warned.has(key)) { warned.add(key); log('JAVA not written: ' + key + m.sig); } return undefined; }
      return fn(jni, args, self);
    };
    const ret = (m, v) => { const t = m.sig.slice(m.sig.indexOf(')') + 1)[0]; if (t === 'V') return undefined; if (t === 'L' || t === '[') return ref(v); if (t === 'F') return sys.retF(Number(v) || 0); if (t === 'D') { sys.retD(Number(v) || 0); return undefined; } if (t === 'Z') return v ? 1 : 0; if (t === 'J') return BigInt(v || 0); return (Number(v) || 0) | 0; };
    def('FindClass', (c, e, name) => ref({ cls: cpu.cstr(name) }));
    def('GetObjectClass', (c, e, o) => ref({ cls: (get(o) && get(o).javaClass) || 'java/lang/Object' }));
    def('GetStaticMethodID', (c, e, cls, name, sig) => ref({ cls: get(cls).cls, name: cpu.cstr(name), sig: cpu.cstr(sig) }));
    def('GetMethodID', (c, e, cls, name, sig) => ref({ cls: get(cls).cls, name: cpu.cstr(name), sig: cpu.cstr(sig) }));
    for (const kind of ['Object', 'Boolean', 'Int', 'Float', 'Void', 'Double']) {
      if (IDX['CallStatic' + kind + 'Method']) def('CallStatic' + kind + 'Method', (c, e, cls, mid) => { const m = get(mid); return ret(m, invoke(m, null, sys.regArgs(3))); });
      if (IDX['CallStatic' + kind + 'MethodV']) def('CallStatic' + kind + 'MethodV', (c, e, cls, mid, va) => { const m = get(mid); return ret(m, invoke(m, null, vaReader(va))); });
      if (IDX['Call' + kind + 'Method']) def('Call' + kind + 'Method', (c, e, o, mid) => { const m = get(mid); return ret(m, invoke(m, get(o), sys.regArgs(3))); });
      if (IDX['Call' + kind + 'MethodV']) def('Call' + kind + 'MethodV', (c, e, o, mid, va) => { const m = get(mid); return ret(m, invoke(m, get(o), vaReader(va))); });
    }
    const vaReader = (p) => ({ w: () => { const v = cpu.r32(p); p += 4; return v; }, d: () => { p = (p + 7) & ~7; const v = cpu.rf64(p); p += 8; return v; }, q: () => { p = (p + 7) & ~7; const v = (BigInt(cpu.r32(p + 4)) << 32n) | BigInt(cpu.r32(p) >>> 0); p += 8; return v; } });
    def('NewStringUTF', (c, e, s) => ref(cpu.cstr(s)));
    def('GetStringUTFChars', (c, e, s, isCopy) => { if (isCopy) cpu.u8[isCopy] = 1; return sys.strdup(String(get(s) ?? '')); });
    def('GetStringUTFLength', (c, e, s) => Cpu.enc.encode(String(get(s) ?? '')).length);
    def('ReleaseStringUTFChars', (c, e, s, p) => { sys.free(p); });
    def('DeleteLocalRef', () => {}); def('DeleteGlobalRef', () => {}); def('NewGlobalRef', (c, e, o) => o);
    def('ExceptionCheck', () => 0); def('ExceptionOccurred', () => 0); def('ExceptionClear', () => {}); def('ExceptionDescribe', () => {});
    def('GetArrayLength', (c, e, a) => (get(a) ? get(a).length : 0));
    def('NewByteArray', (c, e, n) => ref(new Uint8Array(n)));
    def('GetByteArrayElements', (c, e, a, isCopy) => { const b = get(a), p = sys.malloc(b.length || 1); cpu.u8.set(b, p); if (isCopy) cpu.u8[isCopy] = 1; return p; });
    def('ReleaseByteArrayElements', (c, e, a, p) => { sys.free(p); });
    def('GetByteArrayRegion', (c, e, a, start, len) => { cpu.u8.set(get(a).subarray(start, start + len), sys.arg(4)); }); // the 5th argument is on the stack
    def('SetByteArrayRegion', (c, e, a, start, len) => { const src = sys.arg(4); get(a).set(cpu.u8.subarray(src, src + len), start); });
    // int[] and float[] (touch moves pass ids, xs and ys as arrays)
    const elems = (i) => cpu.w32(table + i * 4, cpu.trap((c, e, a, isCopy) => { const t = get(a), p = sys.malloc(t.byteLength || 4); cpu.u8.set(new Uint8Array(t.buffer, t.byteOffset, t.byteLength), p); if (isCopy) cpu.u8[isCopy] = 1; return p; }, 'JNI.GetArrayElements'));
    elems(187); elems(189);
    for (const i of [195, 197]) cpu.w32(table + i * 4, cpu.trap((c, e, a, p) => { sys.free(p); }, 'JNI.ReleaseArrayElements'));
    for (const i of [203, 205]) cpu.w32(table + i * 4, cpu.trap((c, e, a, start, len) => { const t = get(a); cpu.u8.set(new Uint8Array(t.buffer, t.byteOffset + start * 4, len * 4), sys.arg(4)); }, 'JNI.GetArrayRegion'));
    // the JavaVM: GetEnv and AttachCurrentThread hand out the one JNIEnv
    const vmTable = sys.malloc(8 * 4);
    for (let i = 0; i < 8; i++) cpu.w32(vmTable + i * 4, cpu.trap(() => 0, 'JavaVM#' + i));
    const giveEnv = (c, vm, penv) => { cpu.w32(penv, env); return 0; };
    cpu.w32(vmTable + 4 * 4, cpu.trap(giveEnv, 'AttachCurrentThread')); cpu.w32(vmTable + 6 * 4, cpu.trap(giveEnv, 'GetEnv')); cpu.w32(vmTable + 7 * 4, cpu.trap(giveEnv, 'AttachCurrentThreadAsDaemon'));
    const vm = sys.malloc(4); cpu.w32(vm, vmTable);
    const jni = { env, vm, ref, get, objs };
    return jni;
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = makeJni; else root.EmuMakeJni = makeJni;
})(typeof window !== 'undefined' ? window : globalThis);
