# X / Twitter Ads API (current state)

## Access & status
- Ads API is **separate** from the public X API tiers. Requires an approved Ads API application and an active ad account in good standing.
- Access typically granted to managed/qualified advertisers; smaller accounts may need to request via the X Ads developer form. Public API paid tiers do **not** include Ads API.
- OAuth 1.0a user context is common; some endpoints support OAuth2.

## Capabilities
- Manage campaigns, line items, promotable tweets, targeting criteria, and funding instruments
- Analytics endpoints for entity-level stats (campaign/line item/ad/creative) with segmentation. Async jobs for larger windows.
- Tailored Audiences management (upload, list, delete) subject to whitelisting
- Creative is Tweet-first: promote existing Tweets or create draft promotable Tweets via main X API

## Python library
**`twitter-python-ads-sdk`** (official/maintained, ~500 ⭐) — supports core Ads API and async analytics.

## Rate limits
Returned in headers (`x-rate-limit-limit/remaining/reset`). Async analytics has separate throttles; plan for backoff and job polling.

## Practical assessment
- Approval friction is higher post-2023; expect manual review and potential spend minimums.
- For **low-volume ad spend**, manual Ads Manager is simpler. Automation is most valuable for **reporting**, **creative rotation/testing**, and **budget/bid rules** once meaningful spend is established.
- Tweet creation uses the core X API (paid tier), then Ads API references the Tweet ID for promotion — two separate systems.
- **Recommendation:** Start manual on X/Twitter. Add API automation only when monthly spend justifies the integration effort.
