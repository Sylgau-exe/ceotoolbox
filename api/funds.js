// api/funds.js — investment funds available per year (portfolio summary)
import { sql } from '@vercel/postgres';
import { cors, requireAuth } from '../lib/auth.js';

if (!process.env.POSTGRES_URL && process.env.DATABASE_URL) { process.env.POSTGRES_URL = process.env.DATABASE_URL; }

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  const decoded = await requireAuth(req, res);
  if (!decoded) return;
  try {
    await sql`CREATE TABLE IF NOT EXISTS portfolio_funds (year INTEGER PRIMARY KEY, funds NUMERIC NOT NULL DEFAULT 0)`;
    if (req.method === 'GET') {
      const result = await sql`SELECT year, funds FROM portfolio_funds ORDER BY year`;
      return res.status(200).json({ funds: result.rows.map(r => ({ year: r.year, funds: Number(r.funds) })) });
    }
    if (req.method === 'PUT') {
      const { year, funds } = req.body || {};
      if (!year) return res.status(400).json({ error: 'year required' });
      await sql`
        INSERT INTO portfolio_funds (year, funds) VALUES (${year}, ${funds || 0})
        ON CONFLICT (year) DO UPDATE SET funds = ${funds || 0}`;
      return res.status(200).json({ ok: true });
    }
    if (req.method === 'DELETE') {
      const year = Number(req.query.year);
      if (!year) return res.status(400).json({ error: 'year required' });
      await sql`DELETE FROM portfolio_funds WHERE year = ${year}`;
      return res.status(200).json({ ok: true });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Funds error:', error);
    return res.status(500).json({ error: 'Funds operation failed' });
  }
}
