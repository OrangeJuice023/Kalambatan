-- Silver: standardized customer profile.
select
    customer_id,
    cast(age as integer)            as age,
    gender,
    region,
    city,
    plan_id,
    device_brand,
    device_tier,
    acquisition_channel,
    cast(autopay_enrolled as boolean) as autopay_enrolled,
    cast(email_opt_in as boolean)     as email_opt_in,
    cast(signup_date as date)          as signup_date,
    cast(contract_start_date as date)  as contract_start_date,
    cast(contract_end_date as date)    as contract_end_date
from {{ source('raw', 'customers') }}
