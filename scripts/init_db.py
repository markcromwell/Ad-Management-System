"""
init_db.py — Initialize the SQLite database from schema.sql

Run once before anything else:
    python scripts/init_db.py

Safe to re-run — all CREATE statements use IF NOT EXISTS.
"""

import sqlite3
import os
import sys

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'ad_manager.db')
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'schema.sql')


def init_db():
    db_path = os.path.abspath(DB_PATH)
    schema_path = os.path.abspath(SCHEMA_PATH)

    if not os.path.exists(schema_path):
        print(f"ERROR: schema not found at {schema_path}")
        sys.exit(1)

    os.makedirs(os.path.dirname(db_path), exist_ok=True)

    with open(schema_path, 'r') as f:
        schema = f.read()

    conn = sqlite3.connect(db_path)
    try:
        conn.executescript(schema)
        conn.commit()
        print(f"Database initialized: {db_path}")

        # Verify tables
        cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        tables = [row[0] for row in cur.fetchall()]
        print(f"Tables: {', '.join(tables)}")
    finally:
        conn.close()


if __name__ == '__main__':
    init_db()
