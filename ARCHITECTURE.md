# Ad Management System — Architecture

## Purpose
A self-hosted, brand-agnostic tool for managing and automating ads across Amazon, Facebook/Instagram, and X/Twitter. Designed for small publishers and indie authors. Runs as a scheduled process on a single VM — no web UI required.

## Key design decisions

**Build on official SDKs, not reinvent:**
- Amazon: `python-amazon-ad-api`
- Facebook/Meta: `facebook-business`
- X/Twitter: `twitter-python-ads-sdk` (only when spend justifies it)

**No multi-platform management tool exists** — open source projects all do ingestion/reporting only. The control plane (bid changes, creative rotation, budget rules) is the gap we're filling.

**KU KENP is the critical special case:** Amazon KENP page-read revenue is not in the Ads API. It must be pulled from KDP Reports and joined offline. Any rotation rule for a KU book that ignores KENP will make wrong decisions. Treat KDP as the canonical source for KU revenue — always.

**Rule-based, not ML** at current scale. ML makes sense at $5k+/month spend with many creatives. At indie spend, rule-based with sensible thresholds is more reliable and explainable.

**Change Requests are the single execution primitive.** Nothing changes the outside world without going through a CR. See below.

---

## Change Requests — the execution spine

Every action that changes the outside world (bids, budgets, pauses, new campaigns, keyword adds/negatives) is a **Change Request (CR)**. Connectors can only execute approved CRs. This is what makes hard limits real and makes "AI suggests, humans decide" enforceable.

```
CR fields:
  id                — unique ID
  brand             — which brand
  platform          — amazon / facebook / twitter
  action            — UPDATE_BID / UPDATE_BUDGET / PAUSE / ADD_NEGATIVE / etc.
  entity_id         — platform entity (campaign/ad group/keyword ID)
  before            — current value
  after             — proposed value
  rationale         — why (from optimizer or human)
  risk_level        — low / medium / high
  status            — pending / approved / rejected / applied / rolled_back
  approved_by       — who approved (human name or "auto" if within pre-approved rules)
  applied_at        — timestamp
  last_changed_at   — timestamp of previous CR applied to this entity (for cooldown)
  expected_impact   — {spend_change_per_day, acos_direction, confidence} (for human review)
```

**Auto-approval rules** (no human needed):
- Bid change ≤ 15% in either direction on a known entity
- Budget change ≤ 15% in either direction
- Pausing a keyword that has ≥ 40 clicks and zero orders AND zero KENP
- Entity has not been changed within the last `min_days_between_changes` (default: 3 days)

**Human approval required:**
- Any new campaign or ad group creation
- Targeting additions or removals
- Creative rotations
- Any change flagged as risk_level = high
- Anything X/Twitter

CRs are stored in `data/{brand}/change-requests/` as JSON. The daily report summarizes all pending, applied, and rejected CRs.

---

## Directory structure

```
Ad-Management-System/
├── brands/
│   └── {brand-name}/
│       ├── config.json         ← ad account IDs, ASINs, rotation thresholds
│       ├── limits.json         ← hard spend caps (see SAFETY.md)
│       ├── creatives/          ← creative assets and metadata
│       └── rules.json          ← brand-specific rotation rules
├── platforms/
│   ├── amazon.py               ← Amazon Ads API connector
│   ├── amazon_reporting.py     ← AmazonReportingProvider (isolated — see note)
│   ├── facebook.py             ← Meta Marketing API connector
│   ├── twitter.py              ← X Ads API connector (or launch-packet generator)
│   └── kdp_reports.py          ← KDP KENP/royalties CSV ingest
├── scripts/
│   ├── pull_performance.py     ← daily data pull from all active platforms
│   ├── rotate_ads.py           ← generate CRs from rules; apply approved ones
│   ├── harvest_keywords.py     ← Amazon search term → exact campaign migration
│   ├── report.py               ← human-readable daily summary + CR inbox
│   └── resume.py               ← manual resume after emergency pause
├── data/
│   └── {brand}/
│       ├── amazon/{date}.json
│       ├── kdp/{date}.json
│       ├── facebook/{date}.json
│       ├── spend-log.json      ← local spend tracking (source of truth for limits)
│       └── change-requests/    ← all CRs, one file per run
├── logs/
│   └── {brand}/
│       ├── {date}.log          ← applied changes
│       └── alerts.log
├── research/                   ← platform research docs
└── .env                        ← credentials (gitignored)
```

---

## Amazon Reporting — isolated behind an interface

Amazon has been evolving its reporting API surfaces (new unified reporting beta, endpoint version migrations). **Do not couple rotation logic directly to any specific Amazon reporting endpoint.**

All Amazon reporting goes through `platforms/amazon_reporting.py` which exposes a stable internal interface:

