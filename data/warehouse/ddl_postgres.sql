-- Kalambatan warehouse — Bronze (raw) layer DDL for PostgreSQL
-- Raw tables mirror the landed CSVs exactly: no transformation at this layer.
--
--   createdb kalambatan
--   psql -d kalambatan -f ddl_postgres.sql

CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.customers;
CREATE TABLE raw.customers (
    customer_id          varchar(12) PRIMARY KEY,
    age                  smallint,
    gender               varchar(1),
    region               varchar(40),
    city                 varchar(40),
    plan_id              varchar(8),
    device_brand         varchar(20),
    device_tier          varchar(10),
    acquisition_channel  varchar(20),
    autopay_enrolled     boolean,
    email_opt_in         boolean,
    signup_date          date,
    contract_start_date  date,
    contract_end_date    date
);

DROP TABLE IF EXISTS raw.plans;
CREATE TABLE raw.plans (
    plan_id            varchar(8) PRIMARY KEY,
    plan_name          varchar(40),
    plan_type          varchar(10),
    monthly_fee_php    numeric(10,2),
    data_allowance_gb  numeric(8,2),
    voice_minutes      integer,
    sms_allowance      integer,
    contract_months    smallint,
    launch_date        date
);

DROP TABLE IF EXISTS raw.billing;
CREATE TABLE raw.billing (
    invoice_id        varchar(12) PRIMARY KEY,
    customer_id       varchar(12),
    billing_month     date,
    plan_fee_php      numeric(10,2),
    overage_php       numeric(10,2),
    total_amount_php  numeric(10,2),
    payment_status    varchar(10),
    paid_date         date
);

DROP TABLE IF EXISTS raw.network_usage;
CREATE TABLE raw.network_usage (
    usage_id           varchar(20) PRIMARY KEY,
    customer_id        varchar(12),
    usage_month        date,
    data_used_gb       numeric(10,2),
    voice_minutes_used integer,
    sms_sent           integer,
    avg_download_mbps  numeric(6,1),
    dropped_call_rate  numeric(6,4)
);

DROP TABLE IF EXISTS raw.support_tickets;
CREATE TABLE raw.support_tickets (
    ticket_id      varchar(12) PRIMARY KEY,
    customer_id    varchar(12),
    opened_date    date,
    channel        varchar(12),
    category       varchar(24),
    priority       varchar(8),
    resolved_date  date,
    csat_score     smallint
);

DROP TABLE IF EXISTS raw.retention_actions;
CREATE TABLE raw.retention_actions (
    action_id        varchar(12) PRIMARY KEY,
    customer_id      varchar(12),
    action_date      date,
    campaign_name    varchar(24),
    action_type      varchar(20),
    offer_value_php  numeric(10,2),
    accepted         boolean
);

DROP TABLE IF EXISTS raw.churn_events;
CREATE TABLE raw.churn_events (
    churn_id                varchar(12) PRIMARY KEY,
    customer_id             varchar(12),
    churn_date              date,
    churn_month             date,
    churn_type              varchar(12),
    churn_reason            varchar(30),
    last_plan_id            varchar(8),
    tenure_months_at_churn  smallint
);
