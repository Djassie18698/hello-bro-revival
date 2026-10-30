// Claude tool-use loop (manual, so it is easy to test with a fake client). Pure: knows nothing about Discord.
const MAX_TURNS = 12;

// Opus 5.5 needs adaptive thinking; server-side fallbacks route refusals to another model (disable with CLAUDE_FALLBACKS=0).
function request(client, params) {
  if (process.env.CLAUDE_FALLBACKS === '0') return client.messages.create(params);
  return client.beta.messages.create({ ...params, betas: ['server-side-fallback-2026-07-01'], fallbacks: 'default' });
}

const textOf = (content) => content.filter((b) => b.type === 'text').map((b) => b.text).join('\n').trim();

// tools: [{ def: {name, description, input_schema}, run: async (input) => string }]
async function runAgent({ client, model, system, tools, history = [], userText, log = () => {}, maxTurns = MAX_TURNS }) {
  const byName = new Map(tools.map((t) => [t.def.name, t]));
  const messages = [...history, { role: 'user', content: userText }];
  for (let turn = 0; turn < maxTurns; turn++) {
    const res = await request(client, {
      model, max_tokens: 16000, system, tools: tools.map((t) => t.def), messages,
      thinking: { type: 'adaptive' }, output_config: { effort: 'medium' },
    });
    if (res.stop_reason === 'refusal') return 'Claude declined that request.';
    if (res.stop_reason === 'max_tokens') return 'The answer got cut off (too long). Try asking for something smaller.';
    const calls = res.content.filter((b) => b.type === 'tool_use');
    if (!calls.length) return textOf(res.content) || 'Done.';
    messages.push({ role: 'assistant', content: res.content }); // unchanged: thinking blocks must be passed back as received
    const results = [];
    for (const c of calls) {
      const tool = byName.get(c.name);
      let out, isError = false;
      try {
        if (!tool) throw new Error('unknown tool ' + c.name);
        log('tool', c.name, JSON.stringify(c.input).slice(0, 300));
        out = await tool.run(c.input || {});
      } catch (e) { out = 'Error: ' + e.message; isError = true; }
      results.push({ type: 'tool_result', tool_use_id: c.id, content: String(out).slice(0, 30000), ...(isError ? { is_error: true } : {}) });
    }
    messages.push({ role: 'user', content: results }); // all results of one turn go in ONE user message
  }
  return 'I stopped after too many steps. Check the channels to see what already happened, then tell me what is left.';
}

module.exports = { runAgent, textOf, MAX_TURNS };
