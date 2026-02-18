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
    "emergency_stop_on_anomaly": true
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

## Circuit breakers (automatic emergency stops)

The system halts and triggers emergency-pause if any of these are detected:

| Trigger | Threshold |
|---------|-----------|
| Daily spend spike | >150% of previous 7-day average daily spend |
| ACOS spike | ACOS > 300% of target for 2 consecutive days |
| Spend limit hit | Any daily/weekly/monthly limit reached |
| API error storm | >10 consecutive API errors (possible credential issue) |
| Anomalous bid | Any bid update that would be >3× the current bid |

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
