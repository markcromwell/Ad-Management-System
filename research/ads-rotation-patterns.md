# Automated ad rotation patterns

## Approach for indie/small advertisers: rule-based
ML approaches (multi-armed bandit, Bayesian estimators) are valid but require data volume. At indie spend levels, rule-based thresholds with sensible minimums are more reliable and explainable.

## Rule-based rotation
- Set **minimum data thresholds** before any action: 20–30 clicks (not impressions) for low-spend accounts. Impressions are cheap noise at indie volume.
- **Pause creatives** below CTR threshold vs. peers after threshold reached
- **Raise bids** on keywords with strong KENP/click and acceptable ACOS — small increments (5–15%) to avoid learning resets
- **Pause/negative** keywords above ACOS target after click threshold
- **Time-based creative swap** — rotate fresh creatives every 3–7 days or when frequency > 2–3 (Meta)
- **Search term harvesting** (Amazon) — auto campaign finds profitable terms, migrate to exact campaigns weekly

## Budget/bid automation rules
- Increase bids/budgets on winners by ≤15% per day to avoid learning resets
- Decrease/pause losers after consistent underperformance across multiple windows
- Keep an **evergreen control creative** — archive only after sustained underperformance

## KU-specific metric: KENP/click
- Standard ACOS = ad spend / (sale revenue). For KU, must add: KENP pages read / click × KENP rate (~$0.004–0.005/page)
- A keyword with zero purchases but high KENP reads can be profitable. Most tools miss this entirely.
- Join KDP Royalties Report (weekly KENP data) with Ads API search term data to compute **KU-adjusted ACOS**

## Key metrics
| Metric | Use |
|--------|-----|
| CTR | Early signal of creative appeal |
| CPC | Sanity check on bids |
| ACOS (adjusted for KENP) | Primary spend decision for KU books |
| Frequency (Meta) | Detect creative fatigue |
| Impression Share (Amazon) | Detect underdelivery / bid too low |
| KENP/click | KU-specific profitability signal |

## Cadence
- Pull data daily; evaluate and apply changes every 2–3 days at minimum spend
- Batch changes together — avoid mid-day edits on Meta (learning phase)
- Weekly: new creative review, search term harvest, negative keyword additions

## Anti-over-optimization
- Never make changes mid-learning phase on Meta/Google
- Cap daily bid changes at ±15%
- Keep a hold-out control creative at all times
- Log every change with timestamp and reason — makes debugging easy

## Published references
- Revive Adserver rules engine (self-hosted creative rotation patterns)
- Meta automated rules documentation (pause if CPA above target after N conversions)
- Madgicx / Optmyzr / AdEspresso blogs (practical rule sets for indie advertisers)
