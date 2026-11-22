// Test help: runs a private copy of the dev server with its clock moved, so features with opening hours (World Boss 14:00-14:30,
// Border war 12:00-15:00 New York time, ramen ...) can be played at any time of day.
//   HB_SHIFT_TO=14:05 PORT=18083 DB=<copy of hellobro.db> node -r ./tools/dev/shift-clock.js server/server.js
// HB_SHIFT_TO = the local time the server should think it is when it starts (or HB_SHIFT_MIN = minutes to add).
// Then play it with: PLAY_BASE=http://127.0.0.1:18083 node tools/dev/play.js serve <guest> <port>
const RealDate = Date;
let shift = Number(process.env.HB_SHIFT_MIN || 0) * 60000;
if (process.env.HB_SHIFT_TO) {
  const [h, m] = process.env.HB_SHIFT_TO.split(':').map(Number), n = new RealDate();
  const want = new RealDate(n.getFullYear(), n.getMonth(), n.getDate(), h, m || 0, 0);
  shift = want.getTime() - n.getTime();
}
class ShiftedDate extends RealDate {
  constructor(...a) { if (a.length) super(...a); else super(RealDate.now() + shift); }
  static now() { return RealDate.now() + shift; }
}
global.Date = ShiftedDate;
