#!/bin/bash
set -e

# ─── Make env vars available to cron jobs ────────────────────────────────────
# Docker passes env vars to the container process but not to cron's child
# processes. Writing to /etc/environment fixes this.
printenv | grep -v "^_=" | grep -v "^SHLVL=" >> /etc/environment

# ─── Initialize database ─────────────────────────────────────────────────────
if [ ! -f /app/data/ad_manager.db ]; then
    echo "[entrypoint] Initializing database..."
    python /app/scripts/init_db.py
else
    echo "[entrypoint] Database exists: /app/data/ad_manager.db"
fi

# ─── Create log directory ────────────────────────────────────────────────────
mkdir -p /app/logs

# ─── Start cron ──────────────────────────────────────────────────────────────
echo "[entrypoint] Starting cron scheduler..."
exec cron -f
