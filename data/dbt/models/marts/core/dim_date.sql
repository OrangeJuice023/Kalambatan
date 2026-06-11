-- Gold: month-grain date dimension derived from observed billing months.
with months as (
    select distinct billing_month as month_start
    from {{ ref('stg_billing') }}
)
select
    month_start                              as date_key,
    cast(extract(year from month_start) as integer)    as year_number,
    cast(extract(month from month_start) as integer)   as month_number,
    cast(extract(quarter from month_start) as integer) as quarter_number,
    case cast(extract(month from month_start) as integer)
        when 1 then 'January'  when 2 then 'February' when 3 then 'March'
        when 4 then 'April'    when 5 then 'May'      when 6 then 'June'
        when 7 then 'July'     when 8 then 'August'   when 9 then 'September'
        when 10 then 'October' when 11 then 'November' else 'December'
    end                                      as month_name
from months
