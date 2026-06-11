"""Load the synthetic CSVs into a local DuckDB warehouse (zero-setup path).

    python load_duckdb.py

Creates data/warehouse/kalambatan.duckdb with a `raw` schema that mirrors
the PostgreSQL Bronze layer, so the same dbt models run on either engine.
"""

from pathlib import Path

import duckdb

HERE = Path(__file__).parent
CSV_DIR = HERE.parent / "synthetic" / "output"
DB_PATH = HERE / "kalambatan.duckdb"

TABLES = [
    "customers", "plans", "billing", "network_usage",
    "support_tickets", "retention_actions", "churn_events",
]

con = duckdb.connect(str(DB_PATH))
con.execute("CREATE SCHEMA IF NOT EXISTS raw")
for t in TABLES:
    csv = CSV_DIR / f"raw_{t}.csv"
    if not csv.exists():
        raise SystemExit(f"Missing {csv} — run data/synthetic/generate.py first.")
    con.execute(f"CREATE OR REPLACE TABLE raw.{t} AS SELECT * FROM read_csv_auto('{csv}')")
    n = con.execute(f"SELECT count(*) FROM raw.{t}").fetchone()[0]
    print(f"raw.{t}: {n:,} rows")
con.close()
print(f"\nWarehouse ready: {DB_PATH}")
