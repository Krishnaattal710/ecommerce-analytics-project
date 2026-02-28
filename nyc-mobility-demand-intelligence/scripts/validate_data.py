#!/usr/bin/env python3
"""Validate NYC mobility project tables and views."""

from __future__ import annotations

import os
import sys

from sqlalchemy import create_engine, text


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://localhost/nyc_mobility_analytics")


CHECKS = {
    "public.nyc_taxi_trips": "select count(*) from nyc_taxi_trips;",
    "public.nyc_taxi_zones": "select count(*) from nyc_taxi_zones;",
    "analytics.vw_trip_fact": "select count(*) from analytics.vw_trip_fact;",
    "analytics.vw_kpi_snapshot": "select count(*) from analytics.vw_kpi_snapshot;",
    "analytics.vw_hourly_demand": "select count(*) from analytics.vw_hourly_demand;",
    "analytics.vw_daily_borough_demand": "select count(*) from analytics.vw_daily_borough_demand;",
    "analytics.vw_top_routes": "select count(*) from analytics.vw_top_routes;",
}


def main() -> int:
    try:
        engine = create_engine(DATABASE_URL)
        failed = False

        with engine.connect() as conn:
            print("Validation results")
            print("------------------")
            for name, query in CHECKS.items():
                try:
                    value = conn.execute(text(query)).scalar()
                    print(f"{name:<35} rows={value}")
                    if value is None or int(value) == 0:
                        failed = True
                except Exception as exc:
                    print(f"{name:<35} ERROR: {exc}")
                    failed = True

        if failed:
            print("\nValidation failed.")
            return 1

        print("\nValidation passed.")
        return 0

    except Exception as exc:
        print(f"Connection failed: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
