// api/sources.js — user-suggested data sources for the collection engine
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
      const city = req.query.city ? String(req.query.city) : null;
      const result = city
        ? await sql`SELECT s.*, u.name AS suggested_by FROM sources s LEFT JOIN users u ON u.id = s.user_id WHERE s.city = ${city} OR s.city = 'Vietnam' ORDER BY s.created_at DESC`
        : await sql`SELECT s.*, u.name AS suggested_by FROM sources s LEFT JOIN users u ON u.id = s.user_id ORDER BY s.created_at DESC`;
      return res.status(200).json({ sources: result.rows });
    }
    if (req.method === 'POST') {
      const { name, url, city, kind, language, notes } = req.body || {};
      if (!name || !url || !city) return res.status(400).json({ error: 'name, url and city are required' });
      let cleanUrl = String(url).trim();
      if (!/^https?:\/\//i.test(cleanUrl)) cleanUrl = 'https://' + cleanUrl;
      const result = await sql`
        INSERT INTO sources (user_id, name, url, city, kind, language, notes)
        VALUES (${decoded.userId}, ${name}, ${cleanUrl}, ${city}, ${kind || 'website'}, ${language || 'vi'}, ${notes || null})
        RETURNING *
      `;
      return res.status(201).json({ source: result.rows[0] });
    }
    if (req.method === 'DELETE') {
      const id = Number(req.query.id);
      if (!id) return res.status(400).json({ error: 'id required' });
      const adm = await sql`SELECT is_admin FROM users WHERE id = ${decoded.userId}`;
      if (adm.rows[0]?.is_admin) await sql`DELETE FROM sources WHERE id = ${id}`;
      else await sql`DELETE FROM sources WHERE id = ${id} AND user_id = ${decoded.userId}`;
      return res.status(200).json({ ok: true });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Sources error:', error);
    return res.status(500).json({ error: 'Source operation failed' });
  }
}
