-- Gold/KPI: company-wide monthly KPIs for the Executive Command Center.
-- Definitions documented in docs/KPI_DEFINITIONS.md.

with monthly as (
    select
        month_key,
        count(*)                                         as active_customers,
        sum(churned_this_month)                          as churned_customers,
        sum(total_amount_php)                            as billed_revenue_php,
        sum(case when churned_this_month = 1
                 then monthly_fee_php else 0 end)        as revenue_lost_to_churn_php,
        sum(tickets_opened)                              as tickets_opened,
        sum(retention_actions)                           as retention_actions,
        sum(retention_accepted)                          as retention_accepted,
        avg(data_used_gb)                                as avg_data_used_gb
    from {{ ref('fct_customer_month') }}
    group by 1
),

adds as (
    select
        {{ dbt.date_trunc('month', 'signup_date') }}     as month_key,
        count(*)                                         as gross_adds
    from {{ ref('stg_customers') }}
    group by 1
)

select
    m.month_key,
    m.active_customers,
    coalesce(a.gross_adds, 0)                            as gross_adds,
    m.churned_customers,
    round(cast(m.churned_customers as numeric)
        / nullif(m.active_customers, 0), 4)              as churn_rate,
    m.billed_revenue_php,
    round(m.billed_revenue_php
        / nullif(m.active_customers, 0), 2)              as arpu_php,
    m.revenue_lost_to_churn_php,
    round(m.revenue_lost_to_churn_php * 12, 2)           as annualized_revenue_at_risk_php,
    round(cast(m.tickets_opened as numeric) * 100
        / nullif(m.active_customers, 0), 2)              as tickets_per_100_customers,
    m.retention_actions,
    round(cast(m.retention_accepted as numeric)
        / nullif(m.retention_actions, 0), 4)             as retention_acceptance_rate,
    m.avg_data_used_gb
from monthly m
left join adds a on m.month_key = a.month_key
order by m.month_key
