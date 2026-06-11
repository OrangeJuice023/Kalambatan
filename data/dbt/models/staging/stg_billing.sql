-- Silver: invoices with payment behavior flags.
select
    invoice_id,
    customer_id,
    cast(billing_month as date)        as billing_month,
    cast(plan_fee_php as numeric)      as plan_fee_php,
    cast(overage_php as numeric)       as overage_php,
    cast(total_amount_php as numeric)  as total_amount_php,
    payment_status,
    cast(paid_date as date)            as paid_date,
    case when payment_status in ('late', 'unpaid') then 1 else 0 end as is_payment_issue,
    case when payment_status = 'unpaid' then 1 else 0 end            as is_unpaid
from {{ source('raw', 'billing') }}
