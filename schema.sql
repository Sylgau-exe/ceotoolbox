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
  source_url TEXT,
  confidence CHAR(1) NOT NULL CHECK (confidence IN ('H','M','L')),
  notes TEXT,
  collected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (city, code, period)
);
CREATE INDEX IF NOT EXISTS idx_indicators_city ON indicators(city);
CREATE INDEX IF NOT EXISTS idx_indicators_code ON indicators(city, code, period_date);
CREATE INDEX IF NOT EXISTS idx_indicators_category ON indicators(category);

-- ============ SAVED SCENARIOS (Module 1 decision tool) ============
CREATE TABLE IF NOT EXISTS scenarios (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  city VARCHAR(80) NOT NULL,
  name VARCHAR(255) NOT NULL,
  inputs JSONB NOT NULL,                -- levers + board requirements + assumptions
  outputs JSONB NOT NULL,               -- computed revenue + the two constraints
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_scenarios_user ON scenarios(user_id);

-- ============ SEED DATA — July 2026 research first pass ============
-- Sources: GSO/HCMC Dept of Tourism, VNAT, FocusEconomics, JLL, OTA scan (July 21-26, 2026).
-- L-confidence competitor prices are placeholders pending the v2 model rate-card verification.

INSERT INTO indicators (city, code, name, category, period, period_date, value, value_text, unit, source, source_url, confidence, notes, collected_at) VALUES
-- Tourism
('Ho Chi Minh City','intl_arrivals','International arrivals','tourism','2025','2025-12-31',8600000,NULL,'visitors/yr','GSO / HCMC Dept of Tourism',NULL,'H','2025 full-year figure','2026-07-21'),
('Ho Chi Minh City','intl_arrivals_target','International arrivals — city target','tourism','2026','2026-12-31',11000000,NULL,'visitors/yr','HCMC Dept of Tourism (announced target)',NULL,'M','Official 2026 target, not an actual','2026-07-21'),
('Vietnam','china_source_share','China share of international arrivals','tourism','2026','2026-06-30',25,NULL,'%','VNAT monthly releases',NULL,'M','China again #1 source market — Siam Niramit dependence risk applies','2026-07-21'),
-- Economy
('Vietnam','inflation_yoy','Inflation (CPI, year-over-year)','economy','2026-05','2026-05-31',5.6,NULL,'%','GSO / FocusEconomics',NULL,'M','Cost pressure on opex','2026-07-21'),
('Vietnam','vnd_usd_depreciation','VND depreciation vs USD (annual)','economy','2025','2025-12-31',4.5,NULL,'%/yr','Market data (SBV reference rate trend)',NULL,'M','4–5% band; USD-denominated production costs inflate','2026-07-21'),
-- Pricing
('Ho Chi Minh City','show_price_floor','Permanent-show price floor (VN market)','pricing','2026-07','2026-07-21',25,NULL,'USD','OTA scan (Klook/Traveloka) first pass',NULL,'M','Bottom of observed VN permanent-show band','2026-07-21'),
('Ho Chi Minh City','show_price_ceiling','Permanent-show price ceiling (A O Show)','pricing','2026-07','2026-07-21',69,NULL,'USD','OTA scan (Klook/Traveloka) first pass',NULL,'H','A O Show top tier = market ceiling','2026-07-21'),
('Ho Chi Minh City','ticket_aoshow','A O Show — reference gross ticket','pricing','2026-07','2026-07-21',1808000,NULL,'VND','OTA scan first pass',NULL,'H','~US$69 at 26,200 VND/USD; weight 40% in price analysis','2026-07-21'),
('Hoi An','ticket_hoian_memories','Hoi An Memories — reference gross ticket','pricing','2026-07','2026-07-21',700000,NULL,'VND','OTA scan first pass',NULL,'L','PLACEHOLDER — verify against v2 model rate card; weight 25%','2026-07-21'),
('Hanoi','ticket_tinh_hoa_bac_bo','Tinh Hoa Bac Bo — reference gross ticket','pricing','2026-07','2026-07-21',500000,NULL,'VND','OTA scan first pass',NULL,'L','PLACEHOLDER — verify against v2 model rate card; weight 20%','2026-07-21'),
('Phu Quoc','ticket_kiss_of_the_sea','Kiss of the Sea — reference gross ticket','pricing','2026-07','2026-07-21',900000,NULL,'VND','OTA scan first pass',NULL,'L','PLACEHOLDER — rate card is a known research gap; weight 15%','2026-07-21'),
('Vietnam','fx_vnd_usd','Exchange rate','economy','2026-07','2026-07-21',26200,NULL,'VND/USD','Market rate at collection',NULL,'M','Used for VND↔USD conversion in Module 1','2026-07-21'),
-- Infrastructure
('Ho Chi Minh City','hotel_revpar_yoy','Hotel RevPAR growth (YoY)','infrastructure','2026-Q1','2026-03-31',19,NULL,'%','JLL Vietnam hotel market report',NULL,'M','Q1 2026','2026-07-21'),
-- Benchmarks kept as pricing context
('Hoi An','hoian_memories_attendance','Hoi An Memories — nightly attendance','pricing','2019','2019-12-31',2000,NULL,'guests/night','Public reporting (pre-COVID)',NULL,'M','Only sustained VN success — captive resort context; post-2019 figure is a research gap','2026-07-21'),
-- Policy
('Vietnam','cultural_industries_strategy','National cultural-industries strategy','policy','2025-11','2025-11-30',NULL,'Performing arts named a priority sector in the November 2025 national cultural-industries strategy — leverage for licensing, land and incentives.',NULL,'Government of Vietnam (Nov 2025 strategy)',NULL,'H',NULL,'2026-07-21')
ON CONFLICT (city, code, period) DO NOTHING;

-- Verify
SELECT category, COUNT(*) FROM indicators GROUP BY category ORDER BY category;
