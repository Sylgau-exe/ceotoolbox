// api/admin/stats.js - Admin dashboard statistics (CEO Toolbox)
import { sql } from '@vercel/postgres';
import { getUserFromRequest, cors } from '../../lib/auth.js';

// Accept Neon's DATABASE_URL when POSTGRES_URL is not set (Vercel marketplace integration)
if (!process.env.POSTGRES_URL && process.env.DATABASE_URL) { process.env.POSTGRES_URL = process.env.DATABASE_URL; }

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const decoded = getUserFromRequest(req);
  if (!decoded) return res.status(401).json({ error: 'Authentication required' });

  const adminCheck = await sql`SELECT is_admin FROM users WHERE id = ${decoded.userId}`;
  if (!adminCheck.rows[0]?.is_admin) return res.status(403).json({ error: 'Admin access required' });

  try {
    const userCount = await sql`SELECT COUNT(*) as count FROM users`;
    let scenarioCount = { rows: [{ count: 0 }] };
    let indicatorCount = { rows: [{ count: 0 }] };
    let newUsers7d = { rows: [{ count: 0 }] };
    let scenarios7d = { rows: [{ count: 0 }] };
    let cityDist = { rows: [] };

    try { scenarioCount = await sql`SELECT COUNT(*) as count FROM scenarios`; } catch(e) {}
    try { indicatorCount = await sql`SELECT COUNT(*) as count FROM indicators`; } catch(e) {}
    try { newUsers7d = await sql`SELECT COUNT(*) as count FROM users WHERE created_at > NOW() - INTERVAL '7 days'`; } catch(e) {}
    try { scenarios7d = await sql`SELECT COUNT(*) as count FROM scenarios WHERE created_at > NOW() - INTERVAL '7 days'`; } catch(e) {}
    try { cityDist = await sql`SELECT city as goal, COUNT(*) as count FROM scenarios GROUP BY city ORDER BY count DESC`; } catch(e) {}

    return res.status(200).json({
      overview: {
        totalUsers: parseInt(userCount.rows[0].count) || 0,
        totalAssessments: parseInt(scenarioCount.rows[0].count) || 0,   // scenarios (key kept for UI)
        totalLeads: parseInt(indicatorCount.rows[0].count) || 0,        // indicators (key kept for UI)
        avgOverallScore: 0,
        avgGapCount: 0
      },
      last7Days: {
        newUsers: parseInt(newUsers7d.rows[0].count) || 0,
        assessments: parseInt(scenarios7d.rows[0].count) || 0
      },
      goalDistribution: cityDist.rows
    });
  } catch (error) {
    console.error('Admin stats error:', error);
    return res.status(500).json({ error: 'Failed to fetch stats', details: error.message });
  }
}
