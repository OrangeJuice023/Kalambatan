-- Silver: retention campaign touches.
select
    action_id,
    customer_id,
    cast(action_date as date)       as action_date,
    {{ dbt.date_trunc('month', "cast(action_date as date)") }} as action_month,
    campaign_name,
    action_type,
    cast(offer_value_php as numeric) as offer_value_php,
    cast(accepted as boolean)        as accepted
from {{ source('raw', 'retention_actions') }}
