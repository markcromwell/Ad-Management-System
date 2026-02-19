-- Ad Management System — SQLite schema
-- Single database: data/ad_manager.db
-- Run via: python scripts/init_db.py

PRAGMA journal_mode = WAL;   -- safe for concurrent readers
PRAGMA foreign_keys = ON;

-- ─────────────────────────────────────────────
-- Books
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS books (
    id              INTEGER PRIMARY KEY,
    asin            TEXT NOT NULL,
    marketplace     TEXT NOT NULL DEFAULT 'US',   -- US, UK, DE, etc.
    brand           TEXT NOT NULL,
    title           TEXT NOT NULL,
    series          TEXT,
    format          TEXT NOT NULL,                -- ebook | paperback | audiobook
    ku_enrolled     INTEGER NOT NULL DEFAULT 0,   -- 0/1 boolean
    kenp_rate       REAL,                         -- $/page, updated monthly
    kenp_lag_days   INTEGER NOT NULL DEFAULT 7,
    active          INTEGER NOT NULL DEFAULT 1,
    UNIQUE(asin, marketplace, format)
);

-- ─────────────────────────────────────────────
-- Campaigns (internal canonical records)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS campaigns (
    id              INTEGER PRIMARY KEY,
    brand           TEXT NOT NULL,
    internal_name   TEXT NOT NULL,                -- human label, e.g. "NPO B1 SP Auto"
    campaign_role   TEXT NOT NULL DEFAULT 'core', -- core | experiment
    active          INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL,
    UNIQUE(brand, internal_name)
);

-- ─────────────────────────────────────────────
-- Platform entities
-- Maps our internal campaign IDs to platform-specific IDs
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform_entities (
    id              INTEGER PRIMARY KEY,
    campaign_id     INTEGER NOT NULL REFERENCES campaigns(id),
    platform        TEXT NOT NULL,                -- amazon | facebook | twitter
    entity_type     TEXT NOT NULL,                -- campaign | ad_group | keyword | ad_set | ad | creative
    platform_id     TEXT NOT NULL,                -- the ID in the platform's system
    name            TEXT,
    current_bid     REAL,
    current_budget  REAL,
    status          TEXT NOT NULL DEFAULT 'active',  -- active | paused | archived
    last_changed_at TEXT,                         -- timestamp of last CR applied to this entity
    UNIQUE(platform, entity_type, platform_id)
);

-- ─────────────────────────────────────────────
-- Change Requests — the execution spine
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS change_requests (
    id                          INTEGER PRIMARY KEY,
    created_at                  TEXT NOT NULL,
    brand                       TEXT NOT NULL,
    platform                    TEXT NOT NULL,
    action                      TEXT NOT NULL,    -- UPDATE_BID | UPDATE_BUDGET | PAUSE | UNPAUSE | ADD_KEYWORD | ADD_NEGATIVE | CREATIVE_ROTATION | ROLLBACK
    entity_id                   INTEGER REFERENCES platform_entities(id),
    entity_platform_id          TEXT,             -- denormalized for readability in reports
    before_value                TEXT,             -- JSON or scalar
    after_value                 TEXT,             -- JSON or scalar
    rationale                   TEXT NOT NULL,
    risk_level                  TEXT NOT NULL DEFAULT 'low',   -- low | medium | high
    status                      TEXT NOT NULL DEFAULT 'pending',  -- pending | approved | rejected | applied | rolled_back
    approved_by                 TEXT,             -- human name | 'auto:rule_name'
    applied_at                  TEXT,
    rollback_of_cr_id           INTEGER REFERENCES change_requests(id),
    blended_acos_confidence     TEXT,             -- high | medium | low (at time of CR creation)
    expected_spend_change       REAL,             -- per day estimate
    expected_acos_direction     TEXT,             -- up | down | stable
    expected_impact_confidence  TEXT              -- high | medium | low
);

CREATE INDEX IF NOT EXISTS idx_cr_brand_status  ON change_requests(brand, status);
CREATE INDEX IF NOT EXISTS idx_cr_created       ON change_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_cr_entity        ON change_requests(entity_id);

