# Facebook/Instagram (Meta) Marketing API

## How it works
- Graph API–based, versioned (v19+). Access tokens tied to a **Business App** + **Ad Account**.
- Permissions needed: `ads_management`, `business_management`. For custom audiences: `ads_read` / `read_insights`. App Review required for production.
- Objects: Business → Ad Account → Campaign → Ad Set → Ad. Creative assets via Ad Creative endpoints; audiences via Custom Audiences/Lookalikes.
- Insights endpoint provides aggregated metrics with breakdowns (age, gender, placement, device, etc.).

## What can be automated
- Campaign / Ad Set / Ad creation with targeting, placements, budgets (daily/lifetime), bid strategies (lowest cost, cost cap), optimization events
- **Creative rotation** — create multiple ad creatives; rotate by enabling/disabling based on performance; Dynamic Creative can auto-combine assets
- Bid/budget adjustments — rules on cost cap, bid, budget changes; dayparting via scheduling
- Audience management — create/update custom audiences (email/phone hashed), website custom audiences (requires pixel), lookalikes
- Reporting — scheduled Insights pulls with breakdowns; attribution window configurable

## Python library
**`facebook-business`** (official Business SDK) — covers all Marketing API objects, batch requests, retries.

## Credentials (existing ad account)
1. Create a Meta App at developers.facebook.com (set to Business type); enable Marketing API
2. Generate System User + Ad Account access via Business Manager; assign `ads_management` role
3. Get a **long-lived System User access token** with required scopes; store securely
4. Use Ad Account ID (`act_<id>`) in all SDK calls

## Quirks / gotchas for small advertisers
- **Rate limits** opaque; handled via `X-Ad-Account-Usage` header. Implement exponential backoff.
- **Ad review delays** and creative disapprovals are common; automate status polling and fallback handling.
- **Timezone** — Insights default to ad account timezone; specify `time_range` and `time_increment` explicitly.
- **Learning phase** — avoid frequent large edits (resets learning). Prefer incremental bid/budget changes (≤15% at a time).
- **System User tokens** don't expire; prefer over user tokens for server automation. Enforce 2FA on Business Manager.
