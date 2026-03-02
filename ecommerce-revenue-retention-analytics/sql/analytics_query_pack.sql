-- Olist Ecommerce Analytics Query Pack
-- Target: PostgreSQL

create schema if not exists analytics;

-- Drop in dependency order for repeatable runs.
drop view if exists analytics.vw_cohort_retention_0_6;
drop view if exists analytics.vw_failed_order_trend;
drop view if exists analytics.vw_payment_mix;
drop view if exists analytics.vw_top_categories;
drop view if exists analytics.vw_sla_state;
drop view if exists analytics.vw_new_vs_returning_monthly;
drop view if exists analytics.vw_customer_repeat_rate;
drop view if exists analytics.vw_monthly_revenue_orders;
drop view if exists analytics.vw_kpi_snapshot_12m;
drop view if exists analytics.vw_order_category;
drop view if exists analytics.vw_order_fact;

-- 1) Core order-level fact view (one row per order)
create view analytics.vw_order_fact as
with item_agg as (
    select
        order_id,
        count(*) as items_count,
        sum(price) as item_revenue,
        sum(freight_value) as freight_value
    from olist_order_items
    group by order_id
),
payment_agg as (
    select
        order_id,
        sum(payment_value) as payment_value
    from olist_order_payments
    group by order_id
),
review_agg as (
    select
        order_id,
        avg(review_score)::numeric(10,2) as avg_review_score
    from olist_order_reviews
    group by order_id
)
select
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp::timestamp as purchase_ts,
    o.order_approved_at::timestamp as approved_ts,
    o.order_delivered_carrier_date::timestamp as carrier_ts,
    o.order_delivered_customer_date::timestamp as delivered_ts,
    o.order_estimated_delivery_date::timestamp as estimated_delivery_ts,
    coalesce(i.items_count, 0) as items_count,
    coalesce(i.item_revenue, 0)::numeric(12,2) as item_revenue,
    coalesce(i.freight_value, 0)::numeric(12,2) as freight_value,
    coalesce(p.payment_value, 0)::numeric(12,2) as payment_value,
    r.avg_review_score
from olist_orders o
join olist_customers c on c.customer_id = o.customer_id
left join item_agg i on i.order_id = o.order_id
left join payment_agg p on p.order_id = o.order_id
left join review_agg r on r.order_id = o.order_id;

-- 2) Order-category bridge view
create view analytics.vw_order_category as
select
    oi.order_id,
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as category,
    sum(oi.price)::numeric(12,2) as category_revenue
from olist_order_items oi
left join olist_products p
    on p.product_id = oi.product_id
left join product_category_name_translation t
    on t.product_category_name = p.product_category_name
group by
    oi.order_id,
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown');

-- 3) KPI snapshot (last 12 months, delivered orders)
create view analytics.vw_kpi_snapshot_12m as
with max_month_cte as (
    select date_trunc('month', max(purchase_ts))::date as max_month
    from analytics.vw_order_fact
)
select
    count(distinct order_id) as orders,
    round(sum(payment_value), 2) as gross_revenue,
    round(sum(payment_value) / nullif(count(distinct order_id), 0), 2) as aov,
    round(avg(avg_review_score), 2) as avg_review_score,
    round(
        100.0 * avg(
            case
                when delivered_ts is not null
                    and estimated_delivery_ts is not null
                    and delivered_ts <= estimated_delivery_ts then 1.0
                else 0.0
            end
        ),
        2
    ) as on_time_delivery_pct,
    round(avg((delivered_ts::date - purchase_ts::date)), 2) as avg_delivery_days
from analytics.vw_order_fact
cross join max_month_cte mm
where order_status = 'delivered'
    and purchase_ts >= mm.max_month - interval '11 months'
    and purchase_ts < mm.max_month + interval '1 month';

-- 4) Monthly trend
create view analytics.vw_monthly_revenue_orders as
with monthly as (
    select
        date_trunc('month', purchase_ts)::date as month,
        count(distinct order_id) as orders,
        sum(payment_value) as revenue
    from analytics.vw_order_fact
    where order_status = 'delivered'
    group by 1
)
select
    month,
    orders,
    round(revenue, 2) as revenue,
    round(
        100.0 * (revenue - lag(revenue) over (order by month))
        / nullif(lag(revenue) over (order by month), 0),
        2
    ) as mom_revenue_pct
from monthly
order by month;

-- 5) Overall repeat rate
create view analytics.vw_customer_repeat_rate as
with customer_orders as (
    select
        customer_unique_id,
        count(distinct order_id) as orders
    from analytics.vw_order_fact
    where order_status = 'delivered'
    group by 1
)
select
    count(*) as customers,
    count(*) filter (where orders >= 2) as repeat_customers,
    round(
        100.0 * count(*) filter (where orders >= 2)
        / nullif(count(*), 0),
        2
    ) as repeat_rate_pct
