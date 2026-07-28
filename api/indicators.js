// api/indicators.js — Market Intelligence indicator base (read API)
// GET /api/indicators?city=Ho%20Chi%20Minh%20City
// Returns national ('Vietnam') + city indicators, each with latest value + history.
import { sql } from '@vercel/postgres';
import { cors, requireAuth } from '../lib/auth.js';

// Accept Neon's DATABASE_URL when POSTGRES_URL is not set (Vercel marketplace integration)
if (!process.env.POSTGRES_URL && process.env.DATABASE_URL) { process.env.POSTGRES_URL = process.env.DATABASE_URL; }

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  const city = (req.query.city || 'Ho Chi Minh City').toString();

  try {
    const result = await sql`
      SELECT city, code, name, category, period, period_date, value, value_text,
             unit, source, source_url, archive_url, confidence, notes, collected_at
      FROM indicators
      WHERE city = ${city} OR city = 'Vietnam'
      ORDER BY code, period_date ASC
    `;

    // Group rows into indicator objects: latest + history
    const byKey = {};
    for (const row of result.rows) {
      const key = row.city + '|' + row.code;
      if (!byKey[key]) {
        byKey[key] = {
          city: row.city, code: row.code, name: row.name, category: row.category,
          history: []
        };
      }
      byKey[key].history.push({
        period: row.period, period_date: row.period_date, value: row.value === null ? null : Number(row.value),
        value_text: row.value_text, unit: row.unit, source: row.source, source_url: row.source_url, archive_url: row.archive_url,
        confidence: row.confidence, notes: row.notes, collected_at: row.collected_at
      });
    }
    const indicators = Object.values(byKey).map(ind => {
      const latest = ind.history[ind.history.length - 1];
      const prev = ind.history.length > 1 ? ind.history[ind.history.length - 2] : null;
      let trend = null;
      if (prev && latest.value != null && prev.value != null && prev.value !== 0) {
        trend = (latest.value - prev.value) / Math.abs(prev.value);
      }
      return { ...ind, latest, trend };
    });

    // Also expose the competitor ticket set (cross-city) for Module 1 price analysis
    const tickets = await sql`
      SELECT DISTINCT ON (code) city, code, name, value, unit, confidence, period, source, notes
      FROM indicators
      WHERE code LIKE 'ticket_%'
      ORDER BY code, period_date DESC
    `;

    return res.status(200).json({
      city,
      indicators,
      competitorTickets: tickets.rows.map(r => ({ ...r, value: r.value === null ? null : Number(r.value) })),
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('Indicators error:', error);
    return res.status(500).json({ error: 'Failed to load indicators' });
  }
}
