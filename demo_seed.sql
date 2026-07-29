-- CEO Toolbox — DEMO DATASET · 6 in-progress projects (different phases) + 7 opportunity assessments
-- ⚠ This clears the opportunities table first. Run in the Neon SQL Editor.

-- ensure newer columns exist (older deployments may lack them)
ALTER TABLE opportunities ADD COLUMN IF NOT EXISTS assessment JSONB DEFAULT '{}';
ALTER TABLE opportunities ADD COLUMN IF NOT EXISTS viability JSONB;

TRUNCATE opportunities RESTART IDENTITY;

INSERT INTO opportunities
(name, city, otype, sponsor, objective, strategic_link, est_investment, est_timeline, scores, status, assessment, viability) VALUES

-- ================= 6 PROJECTS IN PROGRESS (assessment.progress pins the phase) =================
('Flagship theatrical show — HCMC downtown','Ho Chi Minh City','new-show','GSM BD',
 'Permanent resident show anchored on the HCMC constraint sheet','Entertainment pillar; feeds hotel & F&B nights',
 5.2,'24 months','{"strategic":5,"market":4,"financial":4,"capability":3,"risk":3}','go',
 '{"progress":0.75,"phase":"Production"}',
 '{"city":"Ho Chi Minh City","date":"2026-05-12","inputs":{"seats":1200,"shows":300,"occupancy":0.65},"outputs":{"revenueUSD":6906000,"opexCeilingUSD":5870000,"maxInvestmentUSD":5180000,"netTicket":773409}}'),

('Anchor show — Da Nang market gap','Da Nang','new-show','GSM BD',
 'Fill the permanent-show whitespace (~11M visitors, no theatrical anchor)','Sun World Ba Na Hills cross-sell',
 3.9,'18 months','{"strategic":5,"market":4,"financial":3,"capability":3,"risk":2}','go',
 '{"progress":0.45,"phase":"Pre-production"}',
 '{"city":"Da Nang","date":"2026-06-02","inputs":{"seats":1200,"shows":300,"occupancy":0.60},"outputs":{"revenueUSD":5240000,"opexCeilingUSD":4450000,"maxInvestmentUSD":3930000,"netTicket":635817}}'),

('Sun World night parade — Ba Na Hills','Da Nang','attraction','GSM Ops',
 'Nightly parade extending guest dwell time and evening spend','Existing Sun World asset uplift',
 1.8,'12 months','{"strategic":4,"market":4,"financial":3,"capability":4,"risk":4}','go',
 '{"progress":0.20,"phase":"Planning"}',
 '{"city":"Da Nang","date":"2026-06-20","inputs":{"seats":0,"shows":330,"occupancy":0.7},"outputs":{"revenueUSD":2600000,"opexCeilingUSD":2210000,"maxInvestmentUSD":1650000,"netTicket":180000}}'),

('Kiss of the Sea — phase-2 revenue build','Phu Quoc','phase2-revenue','GSM Ops',
 'Sponsorship, F&B and merchandising layers on the existing show','Existing asset; margins separate from tickets',
 0.8,'6 months','{"strategic":4,"market":3,"financial":4,"capability":5,"risk":4}','go',
 '{"progress":0.90,"phase":"Production"}',
 '{"city":"Phu Quoc","date":"2026-07-01","inputs":{"seats":900,"shows":310,"occupancy":0.55},"outputs":{"revenueUSD":1900000,"opexCeilingUSD":1550000,"maxInvestmentUSD":1050000,"netTicket":420000}}'),

('Nha Trang beachfront amphitheater','Nha Trang','venue','GSM BD',
 'Open-air venue for touring + resident programming','Northern beach market entry; venue-first strategy',
 4.5,'20 months','{"strategic":4,"market":3,"financial":3,"capability":3,"risk":3}','go',
 '{"progress":0.08,"phase":"Initiation"}',
 '{"city":"Nha Trang","date":"2026-07-18","inputs":{"seats":1500,"shows":260,"occupancy":0.55},"outputs":{"revenueUSD":5100000,"opexCeilingUSD":4330000,"maxInvestmentUSD":3830000,"netTicket":610000}}'),

