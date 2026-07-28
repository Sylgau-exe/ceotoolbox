// api/scenarios.js — save/list Module 1 scenarios
import { sql } from '@vercel/postgres';
import { cors, requireAuth } from '../lib/auth.js';

// Accept Neon's DATABASE_URL when POSTGRES_URL is not set (Vercel marketplace integration)
if (!process.env.POSTGRES_URL && process.env.DATABASE_URL) { process.env.POSTGRES_URL = process.env.DATABASE_URL; }

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  try {
    if (req.method === 'GET') {
      const pid = Number(req.query.project_id) || null;
      const result = pid
        ? await sql`SELECT id, city, name, project_id, inputs, outputs, created_at FROM scenarios WHERE user_id = ${decoded.userId} AND project_id = ${pid} ORDER BY created_at DESC LIMIT 50`
        : await sql`SELECT id, city, name, project_id, inputs, outputs, created_at FROM scenarios WHERE user_id = ${decoded.userId} ORDER BY created_at DESC LIMIT 50`;
      return res.status(200).json({ scenarios: result.rows });
    }

    if (req.method === 'POST') {
      const { city, name, inputs, outputs, project_id } = req.body || {};
      if (!city || !name || !inputs || !outputs) {
        return res.status(400).json({ error: 'city, name, inputs and outputs are required' });
      }
      const result = await sql`
        INSERT INTO scenarios (user_id, city, name, project_id, inputs, outputs)
        VALUES (${decoded.userId}, ${city}, ${name}, ${project_id || null}, ${JSON.stringify(inputs)}, ${JSON.stringify(outputs)})
        RETURNING id, city, name, created_at
      `;
      return res.status(201).json({ scenario: result.rows[0] });
    }

    if (req.method === 'DELETE') {
      const id = Number(req.query.id);
      if (!id) return res.status(400).json({ error: 'id required' });
      await sql`DELETE FROM scenarios WHERE id = ${id} AND user_id = ${decoded.userId}`;
      return res.status(200).json({ ok: true });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Scenarios error:', error);
    return res.status(500).json({ error: 'Scenario operation failed' });
  }
}
