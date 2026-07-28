// api/scenarios.js — save/list Module 1 scenarios
import { sql } from '@vercel/postgres';
import { cors, requireAuth } from '../lib/auth.js';

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  try {
    if (req.method === 'GET') {
      const result = await sql`
        SELECT id, city, name, inputs, outputs, created_at
        FROM scenarios WHERE user_id = ${decoded.userId}
        ORDER BY created_at DESC LIMIT 50
      `;
      return res.status(200).json({ scenarios: result.rows });
    }

    if (req.method === 'POST') {
      const { city, name, inputs, outputs } = req.body || {};
      if (!city || !name || !inputs || !outputs) {
        return res.status(400).json({ error: 'city, name, inputs and outputs are required' });
      }
      const result = await sql`
        INSERT INTO scenarios (user_id, city, name, inputs, outputs)
        VALUES (${decoded.userId}, ${city}, ${name}, ${JSON.stringify(inputs)}, ${JSON.stringify(outputs)})
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
