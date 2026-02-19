# Compliance & Platform Rules

This document covers platform Terms of Service constraints on automation,
rate limits, and how this system stays within them.

Last reviewed: February 2026. Review again whenever a platform updates its TOS.

---

## Amazon Advertising API

**Automation status:** Fully permitted via official API.

**Rate limits:**
- Sponsored Products: ~1 request/second per profile
- Reports API: varies by report type; treat as ~5 requests/minute
- Always check `x-amzn-ratelimit-limit` response headers and back off on 429

**What we do:**
- All bid/budget/keyword changes go through the official Amazon Ads API
- Never scrape Seller Central or advertising.amazon.com dashboards
- KDP KENP data: manual CSV download only. Playwright automation (if ever used) is explicitly rate-limited to weekly logins, read-only, and runs as a separately killable process

**What Amazon prohibits:**
- Accessing data via scraping (ToS violation, account risk)
- Automated account creation
- Using API to create campaigns faster than human-review pace

**Our safeguards:**
- 250–500ms delay between sequential API calls
- Change cooldowns (3-day minimum between changes to same entity) prevent hammering
- All actions logged with timestamps for audit

---

## Meta (Facebook / Instagram) Marketing API

**Automation status:** Fully permitted via official Marketing API.

**Rate limits:**
- Business use tier: ~200 calls/hour per ad account (quota is dynamic)
- Rate limit info in response headers: `x-business-use-case-usage`
- Avoid bulk changes in rapid succession — Meta tracks "edit velocity"

**What Meta permits:**
- Full automation of bids, budgets, creative rotation, pausing
- Third-party tools with explicit user authorization

**What Meta penalizes (not explicitly forbidden, but hurts performance):**
- Frequent edits during learning phase (resets 50-conversion learning window)
- Targeting changes that effectively rebuild an ad set
- More than 1 budget change per ad set per 15 minutes

**Our safeguards:**
- `meta_safety_mode: true` by default — forbids targeting resets and bid strategy changes without high-risk CR
- Max 1 budget change per ad set per day
- Creative rotations in weekly batches only
- Learning phase detection: system checks if ad set has exited learning before proposing structural changes

---

## X (Twitter) Ads API

**Automation status:** Requires manual approval; currently in launch-packet mode.

**When API access is approved:**
- Rate limits: ~100 requests/minute (generous)
- Automation explicitly permitted for third-party tools
- All CRs still require human approval (system rule, not platform requirement)

**What X prohibits:**
- Fake or automated accounts for ad management (we use the real account)
- Impersonating user actions

**Current mode:** Launch packets — system generates campaign specs for manual upload. No API calls until access is approved and `twitter.mode` is set to `"api"` in brand config.

---

## KDP / Amazon Author Central

**Automation status:** No public API. Manual CSV export only.

**Playwright fallback (if ever activated):**
- Login frequency: max once per week
- Actions: read-only report download only
- No purchases, no account setting changes
- Runs as isolated process with its own kill switch (`PLAYWRIGHT_KDP_ENABLED=true` env flag required)
- Session ends immediately after download
- Activity indistinguishable from a human downloading their own reports

**Default:** `PLAYWRIGHT_KDP_ENABLED` is unset (disabled). Manual CSV drop-in to `data/{brand}/kdp/` is the standard workflow.

---

## How This System Stays Compliant

1. **Official APIs only.** No scraping of ad dashboards. KDP is the one exception and defaults to manual.

2. **Rate limiting built in.** Delays between API calls. Batch changes rather than fire-and-forget loops.

3. **Change velocity is low by design.** 3-day cooldowns, 15% bid caps, weekly creative rotations, and 1 structural change per day all mean the system never generates burst traffic against platform APIs.

4. **Every action is logged.** `audit_log` in the database captures every API call with timestamp and outcome. If a platform ever asks "did you do X?" the answer is provable.

5. **Dry-run default.** New brands and post-config-change periods use zero write calls. Nothing can go wrong in dry-run.

6. **Git history is the compliance audit trail.** Every change to `rules.json`, `limits.json`, and `config.json` is version-controlled with timestamp and author.

---

## If a Platform Changes Its Rules

1. Update this document immediately.
2. Check whether any system behavior now violates the new rules.
3. If yes: set the brand to dry-run (`brands/{brand}/.dry_run_forced`) and do not re-enable until the code is updated.
4. Update the rate limit constants in `platforms/{platform}.py`.
