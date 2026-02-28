\set ON_ERROR_STOP on
\! mkdir -p dashboards/exports

\copy (select * from analytics.kpi_snapshot) to 'dashboards/exports/kpi_snapshot.csv' csv header
\copy (select * from analytics.hourly_demand) to 'dashboards/exports/hourly_demand.csv' csv header
\copy (select * from analytics.daily_borough_demand) to 'dashboards/exports/daily_borough_demand.csv' csv header
\copy (select * from analytics.zone_demand) to 'dashboards/exports/zone_demand.csv' csv header
\copy (select * from analytics.payment_mix) to 'dashboards/exports/payment_mix.csv' csv header
\copy (select * from analytics.top_routes) to 'dashboards/exports/top_routes.csv' csv header
\copy (select * from analytics.forecast_next_7_days) to 'dashboards/exports/forecast_next_7_days.csv' csv header
