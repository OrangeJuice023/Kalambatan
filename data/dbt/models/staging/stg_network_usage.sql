-- Silver: monthly network usage per customer.
select
    usage_id,
    customer_id,
    cast(usage_month as date)          as usage_month,
    cast(data_used_gb as numeric)      as data_used_gb,
    cast(voice_minutes_used as integer) as voice_minutes_used,
    cast(sms_sent as integer)          as sms_sent,
    cast(avg_download_mbps as numeric) as avg_download_mbps,
    cast(dropped_call_rate as numeric) as dropped_call_rate
from {{ source('raw', 'network_usage') }}
