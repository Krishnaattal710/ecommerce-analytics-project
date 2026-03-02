# Dashboard Layout (Tableau or Power BI)

Build one dashboard with 3 sections (or 3 pages):

## 1) Executive Overview
- KPI card: `Gross Revenue` -> `SUM(payment_value)` from `analytics.vw_order_fact` (filter delivered)
- KPI card: `Orders` -> `COUNTD(order_id)` (filter delivered)
- KPI card: `AOV` -> `SUM(payment_value) / COUNTD(order_id)`
- KPI card: `Repeat Rate` -> `repeat_rate_pct` from `analytics.vw_customer_repeat_rate`
- Line chart: monthly revenue and orders from `analytics.vw_monthly_revenue_orders`
- Bar chart: top categories from `analytics.vw_top_categories` (Top 10 by revenue)
- Map or bar: state performance from `analytics.vw_sla_state`

## 2) Customer & Retention
- Line/column: new vs returning customers from `analytics.vw_new_vs_returning_monthly`
- Heatmap: cohort retention from `analytics.vw_cohort_retention_0_6`
  - Rows: `cohort_month`
  - Columns: `month_number`
  - Color/label: `retention_pct`
- Optional: avg review score trend from `analytics.vw_order_fact`

## 3) Operations
- Line chart: failed order percentage from `analytics.vw_failed_order_trend`
- Bar chart: worst states by `avg_delay_days` from `analytics.vw_sla_state`
- Donut/pie: payment mix from `analytics.vw_payment_mix`

## Filters (global)
- Purchase month/date range
- Customer state
- Product category

## Design tips
- Use consistent currency formatting.
- Show tooltips with business explanation, not just numbers.
- Keep colors minimal: one primary, one warning color for delays/failure.
