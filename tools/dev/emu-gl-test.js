// The browser game's shaders (server/webclient/emu/gl.js samePrecision): cocos2d-x puts the same uniforms on top of every vertex
// shader (under 'precision highp float') and every fragment shader ('precision mediump float'). WebGL wants a uniform that both
// shaders declare to have one precision; Firefox, Mali and PowerVR refused to link every program and the game stayed black until
// 17 Nov 2026. The rewrite must give every CC_ uniform the same precision in both and leave everything else alone.
// node tools/dev/emu-gl-test.js
'use strict';
const path = require('path');
const makeGl = require(path.join(__dirname, '..', '..', 'server', 'webclient', 'emu', 'gl.js'));
let bad = 0;
const ok = (c, m) => { if (!c) { bad++; console.log('FAIL ' + m); } };
// the header as libgame.so (cocos2d-x 2 CCGLProgram::compileShader) sends it
const HEAD = 'uniform mat4 CC_PMatrix;\nuniform mat4 CC_MVMatrix;\nuniform mat4 CC_MVPMatrix;\nuniform vec4 CC_Time;\nuniform vec4 CC_SinTime;\nuniform vec4 CC_CosTime;\nuniform vec4 CC_Random01;\n//CC INCLUDES END\n\n';
const vert = 'precision highp float;\n' + HEAD + 'attribute vec4 a_position;\nvoid main() { gl_Position = CC_MVPMatrix * a_position; }\n';
const frag = 'precision mediump float;\n' + HEAD + '\n#ifdef GL_ES\nprecision lowp float;\n#endif\nuniform vec4 u_color;\nuniform\t\tfloat CC_alpha_value;\nvoid main() { gl_FragColor = u_color * CC_Time.x; }\n';
const ccLines = (s) => s.split('\n').filter((l) => /\bCC_[A-Za-z0-9]+\s*;/.test(l) && /^uniform/.test(l) && /mat4|vec4/.test(l));
for (const prec of ['highp', 'mediump']) {
  const v = makeGl.samePrecision(vert, prec), f = makeGl.samePrecision(frag, prec);
  const lv = ccLines(v), lf = ccLines(f);
  ok(lv.length === 7 && lf.length === 7, prec + ': 7 CC_ uniforms in each shader, got ' + lv.length + ' / ' + lf.length);
  ok(lv.every((l) => l.startsWith('uniform ' + prec + ' ')), prec + ': vertex CC_ uniforms without the precision: ' + lv.join(' | '));
  ok(lv.join('\n') === lf.join('\n'), prec + ': vertex and fragment shaders declare the CC_ uniforms differently');
  ok(f.includes('uniform vec4 u_color;') && f.includes('uniform\t\tfloat CC_alpha_value;'), prec + ': other uniforms were changed');
  ok(v.endsWith('void main() { gl_Position = CC_MVPMatrix * a_position; }\n') && f.includes('precision lowp float;'), prec + ': shader body changed');
  ok(makeGl.samePrecision(v, prec) === v, prec + ': a second pass changes the shader again');
}
if (bad) { console.log('emu gl test: ' + bad + ' problem(s)'); process.exit(1); }
console.log('emu gl test: shared CC_ uniforms get one precision in vertex and fragment shaders (Firefox / Mali / PowerVR black screen)');
