FROM python:3.12-slim

# Install cron daemon
RUN apt-get update \
    && apt-get install -y --no-install-recommends cron \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps (separate layer for cache efficiency)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Set up crontab
COPY docker/crontab /etc/cron.d/ad-manager
RUN chmod 0644 /etc/cron.d/ad-manager

# Entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# data/ and logs/ are mounted from the host — don't bake them in
VOLUME ["/app/data", "/app/logs"]

ENTRYPOINT ["/entrypoint.sh"]
