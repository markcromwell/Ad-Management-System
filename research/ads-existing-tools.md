# Open source / widely used building blocks for multi-platform ad management

Purpose: identify what we can build on (libraries, connectors, dashboards) vs. reinventing.

## Multi-platform / aggregation projects (500+ ⭐ or notable)
- **Airbyte (13k+ ⭐)** – open-source ELT with connectors for Meta Ads (`facebook-marketing`), Amazon Ads (`amazon-ads`), Twitter Ads (`twitter-ads`). Good for unified data ingestion to warehouses; not a management UI but strong for reporting pipelines.
- **Meltano (5k+ ⭐)** – orchestrates Singer taps/targets. Taps exist for Facebook, Google Ads, TikTok, etc.; can be extended for Amazon/Twitter. Good for scheduled extraction + dbt modeling.
- **Singer taps (varied)** – community taps for Facebook/Instagram (`tap-facebook`), Google Ads, TikTok. Useful for ingestion; management features limited.
- **Apache Superset (50k+ ⭐) / Metabase (35k+ ⭐)** – self-hosted BI dashboards. Not ad-specific but pair well with Airbyte/Meltano for reporting.
- **Awesome-agentic-advertising (curated list)** – catalog of agentic ad tools; highlights **Synter Media** (multi-platform MCP server for Google, Meta, LinkedIn, Reddit, Microsoft, TikTok, X) and **Adzviser** (multi-platform ad data connectivity). Both open-source starting points for AI-agent-driven campaign ops.

## Platform SDKs / clients (Python)
- **Meta / Facebook Marketing API** – `facebook-business` (official SDK)
- **Amazon Ads** – `python-amazon-ad-api` (popular community lib), `amazon-advertising-api-python` (Amazon-authored legacy), `ad_api` / `sp_api` family (unofficial, active)
- **Twitter/X Ads** – `twitter-python-ads-sdk` (official/maintained ~500 ⭐), `twitter-ads` (community PyPI)
- **Google Ads** – `google-ads` (official). Useful if we later expand.

## Ad serving / self-hosted patterns
- **Revive Adserver (2k+ ⭐)** – self-hosted ad server; supports rotation rules, targeting, reporting. Useful to study for creative rotation UX patterns.
- **OpenAdServer (ML-powered, FastAPI/PyTorch)** – self-hosted ad server with CTR prediction; useful for ML rotation patterns.

## Gaps / opportunity
- No open-source project provides **full multi-platform campaign creation/bidding** in one control plane. Most open-source focuses on data ingestion and dashboards. The unified control plane (budgets, bids, rotation rules) atop the official SDKs is the gap we're building into.