from customer_orders;

-- 6) New vs returning customers by month
create view analytics.vw_new_vs_returning_monthly as
with first_order as (
    select
        customer_unique_id,
        date_trunc('month', min(purchase_ts))::date as first_month
    from analytics.vw_order_fact
    where order_status = 'delivered'
    group by 1
),
orders_m as (
    select
        customer_unique_id,
        date_trunc('month', purchase_ts)::date as month
    from analytics.vw_order_fact
    where order_status = 'delivered'
)
select
    o.month,
    count(distinct case when o.month = f.first_month then o.customer_unique_id end) as new_customers,
    count(distinct case when o.month > f.first_month then o.customer_unique_id end) as returning_customers
from orders_m o
join first_order f
    on f.customer_unique_id = o.customer_unique_id
group by 1
order by 1;

-- 7) Delivery SLA by state
create view analytics.vw_sla_state as
select
    customer_state,
    count(distinct order_id) as delivered_orders,
    round(avg((delivered_ts::date - purchase_ts::date)), 2) as avg_delivery_days,
    round(avg((delivered_ts::date - estimated_delivery_ts::date)), 2) as avg_delay_days,
    round(
        100.0 * avg(
            case when delivered_ts <= estimated_delivery_ts then 1.0 else 0.0 end
        ),
        2
    ) as on_time_pct
from analytics.vw_order_fact
where order_status = 'delivered'
    and delivered_ts is not null
    and estimated_delivery_ts is not null
group by 1
having count(distinct order_id) >= 100
order by on_time_pct asc;

-- 8) Top categories
create view analytics.vw_top_categories as
select
    oc.category,
    round(sum(oc.category_revenue), 2) as revenue,
    count(distinct f.order_id) as orders
from analytics.vw_order_fact f
join analytics.vw_order_category oc
    on oc.order_id = f.order_id
where f.order_status = 'delivered'
group by 1
order by revenue desc;

-- 9) Payment mix
create view analytics.vw_payment_mix as
select
    p.payment_type,
    round(sum(p.payment_value)::numeric, 2) as payment_value,
    round(
        (
            100.0 * sum(p.payment_value)
            / sum(sum(p.payment_value)) over ()
        )::numeric,
        2
    ) as share_pct
from olist_order_payments p
join olist_orders o
    on o.order_id = p.order_id
where o.order_status = 'delivered'
group by 1
order by payment_value desc;

-- 10) Failed order trend
create view analytics.vw_failed_order_trend as
select
    date_trunc('month', purchase_ts)::date as month,
    count(distinct order_id) as total_orders,
    count(distinct order_id)
        filter (where order_status in ('canceled', 'unavailable')) as failed_orders,
    round(
        100.0 * count(distinct order_id)
            filter (where order_status in ('canceled', 'unavailable'))
        / nullif(count(distinct order_id), 0),
        2
    ) as failed_order_pct
from analytics.vw_order_fact
group by 1
order by 1;

-- 11) Cohort retention (month 0..6)
create view analytics.vw_cohort_retention_0_6 as
with first_order as (
    select
        customer_unique_id,
        date_trunc('month', min(purchase_ts))::date as cohort_month
    from analytics.vw_order_fact
    where order_status = 'delivered'
    group by 1
),
activity as (
    select
        f.customer_unique_id,
        f.cohort_month,
        date_trunc('month', o.purchase_ts)::date as order_month
    from first_order f
    join analytics.vw_order_fact o
        on o.customer_unique_id = f.customer_unique_id
    where o.order_status = 'delivered'
),
ret as (
    select
        cohort_month,
        (
            (date_part('year', order_month) - date_part('year', cohort_month)) * 12
            + (date_part('month', order_month) - date_part('month', cohort_month))
        )::int as month_number,
        count(distinct customer_unique_id) as active_customers
    from activity
    group by 1, 2
),
cohort_size as (
    select
        cohort_month,
        active_customers as cohort_customers
    from ret
    where month_number = 0
)
select
    r.cohort_month,
    r.month_number,
    r.active_customers,
    round(
        100.0 * r.active_customers / nullif(c.cohort_customers, 0),
        2
    ) as retention_pct
from ret r
join cohort_size c
    on c.cohort_month = r.cohort_month
where r.month_number between 0 and 6
order by r.cohort_month, r.month_number;

-- Sample usage checks
-- select * from analytics.vw_kpi_snapshot_12m;
-- select * from analytics.vw_monthly_revenue_orders;
-- select * from analytics.vw_customer_repeat_rate;
-- select * from analytics.vw_new_vs_returning_monthly;
-- select * from analytics.vw_sla_state;
-- select * from analytics.vw_top_categories limit 15;
-- select * from analytics.vw_payment_mix;
-- select * from analytics.vw_failed_order_trend;
-- select * from analytics.vw_cohort_retention_0_6;
