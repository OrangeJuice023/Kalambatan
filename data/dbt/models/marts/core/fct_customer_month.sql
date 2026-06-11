-- Gold: customer-month snapshot — the analytical spine of the platform.
--
-- One row per customer per active month, combining usage, billing, support,
-- and retention signals. This is the training base for the Phase 3 churn
-- models: `churned_next_month` is the prediction label, everything else is
-- a candidate feature.

with usage as (
    select * from {{ ref('stg_network_usage') }}
),

billing as (
    select * from {{ ref('stg_billing') }}
),

tickets as (
    select
        customer_id,
        opened_month,
        count(*)                                                    as tickets_opened,
        sum(case when priority = 'high' then 1 else 0 end)          as high_priority_tickets,
        avg(csat_score)                                             as avg_csat
    from {{ ref('stg_support_tickets') }}
    group by 1, 2
),

retention as (
    select
        customer_id,
        action_month,
        count(*)                                                    as retention_actions,
        sum(case when accepted then 1 else 0 end)                   as retention_accepted
    from {{ ref('stg_retention_actions') }}
    group by 1, 2
),

churn as (
    select customer_id, churn_month, churn_type, churn_reason
    from {{ ref('stg_churn_events') }}
),

base as (
    select
        u.customer_id,
        u.usage_month                                               as month_key,
        c.region,
        c.plan_id,
        p.plan_type,
        p.monthly_fee_php,
        {{ dbt.datediff('c.signup_date', 'u.usage_month', 'month') }} as tenure_months,
        case
            when c.contract_end_date is not null
             and {{ dbt.datediff('u.usage_month', 'c.contract_end_date', 'month') }} between -1 and 1
            then 1 else 0
        end                                                         as contract_ending_flag,

        u.data_used_gb,
        u.voice_minutes_used,
        u.sms_sent,
        u.avg_download_mbps,
        u.dropped_call_rate,

        b.total_amount_php,
        b.overage_php,
        b.is_payment_issue,
        b.is_unpaid,

        coalesce(t.tickets_opened, 0)                               as tickets_opened,
        coalesce(t.high_priority_tickets, 0)                        as high_priority_tickets,
        t.avg_csat,

        coalesce(r.retention_actions, 0)                            as retention_actions,
        coalesce(r.retention_accepted, 0)                           as retention_accepted,

        case when ch.customer_id is not null then 1 else 0 end      as churned_this_month,
        ch.churn_type,
        ch.churn_reason
    from usage u
    left join {{ ref('stg_customers') }} c on u.customer_id = c.customer_id
    left join {{ ref('stg_plans') }} p on c.plan_id = p.plan_id
    left join billing b
        on u.customer_id = b.customer_id and u.usage_month = b.billing_month
    left join tickets t
        on u.customer_id = t.customer_id and u.usage_month = t.opened_month
    left join retention r
        on u.customer_id = r.customer_id and u.usage_month = r.action_month
    left join churn ch
        on u.customer_id = ch.customer_id and u.usage_month = ch.churn_month
),

windowed as (
    select
        *,
        avg(data_used_gb) over (
            partition by customer_id order by month_key
            rows between 3 preceding and 1 preceding
        )                                                           as data_used_gb_prev3_avg,
        sum(tickets_opened) over (
            partition by customer_id order by month_key
            rows between 2 preceding and current row
        )                                                           as tickets_last3,
        sum(is_payment_issue) over (
            partition by customer_id order by month_key
            rows between 2 preceding and current row
        )                                                           as payment_issues_last3,
        lead(churned_this_month) over (
            partition by customer_id order by month_key
        )                                                           as churned_next_month_raw
    from base
)

select
    customer_id,
    month_key,
    region,
    plan_id,
    plan_type,
    monthly_fee_php,
    tenure_months,
    contract_ending_flag,
    data_used_gb,
    voice_minutes_used,
    sms_sent,
    avg_download_mbps,
    dropped_call_rate,
    data_used_gb_prev3_avg,
    case
        when data_used_gb_prev3_avg is not null and data_used_gb_prev3_avg > 0
        then (data_used_gb - data_used_gb_prev3_avg) / data_used_gb_prev3_avg
    end                                          as data_usage_change_pct,
    total_amount_php,
    overage_php,
    is_payment_issue,
    is_unpaid,
    payment_issues_last3,
    tickets_opened,
    high_priority_tickets,
    tickets_last3,
    avg_csat,
    retention_actions,
    retention_accepted,
    churned_this_month,
    churn_type,
    churn_reason,
    -- ML label: did this customer churn in the following month?
    -- Final observed month per customer has no lookahead -> label is null,
    -- which Phase 3 must exclude from training.
    churned_next_month_raw                       as churned_next_month
from windowed
