-- Gold: billing fact at invoice grain (one invoice per customer-month).
select
    b.invoice_id,
    b.customer_id,
    b.billing_month       as date_key,
    c.plan_id,
    c.region,
    b.plan_fee_php,
    b.overage_php,
    b.total_amount_php,
    b.payment_status,
    b.is_payment_issue,
    b.is_unpaid
from {{ ref('stg_billing') }} b
left join {{ ref('stg_customers') }} c on b.customer_id = c.customer_id
