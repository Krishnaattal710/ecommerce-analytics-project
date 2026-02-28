# Ecommerce Revenue & Retention Analytics (Olist)

End-to-end analytics project built for job applications. This project ingests raw ecommerce CSV files into PostgreSQL, builds reusable SQL analytics views, and powers a Tableau/Power BI dashboard.

## 1) What this project demonstrates

- SQL for business analytics (KPIs, retention, cohorts, delivery SLA, category performance)
- Python ETL/load workflow from CSV to Postgres
- BI dashboarding with executive + customer + operations insights
- Repo hygiene for portfolio projects (clean structure, reproducible setup)

## 2) Tech stack

- Python
- PostgreSQL
- SQL (CTEs, window functions, cohort logic)
- Tableau Public or Power BI

## 3) Project structure

```text
.
├── .env.example
├── .gitignore
├── Makefile
├── README.md
├── requirements.txt
├── dashboards/
│   └── dashboard_layout.md
├── data/
│   └── raw/
├── docs/
│   └── insights_template.md
├── images/
├── scripts/
│   ├── load_olist.py
│   └── validate_data.py
└── sql/
    └── analytics_query_pack.sql
```

## 4) Setup (one time)

### 4.1 Create Python environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4.2 Install and start PostgreSQL (macOS)

```bash
brew install postgresql@16
brew services start postgresql@16
createdb olist_analytics
```

If `psql` or `createdb` is not found (keg-only formula), run:

```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

Quick DB check:

```bash
psql -d olist_analytics -c "select 'db ok' as status;"
```

## 5) Download dataset

Download the Olist dataset and unzip CSVs into:

`data/raw/`

Expected files:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

## 6) Run pipeline

### Option A: one command per step

```bash
source .venv/bin/activate
python scripts/load_olist.py --data-dir data/raw --strict
psql -d olist_analytics -f sql/analytics_query_pack.sql
python scripts/validate_data.py
```

### Option B: Makefile shortcuts

```bash
make setup
make load
make sql PSQL=/opt/homebrew/opt/postgresql@16/bin/psql
make validate
```

## 7) Build dashboard

Use `dashboards/dashboard_layout.md` to create your dashboard pages/sections:

1. Executive Overview
2. Customer & Retention
3. Operations

Save screenshots in `images/`.

If using Tableau Public, publish and copy your public dashboard URL.

## 7.1 Optional: materialize analytics tables (for BI speed)

If you prefer physical tables instead of views in your BI tool:

```bash
psql -d olist_analytics -f sql/materialize_analytics_tables.sql
```

This creates tables like:
- `analytics.fact_order`
- `analytics.bridge_order_category`
- `analytics.monthly_revenue_orders`
- `analytics.cohort_retention_0_6`

## 8) Key queries/views to use in BI

- `analytics.vw_order_fact`
- `analytics.vw_kpi_snapshot_12m`
- `analytics.vw_monthly_revenue_orders`
- `analytics.vw_customer_repeat_rate`
- `analytics.vw_new_vs_returning_monthly`
- `analytics.vw_sla_state`
- `analytics.vw_top_categories`
- `analytics.vw_payment_mix`
- `analytics.vw_failed_order_trend`
- `analytics.vw_cohort_retention_0_6`

## 9) Add project insights

Use `docs/insights_template.md` to write 5 insights + 3 recommendations.

## 10) Push to GitHub

Create an empty GitHub repo first, then run:

```bash
git add .
git commit -m "Build ecommerce analytics project with SQL views and dashboard workflow"
git branch -M main
git remote add origin https://github.com/<your-username>/ecommerce-analytics-project.git
git push -u origin main
```

## 11) Resume bullets (copy-ready)

- Built an end-to-end ecommerce analytics project using Python, PostgreSQL, SQL, and Tableau/Power BI on 100K+ orders.
- Designed reusable analytics views for revenue, retention, delivery SLA, and category performance to support executive decision-making.
- Delivered an interactive business dashboard that surfaced repeat-customer patterns, top category trends, and operational bottlenecks.

## 12) Interview talking points

- Why one row per order in `vw_order_fact` avoids double-counting revenue.
- How cohort retention is calculated month-over-month.
- How delivery SLA metrics can guide regional operations improvements.
