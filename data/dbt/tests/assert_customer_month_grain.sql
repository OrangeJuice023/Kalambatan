-- Grain test: fct_customer_month must have exactly one row per
-- customer per month. Returns offending rows (test passes when empty).
select customer_id, month_key, count(*) as n
from {{ ref('fct_customer_month') }}
group by 1, 2
having count(*) > 1
