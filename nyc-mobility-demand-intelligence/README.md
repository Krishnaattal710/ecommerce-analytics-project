# NYC Mobility Demand Intelligence

Second portfolio project focused on urban mobility analytics using NYC TLC trip data. This project builds a repeatable data pipeline from raw parquet files to PostgreSQL analytics tables and Tableau-ready exports.

## What this project demonstrates

- Real-world transportation analytics workflow
- Python ingestion of parquet datasets into PostgreSQL
- SQL analytics for demand, route intelligence, payment behavior, and forecast baseline
- BI-ready dataset exports for Tableau

## Tech stack

- Python
- PostgreSQL
- SQL
- Tableau / Power BI

## Project structure

```text
.
├── .env.example
├── .gitignore
├── Makefile
├── README.md
├── requirements.txt
├── dashboards/
│   ├── dashboard_layout.md
│   └── exports/
├── data/
│   └── raw/
├── docs/
│   └── insights_template.md
├── scripts/
│   ├── download_tlc_data.py
│   ├── load_tlc.py
│   └── validate_data.py
└── sql/
    ├── analytics_query_pack.sql
    ├── materialize_analytics_tables.sql
    └── export_dashboard_csv.sql
```

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

If PostgreSQL binaries are not in PATH on macOS:

```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

Create DB:

```bash
createdb nyc_mobility_analytics
```

## Run end-to-end

```bash
# Download 1 month of yellow taxi data + zone lookup (fast path)
python scripts/download_tlc_data.py --data-dir data/raw --taxi-type yellow --year 2024 --months 10 --skip-existing

# Load into PostgreSQL
DATABASE_URL=postgresql+psycopg2://localhost/nyc_mobility_analytics \
python scripts/load_tlc.py --data-dir data/raw --taxi-type yellow --strict

# Build analytics views
psql -d nyc_mobility_analytics -f sql/analytics_query_pack.sql

# Materialize analytics tables
psql -d nyc_mobility_analytics -f sql/materialize_analytics_tables.sql

# Validate
DATABASE_URL=postgresql+psycopg2://localhost/nyc_mobility_analytics \
python scripts/validate_data.py

# Export CSVs for Tableau
psql -d nyc_mobility_analytics -f sql/export_dashboard_csv.sql
```

To extend this project, rerun download/load with additional months:

```bash
python scripts/download_tlc_data.py --data-dir data/raw --taxi-type yellow --year 2024 --months 11 12 --skip-existing
```

## Tableau data sources

Use CSVs from:

`dashboards/exports/`

Main files:
- `kpi_snapshot.csv`
- `hourly_demand.csv`
- `daily_borough_demand.csv`
- `zone_demand.csv`
- `payment_mix.csv`
- `top_routes.csv`
- `forecast_next_7_days.csv`

## Current KPI snapshot (Oct 2024 run)

- Total trips analyzed: **3,772,345**
- Average total fare: **29.36**
- Average trip distance: **5.15**
- Average trip duration: **18.31 min**
- Credit card share: **75.66%**
- Average daily trips: **107,781**

## Quick insights from this run

1. Peak demand hour is **18:00**, followed by **17:00** and **19:00**.
2. **Manhattan** contributes the largest pickup volume by a wide margin.
3. Top pickup zones include **Upper East Side South**, **JFK Airport**, and **Midtown Center**.

## Suggested resume bullets

- Built a mobility analytics pipeline using NYC TLC trip data (parquet -> PostgreSQL -> SQL marts -> Tableau-ready exports).
- Developed demand, route, payment, and forecast baseline analytics to support fleet planning decisions.
- Materialized analytics tables and validated KPI outputs for reliable stakeholder reporting.
