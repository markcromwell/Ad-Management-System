"""
backup.py — Back up the SQLite database and brand configs to cloud storage.

Uses rclone (https://rclone.org) — supports Google Drive, S3, Backblaze B2,
Dropbox, OneDrive, and dozens more. Configure rclone once, then set
BACKUP_RCLONE_DEST in .env to your destination (e.g. "gdrive:ad-manager-backups").

Run manually:
    python scripts/backup.py

Or add to crontab (runs automatically after Sunday harvest):
    0 9 * * 0  root  cd /app && python scripts/backup.py >> /app/logs/cron.log 2>&1

What gets backed up:
    data/ad_manager.db          — the entire SQLite database
    brands/*/config.json        — brand configuration
    brands/*/limits.json        — spend limits
    brands/*/rules.json         — optimization rules
    data/schema.sql             — schema (for disaster recovery)

What does NOT get backed up (by design):
    .env                        — credentials never leave the VM
    data/*/amazon/              — raw API snapshots (re-pullable)
    logs/                       — not critical for recovery
"""

import os
import shutil
import subprocess
import sys
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).parent.parent
DB_PATH = ROOT / 'data' / 'ad_manager.db'
BACKUP_RCLONE_DEST = os.getenv('BACKUP_RCLONE_DEST', '')


def sqlite_backup(dest_path: Path):
    """Hot backup of SQLite DB — safe while the DB is in use."""
    src = sqlite3.connect(str(DB_PATH))
    dst = sqlite3.connect(str(dest_path))
    try:
        src.backup(dst)
    finally:
        src.close()
        dst.close()


def collect_files(staging_dir: Path):
    """Copy files to backup into a staging directory."""
    staging_dir.mkdir(parents=True, exist_ok=True)

    # SQLite database (hot backup — safe while running)
    db_dest = staging_dir / 'ad_manager.db'
    sqlite_backup(db_dest)
    print(f"  ✓ database ({db_dest.stat().st_size // 1024} KB)")

    # Schema
    schema_src = ROOT / 'data' / 'schema.sql'
    if schema_src.exists():
        shutil.copy2(schema_src, staging_dir / 'schema.sql')
        print("  ✓ schema.sql")

    # Brand configs
    brands_dir = staging_dir / 'brands'
    for config_file in ROOT.glob('brands/*/config.json'):
        dest = brands_dir / config_file.parent.name / config_file.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(config_file, dest)

    for limits_file in ROOT.glob('brands/*/limits.json'):
        dest = brands_dir / limits_file.parent.name / limits_file.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(limits_file, dest)

    for rules_file in ROOT.glob('brands/*/rules.json'):
        dest = brands_dir / rules_file.parent.name / rules_file.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(rules_file, dest)

    brand_count = len(list(brands_dir.glob('*'))) if brands_dir.exists() else 0
    print(f"  ✓ brand configs ({brand_count} brands)")


def upload_to_cloud(staging_dir: Path, dest: str, timestamp: str):
    """Upload staging directory to cloud via rclone."""
    if not shutil.which('rclone'):
        print("  ✗ rclone not found — skipping cloud upload")
        print("    Install: https://rclone.org/install/")
        print(f"    Local backup available at: {staging_dir}")
        return False

    remote_path = f"{dest}/{timestamp}"
    result = subprocess.run(
        ['rclone', 'copy', str(staging_dir), remote_path, '--progress'],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f"  ✓ uploaded to {remote_path}")
        return True
    else:
        print(f"  ✗ rclone error: {result.stderr}")
        return False


def cleanup_old_backups(dest: str, keep: int = 30):
    """Delete cloud backups older than `keep` days."""
    if not shutil.which('rclone'):
        return
    result = subprocess.run(
        ['rclone', 'delete', dest, '--min-age', f'{keep}d'],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f"  ✓ old backups (>{keep} days) pruned")


def main():
    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H%M%SZ')
    staging_dir = ROOT / 'data' / '_backup_staging' / timestamp

    print(f"[backup] {timestamp}")
    print("Collecting files...")

    if not DB_PATH.exists():
        print(f"  ✗ database not found at {DB_PATH} — nothing to back up")
        sys.exit(1)

    collect_files(staging_dir)

    if not BACKUP_RCLONE_DEST:
        print("\nBACKUP_RCLONE_DEST not set in .env.")
        print(f"Local snapshot saved at: {staging_dir}")
        print("Set BACKUP_RCLONE_DEST=gdrive:ad-manager-backups (or similar) to enable cloud.")
        return

    print(f"\nUploading to {BACKUP_RCLONE_DEST}...")
    success = upload_to_cloud(staging_dir, BACKUP_RCLONE_DEST, timestamp)

    if success:
        cleanup_old_backups(BACKUP_RCLONE_DEST)
        # Remove local staging after successful upload
        shutil.rmtree(staging_dir)
        print("\nBackup complete.")
    else:
        print(f"\nCloud upload failed. Local backup kept at: {staging_dir}")
        sys.exit(1)


if __name__ == '__main__':
    main()
