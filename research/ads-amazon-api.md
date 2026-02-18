# Amazon Advertising API – KDP/KU focus

## What matters for KDP/KU authors
- Same Amazon Ads API used by sellers/brands; books use **Sponsored Products (SP)**, **Sponsored Brands (SB)**, **Sponsored Display (SD)**. No separate KDP API for ads.
- **CRITICAL: KENP/Pages Read is NOT in the Ads API.** It lives in KDP Reports. Must join KENP data from KDP with Ads reporting offline to compute true ACOS/ROAS for KU books. Most ad tools get this wrong.

## Key endpoints
- **Profiles** — get profile_id for the advertiser (KDP account). Required for all calls.
- **Campaigns / Ad Groups / Keywords / Products** — CRUD + state toggles; bid updates at keyword/target level
- **Budgets** — shared budgets, campaign budgets, budget rules
- **Negative keywords/targets** — pruning unprofitable search terms
- **Reports (async)** — campaigns, ad groups, keywords, product ads, **search terms** (critical), product targeting. SP/SB/SD each have report types.
- **Snapshots** — bulk entity exports for faster sync
- **Placements** — performance by placement for bid adjustments
- **Recommendations (beta)** — bid/keyword suggestions depending on region

## Credentials / onboarding
1. Register as an **Amazon Ads developer** in the Advertising console
2. Create app in **Amazon Advertising Console → Manage Applications** → get `client_id` / `client_secret` (Login With Amazon)
3. OAuth flow to obtain `refresh_token` (user grants `cpc_advertising:campaign_management`)
4. Call **/v2/profiles** to list profiles; choose the KDP advertiser `profile_id`
5. Use **Production** endpoint for live ads; Sandbox available for testing

## Rate limits
- Throttling per endpoint; headers: `x-amzn-RateLimit-Limit`, `x-amzn-RateLimit-Remaining`, `x-amzn-RateLimit-Reset`
- Typical SP limits: ~1 req/sec baseline; reports have stricter creation limits but allow polling
- Design client with backoff and header-aware pacing

## What can be automated
- Campaign/keyword/target creation at scale
- Bid optimization loops (CPC down on high-ACOS terms; up on winners)
- Negative harvesting from Search Term reports (auto → exact/phrase migration)
- Budget pacing rules (dayparting, shared budget shifts)
- Scheduled report pulls; join with KENP revenue for KU-aware ACOS
- SP auto campaigns for discovery; harvest profitable terms into exact campaigns

## Python library recommendation
**`python-amazon-ad-api`** (denisneuf) — actively maintained, covers SP/SB/SD v2/v3, good typing and retries.

## KU-specific note
Attribution window is short; KU earnings lag clicks. Store raw search term clicks and join with KENP payouts after the payout window closes to assess true value. SP auto campaigns are still best for discovery.
