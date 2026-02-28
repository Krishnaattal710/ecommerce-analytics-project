-- Materialize NYC mobility analytics views into physical tables

create schema if not exists analytics;

drop table if exists analytics.fact_trip;
create table analytics.fact_trip as
select * from analytics.vw_trip_fact;

create index if not exists idx_fact_trip_pickup_ts
    on analytics.fact_trip (pickup_ts);
create index if not exists idx_fact_trip_trip_date
    on analytics.fact_trip (trip_date);
create index if not exists idx_fact_trip_pickup_zone
    on analytics.fact_trip (pickup_zone);

drop table if exists analytics.kpi_snapshot;
create table analytics.kpi_snapshot as
select * from analytics.vw_kpi_snapshot;

drop table if exists analytics.hourly_demand;
create table analytics.hourly_demand as
select * from analytics.vw_hourly_demand;
create index if not exists idx_hourly_demand_pickup_hour_ts
    on analytics.hourly_demand (pickup_hour_ts);

drop table if exists analytics.daily_borough_demand;
create table analytics.daily_borough_demand as
select * from analytics.vw_daily_borough_demand;
create index if not exists idx_daily_borough_demand_trip_date
    on analytics.daily_borough_demand (trip_date);

drop table if exists analytics.zone_demand;
create table analytics.zone_demand as
select * from analytics.vw_zone_demand;

drop table if exists analytics.payment_mix;
create table analytics.payment_mix as
select * from analytics.vw_payment_mix;

drop table if exists analytics.top_routes;
create table analytics.top_routes as
select * from analytics.vw_top_routes;

drop table if exists analytics.forecast_next_7_days;
create table analytics.forecast_next_7_days as
select * from analytics.vw_forecast_next_7_days;

select 'analytics.fact_trip' as table_name, count(*) as rows from analytics.fact_trip
union all
select 'analytics.hourly_demand', count(*) from analytics.hourly_demand
union all
select 'analytics.daily_borough_demand', count(*) from analytics.daily_borough_demand
union all
select 'analytics.top_routes', count(*) from analytics.top_routes
union all
select 'analytics.forecast_next_7_days', count(*) from analytics.forecast_next_7_days;
