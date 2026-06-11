-- Gold: acquisition channel dimension.
select distinct
    acquisition_channel as channel_key,
    acquisition_channel as channel_name
from {{ ref('stg_customers') }}
