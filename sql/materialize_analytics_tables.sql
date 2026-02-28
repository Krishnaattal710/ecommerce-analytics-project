-- Materialize analytics views into physical tables for BI tools
-- Run after sql/analytics_query_pack.sql

create schema if not exists analytics;

-- 1) Order-level fact table

drop table if exists analytics.fact_order;
create table analytics.fact_order as
select * from analytics.vw_order_fact;

alter table analytics.fact_order
    add primary key (order_id);

create index if not exists idx_fact_order_purchase_ts
    on analytics.fact_order (purchase_ts);
create index if not exists idx_fact_order_customer_unique_id
    on analytics.fact_order (customer_unique_id);
create index if not exists idx_fact_order_customer_state
    on analytics.fact_order (customer_state);

-- 2) Order-category bridge table

drop table if exists analytics.bridge_order_category;
create table analytics.bridge_order_category as
select * from analytics.vw_order_category;

create index if not exists idx_bridge_order_category_order_id
    on analytics.bridge_order_category (order_id);
create index if not exists idx_bridge_order_category_category
    on analytics.bridge_order_category (category);

-- 3) Dashboard aggregate tables

drop table if exists analytics.kpi_snapshot_12m;
create table analytics.kpi_snapshot_12m as
select * from analytics.vw_kpi_snapshot_12m;

drop table if exists analytics.monthly_revenue_orders;
create table analytics.monthly_revenue_orders as
select * from analytics.vw_monthly_revenue_orders;
create index if not exists idx_monthly_revenue_orders_month
    on analytics.monthly_revenue_orders (month);

drop table if exists analytics.customer_repeat_rate;
create table analytics.customer_repeat_rate as
select * from analytics.vw_customer_repeat_rate;

drop table if exists analytics.new_vs_returning_monthly;
create table analytics.new_vs_returning_monthly as
select * from analytics.vw_new_vs_returning_monthly;
create index if not exists idx_new_vs_returning_monthly_month
    on analytics.new_vs_returning_monthly (month);

drop table if exists analytics.sla_state;
create table analytics.sla_state as
select * from analytics.vw_sla_state;

drop table if exists analytics.top_categories;
create table analytics.top_categories as
select * from analytics.vw_top_categories;
create index if not exists idx_top_categories_revenue
    on analytics.top_categories (revenue desc);

drop table if exists analytics.payment_mix;
create table analytics.payment_mix as
select * from analytics.vw_payment_mix;

drop table if exists analytics.failed_order_trend;
create table analytics.failed_order_trend as
select * from analytics.vw_failed_order_trend;
create index if not exists idx_failed_order_trend_month
    on analytics.failed_order_trend (month);

drop table if exists analytics.cohort_retention_0_6;
create table analytics.cohort_retention_0_6 as
select * from analytics.vw_cohort_retention_0_6;
create index if not exists idx_cohort_retention_cohort_month
    on analytics.cohort_retention_0_6 (cohort_month, month_number);

-- quick row counts
select 'analytics.fact_order' as table_name, count(*) as rows from analytics.fact_order
union all
select 'analytics.bridge_order_category', count(*) from analytics.bridge_order_category
union all
select 'analytics.monthly_revenue_orders', count(*) from analytics.monthly_revenue_orders
union all
select 'analytics.cohort_retention_0_6', count(*) from analytics.cohort_retention_0_6;