('Hanoi heritage light show','Hanoi','new-show','GSM BD',
 'Projection show on heritage architecture — opened Q1 2026','Policy tailwind: performing arts priority sector',
 2.4,'14 months','{"strategic":4,"market":4,"financial":4,"capability":4,"risk":3}','go',
 '{"progress":1.20,"phase":"Operation"}',
 '{"city":"Hanoi","date":"2025-11-10","inputs":{"seats":800,"shows":320,"occupancy":0.62},"outputs":{"revenueUSD":3200000,"opexCeilingUSD":2700000,"maxInvestmentUSD":2400000,"netTicket":520000}}'),

-- ================= 7 OPPORTUNITY ASSESSMENTS (3 scored · 3 proposed · 1 parked) =================
('James Bond 60th Anniversary event','Ho Chi Minh City','event','S. Gauthier',
 'IP anniversary event — projection show, one or multiple evenings','Brand halo; relationship with rights holders',
 0.9,'12 months','{"strategic":4,"market":4,"financial":3,"capability":4,"risk":3}','scored',
 '{"ip_owner":"EON, MGM/Amazon","intro":"Franchise anniversary; rights window open.","risks":[{"risk":"Creative","level":"low","strategy":"Proven creative team"},{"risk":"Production","level":"low","strategy":"Proven production team"},{"risk":"Profitability","level":"low","strategy":"Cost control and value-in-kind"}],"estimate":[{"topic":"Pre-production","cost":100000,"remark":"creative"},{"topic":"Production","cost":400000,"remark":"all front"},{"topic":"Marketing","cost":200000,"remark":""},{"topic":"Management","cost":200000,"remark":""}],"case":{"ticketing":{"best":1500000,"probable":1200000,"worst":900000,"assumptions":"avg ticket $150"},"sponsors":{"best":400000,"probable":250000,"worst":100000,"assumptions":""},"other":{"best":100000,"probable":50000,"worst":20000,"assumptions":"beverage, merch"},"cost":{"best":1200000,"probable":1250000,"worst":1300000,"assumptions":"incl. rights"}}}',
 NULL),

('Cirque-style resident show — Sunset Town','Phu Quoc','new-show','GSM BD',
 'Second resident show for the Sunset Town evening economy','Kiss of the Sea audience cross-sell',
 4.8,'20 months','{"strategic":5,"market":4,"financial":3,"capability":3,"risk":2}','scored',
 '{"intro":"Sunset Town evening traffic can absorb a second anchor."}',
 '{"city":"Phu Quoc","date":"2026-07-22","inputs":{"seats":1000,"shows":300,"occupancy":0.60},"outputs":{"revenueUSD":5600000,"opexCeilingUSD":4760000,"maxInvestmentUSD":4200000,"netTicket":700000}}'),

('Immersive digital art venue — Hanoi','Hanoi','venue','GSM BD',
 'TeamLab-style permanent immersive venue','Year-round, weather-proof, young domestic audience',
 1.2,'8 months','{"strategic":3,"market":4,"financial":4,"capability":3,"risk":4}','scored',
 '{"intro":"Digital art venues show strong Asia benchmarks; low labor intensity."}',
 NULL),

('Dinner theater concept — Nha Trang','Nha Trang','new-show','GSM BD',
 'Show + F&B single-ticket format for resort guests','Feeds the amphitheater pipeline; F&B margins',
 2.2,'14 months','{}','proposed','{"intro":"Resort partners requesting evening product."}',NULL),

('VR heritage experience — HCMC','Ho Chi Minh City','attraction','GSM BD',
 'Compact VR walk-through of Vietnamese history for tourists','High throughput, small footprint, mall-compatible',
 1.5,'10 months','{}','proposed','{"intro":"Two mall operators offered anchor space."}',NULL),

('Festival co-production — national','Vietnam','partnership','GSM BD',
 'Co-produce a touring festival with VNAT under the cultural-industries strategy','Policy alignment; low capex market testing',
 0.6,'6 months','{}','proposed','{"intro":"Nov 2025 strategy names performing arts a priority sector."}',NULL),

('Water puppet modernization tour','Vietnam','partnership','GSM BD',
 'Modernized water puppetry tour with contemporary staging','Heritage IP; export potential',
 0.4,'9 months','{}','parked','{"intro":"Parked pending festival co-production learnings."}',NULL);

-- verify
SELECT status, COUNT(*) FROM opportunities GROUP BY status ORDER BY status;
