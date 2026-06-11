-- Gold: location dimension (region/city grain).
select distinct
    region || ' / ' || city as location_key,
    region,
    city
from {{ ref('stg_customers') }}
