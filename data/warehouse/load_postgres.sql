-- Load the synthetic CSVs into the raw schema.
-- Run from the data/warehouse directory:
--   psql -d kalambatan -f load_postgres.sql

\copy raw.customers         FROM '../synthetic/output/raw_customers.csv'         CSV HEADER
\copy raw.plans             FROM '../synthetic/output/raw_plans.csv'             CSV HEADER
\copy raw.billing           FROM '../synthetic/output/raw_billing.csv'           CSV HEADER
\copy raw.network_usage     FROM '../synthetic/output/raw_network_usage.csv'     CSV HEADER
\copy raw.support_tickets   FROM '../synthetic/output/raw_support_tickets.csv'   CSV HEADER
\copy raw.retention_actions FROM '../synthetic/output/raw_retention_actions.csv' CSV HEADER
\copy raw.churn_events      FROM '../synthetic/output/raw_churn_events.csv'      CSV HEADER

ANALYZE;
