# Ad Management System — Architecture

## Purpose
A self-hosted, brand-agnostic tool for managing and automating ads across Amazon, Facebook/Instagram, and X/Twitter. Designed for small publishers and indie authors. Runs as a scheduled process — no web UI required.

## Key design decisions (from research)

**Build on official SDKs, not reinvent:**
- Amazon: `python-amazon-ad-api`
- Facebook/Meta: `facebook-business`
- X/Twitter: `twitter-python-ads-sdk` (only when spend justifies it)

**No multi-platform management tool exists** — open source projects all do ingestion/reporting only. The control plane (bid changes, creative rotation, budget rules) is the gap we're filling.

**KU KENP is the critical special case:** Amazon KENP page-read revenue is not in the Ads API. It must be pulled from KDP Reports and joined offline. Any rotation rule for a KU book that ignores KENP will make wrong decisions.

**Rule-based, not ML** at current scale. ML makes sense at $5k+/month spend with many creatives. At indie spend, rule-based with sensible thresholds is more reliable and explainable.

---

## Directory structure

```
Ad-Management-System/
├── brands/
│   └── {brand-name}/
│       ├── config.json         ← ad account IDs, ASINs, rotation thresholds
│       ├── creatives/          ← creative assets and metadata
│       └── rules.json          ← brand-specific rotation rules
├── platforms/
│   ├── amazon.py               ← Amazon Ads API connector
│   ├── facebook.py             ← Meta Marketing API connector
│   ├── twitter.py              ← X Ads API connector
│   └── kdp_reports.py          ← KDP KENP data puller (joins with Amazon Ads)
├── scripts/
│   ├── pull_performance.py     ← daily data pull from all active platforms
│   ├── rotate_ads.py           ← apply rotation rules per brand
│   ├── harvest_keywords.py     ← Amazon search term → exact campaign migration
│   └── report.py               ← human-readable daily summary
├── data/
│   └── {brand}/{platform}/     ← daily snapshots (gitignored raw data)
├── logs/                       ← change log (what was changed, when, why)
├── research/                   ← platform research (this directory)
└── .env                        ← credentials (gitignored)
```

---

## Brand config schema (`brands/{name}/config.json`)

```json
{
  "name": "new-paladin-order",
  "amazon": {
    "profile_id": "",
    "asins": ["B0...", "B0..."],
    "ku_enrolled": true
  },
  "facebook": {
    "ad_account_id": "act_...",
    "pixel_id": ""
  },
  "twitter": {
    "account_id": "",
    "enabled": false
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
    "kenp_rate": 0.0045,
    "harvest_search_terms": true,
    "harvest_min_clicks": 10
  },
  "facebook": {
    "min_clicks_before_action": 20,
    "min_ctr_percent": 1.0,
    "max_frequency_before_rotate": 3.0,
    "creative_rotation_days": 7,
    "max_budget_change_per_day_percent": 15
  }
}
```

---

## Data flow

```
Daily cron (6 AM):
  pull_performance.py
    → Amazon Ads API → data/{brand}/amazon/{date}.json
    → KDP Reports    → data/{brand}/kdp/{date}.json   (KENP join)
    → Facebook API   → data/{brand}/facebook/{date}.json

  rotate_ads.py
    → load today's data
    → apply rules.json thresholds
    → make bid/budget/creative changes via platform APIs
    → log all changes to logs/{brand}/{date}.log

  harvest_keywords.py (weekly, Sunday)
    → scan Amazon search term report
    → migrate profitable auto terms to exact campaigns
    → add negatives for waste terms

  report.py
    → generate markdown summary
    → commit to repo (reviewable by humans + AI)
    → optionally email
```

---

## Platforms: phased rollout

| Phase | Platform | Justification |
|-------|----------|---------------|
| 1 | Amazon Ads | Highest ROI for KU books, most automatable |
| 2 | Facebook/Meta | Second priority, strong for 30-55 male fantasy |
| 3 | X/Twitter | Only when spend justifies API automation overhead |

---

## Brands: starting config

| Brand | Amazon | Facebook | Twitter | Notes |
|-------|--------|----------|---------|-------|
| new-paladin-order | Yes | Yes | Maybe | KU enrolled, KENP join required |
| epic-fantasy-novels | No | Maybe | Yes | Affiliate, no direct book ads yet |

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
- `KDP_EMAIL` / `KDP_PASSWORD` or export manually — KDP has no public API for royalty reports; may need browser automation or manual weekly export.

---

## Open questions
1. Does NPO have an active Amazon Ads campaign? What campaigns/ad groups currently exist?
2. Is there a Facebook Business Manager account set up for NPO?
3. KDP KENP reports — can Omnius automate the KDP dashboard export, or will these be pulled manually?
4. X/Twitter — what was the last campaign spend? Worth automating or manual-only for now?
