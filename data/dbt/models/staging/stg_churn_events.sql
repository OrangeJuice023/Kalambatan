-- Silver: churn events.
select
    churn_id,
    customer_id,
    cast(churn_date as date)  as churn_date,
    cast(churn_month as date) as churn_month,
    churn_type,
    churn_reason,
    last_plan_id,
    cast(tenure_months_at_churn as integer) as tenure_months_at_churn
from {{ source('raw', 'churn_events') }}
