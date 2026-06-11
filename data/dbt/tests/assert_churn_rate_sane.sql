-- Business sanity test: monthly churn rate must stay within a plausible
-- telecom band (0.1% – 8%). Catches both generator bugs and broken joins.
select month_key, churn_rate
from {{ ref('kpi_executive_monthly') }}
where churn_rate < 0.001 or churn_rate > 0.08
