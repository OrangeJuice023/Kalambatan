-- Gold: plan dimension.
select
    plan_id,
    plan_name,
    plan_type,
    monthly_fee_php,
    data_allowance_gb,
    voice_minutes,
    sms_allowance,
    contract_months,
    php_per_gb,
    launch_date
from {{ ref('stg_plans') }}
