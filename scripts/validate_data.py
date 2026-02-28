#!/usr/bin/env python3
"""Run quick validation checks against loaded Olist data and analytics views."""

from __future__ import annotations

import os
import sys

from sqlalchemy import create_engine, text


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://localhost/olist_analytics")


TABLE_CHECKS = {
    "olist_orders": "select count(*) from olist_orders;",
    "olist_customers": "select count(*) from olist_customers;",
    "olist_order_items": "select count(*) from olist_order_items;",
    "olist_order_payments": "select count(*) from olist_order_payments;",
}

VIEW_CHECKS = {
    "analytics.vw_order_fact": "select count(*) from analytics.vw_order_fact;",
    "analytics.vw_kpi_snapshot_12m": "select count(*) from analytics.vw_kpi_snapshot_12m;",
    "analytics.vw_monthly_revenue_orders": "select count(*) from analytics.vw_monthly_revenue_orders;",
    "analytics.vw_cohort_retention_0_6": "select count(*) from analytics.vw_cohort_retention_0_6;",
}


def run_scalar(conn, query: str):
    return conn.execute(text(query)).scalar()


def main() -> int:
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            print("Validation results")
            print("------------------")

            failed = False

            for name, query in TABLE_CHECKS.items():
                try:
                    value = run_scalar(conn, query)
                    print(f"{name:<35} rows={value}")
                    if value is None or int(value) == 0:
                        failed = True
                except Exception as exc:
                    failed = True
                    print(f"{name:<35} ERROR: {exc}")

            print("\nAnalytics views")
            print("---------------")
            for name, query in VIEW_CHECKS.items():
                try:
                    value = run_scalar(conn, query)
                    print(f"{name:<35} rows={value}")
                    if value is None or int(value) == 0:
                        failed = True
                except Exception as exc:
                    failed = True
                    print(f"{name:<35} ERROR: {exc}")

            if failed:
                print("\nValidation failed. Check errors above.")
                return 1

            print("\nValidation passed.")
            return 0

    except Exception as exc:
        print(f"Database connection error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
