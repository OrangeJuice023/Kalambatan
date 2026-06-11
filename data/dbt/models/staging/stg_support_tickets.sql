-- Silver: support tickets with resolution time.
select
    ticket_id,
    customer_id,
    cast(opened_date as date)   as opened_date,
    {{ dbt.date_trunc('month', "cast(opened_date as date)") }} as opened_month,
    channel,
    category,
    priority,
    cast(resolved_date as date) as resolved_date,
    cast(csat_score as integer) as csat_score,
    {{ dbt.datediff("cast(opened_date as date)", "cast(resolved_date as date)", 'day') }}
        as resolution_days
from {{ source('raw', 'support_tickets') }}
