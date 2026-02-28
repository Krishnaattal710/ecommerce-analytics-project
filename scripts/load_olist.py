#!/usr/bin/env python3
"""Load Olist CSV datasets into PostgreSQL tables."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine

FILE_MAP = {
    "olist_customers_dataset.csv": "olist_customers",
    "olist_geolocation_dataset.csv": "olist_geolocation",
    "olist_order_items_dataset.csv": "olist_order_items",
    "olist_order_payments_dataset.csv": "olist_order_payments",
    "olist_order_reviews_dataset.csv": "olist_order_reviews",
    "olist_orders_dataset.csv": "olist_orders",
    "olist_products_dataset.csv": "olist_products",
    "olist_sellers_dataset.csv": "olist_sellers",
    "product_category_name_translation.csv": "product_category_name_translation",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load Olist CSV files into PostgreSQL")
    parser.add_argument(
        "--data-dir",
        default="data/raw",
        help="Directory that contains the Olist CSV files (default: data/raw)",
    )
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL", "postgresql+psycopg2://localhost/olist_analytics"),
        help="SQLAlchemy database URL (default: env DATABASE_URL or local olist_analytics)",
    )
    parser.add_argument(
        "--chunksize",
        type=int,
        default=50000,
        help="Rows per read chunk while loading CSV files (default: 50000)",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with code 1 if any expected CSV file is missing.",
    )
    return parser.parse_args()


def load_csv_to_table(engine, file_path: Path, table_name: str, chunksize: int) -> int:
    total_rows = 0
    first_chunk = True

    for chunk in pd.read_csv(file_path, chunksize=chunksize, low_memory=False):
        chunk.columns = chunk.columns.str.strip().str.lower()
        chunk.to_sql(
            name=table_name,
            con=engine,
            if_exists="replace" if first_chunk else "append",
            index=False,
            method="multi",
            chunksize=5000,
        )
        total_rows += len(chunk)
        first_chunk = False

    return total_rows


def main() -> int:
    args = parse_args()
    data_dir = Path(args.data_dir)

    if not data_dir.exists() or not data_dir.is_dir():
        print(f"ERROR: data directory does not exist: {data_dir}")
        return 1

    engine = create_engine(args.database_url)
    missing_files: list[str] = []

    print("Starting load into PostgreSQL...")
    print(f"Data directory: {data_dir}")

    for csv_file, table_name in FILE_MAP.items():
        file_path = data_dir / csv_file
        if not file_path.exists():
            missing_files.append(csv_file)
            print(f"[MISSING] {csv_file}")
            continue

        try:
            row_count = load_csv_to_table(engine, file_path, table_name, args.chunksize)
            print(f"[LOADED] {table_name:<35} rows={row_count:,}")
        except Exception as exc:
            print(f"[ERROR] Failed loading {csv_file} -> {table_name}: {exc}")
            return 1

    if missing_files:
        print("\nSome files were missing:")
        for name in missing_files:
            print(f"- {name}")
        if args.strict:
            print("\nStrict mode enabled: exiting with code 1.")
            return 1

    print("\nLoad complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
