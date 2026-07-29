// api/auth/me.js (adapted to use db.js like BizSimHub)
import { sql } from '@vercel/postgres';
import { requireAuth, cors } from '../../lib/auth.js';
import { UserDB } from '../../lib/db.js';

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const decoded = await requireAuth(req, res);
  if (!decoded) return;

  try {
    const user = await UserDB.findById(decoded.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    let scenarioCount = 0;
    try {
      const sc = await sql`SELECT COUNT(*) as count FROM scenarios WHERE user_id = ${user.id}`;
      scenarioCount = parseInt(sc.rows[0].count) || 0;
    } catch (e) { /* table may not exist yet */ }

    return res.status(200).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        organization: user.organization,
        jobTitle: user.job_title,
        isAdmin: user.is_admin,
        authProvider: user.auth_provider,
        createdAt: user.created_at,
        assessmentCount: scenarioCount
      }
    });
  } catch (error) {
    console.error('Me error:', error);
    return res.status(500).json({ error: 'Failed to fetch user data' });
  }
}