```python
class AmazonReportingProvider:
    def get_keyword_performance(brand, date_range) -> list[KeywordMetrics]
    def get_search_term_report(brand, date_range) -> list[SearchTermMetrics]
    def get_campaign_summary(brand, date_range) -> list[CampaignMetrics]
```

The implementation behind this interface can be swapped as Amazon's API evolves. Rotation rules and the optimizer only call this interface — they never talk to Amazon endpoints directly.

---

## KU-aware ROI — BlendedACOS

Standard ACOS (`spend / ad-attributed sales`) is wrong for KU books because it misses page-read revenue entirely. Use BlendedACOS for all optimization decisions on KU-enrolled titles.

```
EffectiveRevenue = PaidEbookRoyalties
                 + PaperbackRoyalties
                 + AudiobookRoyalties  (if applicable)
                 + (KENP_Pages_Read * KENP_PayoutRate)

BlendedACOS = Spend / EffectiveRevenue

Profit = EffectiveRevenue - Spend
```

**KENP payout rate:** ~$0.004–$0.005/page, varies monthly. Store in `brands/{name}/config.json` as `kenp_rate` and update monthly. Log the date of each update.

**KENP lag:** Page reads typically lag ad clicks by 1–7 days. Don't evaluate a keyword's KU performance until at least 7 days after its last significant click volume. Store a `kenp_lag_days` value per brand (default: 7).

**BlendedACOS confidence flag:** KENP is not campaign-attributed — it's only attributed to an ASIN. When multiple campaigns run for the same ASIN simultaneously, or a campaign transition happens inside the lag window, BlendedACOS can credit the wrong campaign. Tag every calculation:

```
blended_acos_confidence:
  high   — only one active campaign for this ASIN during the full lag window
  medium — multiple campaigns, but no major changes or transitions
  low    — campaign transitions inside the lag window
```

- Auto-approve optimization CRs only on **high** or **medium** confidence
- **Never auto-approve** based on low-confidence BlendedACOS — flag for human review

**Two ROI views in every report:**
1. **Direct** — Amazon-reported attributed sales only (conservative, fast)
2. **Blended** — Direct + KDP KENP + royalties (true picture, lagged)

Optimization rules use Blended. Short-term alerts use Direct (available sooner).

**KDP ingest:** No public KDP API for royalties/KENP. Two options:
1. Manual: Kenneth/Charles download the CSV weekly from KDP portal, drop in `data/{brand}/kdp/`
2. Automated: Omnius uses Playwright to log into KDP dashboard and download the report. Treat this as read-only browser automation — no purchases or account changes.

---

## Brand config schema (`brands/{name}/config.json`)

```json
{
  "name": "new-paladin-order",
  "amazon": {
    "profile_id": "",
    "asins": ["B0...", "B0..."],
    "ku_enrolled": true,
    "kenp_rate": 0.0045,
    "kenp_lag_days": 7
  },
  "facebook": {
    "ad_account_id": "act_...",
    "pixel_id": ""
  },
  "twitter": {
    "account_id": "",
    "enabled": false
  },
  "campaign_roles": {
    "note": "Maps internal campaign names to core|experiment. Circuit breakers pause experiments first; core requires human approval to pause.",
    "examples": { "Sponsored Products - Auto": "core", "Sponsored Products - Test Broad": "experiment" }
  }
}
```

## Rotation rules schema (`brands/{name}/rules.json`)

```json
{
  "amazon": {
    "min_clicks_before_action": 25,
    "target_acos_percent": 40,
    "max_bid_change_per_day_percent": 15,
    "max_structural_changes_per_day": 1,
    "harvest_search_terms": true,
    "harvest_min_clicks": 10
  },
  "facebook": {
    "min_clicks_before_action": 20,
    "min_ctr_percent": 1.0,
    "max_frequency_before_rotate": 3.0,
    "creative_rotation_days": 7,
    "max_budget_change_per_day_percent": 15,
    "meta_safety_mode": true
  }
}
```

---

## Meta safety mode

Meta's learning phase is sensitive to frequent edits. When `meta_safety_mode: true` (default), the system restricts itself to:

**Allowed without high-risk approval:**
- Budget changes within ±15%/day
- Pausing/unpausing ad sets
- Adding new creatives to existing ad sets

**Forbidden (require high-risk CR + human approval):**
- Targeting resets or major targeting changes
- Conversion event swaps
- Bid strategy changes
- Rebuilding ad sets

**Cadence:** No more than 1 budget change per ad set per day. Creative rotations in weekly batches, not daily.

---

## X/Twitter — two modes

X Ads API requires manual approval and has high access friction. Design for both:

**Mode A — Launch Packets (default, no API needed):**
The system generates a "launch packet" for each proposed X campaign:
- Ad copy + creative spec
- Targeting summary
- Budget recommendation
- Policy checklist (character limits, prohibited claims, trademark check)
- Step-by-step upload instructions for Ads Manager

