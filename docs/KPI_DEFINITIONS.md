# KPI Definitions

Single source of truth for every metric on the executive dashboards.
Implemented in `data/dbt/models/marts/kpi/`.

| KPI | Definition | Formula | Notes |
|---|---|---|---|
| **Active Customers** | Customers with network activity in the month | `count(rows in fct_customer_month for month)` | Activity-based, not contract-based |
| **Gross Adds** | New activations in the month | `count(customers where signup month = month)` | |
| **Monthly Churn Rate** | Share of active customers who churned in the month | `churned_customers / active_customers` | Includes voluntary + involuntary; tested to stay in 0.1%–8% |
| **MRR (Billed Revenue)** | Total amount billed in the month | `sum(total_amount_php)` | Includes overage |
| **ARPU** | Average revenue per user | `billed_revenue / active_customers` | ₱, monthly |
| **Revenue Lost to Churn** | Monthly recurring fee of customers who churned | `sum(monthly_fee_php where churned_this_month)` | Realized loss |
| **Annualized Revenue at Risk** | Forward-looking yearly impact of this month's churn | `revenue_lost_to_churn × 12` | Phase 3 replaces this with model-scored risk: `sum(churn_probability × fee × 12)` over active base |
| **Tickets per 100 Customers** | Support friction index | `tickets_opened × 100 / active_customers` | |
| **Retention Acceptance Rate** | Offer effectiveness | `retention_accepted / retention_actions` | |
| **Regional Churn Rate** | Churn rate by region | Same as churn rate, grouped by region | `kpi_regional_monthly` |

Conventions: all currency in PHP; all rates as decimals (0.0152 = 1.52%);
month keys are first-of-month dates; a customer is counted in churn in the
calendar month of the churn event.
