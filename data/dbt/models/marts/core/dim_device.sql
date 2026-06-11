-- Gold: device dimension.
select distinct
    device_brand || ' / ' || device_tier as device_key,
    device_brand,
    device_tier
from {{ ref('stg_customers') }}
