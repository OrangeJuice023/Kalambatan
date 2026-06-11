-- Gold: customer dimension enriched with plan and churn status.
select
    c.customer_id,
    c.age,
    case
        when c.age < 25 then '18-24'
        when c.age < 35 then '25-34'
        when c.age < 45 then '35-44'
        when c.age < 60 then '45-59'
        else '60+'
    end                                as age_band,
    c.gender,
    c.region,
    c.city,
    c.plan_id,
    p.plan_name,
    p.plan_type,
    p.monthly_fee_php,
    c.device_brand,
    c.device_tier,
    c.acquisition_channel,
    c.autopay_enrolled,
    c.email_opt_in,
    c.signup_date,
    c.contract_start_date,
    c.contract_end_date,
    ch.churn_month                     as churn_month,
    case when ch.customer_id is not null then 1 else 0 end as is_churned
from {{ ref('stg_customers') }} c
left join {{ ref('stg_plans') }} p on c.plan_id = p.plan_id
left join {{ ref('stg_churn_events') }} ch on c.customer_id = ch.customer_id
