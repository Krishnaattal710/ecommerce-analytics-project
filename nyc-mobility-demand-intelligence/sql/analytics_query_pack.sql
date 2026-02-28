-- NYC Mobility Demand Intelligence - SQL Query Pack
-- Target: PostgreSQL

create schema if not exists analytics;

-- Drop views in reverse dependency order

drop view if exists analytics.vw_forecast_next_7_days;
drop view if exists analytics.vw_top_routes;
drop view if exists analytics.vw_payment_mix;
drop view if exists analytics.vw_zone_demand;
drop view if exists analytics.vw_daily_borough_demand;
drop view if exists analytics.vw_hourly_demand;
drop view if exists analytics.vw_kpi_snapshot;
drop view if exists analytics.vw_trip_fact;

-- 1) Core trip fact view with derived metrics
create view analytics.vw_trip_fact as
select
    t.vendorid,
    t.tpep_pickup_datetime as pickup_ts,
    t.tpep_dropoff_datetime as dropoff_ts,
    date_trunc('day', t.tpep_pickup_datetime)::date as trip_date,
    date_trunc('hour', t.tpep_pickup_datetime) as pickup_hour_ts,
    extract(hour from t.tpep_pickup_datetime)::int as pickup_hour,
    extract(dow from t.tpep_pickup_datetime)::int as pickup_dow,
    t.passenger_count,
    t.trip_distance,
    t.pulocationid as pickup_location_id,
    t.dolocationid as dropoff_location_id,
    pz.borough as pickup_borough,
    pz.zone as pickup_zone,
    dz.borough as dropoff_borough,
    dz.zone as dropoff_zone,
    t.payment_type,
    case
        when t.payment_type = 1 then 'Credit card'
        when t.payment_type = 2 then 'Cash'
        when t.payment_type = 3 then 'No charge'
        when t.payment_type = 4 then 'Dispute'
        when t.payment_type = 5 then 'Unknown'
        when t.payment_type = 6 then 'Voided trip'
        else 'Other'
    end as payment_type_label,
    t.fare_amount,
    t.tip_amount,
    t.tolls_amount,
    t.total_amount,
    coalesce(t.congestion_surcharge, 0) as congestion_surcharge,
    coalesce(t.airport_fee, 0) as airport_fee,
    case
        when t.tpep_dropoff_datetime is not null
            and t.tpep_pickup_datetime is not null
        then extract(epoch from (t.tpep_dropoff_datetime - t.tpep_pickup_datetime)) / 60.0
        else null
    end as trip_duration_min,
    t.source_file
from nyc_taxi_trips t
left join nyc_taxi_zones pz
    on pz.location_id = t.pulocationid
left join nyc_taxi_zones dz
    on dz.location_id = t.dolocationid
where t.tpep_pickup_datetime is not null
    and t.tpep_dropoff_datetime is not null
    and t.total_amount is not null
    and t.total_amount >= 0
    and t.trip_distance is not null
    and t.trip_distance >= 0;

-- 2) KPI snapshot
create view analytics.vw_kpi_snapshot as
select
    count(*) as total_trips,
    round(avg(total_amount)::numeric, 2) as avg_total_fare,
    round(avg(trip_distance)::numeric, 2) as avg_trip_distance,
    round(avg(trip_duration_min)::numeric, 2) as avg_trip_duration_min,
    round(100.0 * avg(case when payment_type_label = 'Credit card' then 1.0 else 0.0 end)::numeric, 2) as credit_card_share_pct,
    round(avg(case when fare_amount > 0 then tip_amount / nullif(fare_amount, 0) end)::numeric * 100.0, 2) as avg_tip_pct_on_fare,
    round((count(*)::numeric / nullif(count(distinct trip_date), 0)), 2) as avg_daily_trips
from analytics.vw_trip_fact;

-- 3) Hourly demand trend
create view analytics.vw_hourly_demand as
select
    pickup_hour_ts,
    trip_date,
    pickup_hour,
    count(*) as trips,
    round(sum(total_amount)::numeric, 2) as gross_revenue,
    round(avg(total_amount)::numeric, 2) as avg_fare,
    round(avg(trip_duration_min)::numeric, 2) as avg_duration_min
from analytics.vw_trip_fact
group by 1,2,3
order by 1;

-- 4) Daily demand by borough
create view analytics.vw_daily_borough_demand as
select
    trip_date,
    coalesce(pickup_borough, 'Unknown') as pickup_borough,
    count(*) as trips,
    round(sum(total_amount)::numeric, 2) as gross_revenue,
    round(avg(total_amount)::numeric, 2) as avg_fare
from analytics.vw_trip_fact
group by 1,2
order by 1,2;

-- 5) Zone demand leaderboard
create view analytics.vw_zone_demand as
select
    coalesce(pickup_zone, 'Unknown') as pickup_zone,
    coalesce(pickup_borough, 'Unknown') as pickup_borough,
    count(*) as trips,
    round(sum(total_amount)::numeric, 2) as gross_revenue,
    round(avg(trip_duration_min)::numeric, 2) as avg_duration_min
from analytics.vw_trip_fact
group by 1,2
having count(*) >= 100
order by trips desc;

-- 6) Payment mix
create view analytics.vw_payment_mix as
select
    payment_type_label,
    count(*) as trips,
    round(100.0 * count(*)::numeric / nullif(sum(count(*)) over (), 0), 2) as trips_share_pct,
    round(sum(total_amount)::numeric, 2) as gross_revenue
from analytics.vw_trip_fact
group by 1
order by trips desc;

-- 7) Top origin-destination routes
create view analytics.vw_top_routes as
select
    coalesce(pickup_zone, 'Unknown') as pickup_zone,
    coalesce(dropoff_zone, 'Unknown') as dropoff_zone,
    coalesce(pickup_borough, 'Unknown') as pickup_borough,
    coalesce(dropoff_borough, 'Unknown') as dropoff_borough,
    count(*) as trips,
    round(avg(total_amount)::numeric, 2) as avg_fare,
    round(avg(trip_duration_min)::numeric, 2) as avg_duration_min
from analytics.vw_trip_fact
group by 1,2,3,4
having count(*) >= 200
order by trips desc;

-- 8) Lightweight forecast (next 7 days) from weekday averages
create view analytics.vw_forecast_next_7_days as
with daily as (
    select
        trip_date,
        extract(dow from trip_date)::int as dow,
        count(*) as trips
    from analytics.vw_trip_fact
    group by 1
),
latest as (
    select max(trip_date) as max_trip_date from daily
),
weekday_avg as (
    select dow, round(avg(trips)::numeric, 0) as avg_trips
    from daily
    group by dow
),
future_days as (
    select (l.max_trip_date + gs.day_offset)::date as forecast_date
    from latest l
    cross join generate_series(1, 7) as gs(day_offset)
)
select
    f.forecast_date,
    extract(dow from f.forecast_date)::int as dow,
    w.avg_trips as forecast_trips
from future_days f
join weekday_avg w
    on w.dow = extract(dow from f.forecast_date)::int
order by f.forecast_date;

-- Suggested checks
-- select * from analytics.vw_kpi_snapshot;
-- select * from analytics.vw_hourly_demand limit 20;
-- select * from analytics.vw_daily_borough_demand limit 20;
-- select * from analytics.vw_zone_demand limit 20;
-- select * from analytics.vw_payment_mix;
-- select * from analytics.vw_top_routes limit 20;
-- select * from analytics.vw_forecast_next_7_days;