-- ─────────────────────────────────────────────
-- Ad metrics (daily, platform-normalized)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ad_metrics_daily (
    id              INTEGER PRIMARY KEY,
    date            TEXT NOT NULL,               -- YYYY-MM-DD
    brand           TEXT NOT NULL,
    platform        TEXT NOT NULL,
    entity_id       INTEGER REFERENCES platform_entities(id),
    entity_type     TEXT NOT NULL,               -- campaign | ad_group | keyword | ad_set
    spend           REAL NOT NULL DEFAULT 0,
    impressions     INTEGER NOT NULL DEFAULT 0,
    clicks          INTEGER NOT NULL DEFAULT 0,
    orders          INTEGER NOT NULL DEFAULT 0,
    sales           REAL NOT NULL DEFAULT 0,     -- attributed revenue (ad platform)
    direct_acos     REAL,                        -- spend / sales (NULL if sales = 0)
    source          TEXT NOT NULL DEFAULT 'api', -- api | csv | manual
    UNIQUE(date, brand, platform, entity_id, entity_type)
);

CREATE INDEX IF NOT EXISTS idx_metrics_date_brand ON ad_metrics_daily(date, brand);

-- ─────────────────────────────────────────────
-- KDP metrics (daily, per ASIN)
-- Source: KDP royalty CSV download
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS kdp_metrics_daily (
    id              INTEGER PRIMARY KEY,
    date            TEXT NOT NULL,
    asin            TEXT NOT NULL,
    marketplace     TEXT NOT NULL DEFAULT 'US',
    brand           TEXT NOT NULL,
    kenp_pages_read INTEGER NOT NULL DEFAULT 0,
    kenp_revenue    REAL NOT NULL DEFAULT 0,     -- pages * kenp_rate
    ebook_royalties REAL NOT NULL DEFAULT 0,
    paperback_royalties REAL NOT NULL DEFAULT 0,
    audiobook_royalties REAL NOT NULL DEFAULT 0,
    source_file     TEXT,                        -- filename of the CSV this came from
    UNIQUE(date, asin, marketplace)
);

CREATE INDEX IF NOT EXISTS idx_kdp_date_brand ON kdp_metrics_daily(date, brand);

-- ─────────────────────────────────────────────
-- Spend log (rolling daily/weekly/monthly totals)
-- This is SafetyGuard's source of truth — not the platform APIs
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS spend_log (
    id              INTEGER PRIMARY KEY,
    timestamp       TEXT NOT NULL,               -- ISO 8601 with timezone
    brand           TEXT NOT NULL,
    platform        TEXT NOT NULL,
    spend           REAL NOT NULL,
    cr_id           INTEGER REFERENCES change_requests(id),
    source          TEXT NOT NULL DEFAULT 'api', -- api | manual | reconciliation_adjustment
    notes           TEXT
);

CREATE INDEX IF NOT EXISTS idx_spend_ts    ON spend_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_spend_brand ON spend_log(brand, platform);

-- ─────────────────────────────────────────────
-- Spend reconciliation log
-- Records daily comparison between local log and platform-reported spend
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS spend_reconciliation (
    id                  INTEGER PRIMARY KEY,
    date                TEXT NOT NULL,
    brand               TEXT NOT NULL,
    platform            TEXT NOT NULL,
    local_spend         REAL NOT NULL,
    platform_spend      REAL NOT NULL,
    difference          REAL NOT NULL,
    within_tolerance    INTEGER NOT NULL,         -- 0/1
    tolerance_used      REAL NOT NULL,
    action_taken        TEXT NOT NULL,            -- 'none' | 'frozen' | 'alerted'
    resolved_at         TEXT,
    resolved_by         TEXT,
    UNIQUE(date, brand, platform)
);

-- ─────────────────────────────────────────────
-- Audit log
-- Every system action, whether it changed the world or not
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_log (
    id              INTEGER PRIMARY KEY,
    timestamp       TEXT NOT NULL,
    brand           TEXT,
    platform        TEXT,
    process         TEXT NOT NULL,               -- script name or 'human'
    action          TEXT NOT NULL,               -- what happened
    entity_ref      TEXT,                        -- optional: CR ID, entity ID, etc.
    outcome         TEXT NOT NULL,               -- success | blocked | error
    detail          TEXT                         -- free text, error messages, etc.
);

CREATE INDEX IF NOT EXISTS idx_audit_ts    ON audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_brand ON audit_log(brand);
