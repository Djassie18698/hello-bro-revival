// Error codes. Many game screens show the text the game's own table (Struct_String_Menu) has for the reply's code, not our <message>:
// code 5 there is "Your energy level is full", so every refusal showed that. server.js passes every code-5 reply through here,
// which picks a code whose game text fits the reason. The <message> stays, for the screens that show it.
const RULES = [
  [/log in/i, 10003],                                         // "This account doesn't exist" (login lock: old game file)
  [/gold/i, 10006],                                           // "You have insufficient gold!"
  [/silver/i, 10008],                                         // "You have insufficient silver!"
  [/energy|ramen/i, 10007],                                   // "You have insufficient energy!"
  [/already (bought|purchased)/i, 290105],                    // "You have already purchased this gift pack"
  [/already (claimed|signed|redeemed|received)/i, 170007],    // "You have already claimed, unable to claim again"
  [/sold out/i, 319001],                                      // "It is sold out"
  [/(event|festival) (is|has) (over|ended|expired)|has expired/i, 312000], // "This event has ended"
  [/already (collected|checked in) today/i, 170005],          // "You have already claimed today, please come again tomorrow."
  [/already opened/i, 170004],                                 // "Already claimed."
  [/already in a group|already hold this seat|you are already in/i, 120004], // "Already processed"
  [/Akatsuki is full/i, 480007],                               // "The group is full"
  [/name taken/i, 10002],                                      // "This account name has already been registered"
  [/cooling down|resting, try again/i, 180001],                // "In cd time"
  [/boss is already defeated/i, 315002],                       // "Boss has already been defeated"
  [/registration is closed/i, 323005],                         // "It is not time for registration"
  [/battle is Saturday|only during the battle/i, 323006],      // "It is not time for battle"
  [/no more morale boosts/i, 323007],                          // "You have reached the maximum number of morale boosts"
  [/free recruit not ready/i, 80003],                          // "Have not reached time for free card draw"
  [/no recruits left today/i, 80005],                         // "You have reached the daily limit of free card draw" (1-in-100 orders, 5 a day; 277 crashed the recruit dialog, GitHub #6)
  [/not enough recruitment orders/i, 297],                     // "You have insufficient recruitment orders"
  [/at the maximum|highest rebirth|all gates open/i, 190008],  // "You have reached the highest possible level"
  [/stage already cleared/i, 330001],                          // "You've cleared the level!"
  [/grudge is already full/i, 184],                           // "Energy and duel levels are full, you can continue your adventure!"
  [/can only be exchanged/i, 160011],                         // "Total exchange has reached its limits"
  [/no exchanges of this left today/i, 160012],               // "Today's exchange has reached its limits"
  [/no uses left today/i, 130003],                            // "You have reached the daily limit for using this item"
  [/only the chieftain|vice chieftain/i, 520002],             // "Insufficient Authority"
  [/nothing to claim|no such reward/i, 180007],               // "No rewards available to claim"
  [/climb \d+ floors|fighting power of/i, 160007],            // "You have not met requirements for claiming" / joining
  [/not enough|insufficient|no .* left|choose .*card|not reached/i, 277], // "Insufficient materials"
  [/not (open|available|unlocked)|first|upgrade|level|VIP/i, 166], // "Currently not open"
];
function fix(xml) {
  const m = /^<root code="5"([^>]*)>(?:<message>([^<]*)<\/message>)?/.exec(xml);
  if (!m) return xml;
  const msg = m[2] || '';
  const rule = RULES.find(([re]) => re.test(msg));
  return xml.replace(/^<root code="5"/, `<root code="${rule ? rule[1] : 8000}"`); // 8000 "Parameter error"
}
module.exports = { fix };
