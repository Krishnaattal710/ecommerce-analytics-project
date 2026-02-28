# Dashboard Layout - NYC Mobility Demand Intelligence

## Page 1: Executive Mobility Pulse

- KPI cards:
  - Total Trips
  - Avg Daily Trips
  - Avg Total Fare
  - Avg Trip Distance
  - Avg Trip Duration (min)
- Line chart: Hourly demand trend (`hourly_demand`)
- Bar chart: Borough demand (`daily_borough_demand` aggregated by borough)
- Donut chart: Payment type mix (`payment_mix`)

## Page 2: Operations & Zone Intelligence

- Bar chart: Top pickup zones by trips (`zone_demand`)
- Table: Top origin-destination routes (`top_routes`)
- Heatmap: Hour of day vs day of week demand (`hourly_demand`)

## Page 3: Forecast & Planning

- Line chart: Forecasted next 7 days trips (`forecast_next_7_days`)
- Supporting line: Last 7 actual days from `daily_borough_demand` (all boroughs combined)
- Commentary box: staffing/fleet planning recommendations

## Global Filters

- Trip date
- Pickup borough
- Payment type

## Design Notes

- Use blue for demand, orange for forecast, red for anomaly/high-risk buckets.
- Keep KPI cards at top and use consistent number formatting.
- Add tooltips for business interpretation, not only raw values.
