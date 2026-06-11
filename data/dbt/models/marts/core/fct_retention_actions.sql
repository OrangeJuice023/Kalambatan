-- Gold: retention action fact at action grain.
select
    r.action_id,
    r.customer_id,
    r.action_month       as date_key,
    r.action_date,
    c.region,
    r.campaign_name,
    r.action_type,
    r.offer_value_php,
    r.accepted
from {{ ref('stg_retention_actions') }} r
left join {{ ref('stg_customers') }} c on r.customer_id = c.customer_id
