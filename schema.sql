-- CEO Toolbox — GSM Decision Platform · Database Schema
-- Run this in the Neon SQL Editor (https://console.neon.tech)

-- ============ USERS (auth foundation — do not modify) ============
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  password_hash VARCHAR(255),
  organization VARCHAR(255),
  job_title VARCHAR(255),
  experience_level VARCHAR(50),
  is_admin BOOLEAN DEFAULT false,
  email_verified BOOLEAN DEFAULT false,
  verification_token VARCHAR(255),
  google_id VARCHAR(255),
  auth_provider VARCHAR(50) DEFAULT 'email',
  reset_token VARCHAR(255),
  reset_token_expires TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============ INDICATOR BASE (Market Intelligence — one table of truth) ============
-- city × indicator × period × value  + source · URL · confidence · collected_at
CREATE TABLE IF NOT EXISTS indicators (
  id SERIAL PRIMARY KEY,
  city VARCHAR(80) NOT NULL,            -- 'Ho Chi Minh City', 'Hanoi', ... or 'Vietnam' (national)
  code VARCHAR(80) NOT NULL,            -- machine key, e.g. 'intl_arrivals'
  name VARCHAR(255) NOT NULL,           -- display name
  category VARCHAR(40) NOT NULL,        -- tourism | economy | pricing | infrastructure | policy
  period VARCHAR(20) NOT NULL,          -- '2025', '2026-05', '2026-Q1'
  period_date DATE NOT NULL,            -- sortable anchor for the period
  value NUMERIC,                        -- numeric value (NULL for text indicators)
  value_text TEXT,                      -- qualitative/policy indicators
  unit VARCHAR(40),                     -- 'visitors/yr', '%', 'VND', 'USD', ...
  source VARCHAR(255) NOT NULL,
  source_url TEXT,                      -- link to the source page/report
  archive_url TEXT,                     -- captured backup (PDF/snapshot) for audit
  confidence CHAR(1) NOT NULL CHECK (confidence IN ('H','M','L')),
  notes TEXT,
  collected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (city, code, period)
);
CREATE INDEX IF NOT EXISTS idx_indicators_city ON indicators(city);
CREATE INDEX IF NOT EXISTS idx_indicators_code ON indicators(city, code, period_date);
CREATE INDEX IF NOT EXISTS idx_indicators_category ON indicators(category);

-- ============ DATA SOURCES (user-suggested feeds for the collection engine) ============
CREATE TABLE IF NOT EXISTS sources (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  name VARCHAR(200) NOT NULL,
  url TEXT NOT NULL,
  city VARCHAR(80) NOT NULL,               -- city it covers, or 'Vietnam'
  kind VARCHAR(30) DEFAULT 'website',       -- website | spreadsheet | pdf | portal
  language VARCHAR(10) DEFAULT 'vi',
  notes TEXT,
  status VARCHAR(20) DEFAULT 'pending',     -- pending -> active once the collector reads it
  last_collected_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_sources_city ON sources(city);

-- ============ PROJECTS (Project Alpha — Da Nang, Project Delta — HCMC, ...) ============
CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(30),
  city VARCHAR(80) NOT NULL,
  status VARCHAR(30) DEFAULT 'exploration',   -- exploration | constraints-set | vendor-rfp | on-hold
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_projects_user ON projects(user_id);

-- ============ SAVED SCENARIOS (Module 1 decision tool) ============
CREATE TABLE IF NOT EXISTS scenarios (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  city VARCHAR(80) NOT NULL,
  name VARCHAR(255) NOT NULL,
  project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
  inputs JSONB NOT NULL,                -- levers + board requirements + assumptions
  outputs JSONB NOT NULL,               -- computed revenue + the two constraints
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_scenarios_user ON scenarios(user_id);

-- ============ OPPORTUNITIES (Decision Portfolio — Module 2) ============
CREATE TABLE IF NOT EXISTS opportunities (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  name VARCHAR(160) NOT NULL,
  city VARCHAR(80) NOT NULL,
  otype VARCHAR(40) DEFAULT 'new-show',      -- new-show | attraction | venue | partnership | phase2-revenue | other
  sponsor VARCHAR(120),
  objective TEXT,
  strategic_link TEXT,
  est_investment NUMERIC,                    -- US$M
  est_timeline VARCHAR(60),
  scores JSONB DEFAULT '{}',                 -- {strategic:0-5, market:0-5, financial:0-5, capability:0-5, risk:0-5}
  status VARCHAR(20) DEFAULT 'proposed',     -- proposed | scored | go | parked | rejected
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example charters (demo seeds — delete freely)
INSERT INTO opportunities (name, city, otype, sponsor, objective, strategic_link, est_investment, est_timeline, scores, status)
SELECT * FROM (VALUES
  ('Flagship theatrical show — downtown','Ho Chi Minh City','new-show','GSM BD','Permanent resident show anchored on the constraint sheet for HCMC','Entertainment pillar; feeds hotel & F&B nights',5.2,'18-24 months','{"strategic":5,"market":4,"financial":4,"capability":3,"risk":3}'::jsonb,'scored'),
  ('Anchor show — Da Nang market gap','Da Nang','new-show','GSM BD','Fill the permanent-show whitespace (~11M visitors, no theatrical anchor)','Sun World Ba Na Hills cross-sell; Da Nang Downtown synergy',4.3,'18 months','{"strategic":5,"market":4,"financial":3,"capability":3,"risk":2}'::jsonb,'scored'),
  ('Kiss of the Sea — phase-2 revenue build','Phu Quoc','phase2-revenue','GSM Ops','Add sponsorship, F&B and merchandising layers to the existing show','Existing asset; margin structures separate from tickets',0.8,'6 months','{"strategic":4,"market":3,"financial":4,"capability":5,"risk":4}'::jsonb,'proposed'),
  ('Venue partnership — Hanoi opera scene','Hanoi','partnership','GSM BD','Co-programming agreement instead of new build; test market before capex','Low-capex entry to northern market',1.5,'9 months','{"strategic":3,"market":3,"financial":3,"capability":4,"risk":4}'::jsonb,'proposed')
) AS v(name,city,otype,sponsor,objective,strategic_link,est_investment,est_timeline,scores,status)
WHERE NOT EXISTS (SELECT 1 FROM opportunities);

-- ============ SEED DATA — July 2026 research first pass ============
-- Sources: GSO/HCMC Dept of Tourism, VNAT, FocusEconomics, JLL, OTA scan (July 21-26, 2026).
-- L-confidence competitor prices are placeholders pending the v2 model rate-card verification.

INSERT INTO indicators (city, code, name, category, period, period_date, value, value_text, unit, source, source_url, confidence, notes, collected_at) VALUES
-- Tourism
('Ho Chi Minh City','intl_arrivals','International arrivals','tourism','2025','2025-12-31',8600000,NULL,'visitors/yr','GSO / HCMC Dept of Tourism','https://www.gso.gov.vn/en/statistical-data/','H','2025 full-year figure','2026-07-21'),
('Ho Chi Minh City','intl_arrivals_target','International arrivals — city target','tourism','2026','2026-12-31',11000000,NULL,'visitors/yr','HCMC Dept of Tourism (announced target)','https://sdl.hochiminhcity.gov.vn','M','Official 2026 target, not an actual','2026-07-21'),
('Vietnam','china_source_share','China share of international arrivals','tourism','2026','2026-06-30',25,NULL,'%','VNAT monthly releases','https://vietnamtourism.gov.vn/en/statistic','M','China again #1 source market — Siam Niramit dependence risk applies','2026-07-21'),
-- Economy
('Vietnam','inflation_yoy','Inflation (CPI, year-over-year)','economy','2026-05','2026-05-31',5.6,NULL,'%','GSO / FocusEconomics','https://www.focus-economics.com/countries/vietnam/','M','Cost pressure on opex','2026-07-21'),
('Vietnam','vnd_usd_depreciation','VND depreciation vs USD (annual)','economy','2025','2025-12-31',4.5,NULL,'%/yr','Market data (SBV reference rate trend)','https://www.sbv.gov.vn','M','4–5% band; USD-denominated production costs inflate','2026-07-21'),
-- Pricing
('Ho Chi Minh City','show_price_floor','Permanent-show price floor (VN market)','pricing','2026-07','2026-07-21',25,NULL,'USD','OTA scan (Klook/Traveloka) first pass','https://www.klook.com/en-US/city/33-ho-chi-minh-city/','M','Bottom of observed VN permanent-show band','2026-07-21'),
('Ho Chi Minh City','show_price_ceiling','Permanent-show price ceiling (A O Show)','pricing','2026-07','2026-07-21',69,NULL,'USD','OTA scan (Klook/Traveloka) first pass','https://www.klook.com/en-US/city/33-ho-chi-minh-city/','H','A O Show top tier = market ceiling','2026-07-21'),
('Ho Chi Minh City','ticket_aoshow','A O Show — reference gross ticket (tier avg)','pricing','2026-07','2026-07-28',1230000,NULL,'VND','OTA rate card (Klook)','https://www.klook.com/activity/7980-a-o-show-ticket-at-saigon-opera-house-ho-chi-minh-city/','H','Avg of adult tiers: aah US$31.65 / ooh US$40 / wow US$69.25 (≈US$47); ceiling US$69 kept as price_ceiling','2026-07-21'),
('Hoi An','ticket_hoian_memories','Hoi An Memories — reference gross ticket','pricing','2026-07','2026-07-21',700000,NULL,'VND','OTA scan first pass','https://www.klook.com/en-US/search/?query=vietnam%20show','L','PLACEHOLDER — verify against v2 model rate card; weight 25%','2026-07-21'),
('Hanoi','ticket_tinh_hoa_bac_bo','Tinh Hoa Bac Bo — reference gross ticket','pricing','2026-07','2026-07-21',500000,NULL,'VND','OTA scan first pass','https://www.klook.com/en-US/search/?query=vietnam%20show','L','PLACEHOLDER — verify against v2 model rate card; weight 20%','2026-07-21'),
('Phu Quoc','ticket_kiss_of_the_sea','Kiss of the Sea — reference gross ticket','pricing','2026-07','2026-07-21',900000,NULL,'VND','OTA scan first pass','https://www.klook.com/en-US/search/?query=vietnam%20show','L','PLACEHOLDER — rate card is a known research gap; weight 15%','2026-07-21'),
('Vietnam','fx_vnd_usd','Exchange rate','economy','2026-07','2026-07-21',26200,NULL,'VND/USD','Market rate at collection','https://www.sbv.gov.vn','M','Used for VND↔USD conversion in Module 1','2026-07-21'),
-- Infrastructure
('Ho Chi Minh City','hotel_revpar_yoy','Hotel RevPAR growth (YoY)','infrastructure','2026-Q1','2026-03-31',19,NULL,'%','JLL Vietnam hotel market report','https://www.jll.com/en-vn/insights','M','Q1 2026','2026-07-21'),
-- Benchmarks kept as pricing context
('Hoi An','hoian_memories_attendance','Hoi An Memories — nightly attendance','pricing','2019','2019-12-31',2000,NULL,'guests/night','Public reporting (pre-COVID)','https://hoianmemoriesland.com','M','Only sustained VN success — captive resort context; post-2019 figure is a research gap','2026-07-21'),
-- Policy
('Da Nang','total_visitors','Total visitors (intl + domestic)','tourism','2024','2024-12-31',10900000,NULL,'visitors/yr','Da Nang Dept of Tourism (via VietnamPlus)','https://en.vietnamplus.vn/da-nang-looks-to-attract-119-million-tourists-in-2025-post307707.vnp','M','+32.8% YoY; 2025 target 11.9M total','2026-07-28'),
('Da Nang','intl_arrivals_target','International arrivals — city target','tourism','2025','2025-12-31',4800000,NULL,'visitors/yr','Da Nang Dept of Tourism (via VietnamPlus)','https://en.vietnamplus.vn/da-nang-looks-to-attract-119-million-tourists-in-2025-post307707.vnp','M','2025 target, +17% vs 2024','2026-07-28'),
('Da Nang','tourism_revenue','Tourism revenue','economy','2024','2024-12-31',31,NULL,'trn ₫','Da Nang Dept of Tourism (via VietnamPlus)','https://en.vietnamplus.vn/da-nang-looks-to-attract-119-million-tourists-in-2025-post307707.vnp','M','~US$1.2bn; 2025 target 36 trn ₫','2026-07-28'),
('Da Nang','bana_hills_adult_ticket','Sun World Ba Na Hills — adult entry','pricing','2026','2026-04-22',950000,NULL,'VND','Da Nang tourism portal / Sun Paradise Land','https://sunparadiseland.com/en/SunParadiseLandDaNang/tin-tuc/ba-na-hills-ticket-prices-2026-cable-car-fares-and-saving-tips-7745','M','Range 750k–1,250k ₫ by period; SUN GROUP property; U25 promo from 500k (Jul 2026)','2026-07-28'),
('Da Nang','show_market_gap','Permanent-show market gap','pricing','2026-07','2026-07-28',NULL,'No permanent theatrical show currently operating in Da Nang — nearest comparable is Hoi An Memories (~30 km south). Whitespace for a GSM anchor show in a market of ~11M visitors/yr.',NULL,'OTA scan first pass','https://www.klook.com/en-US/search/?query=da%20nang%20show','M',NULL,'2026-07-28'),
('Vietnam','cultural_industries_strategy','National cultural-industries strategy','policy','2025-11','2025-11-30',NULL,'Performing arts named a priority sector in the November 2025 national cultural-industries strategy — leverage for licensing, land and incentives.',NULL,'Government of Vietnam (Nov 2025 strategy)','https://chinhphu.vn','H',NULL,'2026-07-21')
ON CONFLICT (city, code, period) DO NOTHING;

-- ============ TREND BACKFILL — historical series for key indicators (July 2026 research) ============
INSERT INTO indicators (city, code, name, category, period, period_date, value, value_text, unit, source, source_url, confidence, notes, collected_at) VALUES
-- Vietnam national international arrivals (recovery curve)
('Vietnam','intl_arrivals','International arrivals (national)','tourism','2019','2019-12-31',18000000,NULL,'visitors/yr','VNAT (pre-COVID peak)','https://vietnamtourism.gov.vn/en/statistic','M','Pre-COVID reference year','2026-07-28'),
('Vietnam','intl_arrivals','International arrivals (national)','tourism','2022','2022-12-31',3700000,NULL,'visitors/yr','VNAT','https://vietnamtourism.gov.vn/en/statistic','M','Reopening year','2026-07-28'),
('Vietnam','intl_arrivals','International arrivals (national)','tourism','2023','2023-12-31',12600000,NULL,'visitors/yr','VNAT','https://vietnamtourism.gov.vn/en/statistic','M',NULL,'2026-07-28'),
('Vietnam','intl_arrivals','International arrivals (national)','tourism','2024','2024-12-31',17500000,NULL,'visitors/yr','VNAT (+40% YoY)','https://b-company.jp/vietnam-tourism-in-2024-and-outlooks-for-2025/','M','Korea 4.1M top market; China 3.4M recovering','2026-07-28'),
('Vietnam','intl_arrivals','International arrivals (national)','tourism','2025','2025-12-31',21000000,NULL,'visitors/yr','VNAT via VietnamPlus','https://en.vietnamplus.vn/vietnam-welcomes-more-than-19-million-international-visitors-in-11-months-post333894.vnp','M','19M+ through Nov 2025; full-year estimate — record year','2026-07-28'),
-- HCMC international arrivals (recovery to pre-COVID)
('Ho Chi Minh City','intl_arrivals','International arrivals','tourism','2019','2019-12-31',8600000,NULL,'visitors/yr','HCMC Dept of Tourism (pre-COVID)',NULL,'M','Pre-COVID peak — 2025 = full recovery','2026-07-28'),
('Ho Chi Minh City','intl_arrivals','International arrivals','tourism','2024','2024-12-31',6100000,NULL,'visitors/yr','HCMC Dept of Tourism','https://b-company.jp/vietnam-tourism-in-2024-and-outlooks-for-2025/','M','38M domestic same year','2026-07-28'),
-- Da Nang total visitors
('Da Nang','total_visitors','Total visitors (intl + domestic)','tourism','2023','2023-12-31',8200000,NULL,'visitors/yr','Derived from +32.8% YoY (VietnamPlus)','https://en.vietnamplus.vn/da-nang-looks-to-attract-119-million-tourists-in-2025-post307707.vnp','M','Back-calculated from 2024 growth rate','2026-07-28'),
-- Vietnam inflation (yearly CPI)
('Vietnam','inflation_yoy','Inflation (CPI, year-over-year)','economy','2023','2023-12-31',3.25,NULL,'%','GSO annual CPI',NULL,'M',NULL,'2026-07-28'),
('Vietnam','inflation_yoy','Inflation (CPI, year-over-year)','economy','2024','2024-12-31',3.63,NULL,'%','GSO annual CPI',NULL,'M','Rising trend into 2026','2026-07-28'),
-- China source market share trend
('Vietnam','china_source_share','China share of international arrivals','tourism','2024','2024-12-31',19,NULL,'%','Derived: 3.4M of 17.5M (VNAT)','https://b-company.jp/vietnam-tourism-in-2024-and-outlooks-for-2025/','M','Doubled from 1.5M in 2023','2026-07-28')
ON CONFLICT (city, code, period) DO NOTHING;

-- Verify
SELECT category, COUNT(*) FROM indicators GROUP BY category ORDER BY category;
