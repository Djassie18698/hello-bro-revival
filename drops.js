// A client <award> element for rewards that are not drops (festival trades, spending gifts). Drops go through game.grantDrop.
const el = (n, v) => `<${n}>${v}</${n}>`;

function awardXml(out, dropId = 0) {
  const cards = out.cards.map((c) => `<card>${el('id', c.id)}${el('type', c.type)}${el('num', 1)}${el('attri', 0)}${el('bagIndex', c.seq)}</card>`).join('');
  const props = Object.entries(out.props).map(([id, num]) => `<prop>${el('id', id)}${el('num', num)}</prop>`).join('');
  return `<award dropid="${dropId}"><cardlist>${cards}</cardlist><proplist>${props}</proplist><chipbag></chipbag>` +
    `<coin>${out.coin}</coin><cash>${out.cash}</cash><exp>0</exp><chip>0</chip><action>0</action><merit>0</merit><pk_action>0</pk_action><soul>0</soul></award>`;
}

module.exports = { awardXml };
