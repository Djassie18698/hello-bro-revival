// Checks the web client's Lua 5.1 engine (server/webclient/lua.js): small programs with the output real Lua 5.1 gives, then
// every one of the game's own scripts (re/obb/script + our hot-update copies in server/cdn/src/script) must compile.
// Run by check.sh (skips the script part when re/obb is missing). node tools/dev/lua-test.js [-v]
'use strict';
const fs = require('fs'), path = require('path');
const Lua = require('../../server/webclient/lua.js');
const ROOT = path.join(__dirname, '..', '..');
let bad = 0;
const verbose = process.argv.includes('-v');

function run(src, files = {}) {
  const out = [];
  const L = new Lua.State({ print: (s) => out.push(s), files: (p) => files[p] });
  try { Lua.call(L.load(Lua.toBytes(src), 'test')); } catch (e) { out.push('ERROR: ' + Lua.fromBytes(String(e instanceof Lua.LuaError ? e.value : e.stack))); }
  return out.join('\n');
}
const cases = [
  ['print(1, 2.5, 10/2, 1/3, -0.0, 2^53, 1e15, 1e100, 7 % 3, -7 % 3, 7 % -3, 5 // 1 == nil)', null], // // is not Lua 5.1: a syntax error
  ['print(1, 2.5, 10/2, 1/3, 2^53, 1e15, 1e100, 7 % 3, -7 % 3, 7 % -3, 3 == 3.0)', '1\t2.5\t5\t0.33333333333333\t9.007199254741e+15\t1e+15\t1e+100\t1\t2\t-2\ttrue'],
  ['print("10" + 5, "3" * "4", 10 .. 20, "x" .. 1.5)', '15\t12\t1020\tx1.5'],
  ['local t = {1, 2, 3, nil, 5} print(#t, select("#", 1, nil, 3), select(2, "a", "b", "c"))', '5\t3\tb\tc'],
  ['local function f(...) return ... end local a, b, c = f(1, 2) print(a, b, c, (f(4, 5)))', '1\t2\tnil\t4'],
  ['local t = {f = function(self, x) return self.v + x end, v = 10} print(t:f(5), t.f(t, 1))', '15\t11'],
  ['local s = 0 for i = 10, 1, -3 do s = s + i end print(s) for i = 1, 0 do print("no") end', '22'],
  ['local t = {} for i = 1, 3 do t[i] = function() return i end end print(t[1](), t[3]())', '1\t3'],
  ['local n = 0 repeat local k = n n = n + 1 until k >= 2 print(n)', '3'],
  ['local t = setmetatable({}, {__index = function(t, k) return k .. "!" end}) print(t.hi, rawget(t, "hi"))', 'hi!\tnil'],
  ['local mt = {__add = function(a, b) return a.v + b.v end, __eq = function() return true end, __lt = function(a, b) return a.v < b.v end, __concat = function(a, b) return "cat" end, __tostring = function() return "OBJ" end}\nlocal a, b = setmetatable({v = 1}, mt), setmetatable({v = 2}, mt) print(a + b, a == b, a < b, a .. "x", tostring(a))', '3\ttrue\ttrue\tcat\tOBJ'],
  ['local log = {} local p = setmetatable({}, {__newindex = function(t, k, v) log[#log + 1] = k rawset(t, k, v) end}) p.a = 1 p.a = 2 p.b = 3 print(table.concat(log, ","), p.a)', 'a,b\t2'],
  ['print(string.format("%d|%5d|%-5d|%05d|%.2f|%5.1f|%s|%q|%x|%X|%g|%g|%%|%c|%3s", 7, 42, 42, 42, 3.14159, 2.25, "hi", "a\\"b", 255, 255, 0.1, 1e20, 65, "x"))', '7|   42|42   |00042|3.14|  2.2|hi|"a\\"b"|ff|FF|0.1|1e+20|%|A|  x'],
  ['print(string.find("hello world", "o w"), string.find("hello", "l+"), string.find("a.b", ".", 1, true), string.match("key=val", "(%w+)=(%w+)"))', '5\t3\t2\tkey\tval'], // only the last call in a list gives all its values
  ['print(string.gsub("hello world", "o", "0"), string.gsub("abc", "%w", "%0%0"), string.gsub("$name is $age", "%$(%w+)", {name = "Neji", age = 13}))', 'hell0 w0rld\taabbcc\tNeji is 13\t2'],
  ['local t = {} for w in string.gmatch("one two  three", "%a+") do t[#t + 1] = w end print(#t, t[3]) for k, v in string.gmatch("a=1, b=2", "(%w+)=(%w+)") do io = (io or "") .. k .. v end print(io)', '3\tthree\na1b2'],
  ['print(("%d-%d"):format(1, 2), ("abc"):upper(), #"héllo", string.sub("hello", 2, -2), string.sub("hello", -3), ("x"):rep(3), string.byte("A"), string.char(72, 105))', '1-2\tABC\t6\tell\tllo\txxx\t65\tHi'],
  ['local t = {5, 2, 8, 1} table.sort(t) print(table.concat(t, " ")) table.sort(t, function(a, b) return a > b end) print(table.concat(t, " ")) table.insert(t, 1, 9) table.insert(t, 7) print(table.concat(t, ","), table.remove(t), table.remove(t, 1), #t)', '1 2 5 8\n8 5 2 1\n9,8,5,2,1,7\t7\t9\t4'],
  ['local keys = {} for k, v in pairs({10, 20, x = 1}) do keys[#keys + 1] = tostring(k) end print(table.concat(keys, ",")) for i, v in ipairs({1, 2, nil, 4}) do io = i end print(io)', '1,2,x\n2'],
  ['print(pcall(function() error("boom") end)) print(pcall(function() error({code = 1}) end)) print(select("#", pcall(error)))', 'test:1: boom\nfalse\ttable: 0x', 'prefix'],
  ['print(pcall(function() local x = nil; return x.y end))', 'false\ttest:1: attempt to index a nil value (field \'y\')'],
  ['print(tonumber("0x10"), tonumber("  12  "), tonumber("1e2"), tonumber("abc"), tonumber("ff", 16), tonumber("8", 8), math.floor(-3.5), math.max(3, 7, 1), math.modf(3.7))', '16\t12\t100\tnil\t255\tnil\t-4\t7\t3\t0.7'],
  ['print(type(nil), type({}), type(print), type("s"), type(2), not nil, nil == false, 1 and 2, nil or "d", false and error("x"))', 'nil\ttable\tfunction\tstring\tnumber\ttrue\tfalse\t2\td\tfalse'],
  ['local a = {} a.b = {} a.b.c = 5 function a.b.f(x) return x * 2 end function a.b:g(x) return self.c + x end print(a.b.f(4), a.b:g(1))', '8\t6'],
  ['local i, j = 1, 2 i, j = j, i print(i, j) local t = {} t[1], t[2] = 3, 4 print(t[1] + t[2])', '2\t1\n7'],
  ['print(loadstring("return 1 + 2")(), loadstring("x = ")) ', null],
  ['print(#{n = 1}, #"", ({...}).n, select("#", ...))', '0\t0\tnil\t0'],
  ['local s = [[\nline1\nline2]] print(s, [==[a]]b]==]) -- comment\n--[[ long\ncomment ]] print("ok\\65\\t|")', 'line1\nline2\ta]]b\nokA\t|'],
  ['print(os.date("%Y", 0) >= "1969", type(os.time()), os.time({year = 2026, month = 1, day = 2, hour = 3}) > 0)', 'true\tnumber\ttrue'],
  ['print(math.floor(10 / 3), 2^10, 10 / 0, -10 / 0, math.huge == 1/0, 0.1 + 0.2, 100000000000000, 123456789012345678)', '3\t1024\tinf\t-inf\ttrue\t0.3\t100000000000000\t1.2345678901235e+17'],
  ['local Animal = {} Animal.__index = Animal function Animal.new(n) return setmetatable({n = n}, Animal) end function Animal:name() return self.n end local Dog = setmetatable({}, {__index = Animal}) Dog.__index = Dog function Dog.new(n) local d = Animal.new(n) return setmetatable(d, Dog) end function Dog:bark() return self:name() .. " woof" end print(Dog.new("Rex"):bark())', 'Rex woof'],
  ['local t = {} t[1.0] = "a" t[2] = "b" print(t[1], #t) t[#t + 1] = "c" t[5] = "e" print(#t, t[5]) t[4] = "d" print(#t)', 'a\t2\n3\te\n5'],
];
for (const [src, want, mode] of cases) {
  const got = run(src);
  if (want === null) continue; // only must not crash the engine itself
  const ok = mode === 'prefix' ? got.startsWith(want.split('\n')[0]) || got.includes(want.split('\n')[1] || '\0') : got === want;
  if (!ok) { bad++; console.log(`LUA: ${src.slice(0, 90)}\n  want ${JSON.stringify(want)}\n  got  ${JSON.stringify(got)}`); }
  else if (verbose) console.log('ok  ', src.slice(0, 70));
}
// module(..., package.seeall) + require, like the game's scripts
{
  const files = {
    'script/util/m.lua': Lua.toBytes('module("m", package.seeall)\nlocal hidden = 1\nvalue = 41\nfunction get() return value + hidden end\n'),
    'script/main.lua': Lua.toBytes('require "util/m"\nprint(m.get(), value, m._NAME, package.loaded["util/m"] == m)\n'),
  };
  const out = [];
  const L = new Lua.State({ print: (s) => out.push(s), files: (p) => files[p] });
  try { L.dofile('script/main.lua'); } catch (e) { out.push('ERROR ' + Lua.fromBytes(String(e.value || e.stack))); }
  // Lua 5.1 too: module("m") fills package.loaded.m, while require keeps package.loaded["util/m"] = true
  if (out.join('\n') !== '42\tnil\tm\tfalse') { bad++; console.log('LUA module/require: got ' + JSON.stringify(out.join('\n'))); }
}
// the game's own scripts: every file must compile, except the ones that real Lua 5.1 refuses too
const KNOWN_BROKEN = new Set(['ui_dialogBuyItemLayer.lua']); // line 67: "elseif (...)" with no "then" in the original game
const dirs = [path.join(ROOT, 're', 'obb', 'script'), path.join(ROOT, 'server', 'cdn', 'src', 'script')];
let files = 0, ms = 0, known = 0;
if (fs.existsSync(dirs[0])) {
  const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const f = path.join(d, e.name); if (e.isDirectory()) walk(f); else if (f.endsWith('.lua')) {
    files++;
    const src = fs.readFileSync(f).toString('latin1');
    const t0 = Date.now();
    try { const { js } = Lua.compile(src, path.relative(ROOT, f)); new Function('R', 'ENV', js); }
    catch (e) { if (KNOWN_BROKEN.has(path.basename(f))) known++; else { bad++; console.log('LUA compile ' + path.relative(ROOT, f) + ': ' + Lua.fromBytes(String(e.value || e.message)).slice(0, 300)); } }
    ms += Date.now() - t0;
  } } };
  for (const d of dirs) if (fs.existsSync(d)) walk(d);
}
console.log(bad ? `${bad} Lua problem(s)` : `Lua OK (${cases.length} programs match Lua 5.1; ${files - known} of ${files} game scripts compile in ${ms} ms, ${known} broken in the original too)`);
process.exit(bad ? 1 : 0);
