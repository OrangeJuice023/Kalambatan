-- Gold/KPI: regional churn and revenue performance by month.
select
    month_key,
    region,
    count(*)                                             as active_customers,
    sum(churned_this_month)                              as churned_customers,
    round(cast(sum(churned_this_month) as numeric)
        / nullif(count(*), 0), 4)                        as churn_rate,
    sum(total_amount_php)                                as billed_revenue_php,
    round(sum(total_amount_php)
        / nullif(count(*), 0), 2)                        as arpu_php,
    sum(tickets_opened)                                  as tickets_opened
from {{ ref('fct_customer_month') }}
group by 1, 2
order by 1, 2
