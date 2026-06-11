-- Gold: churn event fact at event grain.
select
    e.churn_id,
    e.customer_id,
    e.churn_month        as date_key,
    e.churn_date,
    c.region,
    c.acquisition_channel,
    e.churn_type,
    e.churn_reason,
    e.last_plan_id,
    p.monthly_fee_php    as lost_monthly_revenue_php,
    e.tenure_months_at_churn
from {{ ref('stg_churn_events') }} e
left join {{ ref('stg_customers') }} c on e.customer_id = c.customer_id
left join {{ ref('stg_plans') }} p on e.last_plan_id = p.plan_id