Human uploads manually. System logs the manual launch date and tracks spend from KDP reporting side.

**Mode B — API Connected (opt-in, when access approved):**
Full connector, same CR pattern, same spend caps. Still requires human approval for all CRs.

Switch via `brands/{name}/config.json`:
```json
"twitter": { "mode": "launch_packets" }  // or "api"
```

---

## Data flow

```
Daily cron (6 AM):
  pull_performance.py
    → AmazonReportingProvider → data/{brand}/amazon/{date}.json
    → kdp_reports.py          → data/{brand}/kdp/{date}.json   (KENP + royalties)
    → Facebook API            → data/{brand}/facebook/{date}.json

  rotate_ads.py (dry-run by default)
    → load today's data + KDP lag window
    → compute BlendedACOS per keyword/target
    → apply rules.json thresholds → generate CRs
    → auto-approve CRs within pre-approved rules
    → flag remaining CRs as pending (human review)
    → if --apply: execute approved CRs via platform APIs
    → SafetyGuard checks every CR before execution
    → log all applied changes

  harvest_keywords.py (weekly, Sunday)
    → scan Amazon search term report
    → migrate profitable auto terms to exact campaigns (as CRs)
    → propose negatives for waste terms (as CRs)

  report.py
    → spend today/week/month vs limits
    → BlendedACOS and Direct ACOS per brand
    → CR inbox: pending approvals + applied changes
    → circuit breaker status
    → email to epicfantasynovels@gmail.com
```

---

## Platforms: phased rollout

| Phase | Platform | Status | Notes |
|-------|----------|--------|-------|
| 1 | Amazon Ads | Build first | Highest ROI for KU books, most automatable |
| 2 | Facebook/Meta | After Amazon stable | Strong for 30-55 male fantasy; safety mode required |
| 3 | X/Twitter | Launch packets now, API later | High access friction; manual-assisted until API approved |

---

## Brands: starting config

| Brand | Amazon | Facebook | Twitter | Notes |
|-------|--------|----------|---------|-------|
| new-paladin-order | Yes | Yes | Launch packets | KU enrolled, KENP join required |
| epic-fantasy-novels | No | Maybe | Organic only | Affiliate/content, no direct book ads yet |

---

## Data model (SQLite, Postgres if scale demands it)

All persistent data goes into `data/ad_manager.db` (SQLite). Raw API responses are
also saved as daily JSON snapshots in `data/{brand}/{platform}/{date}.json` for
replay and debugging — but SQLite is the authoritative store for all analysis,
safety checks, and CR logic.

SQLite is the right choice at indie scale: zero server overhead, single file,
WAL mode for concurrent readers, and `sqlite3` ships with Python. Migrate to
Postgres if spend crosses ~$5k/month or if multiple brands require true parallel writes.

Initialize the database with:
```bash
python scripts/init_db.py
```

**Tables:**
```
books              — ASIN, title, series, marketplace, format, ku_enrolled
campaigns          — internal canonical campaigns (one per logical campaign)
platform_entities  — maps internal IDs → platform campaign/adgroup/creative IDs
change_requests    — full CR log with before/after/rationale/status
ad_metrics_daily   — platform-normalized: spend, clicks, impressions, orders, sales
kdp_metrics_daily  — KENP pages read, royalties, by ASIN/marketplace/date
spend_log          — every spend event (SafetyGuard's source of truth)
spend_reconciliation — daily local-vs-platform comparison results
audit_log          — every system action with timestamp, process, outcome
```

Full schema: `data/schema.sql`

Join key for BlendedACOS: `(asin, marketplace, date_range)`.

---

## Credentials needed to start

### Amazon Ads
- `AMAZON_ADS_CLIENT_ID`
- `AMAZON_ADS_CLIENT_SECRET`
- `AMAZON_ADS_REFRESH_TOKEN`
- `AMAZON_ADS_PROFILE_ID` (KDP advertiser profile)
- ASINs for all NPO books

### Facebook/Meta
- `META_ACCESS_TOKEN` (System User, long-lived)
- `META_AD_ACCOUNT_ID` (`act_...`)

### KDP Reports (for KENP join)
Manual CSV download from KDP portal (weekly), or Playwright automation by Omnius. No public KDP API for royalties.

---

## Open questions
1. Does NPO have an active Amazon Ads campaign? What campaigns/ad groups currently exist?
2. Is there a Facebook Business Manager account set up for NPO?
3. KDP KENP reports — Omnius can automate the CSV download via Playwright. Confirm KDP login credentials are available.
4. X/Twitter — start in launch-packet mode. Confirm whether API access application has been submitted.
5. KENP payout rate — pull from last 3 months of KDP royalty statements to calibrate `kenp_rate`.
