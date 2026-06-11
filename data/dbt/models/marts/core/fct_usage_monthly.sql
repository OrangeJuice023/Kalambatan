-- Gold: network usage fact at customer-month grain.
select
    u.usage_id,
    u.customer_id,
    u.usage_month        as date_key,
    c.plan_id,
    c.region,
    u.data_used_gb,
    u.voice_minutes_used,
    u.sms_sent,
    u.avg_download_mbps,
    u.dropped_call_rate,
    u.data_used_gb / nullif(p.data_allowance_gb, 0) as allowance_utilization
from {{ ref('stg_network_usage') }} u
left join {{ ref('stg_customers') }} c on u.customer_id = c.customer_id
left join {{ ref('stg_plans') }} p on c.plan_id = p.plan_id
