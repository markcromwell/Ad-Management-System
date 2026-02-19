# Ad Management System — User Manual

**Who this is for:** Mark, Kenneth, Charles — the people who will actually run this system and approve its decisions.

**What this covers:**
- What the system does and why it works the way it does
- The ad platforms themselves (Amazon Ads, Facebook, KDP) — what they are, how to navigate them
- The key concepts you need to understand before approving anything
- Day-to-day operation once the system is live
- How to read the daily report
- How to approve or reject changes the system proposes
- What to do when something goes wrong

This manual assumes you have never run ads before and have never used these platforms. Start at the beginning.

---

## Table of Contents

1. [Big Picture — What This System Actually Does](#1-big-picture)
2. [Key Concepts You Must Understand](#2-key-concepts)
3. [The Platforms — What They Are and How to Navigate Them](#3-the-platforms)
   - [Amazon Ads](#31-amazon-ads)
   - [Amazon KDP](#32-amazon-kdp)
   - [Facebook / Meta Ads Manager](#33-facebook--meta-ads-manager)
   - [X / Twitter Ads](#34-x--twitter-ads)
4. [How the System Works — Step by Step](#4-how-the-system-works)
5. [The Daily Report — How to Read It](#5-the-daily-report)
6. [Change Requests — How to Approve or Reject Them](#6-change-requests)
7. [Spend Limits — Understanding the Safety Layer](#7-spend-limits)
8. [Emergency Procedures](#8-emergency-procedures)
9. [Initial Setup — What Has to Happen Before the System Can Run](#9-initial-setup)
10. [Glossary](#10-glossary)

---

## 1. Big Picture

### What problem does this solve?

When you run ads on Amazon, you have to make hundreds of small decisions constantly:

- Is this keyword worth the money I'm paying?
- Should I raise my bid on a keyword that's working?
- Should I cut a keyword that has spent $20 and sold nothing?
- Am I spending too much today?
- Is my ad profitable when I account for Kindle Unlimited page reads?

Doing this manually means checking into the ad dashboards every day, running the math yourself, and making judgment calls. At a small spend level it's manageable. As soon as you have dozens of campaigns and hundreds of keywords, it becomes a full-time job — and an inconsistent one, because humans get tired and forget.

This system watches the data for you, proposes changes based on rules you set, and either applies them automatically (for small safe changes) or puts them in front of you for approval (for anything significant).

### What the system does NOT do

- It does not make creative decisions — it won't write your ad copy, design images, or choose your targeting strategy. That's your job.
- It does not replace your judgment — it surfaces information and proposes actions. For most changes, a human approves or rejects them.
- It does not know your goals unless you configure them — you tell it your target ACOS (what percentage of revenue you're willing to spend on ads) and it works toward that.
- It does not create new campaigns on its own — creating a campaign always requires human approval.

### The core promise

The system will never surprise you with a large unexpected spend. Every dollar it spends is within limits you set in advance. If something goes wrong, it stops and waits for you.

---

## 2. Key Concepts

You need to understand these before you can read the daily report or approve changes intelligently.

---

### 2.1 How Amazon Ads Work (The Basics)

Amazon Ads are **pay-per-click**. You pay only when someone clicks your ad. You do not pay to show the ad.

The ad system runs an **auction**. When a shopper searches for "epic fantasy novels," Amazon runs an instant auction among all advertisers who have that keyword. The winner gets their ad shown. Your **bid** is the maximum you're willing to pay for one click on that keyword.

Higher bid = more likely to win the auction = more impressions (times your ad is shown).

But winning the auction doesn't mean profitable. You could pay $2 per click and never sell a book. Or you could pay $0.30 per click and sell a book on half those clicks. The job is finding the bids that produce profitable traffic.

**Campaign types:**
- **Sponsored Products** — your book shows up in search results and on product pages. This is the main campaign type for books.
- **Sponsored Brands** — a banner at the top of search results. Requires a registered trademark. Not relevant initially.
- **Sponsored Display** — your ad shows on other product pages. Works differently and is secondary.

**Targeting types within Sponsored Products:**
- **Automatic targeting** — Amazon decides which searches to show your ad for. Good for discovery. Less control.
- **Manual — keyword targeting** — you choose exact keywords ("epic fantasy paladin novel"). Full control. Must actively manage.
- **Manual — product targeting** — your ad shows on specific competitor book pages. Another approach, handled separately.

---

### 2.2 ACOS — The Core Metric

**ACOS = Advertising Cost of Sales**

```
ACOS = Ad Spend ÷ Ad-Attributed Sales Revenue × 100%
```

Example: You spend $10 on ads. A customer clicks and buys your $5 book. Amazon records that as an attributed sale.

```
ACOS = $10 ÷ $5 = 200%
```

That's terrible — you spent $10 to make $5.

A good ACOS depends on your royalty rate. If your book earns you $3.50 in royalties per sale at $5, your break-even ACOS is:

```
Break-even ACOS = $3.50 ÷ $5 = 70%
```

At 70% ACOS you're neither making nor losing money on ads. Below 70% you profit. Above 70% you lose.

Your system is configured with a **target ACOS** per brand. This is the threshold below which a keyword is considered profitable.

---

### 2.3 BlendedACOS — Why ACOS Alone Is Wrong for KU Books

If your books are in Kindle Unlimited (KU), readers can borrow them for free and you earn per page read. This revenue is called **KENP** (Kindle Edition Normalized Pages).

Amazon's ad reporting doesn't know about page reads. It only tracks purchases. So a customer might click your ad, borrow the book through KU, read the whole thing, earn you $4 in KENP — and Amazon's ad dashboard will show **zero sales** from that click.

This makes your ACOS look terrible even when the ad is working.

**BlendedACOS** fixes this:

```
Effective Revenue = Paid Ebook Royalties
                  + Paperback Royalties
                  + (KENP Pages Read × KENP Payout Rate)

BlendedACOS = Ad Spend ÷ Effective Revenue × 100%
```

The KENP payout rate is approximately $0.004–$0.005 per page and changes monthly. A 300-page book read through KU earns roughly $1.20–$1.50.

**The system uses BlendedACOS for all optimization decisions on KU books.**

This is why KDP data (where page read numbers come from) is critical — without it, the system is making decisions on incomplete information.

---

### 2.4 KENP Lag

There's a timing problem: when a customer clicks your ad today and borrows the book, they might read it over the next week. Those page reads only show up in your KDP reports 1–7 days later.

This means if you look at a keyword's performance today, the KENP revenue from recent clicks hasn't shown up yet. If you judge the keyword too early, it looks worse than it is.

The system handles this by waiting at least 7 days after significant click activity before making optimization decisions based on BlendedACOS. This is called the **KENP lag window**.

---

### 2.5 Change Requests — How the System Proposes Changes

The system never makes changes silently. Every change it wants to make — raise a bid, lower a budget, pause a keyword — is written up as a **Change Request (CR)**.

A Change Request looks like this:

```
ID:        CR-2026-0312-001
Brand:     new-paladin-order
Platform:  amazon
Action:    UPDATE_BID
Keyword:   "epic fantasy paladin"
Before:    $0.45
After:     $0.52 (+15.6%)
Rationale: Keyword has 52 clicks, 8 orders, BlendedACOS 31% vs 40% target.
           Profitable — raise bid to capture more traffic.
Risk:      low
Status:    pending
Expected:  Spend +$2.10/day, ACOS direction: stable
```

**Two outcomes:**
- **Auto-approved** — for small, safe changes within defined rules (bid change ≤15%, budget change ≤15%). The system applies these on its own but still logs them and reports them.
- **Pending human approval** — for anything bigger, riskier, or structural. These sit in the daily report waiting for you to say yes or no.

You will review pending CRs in the daily email and either approve or reject them.

---

### 2.6 The Safety Layer

The system has hard spending limits that cannot be overridden by any automation. Even if it decides to raise bids everywhere, it will stop if you're approaching your daily limit.

These limits are in a file you configure. Example for NPO:

```
Amazon daily max:   $20
Amazon monthly max: $350
All platforms daily: $40
All platforms monthly: $700
```

If the system would breach a limit, it blocks the change, logs it, and alerts you. It also watches the platform's own reported spend and compares it to its own log — if they differ by more than $2, it freezes automation and asks a human to investigate.

---

### 2.7 Dry-Run vs Apply

The system has two modes:

- **Dry-run** (default): The system analyzes everything and tells you what it would do, but does absolutely nothing. No API calls that change money. This is how it starts with every new brand. You can run dry-run forever if you want — useful for watching and learning.
- **Apply**: The system actually executes approved changes. You turn this on explicitly with `--apply`.

New brands run 7 days in dry-run before apply is available. This is enforced.

---

## 3. The Platforms

### 3.1 Amazon Ads

#### What it is

Amazon Advertising is a separate product from selling on Amazon. You log in at **advertising.amazon.com**, not seller central or KDP.

Your advertising account is linked to your KDP account (since you publish through KDP), but it's a separate dashboard.

#### Navigating the Amazon Ads Console

When you log in at advertising.amazon.com, you'll see a dashboard. The main sections you care about:

**Campaigns** — the top level. A campaign has a daily budget and contains one or more ad groups.

**Ad Groups** — a collection of ads targeting specific keywords. Inside a campaign, you might have one ad group for automatic targeting and one for manual keyword targeting.

**Keywords** — inside a manual ad group. Each keyword has a bid. This is the most granular thing the system manages.

**Search Term Report** — not the same as keywords. The search term report shows what shoppers actually typed when your keyword triggered. An automatic campaign targeting broadly might be triggered by hundreds of different search terms. This is how you discover new profitable keywords to add to manual campaigns.

**Portfolios** — optional organizational layer. The system creates one portfolio per brand to keep things organized and to set portfolio-level budgets as a backup cap.

#### Key pages you'll visit

- **Campaigns list**: advertising.amazon.com → your profile → Sponsored Products → Campaigns
- **Campaign detail**: click a campaign → shows ad groups and spend
- **Ad group detail**: click an ad group → shows keywords, bids, performance
- **Reports**: left sidebar → Reports → create a report → select "Search Terms" or "Keywords"
- **Bulk operations**: left sidebar → Bulk Operations → lets you download/upload spreadsheets

#### How a Sponsored Products campaign is structured

```
Campaign: "NPO Book 1 - Sponsored Products"
  Budget: $15/day
  Ad Group: "Auto"
    Targeting: Automatic (Amazon chooses)
    Ad: Book 1 (ASIN, cover image, title auto-populated)
  Ad Group: "Manual - Exact"
    Targeting: Manual
    Keyword: "epic fantasy paladin" | Bid: $0.45
    Keyword: "sword and sorcery fantasy" | Bid: $0.30
    Ad: Book 1
```

#### What the system manages on Amazon

- **Bid adjustments** — raises bids on profitable keywords, lowers on unprofitable ones
- **Keyword pausing** — pauses keywords with enough data showing no return
- **Keyword harvesting** — finds profitable search terms from the auto campaign and proposes adding them as exact keywords in the manual campaign
- **Negative keywords** — proposes adding wasteful search terms as negatives (so they stop triggering your ads)

#### What you do on Amazon Ads

Before the system can run, someone needs to:
1. Create the initial campaigns (the system doesn't create these — you do)
2. Add the ASINs (book identifiers) and set initial bids
3. Get the Amazon Ads API credentials (see Section 9)

After that, your main job is reviewing the daily report and approving structural changes the system proposes (new negative keywords, new exact keywords from harvesting).

---

### 3.2 Amazon KDP

#### What it is

KDP (Kindle Direct Publishing) is where Kenneth and Charles publish their books. It's at kdp.amazon.com.

The KDP dashboard has royalty reports that show:
- How many pages were read (KENP) per title per day
- Royalties from paid sales (ebook, paperback)

This data is **not** in the Amazon Ads API. The system needs it separately to calculate BlendedACOS.

#### How to get KENP reports

1. Log into kdp.amazon.com
2. Top navigation → **Reports** → **KDP Select Global Fund**
   - This shows total KENP earnings but not per-title detail
3. For per-title detail: **Reports** → **Month-to-Date Sales and Royalties**
   - Change view to "Royalties" tab
   - You can filter by title and see KENP pages read

**What the system needs:**
A CSV export of royalties by title by day. This currently requires a manual download. The process:

1. Log into kdp.amazon.com
2. Reports → Prior Months' Royalties
3. Select the date range (past 30 days covers the KENP lag window)
4. Click Download
5. Save the CSV to `data/new-paladin-order/kdp/` with the date as the filename (e.g. `2026-03-01.csv`)

The system picks this up automatically on its next run.

**Future:** Omnius can automate this download via browser automation. For now, it's a weekly manual task for Kenneth or Charles.

#### What to look for in KDP reports

- **KENP Pages Read** by title — how many pages were read through KU borrows
- **Royalties** — from paid purchases (ebook/paperback)
- **Date** — you want daily data, not just totals

If KENP is high relative to paid sales, your BlendedACOS will look much better than your Direct ACOS. This is normal and expected for popular KU books.

---

### 3.3 Facebook / Meta Ads Manager

#### What it is

Meta Ads Manager (ads.facebook.com) manages ads on Facebook and Instagram simultaneously. One ad can run on both.

For fantasy books, Facebook targets readers by interest — people who like fantasy fiction, specific authors, or related topics. You're not targeting search intent the way Amazon does. You're targeting people who fit a profile.

#### Campaign structure on Facebook

```
Campaign: "NPO Book 1 - Awareness"
  Objective: Traffic (to Amazon or website)
  Ad Set: "Fantasy Readers 35-55 Male US"
    Budget: $10/day
    Audience: Interests: fantasy fiction, sword-and-sorcery, epic fantasy
    Placement: Facebook feed, Instagram feed
    Ad: "NPO_Cover_V1"
      Image: book cover
      Copy: headline + body text
      Link: Amazon product page
```

Facebook's hierarchy: **Campaign → Ad Set → Ad**

The campaign sets the goal (traffic, conversions, awareness). The ad set sets the budget, schedule, and audience. The ad is the creative (image + copy).

#### The learning phase

Facebook's algorithm needs time to learn who actually clicks and converts. For the first 50 conversions after a new ad set launches, it's in a **learning phase**. During this phase:

- Results are unstable and unpredictable
- **You must not make significant changes** or the learning resets
- The system enforces this through Meta safety mode

The learning phase typically takes 1–2 weeks at modest spend levels. Be patient. Checking every day and making edits is the most common mistake with Facebook ads.

#### What the system manages on Facebook

- **Budget adjustments** — within ±15%/day. This is allowed even during learning.
- **Pausing/unpausing ad sets** — when performance is clearly poor
- **Creative rotation** — weekly batches, not daily. When frequency gets too high (the same person seeing your ad 3+ times), it rotates to a fresh creative.

**The system will not:**
- Change targeting without human approval (this resets the learning phase)
- Change bid strategy without human approval
- Rebuild ad sets without human approval

These are classified as high-risk and require explicit approval.

#### Navigating Meta Ads Manager

1. Go to **ads.facebook.com** (or business.facebook.com → Ads Manager)
2. Top left: select your ad account (should be the NPO account)
3. Three-column view: Campaigns → Ad Sets → Ads

**Key columns to look at:**
- Reach: how many unique people saw your ad
- Impressions: total times shown (impressions ÷ reach = frequency)
- Clicks (Link): people who clicked through to Amazon/website
- CTR (Link): click-through rate (links) — aim for >1%
- CPM: cost per 1,000 impressions
- Amount Spent: today's spend

**Frequency warning:** When frequency climbs above 3.0 (same person seeing ad 3+ times), performance drops and cost rises. This is when the system proposes a creative rotation.

#### What you need to set up on Facebook before the system runs

1. A Facebook Business Manager account
2. An ad account linked to it
3. A Facebook Page for The New Paladin Order (or EFN)
4. Creatives (images and ad copy) for at least 2–3 variations per campaign
5. Meta API credentials (see Section 9)

---

### 3.4 X / Twitter Ads

#### Why this works differently

X (formerly Twitter) Ads API requires manual approval. Access is not immediate and has a friction-heavy application process. While that's being sorted out — or if you decide the spend level doesn't justify the API work — the system works in **launch packet mode**.

#### What a launch packet is

Instead of the system directly creating campaigns in X Ads Manager, it generates a document for each proposed campaign with everything you need to set it up manually:

```
LAUNCH PACKET: NPO Book 1 - X Campaign
Generated: 2026-03-12

AD COPY
-------
Headline: "A mercenary. A cursed sword. A dying city."
Body: Join the New Paladin Order — old-school sword-and-sorcery fantasy.
      Free on Kindle Unlimited. [link]
Character counts: Headline 42/70 ✓ | Body 118/280 ✓

TARGETING
---------
Interests: Fantasy, Science Fiction & Fantasy Books, Epic Fantasy
Keywords: epic fantasy, sword and sorcery, fantasy novels
Follower lookalikes: Brandon Sanderson, Patrick Rothfuss, Joe Abercrombie

BUDGET RECOMMENDATION
---------------------
Daily budget: $5/day
Campaign duration: 14 days test
Total budget: $70

POLICY CHECKLIST
----------------
☑ No prohibited claims ("guaranteed bestseller" etc.)
☑ No trademark conflicts detected
☑ Character limits within spec
☑ No health/financial claims

UPLOAD INSTRUCTIONS
-------------------
1. Log into ads.twitter.com
2. Click "Create Campaign"
3. Objective: Website Traffic
[... step by step ...]
```

You take this document, log into ads.twitter.com, and set up the campaign manually. The system logs when you did it and tracks spend from there.

#### Navigating X Ads Manager

1. Go to **ads.twitter.com**
2. Log in with the @EpicFantasyNvls account (or whichever account is running the ads)
3. Dashboard shows active campaigns and spend
4. Create Campaign → Website Traffic or App Installs
5. Set targeting (interests, keywords, follower lookalikes)
6. Set budget and schedule
7. Upload creative (image + copy)

X ad targeting is generally weaker than Amazon or Facebook for book advertising. Start small, test, and don't expect the same ROI as Amazon.

---

## 4. How the System Works

### The daily cycle

Every day at 6 AM UTC, the following happens automatically (once set up on the VM):

```
Step 1 — PULL PERFORMANCE
The system pulls yesterday's data from:
  - Amazon Ads API → keywords, bids, spend, clicks, orders
  - Facebook API → campaigns, ad sets, spend, reach, clicks
  - KDP CSV folder → page reads, royalties (if a new file was dropped in)

Step 2 — ANALYZE
For each keyword / ad set:
  - Compute Direct ACOS (Amazon-reported sales only)
  - Compute BlendedACOS (including KENP, if within lag window)
  - Compare against target ACOS from rules.json
  - Check click thresholds (min 25 clicks before action)
  - Check cooldown (was this entity changed in the last 3 days?)

Step 3 — GENERATE CHANGE REQUESTS
For each entity that needs attention, write a CR:
  - Profitable keyword → raise bid up to 15%
  - Unprofitable keyword with sufficient data → lower bid up to 15%
  - Keyword with 40+ clicks, zero sales, zero KENP → propose pause
  - Auto campaign search terms → propose harvesting to exact campaigns
  - Facebook frequency >3.0 → propose creative rotation

Step 4 — AUTO-APPROVE OR FLAG
  - Small, safe CRs within pre-approved rules: mark "auto-approved"
  - Everything else: mark "pending" for human review

Step 5 — APPLY (if --apply mode is on)
  - For auto-approved CRs: execute via platform APIs
  - For pending CRs: do nothing, wait for human
  - SafetyGuard checks before every write call

Step 6 — RECONCILE SPEND
  - Compare local spend log to platform-reported spend
  - If difference > $2: freeze automation, alert human

Step 7 — GENERATE DAILY REPORT
  - Summary of all spend vs limits
  - All applied changes (what the system did)
  - All pending CRs (what it wants to do, waiting for you)
  - Any alerts or circuit breaker events
  - Email to epicfantasynovels@gmail.com
```

### Weekly cycle (Sundays)

The keyword harvesting script runs weekly:
- Reviews the auto-campaign search term report for the past 30 days
- Proposes profitable search terms for promotion to exact campaigns (as CRs)
- Proposes wasteful search terms for negatives (as CRs)
- These are always flagged for human approval, never auto-applied

---

## 5. The Daily Report

You'll receive a daily email at roughly 6–7 AM UTC. Here's how to read it.

### Section 1: Spend Summary

```
SPEND SUMMARY — 2026-03-12
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Brand: new-paladin-order

AMAZON
  Today:    $8.42  (limit: $20.00 | 42% used)
  This week: $44.10 (limit: $100.00 | 44% used)
  This month: $162.30 (limit: $350.00 | 46% used)
  Status: ✓ Normal

FACEBOOK
  Today:    $6.15  (limit: $20.00 | 31% used)
  This week: $32.80 (limit: $100.00 | 33% used)
  This month: $121.40 (limit: $350.00 | 35% used)
  Status: ✓ Normal

TOTAL ALL PLATFORMS
  Today:    $14.57 (limit: $40.00 | 36% used)
  This month: $283.70 (limit: $700.00 | 41% used)
  Status: ✓ Normal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to look for:**
- Any platform showing >80% of daily or monthly limit should catch your eye
- "FROZEN" status means reconciliation failed — see Section 8
- Circuit breaker events will appear in red here

### Section 2: Performance Summary

```
PERFORMANCE — 2026-03-12 (7-day rolling)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AMAZON — New Paladin Order
  Spend: $44.10 | Clicks: 312 | Orders: 18
  Direct ACOS: 68% (target: 40%) ← lagging KU revenue
  Blended ACOS: 38% ✓ (target: 40%)
  KENP pages read: 14,200 (est. $63.90)
  BlendedACOS confidence: HIGH

FACEBOOK — New Paladin Order
  Spend: $32.80 | Reach: 8,400 | Clicks: 142
  CTR: 1.68% ✓ (target: >1%)
  Frequency: 2.4 ✓ (warning at 3.0)
  Learning phase: complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to look for:**
- Direct ACOS higher than target is normal for KU books — look at Blended
- If BlendedACOS is also over target, something needs attention
- Facebook frequency approaching 3.0 means a creative rotation is coming soon
- BlendedACOS confidence of LOW means the numbers are unreliable (campaign change inside the lag window) — don't make decisions based on it

### Section 3: Changes Applied Today

```
CHANGES APPLIED — 2026-03-12 (auto-approved)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[CR-001] AMAZON | UPDATE_BID | "epic fantasy paladin"
  $0.45 → $0.52 (+15.6%)
  Reason: 52 clicks, 8 orders, BlendedACOS 31% vs 40% target. Profitable.
  Auto-approved. Applied 06:14 UTC.

[CR-002] AMAZON | UPDATE_BID | "sword and sorcery novel"
  $0.55 → $0.47 (-14.5%)
  Reason: 67 clicks, 2 orders, BlendedACOS 84% vs 40% target. Over target.
  Auto-approved. Applied 06:14 UTC.

[CR-003] AMAZON | PAUSE | "fantasy book series complete"
  Status: Active → Paused
  Reason: 44 clicks, 0 orders, 0 KENP pages. Sufficient data, no return.
  Auto-approved. Applied 06:14 UTC.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

These have already happened. You're reading a log, not a request for approval. Review these to stay informed — if something looks wrong, you can manually reverse it in the platform dashboard.

### Section 4: Pending Changes — Your Action Required

```
PENDING CHANGES — AWAITING YOUR APPROVAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[CR-004] AMAZON | ADD_KEYWORD | Add to Manual-Exact campaign
  Keyword: "paladin fantasy series"
  Proposed bid: $0.35
  Source: Auto campaign search term — 28 clicks, 4 orders, BlendedACOS 31%
  Reason: Profitable search term found in auto campaign. Harvest to exact.
  Risk: low
  Impact: Spend +$1.40/day est.

  APPROVE: reply with "approve CR-004"
  REJECT:  reply with "reject CR-004"

[CR-005] AMAZON | ADD_NEGATIVE | "free fantasy ebook"
  Add as negative keyword across all NPO campaigns.
  Reason: 31 clicks in auto campaign, 0 orders, clearly wrong intent.
  Risk: low

  APPROVE: reply with "approve CR-005"
  REJECT:  reply with "reject CR-005"

[CR-006] FACEBOOK | CREATIVE_ROTATION | Ad Set "Fantasy Readers 35-55"
  Current creative: NPO_Cover_V1 (frequency: 3.1 ⚠️)
  Proposed: rotate to NPO_Cover_V2
  Requires: NPO_Cover_V2 must be uploaded to creatives/ folder first.
  Risk: medium

  APPROVE: reply with "approve CR-006"
  REJECT:  reply with "reject CR-006"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

These have NOT happened yet. The system is waiting for you.

---

## 6. Change Requests

### How to approve or reject

When you receive the daily report, pending CRs need a response. Two ways to respond:

**Option 1: Reply to the email**
Reply with the CR IDs you're approving or rejecting:
```
approve CR-004
approve CR-005
reject CR-006
```

The system checks for replies and processes them at the next run.

**Option 2: Run the command manually**
```bash
python scripts/approve.py CR-004 CR-005
python scripts/reject.py CR-006
```

Either works.

### What to consider when approving

**For ADD_KEYWORD (harvesting):**
- Does this keyword make sense for your book?
- Is the data solid? (28+ clicks is a reasonable sample)
- Is the proposed bid reasonable? (look at what it would cost per day)

**For ADD_NEGATIVE:**
- Does this search term clearly have wrong intent? ("free" keywords, irrelevant topics)
- Would blocking it affect any of your current keywords? (the system checks this, but you can double-check)

**For CREATIVE_ROTATION:**
- Is the new creative actually ready and uploaded?
- Is the current creative truly fatigued (frequency >3.0)?

**For PAUSE:**
- 40 clicks with zero sales and zero KENP is a reasonable threshold
- But consider: is this a brand-new keyword that just needs more time? (the system checks cooldowns, but use your judgment)

### Auto-approved changes — when to override

The system auto-approves bid changes ≤15% and budget changes ≤15%. These happen without asking you. You'll still see them in the "Changes Applied" section of the daily report.

If you see an auto-approved change you disagree with, you can:
1. Manually go to the platform dashboard and reverse the change
2. Adjust the threshold in `rules.json` to tighten what gets auto-approved
3. Talk to whoever set up the system about changing the rules

---

## 7. Spend Limits

### Where limits live

Limits are in `brands/{brand-name}/limits.json`. For NPO, that's:
`brands/new-paladin-order/limits.json`

The file looks like:
```json
{
  "amazon": {
    "daily_max": 20.00,
    "monthly_max": 350.00,
    "max_bid_per_keyword": 1.50,
    "alert_at_percent": 80
  },
  ...
}
```

### How to change limits

Edit the file directly. Be careful:

```
max_bid_per_keyword: $1.50
```

This means the system will never set a bid above $1.50 on any keyword, no matter what the data says. If you're in a competitive category and want to bid higher, raise this.

```
daily_max: $20.00
```

This is the hard cap. The system stops all activity if this would be exceeded. If you want to scale up, raise this.

### When you get an alert

If spend hits 80% of any limit, you'll get a warning in the daily report. This isn't an emergency — it's a heads-up that you may hit the cap before the day ends.

If spend hits 100%, automation stops for that platform for the rest of the day. It resumes the next morning automatically.

### The reconciliation freeze

Once per day, the system compares its own spend log to what the platform reports. If they differ by more than $2, it freezes automation and sends you an alert like:

```
⚠️ RECONCILIATION MISMATCH — AMAZON — new-paladin-order
Local spend log: $14.20
Amazon reported: $17.85
Difference: $3.65 (over tolerance of $2.00)

Automation FROZEN until human review.
To unfreeze: python scripts/unfreeze.py --brand new-paladin-order --platform amazon
```

Before unfreezing, check the Amazon Ads console to see what actually happened. Common causes:
- A campaign budget got changed directly in the console (bypassing this system)
- A script ran twice due to a timing issue
- Amazon reported spend is genuinely higher than expected

Once you've confirmed it's safe, run the unfreeze command.

---

## 8. Emergency Procedures

### Pause everything immediately

If something looks wrong — spend spiking, wrong campaigns running, anything unexpected — run:

```bash
python scripts/emergency_pause.py --brand new-paladin-order
```

This:
1. Pauses every campaign on every platform for that brand via API
2. Creates a lockfile (`brands/new-paladin-order/.paused`)
3. Sends you a confirmation email
4. Refuses to run any further automation until the lockfile is manually deleted

**Alternatively**, you can go directly to the platform dashboards and pause campaigns manually. This bypasses the system but is perfectly fine in an emergency.

### What triggers automatic emergency pause

The system pauses itself if:
- Daily spend spikes to >150% of the past 7-day average
- ACOS is over 300% of target for 2 consecutive days (Direct AND Blended for KU)
- Any daily or monthly limit is hit
- The Amazon or Facebook API starts failing consistently (>10 errors in 10 minutes — may indicate credential issue)
- A proposed bid would be >3× the current bid

When this happens you get an alert immediately. Do not dismiss it without investigating.

### Resume after an emergency pause

```bash
python scripts/resume.py --brand new-paladin-order --confirm
```

The `--confirm` flag is required. This is intentional — you can't accidentally resume. Read the daily report first, understand why it paused, and only resume when you're confident it's safe.

There is **no automatic resumption**. The system will sit paused indefinitely until you explicitly resume it.

### If the system crashes entirely

If Omnius's VM goes down or the cron jobs stop running, the worst that happens is: **nothing**. The system doesn't send commands to platforms. The platforms keep running whatever campaigns were last configured. Your campaigns don't go haywire — they just don't get optimized.

This is by design. Inaction is always safer than wrong action.

When the VM comes back, the system will pick up with the current day's data and run normally. It won't try to "make up" for missed days.

---

## 9. Initial Setup

This section describes what has to be done before the system can run for a brand.

### 9.1 Amazon Ads setup

**Step 1: Create an Amazon Ads account (if not already done)**
- Go to advertising.amazon.com
- Sign in with the KDP account
- The publisher profile should already exist if books are being advertised

**Step 2: Note your profile ID**
- advertising.amazon.com → top right → account name → Profile ID
- This goes into `brands/new-paladin-order/config.json` as `amazon.profile_id`

**Step 3: Get API credentials**
Amazon Ads API access requires applying through the Amazon Ads developer program:
- Go to advertising.amazon.com → API access (bottom of dashboard or help section)
- Apply for self-service API access
- You'll get a `Client ID` and `Client Secret`
- You then do an OAuth flow to get a `Refresh Token`
- These go into the VM's `.env` file as `AMAZON_ADS_CLIENT_ID`, `AMAZON_ADS_CLIENT_SECRET`, `AMAZON_ADS_REFRESH_TOKEN`

**Step 4: Create initial campaigns**
The system does not create campaigns — it manages existing ones. Before the system can optimize, someone needs to create at least one Sponsored Products campaign with:
- An auto-targeting ad group (let Amazon find initial traffic)
- A manual exact-match ad group (for keywords you already know work)
- A daily budget set

A reasonable starting structure for NPO Book 1:
- Campaign: "NPO B1 - SP Auto" | Budget: $5/day
- Campaign: "NPO B1 - SP Manual Exact" | Budget: $8/day

**Step 5: Add ASINs to config**
Find the ASIN for each book (it's in the book's Amazon listing URL: `.../dp/BXXXXXXXX/`). Add to `brands/new-paladin-order/config.json`.

**Step 6: Set limits**
Fill in `brands/new-paladin-order/limits.json` with comfortable numbers. Start conservative:
- Amazon daily max: $15
- Monthly max: $300
You can always raise these later.

**Step 7: Run in dry-run for 7 days**
```bash
python scripts/pull_performance.py --brand new-paladin-order
python scripts/rotate_ads.py --brand new-paladin-order
python scripts/report.py --brand new-paladin-order
```

No `--apply` flag means nothing changes. Review the reports and see if the system's proposed changes make sense.

**Step 8: Enable apply**
After 7 days of dry-run that look reasonable:
```bash
python scripts/rotate_ads.py --brand new-paladin-order --apply
```

### 9.2 Facebook setup

**Step 1: Create a Business Manager account**
- business.facebook.com → Create Account
- Follow prompts, connect your Facebook Page

**Step 2: Create an Ad Account**
- Business Manager → Accounts → Ad Accounts → Create New
- Note the Ad Account ID (starts with `act_`)
- Add it to `brands/new-paladin-order/config.json` as `facebook.ad_account_id`

**Step 3: Get API credentials**
- Business Manager → System Users → Add → Admin
- Generate token with `ads_management` and `ads_read` permissions
- This is the `META_ACCESS_TOKEN` in `.env`

**Step 4: Create initial campaigns and upload creatives**
Create at least 2 ad variations (different images or copy). The system needs alternates to rotate to.

Save creative assets to `brands/new-paladin-order/creatives/` with metadata.

**Step 5: Set limits and run dry-run for 7 days**
Same process as Amazon.

### 9.3 KDP CSV setup

**For now (manual):**
Once per week, someone with KDP access downloads the royalty report:

1. kdp.amazon.com → Reports → Prior Months' Royalties
2. Download CSV
3. Drop it into `data/new-paladin-order/kdp/YYYY-MM-DD.csv`

The system will pick it up at next run.

**File naming:** Use the date of the report's end date as the filename.

---

## 10. Glossary

**ACOS** — Advertising Cost of Sales. Ad spend ÷ attributed sales revenue. Lower is better.

**Ad Group** — A collection of ads within a campaign, sharing a budget and targeting approach.

**API** — Application Programming Interface. How software systems talk to each other. The system uses APIs to read data from and send instructions to Amazon, Facebook, etc.

**Attributed Sales** — Sales that Amazon credits to an ad click. If someone clicks your ad and buys within 14 days, Amazon attributes that sale to the ad.

**Auto-targeting** — Amazon's mode where it decides which searches trigger your ad. Good for discovery.

**Bid** — The maximum you'll pay per click on a keyword.

**BlendedACOS** — Modified ACOS that includes KU page-read revenue. The accurate metric for KU books.

**Budget (campaign/ad set)** — The maximum daily spend for a campaign or ad set.

**Campaign** — The top-level container in the ad hierarchy. Has a budget and goal.

**Circuit breaker** — An automatic emergency pause triggered by abnormal conditions (spend spike, ACOS explosion, API failures).

**Change Request (CR)** — The system's formal proposal for a change. Nothing changes without one.

**Confidence flag** — The reliability rating for BlendedACOS calculations (high/medium/low). Don't optimize on low-confidence data.

**Cooldown** — The minimum number of days between changes to the same entity (default: 3 days). Prevents constant churning.

**CPC** — Cost Per Click. What you pay each time someone clicks your ad.

**CPM** — Cost Per Thousand Impressions. What you pay per 1,000 times your ad is shown.

**Creative** — The ad itself: the image and copy.

**CTR** — Click-Through Rate. Clicks ÷ Impressions. How often people who see the ad click it.

**Dry-run** — The system's default mode. Analyzes and proposes, but makes zero changes.

**Entity** — The thing being changed: a keyword, an ad set, a campaign.

**Frequency** — On Facebook: how many times the same person has seen your ad. Above 3.0 means ad fatigue is setting in.

**Harvest** — Moving profitable search terms from an automatic campaign into a manual exact-match campaign where you can bid on them directly.

**Impression** — One time your ad is shown to one person.

**KENP** — Kindle Edition Normalized Pages. The unit Amazon uses to track page reads for KU books.

**KENP lag** — The delay between a reader starting your book (triggered by your ad) and those pages showing up in your KDP reports. Up to 7 days.

**KU** — Kindle Unlimited. Amazon's subscription reading program. Authors earn per page read.

**KDP** — Kindle Direct Publishing. The platform Kenneth and Charles use to publish.

**Launch packet** — The system's document for manually setting up an X/Twitter campaign when API access isn't available.

**Lockfile** — A file the system creates (`brands/{brand}/.paused`) when it pauses itself. No automation runs until this file is manually deleted.

**Manual targeting** — Amazon ad mode where you choose specific keywords and their bids.

**Meta safety mode** — The system's conservative mode for Facebook. Restricts targeting changes and other actions that reset the learning phase.

**Negative keyword** — A keyword you exclude. Searches containing it won't trigger your ad.

**Portfolio** — An organizational layer in Amazon Ads that groups campaigns and can have a portfolio-level budget cap.

**Profile ID** — Your unique ID in the Amazon Advertising system.

**Reconciliation** — The daily check comparing local spend records to platform-reported spend. Freezes automation if they differ by more than $2.

**Royalty** — Your payment per sale or per page read (KU). Different from revenue — it's your cut after Amazon's fees.

**SafetyGuard** — The system component that checks all spend limits before every API write call.

**SERP** — Search Engine Results Page. In Amazon's context, the page of results you see after searching.

**Search term** — What the shopper actually typed. Different from a keyword (which is what you bid on).

**Spend log** — The system's own record of what it has spent. The authoritative source for limit checking.

**Sponsored Products** — The main Amazon ad type for books. Appears in search results and on product pages.

**Target ACOS** — The ACOS you're aiming for. Set per brand in `rules.json`. The system tries to keep BlendedACOS at or below this.
