// api/coach.js — AI Coach: scenario interviewer + analyst (Claude API)
import { cors, requireAuth } from '../lib/auth.js';

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  if (!process.env.ANTHROPIC_API_KEY) {
    return res.status(503).json({ error: 'Coach not configured — set ANTHROPIC_API_KEY in Vercel environment variables.' });
  }
  const { messages, context } = req.body || {};
  if (!Array.isArray(messages) || !messages.length) return res.status(400).json({ error: 'messages required' });

  const ctx = context || {};
  const system = [
    'You are the AI Coach inside "CEO Toolbox — GSM Decision Platform", used by Sun Group Entertainment (GSM) leadership in Vietnam to size permanent-show investments. You speak to executives: concise, concrete, numbers-first, never fluffy.',
    'The model logic (tickets only): weighted competitive reference price × positioning × net realization = avg NET ticket. Seats × shows/yr × occupancy × net ticket = revenue. Constraint #1 opex ceiling = revenue − required profit. Constraint #2 max production investment = required profit × payback years.',
    'TWO MODES: (1) INTERVIEWER — when asked to build a scenario, ask ONE question at a time (theater size → shows/week → occupancy basis → pricing position → board payback → required margin), acknowledging each answer, then propose the full scenario. (2) ANALYST — when asked to analyze, evaluate the current scenario against the market data and benchmarks; be direct about weak assumptions.',
    'KEY BENCHMARKS to apply: Siam Niramit Bangkok closed at ~30% occupancy (China source-market dependence — China is again #1 VN source at ~25%); Hoi An Memories ~2,000 guests/night is the only sustained VN success (captive resort context); capture-rate research suggests ~365K probable annual attendance for a HCMC show — occupancy commitments implying far more guests need justification; VN permanent-show price band US$25–69; Wanda Wuhan closed at 5% of projections; inflation ~5.6% and VND depreciation 4–5%/yr pressure USD-denominated costs.',
    'When you want to propose lever values, end your reply with a fenced block exactly like:\n```settings\n{"seats":1200,"shows":300,"occupancy":0.65,"positioning":1.10,"netRealization":0.78,"paybackYears":5,"margin":0.15}\n```\nOnly include keys you want to change. The user gets an Apply button.',
    'CURRENT CONTEXT: ' + JSON.stringify(ctx).slice(0, 4000),
    'Never invent market data beyond the context and benchmarks above; if data is missing, say what the Market Intelligence base should collect. Keep replies under 180 words unless doing a full analysis (max ~300).'
  ].join('\n\n');

  try {
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        model: process.env.COACH_MODEL || 'claude-sonnet-4-5',
        max_tokens: 1024,
        system,
        messages: messages.slice(-20)
      })
    });
    const data = await r.json();
    if (!r.ok) {
      console.error('Anthropic error:', data);
      return res.status(502).json({ error: (data.error && data.error.message) || 'AI service error' });
    }
    const reply = (data.content || []).map(b => b.text || '').join('');
    return res.status(200).json({ reply });
  } catch (error) {
    console.error('Coach error:', error);
    return res.status(500).json({ error: 'Coach request failed' });
  }
}
