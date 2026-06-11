-- Silver: plan catalog with value metrics.
select
    plan_id,
    plan_name,
    plan_type,
    cast(monthly_fee_php as numeric)   as monthly_fee_php,
    cast(data_allowance_gb as numeric) as data_allowance_gb,
    cast(voice_minutes as integer)     as voice_minutes,
    cast(sms_allowance as integer)     as sms_allowance,
    cast(contract_months as integer)   as contract_months,
    cast(launch_date as date)          as launch_date,
    cast(monthly_fee_php as numeric)
        / nullif(cast(data_allowance_gb as numeric), 0) as php_per_gb
from {{ source('raw', 'plans') }}
