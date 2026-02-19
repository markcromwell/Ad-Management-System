# Safety & Spend Limits

The ad system must never be able to spend more than explicitly configured.
Security and loss-limiting are first-class concerns, not afterthoughts.

---

## Hard spend limits

Every brand has a `limits.json` that sets hard caps. The system checks these
**before every API write call**. If a limit would be exceeded, the change is
blocked, logged, and an alert is sent. The system never assumes the ad platform
is reporting spend accurately in real time — it tracks its own spend log.

### Limits schema (`brands/{name}/limits.json`)

```json
{
  "currency": "USD",
  "amazon": {
    "daily_max": 20.00,
    "weekly_max": 100.00,
    "monthly_max": 350.00,
    "max_bid_per_keyword": 1.50,
    "max_campaign_daily_budget": 15.00,
    "alert_at_percent": 80
  },
  "facebook": {
    "daily_max": 20.00,
    "weekly_max": 100.00,
    "monthly_max": 350.00,
    "max_ad_set_daily_budget": 15.00,
    "alert_at_percent": 80
  },
  "twitter": {
    "daily_max": 10.00,
    "weekly_max": 50.00,
    "monthly_max": 150.00,
    "alert_at_percent": 80
  },
  "global": {
    "daily_max_all_platforms": 40.00,
    "monthly_max_all_platforms": 700.00,
    "emergency_stop_on_anomaly": true,
    "reconciliation_tolerance": 2.00,
    "error_window_minutes": 10
  }
}
```

**Limits are maximums, not targets.** Actual spend may be much lower.

---

## SafetyGuard — the enforcement layer

All platform API calls that spend money or change budgets/bids go through a
`SafetyGuard` wrapper. It is impossible to bypass by design.

```
SafetyGuard.check(brand, platform, action, estimated_cost)
  → pulls today/week/month spend from local spend log
  → adds estimated_cost
  → if any limit would be exceeded: BLOCK, log, alert, return False
  → if spend is above alert_at_percent: WARN, log, continue
  → if safe: log, return True

Only if SafetyGuard returns True does the actual API call proceed.
```

The spend log (`data/{brand}/spend-log.json`) is written locally by the system,
not pulled from the ad platform. Platform-reported spend can lag by hours.
Never trust platform real-time spend as the source of truth for limits.

---

## Modes of operation

### 1. dry-run (DEFAULT)
- Pulls data, runs rotation logic, logs what it *would* do
- Makes **zero** API write calls
- Default mode for all new brands and first 7 days after any config change
- Override with `--apply` flag

### 2. apply (explicit opt-in)
- Runs SafetyGuard checks, then executes changes
- Every change logged to `logs/{brand}/{date}.log` with: timestamp, platform,
  entity changed, old value, new value, reason

### 3. read-only
- Data pull only. No rotation logic. No changes.
- Used for reporting and monitoring.

### 4. emergency-pause (kill switch)
- Immediately pauses all campaigns on all platforms for a brand
- Creates `brands/{brand}/.paused` lockfile — system will not resume until
  lockfile is manually deleted
- Can be triggered: manually, by anomaly detection, or by hitting a limit

---

## Spend reconciliation

The local spend log is the source of truth for limits — but it can drift if a job fails, an API times out, or a partial day is missed. A daily reconciliation check catches this before it becomes a silent risk.

```
once per day, after data pull:
  for each brand / platform:
    local_spend = sum(spend-log.json entries for today)
    platform_spend = spend from platform API daily summary
    if abs(local_spend - platform_spend) > reconciliation_tolerance:
      freeze automation for that brand/platform
      alert human with both figures
```

`reconciliation_tolerance` defaults to `$2.00`. Store in `brands/{name}/limits.json`.

If reconciliation fails, the system does **not** apply any CRs for that brand until a human clears it. Reads and dry-runs are unaffected.

---

## Circuit breakers (automatic emergency stops)

The system halts and triggers emergency-pause if any of these are detected:

| Trigger | Threshold |
|---------|-----------|
| Daily spend spike | >150% of previous 7-day average daily spend |
| ACOS spike — non-KU | Direct ACOS > 300% of target for 2 consecutive days |
| ACOS spike — KU | Direct ACOS > 300% AND BlendedACOS > 300% after full lag window |
| Spend limit hit | Any daily/weekly/monthly limit reached |
| API error storm | >10 consecutive API errors within `error_window_minutes` (default: 10) |
| Anomalous bid | Any bid update that would be >3× the current bid |

**KU note:** For KU-enrolled titles, Direct ACOS alone can look catastrophic while BlendedACOS remains healthy. The KENP lag window makes day-to-day Direct ACOS noisy. Only trigger the breaker when both views confirm a problem.

**API error window:** Errors must be both consecutive *and* within the window. This prevents a slow overnight API blip from halting everything.

**Spend estimation confidence:** `SafetyGuard.check()` relies on `estimated_cost`, but CPC bids are not guaranteed spend. Tag each estimate with a confidence level:
- `high` — budget changes (fixed)
- `medium` — bid changes on stable, known-volume campaigns
- `low` — bid increases on high-volume or newly-ramping campaigns

`low` confidence estimates require human approval or are capped at a reduced delta (5% instead of 15%).

On circuit break: all campaigns paused, lockfile created, alert sent,
human review required before resuming.

---

## Security

**Credentials:**
- Stored in `.env` on the VM only — never in git
- Separate credential sets per platform — compromise of one does not affect others
- API tokens should have the minimum required permissions:
  - Amazon: `cpc_advertising:campaign_management` only
  - Facebook: `ads_management` only (not `business_management` if avoidable)
  - Twitter: ads account scoped

**VM access:**
- Only Omnius/OpenClaw runs the system processes
- SSH key auth only, no password auth
- System runs as a non-root user

**Budget guardrails in the ad platforms themselves (second layer):**
- Set campaign daily budgets in Amazon/Facebook Ads Manager as a backup cap
- These platform-side budgets should equal your `limits.json` daily caps
- Two independent systems both enforcing the same limits

---

## Alerting

When a limit is hit or a circuit breaker fires, the system:
1. Logs to `logs/{brand}/alerts.log`
2. Sends an email to `epicfantasynovels@gmail.com`
3. Creates `brands/{brand}/.paused` lockfile if it was a hard stop

The daily report (generated whether or not changes were made) includes:
- Spend today / this week / this month vs. limits (with % used)
- Any triggered circuit breakers
- A summary of all changes made (or in dry-run mode, would have made)

---

## Resume after pause

Manual process — human reviews, decides it's safe, then:

```bash
python scripts/resume.py --brand new-paladin-order --confirm
```

This deletes the lockfile and sends a confirmation log entry.
No automatic resumption. Ever.
