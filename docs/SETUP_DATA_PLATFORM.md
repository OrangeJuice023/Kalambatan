# Data Platform Setup (₱0)

Two paths. DuckDB is the fast path (no server, runs anywhere); PostgreSQL is
the primary warehouse. Both run the **same dbt models**.

## 0. Generate the synthetic dataset (both paths)

```bash
pip install numpy pandas
cd data/synthetic
python generate.py            # 5,000 customers, 24 months, seed 42
```

## Path A — DuckDB (zero setup, recommended first)

```bash
pip install dbt-core dbt-duckdb duckdb
cd data/warehouse && python load_duckdb.py
cd ../dbt && DBT_PROFILES_DIR=. dbt build
```

Windows PowerShell: `$env:DBT_PROFILES_DIR="."; dbt build`

Expected: **58 passing** (21 models + 37 tests). Query results:

```bash
python -c "import duckdb; print(duckdb.connect('../warehouse/kalambatan.duckdb') \
  .execute('select * from gold.kpi_executive_monthly order by month_key').df())"
```

## Path B — PostgreSQL (primary warehouse)

```bash
# with PostgreSQL installed locally (free):
createdb kalambatan
psql -d kalambatan -c "CREATE USER kalambatan WITH PASSWORD 'kalambatan'; \
  GRANT ALL ON DATABASE kalambatan TO kalambatan;"
cd data/warehouse
psql -d kalambatan -f ddl_postgres.sql
psql -d kalambatan -f load_postgres.sql

pip install dbt-postgres
cd ../dbt && DBT_PROFILES_DIR=. dbt build --target postgres
```

Credentials are read from env vars (`KALAMBATAN_PG_HOST/USER/PASSWORD`) with
local-dev defaults — see `data/dbt/profiles.yml`.

## Layer map

| Layer | Where | What |
|---|---|---|
| Bronze | `raw.*` tables | CSVs landed as-is |
| Silver | `silver.*` views (`models/staging/`) | Typed, standardized, flagged |
| Gold | `gold.*` tables (`models/marts/`) | Star schema + KPI marts |
