# CEO Toolbox — GSM Decision Platform

Demo build v1.0.0 · Confidential · Sun Group Entertainment (GSM) · Panda Projet Inc.

Two live modules: **Market Intelligence** (indicator base with source/confidence/freshness) and the **Vietnam Market Business Model** (city-configurable decision tool producing the two vendor constraints). Decision Portfolio, TCO and Company Dashboard shown as roadmap.

## Deploy (all via web UIs — no CLI)

### 1. GitHub
Upload the contents of this folder to https://github.com/Sylgau-exe/ceotoolbox (Add file → Upload files, drag everything, commit to `main`).

### 2. Neon (database)
1. console.neon.tech → create project `ceotoolbox` (region: Singapore `ap-southeast-1` — closest to Vietnam demo).
2. Open the **SQL Editor**, paste the full contents of `schema.sql`, Run. It creates `users`, `indicators`, `scenarios` and seeds the July 2026 research data (15 indicators).

### 3. Vercel
1. vercel.com → Add New → Project → import `Sylgau-exe/ceotoolbox`. Framework preset: **Other**. No build command.
2. Storage tab → Connect Store → link the Neon database (this auto-sets `POSTGRES_URL`), **or** set env var `POSTGRES_URL` manually from Neon's connection string.
3. Environment variables (Settings → Environment Variables):
   - `JWT_SECRET` — any long random string (required)
   - Optional (only for password-reset emails): `RESEND_API_KEY`, `FROM_EMAIL`
   - Optional (only for Google sign-in): `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI`
4. Deploy.

### 4. First accounts
1. Open the deployed URL → **Request access** → create your account.
2. In Neon SQL Editor: `UPDATE users SET is_admin = true WHERE email = 'sylgauthier@gmail.com';`
3. Sign out/in → Admin link appears. Create Corbo's account the same way (leave non-admin).

## Demo storyline
Market Intelligence (fresh numbers, sources, confidence) → Open in Market Business Model → set CEO levers + board requirements → the two constraints → Print Concept Constraint Sheet → "vendors design inside the boundaries."

## Validation
The web engine reproduces the v2 model defaults (1,200 seats · 300 shows · 65% occ · 15% margin · 5-yr payback): net ticket ~773k ₫, revenue ~US$6.9M/yr, opex ceiling ~US$5.9M/yr, max production investment ~US$5.2M. Sensitivity range US$2.9M–8.7M.

**Note:** the three L-confidence competitor ticket prices are placeholders pending the v2 rate-card verification — update them in the `indicators` table (codes `ticket_hoian_memories`, `ticket_tinh_hoa_bac_bo`, `ticket_kiss_of_the_sea`) and the model picks them up live.

## Post-funding roadmap (already architected)
Scheduled AI collector (monthly + on-demand, change detection) · MCP server on the indicator base (`indicator_get` / `history` / `update`) · Decision Portfolio (Proposal 2) · TCO · Company Dashboard.
