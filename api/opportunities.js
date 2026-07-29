// api/opportunities.js — Decision Portfolio: opportunity charters + scoring
import { sql } from '@vercel/postgres';
import { cors, requireAuth } from '../lib/auth.js';

if (!process.env.POSTGRES_URL && process.env.DATABASE_URL) { process.env.POSTGRES_URL = process.env.DATABASE_URL; }

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  try {
    if (req.method === 'GET') {
      const result = await sql`
        SELECT o.*, u.name AS created_by FROM opportunities o
        LEFT JOIN users u ON u.id = o.user_id
        ORDER BY o.updated_at DESC`;
      return res.status(200).json({ opportunities: result.rows });
    }
    if (req.method === 'POST') {
      const { name, city, otype, sponsor, objective, strategic_link, est_investment, est_timeline, scores, assessment } = req.body || {};
      if (!name || !city) return res.status(400).json({ error: 'name and city are required' });
      const result = await sql`
        INSERT INTO opportunities (user_id, name, city, otype, sponsor, objective, strategic_link, est_investment, est_timeline, scores)
        VALUES (${decoded.userId}, ${name}, ${city}, ${otype || 'new-show'}, ${sponsor || null}, ${objective || null},
                ${strategic_link || null}, ${est_investment || null}, ${est_timeline || null}, ${JSON.stringify(scores || {})})
        RETURNING *`;
      if (assessment) await sql`UPDATE opportunities SET assessment = ${JSON.stringify(assessment)} WHERE id = ${result.rows[0].id}`;
      return res.status(201).json({ opportunity: result.rows[0] });
    }
    if (req.method === 'PATCH') {
      const { id, name, city, otype, sponsor, objective, strategic_link, est_investment, est_timeline, scores, status, assessment, viability } = req.body || {};
      if (!id) return res.status(400).json({ error: 'id required' });
      const result = await sql`
        UPDATE opportunities SET
          name = COALESCE(${name}, name), city = COALESCE(${city}, city), otype = COALESCE(${otype}, otype),
          sponsor = COALESCE(${sponsor}, sponsor), objective = COALESCE(${objective}, objective),
          strategic_link = COALESCE(${strategic_link}, strategic_link),
          est_investment = COALESCE(${est_investment}, est_investment), est_timeline = COALESCE(${est_timeline}, est_timeline),
          scores = COALESCE(${scores ? JSON.stringify(scores) : null}, scores),
          assessment = COALESCE(${assessment ? JSON.stringify(assessment) : null}, assessment),
          viability = COALESCE(${viability ? JSON.stringify(viability) : null}, viability),
          status = COALESCE(${status}, status), updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id} RETURNING *`;
      return res.status(200).json({ opportunity: result.rows[0] });
    }
    if (req.method === 'DELETE') {
      const id = Number(req.query.id);
      if (!id) return res.status(400).json({ error: 'id required' });
      await sql`DELETE FROM opportunities WHERE id = ${id}`;
      return res.status(200).json({ ok: true });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Opportunities error:', error);
    return res.status(500).json({ error: 'Opportunity operation failed' });
  }
}
