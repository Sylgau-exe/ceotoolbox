// api/projects.js — project folders (Project Alpha — Da Nang, Project Delta — HCMC, ...)
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
        SELECT p.*, COALESCE(s.cnt,0) AS scenario_count, s.latest_outputs
        FROM projects p
        LEFT JOIN (
          SELECT project_id, COUNT(*) AS cnt,
                 (ARRAY_AGG(outputs ORDER BY created_at DESC))[1] AS latest_outputs
          FROM scenarios WHERE project_id IS NOT NULL GROUP BY project_id
        ) s ON s.project_id = p.id
        WHERE p.user_id = ${decoded.userId}
        ORDER BY p.updated_at DESC
      `;
      return res.status(200).json({ projects: result.rows });
    }
    if (req.method === 'POST') {
      const { name, code, city, description } = req.body || {};
      if (!name || !city) return res.status(400).json({ error: 'name and city are required' });
      const result = await sql`
        INSERT INTO projects (user_id, name, code, city, description)
        VALUES (${decoded.userId}, ${name}, ${code || null}, ${city}, ${description || null})
        RETURNING *
      `;
      return res.status(201).json({ project: result.rows[0] });
    }
    if (req.method === 'PATCH') {
      const { id, name, code, city, description, status } = req.body || {};
      if (!id) return res.status(400).json({ error: 'id required' });
      const result = await sql`
        UPDATE projects SET
          name = COALESCE(${name}, name), code = COALESCE(${code}, code),
          city = COALESCE(${city}, city), description = COALESCE(${description}, description),
          status = COALESCE(${status}, status), updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id} AND user_id = ${decoded.userId} RETURNING *
      `;
      return res.status(200).json({ project: result.rows[0] });
    }
    if (req.method === 'DELETE') {
      const id = Number(req.query.id);
      if (!id) return res.status(400).json({ error: 'id required' });
      await sql`DELETE FROM projects WHERE id = ${id} AND user_id = ${decoded.userId}`;
      return res.status(200).json({ ok: true });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Projects error:', error);
    return res.status(500).json({ error: 'Project operation failed' });
  }
}
