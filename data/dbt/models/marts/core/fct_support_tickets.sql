-- Gold: support ticket fact at ticket grain.
select
    t.ticket_id,
    t.customer_id,
    t.opened_month       as date_key,
    t.opened_date,
    c.region,
    t.channel,
    t.category,
    t.priority,
    t.resolution_days,
    t.csat_score
from {{ ref('stg_support_tickets') }} t
left join {{ ref('stg_customers') }} c on t.customer_id = c.customer_id
