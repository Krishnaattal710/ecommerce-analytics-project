#!/usr/bin/env python3
"""Load NYC TLC parquet files into PostgreSQL."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

import pandas as pd
import pyarrow.parquet as pq
from sqlalchemy import create_engine


TRIP_TABLE = "nyc_taxi_trips"
ZONE_TABLE = "nyc_taxi_zones"

TRIP_COLUMNS = [
    "vendorid",
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime",
    "passenger_count",
    "trip_distance",
    "ratecodeid",
    "pulocationid",
    "dolocationid",
    "payment_type",
    "fare_amount",
    "tip_amount",
    "tolls_amount",
    "total_amount",
    "congestion_surcharge",
    "airport_fee",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load NYC TLC parquet files into PostgreSQL")
    parser.add_argument("--data-dir", default="data/raw", help="Directory containing parquet files")
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL", "postgresql+psycopg2://localhost/nyc_mobility_analytics"),
        help="SQLAlchemy database URL",
    )
    parser.add_argument(
        "--taxi-type",
        default="yellow",
        choices=["yellow", "green", "fhv", "fhvhv"],
        help="Taxi type prefix in filenames",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=100000,
        help="PyArrow record batch size",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail if no parquet files are found",
    )
    return parser.parse_args()


def normalize_trip_chunk(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [c.lower().strip() for c in df.columns]

    missing = [c for c in TRIP_COLUMNS if c not in df.columns]
    for col in missing:
        df[col] = pd.NA

    df = df[TRIP_COLUMNS].copy()

    df["tpep_pickup_datetime"] = pd.to_datetime(df["tpep_pickup_datetime"], errors="coerce")
    df["tpep_dropoff_datetime"] = pd.to_datetime(df["tpep_dropoff_datetime"], errors="coerce")

    numeric_cols = [
        "passenger_count",
        "trip_distance",
        "fare_amount",
        "tip_amount",
        "tolls_amount",
        "total_amount",
        "congestion_surcharge",
        "airport_fee",
    ]

    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    int_cols = ["vendorid", "ratecodeid", "pulocationid", "dolocationid", "payment_type"]
    for col in int_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")

    return df


def load_trip_parquet(engine, file_path: Path, batch_size: int, replace: bool) -> int:
    parquet = pq.ParquetFile(file_path)
    total_rows = 0
    first = replace

    for batch in parquet.iter_batches(batch_size=batch_size):
        df = batch.to_pandas(types_mapper=None)
        df = normalize_trip_chunk(df)
        df["source_file"] = file_path.name

        df.to_sql(
            TRIP_TABLE,
            engine,
            if_exists="replace" if first else "append",
            index=False,
            method="multi",
            chunksize=5000,
        )

        total_rows += len(df)
        first = False

    return total_rows


def load_zone_lookup(engine, zone_path: Path) -> int:
    zones = pd.read_csv(zone_path)
    zones.columns = [c.lower().strip() for c in zones.columns]
    zones = zones.rename(columns={"locationid": "location_id"})

    expected = ["location_id", "borough", "zone", "service_zone"]
    zones = zones[expected]

    zones.to_sql(
        ZONE_TABLE,
        engine,
        if_exists="replace",
        index=False,
        method="multi",
        chunksize=5000,
    )
    return len(zones)


def main() -> int:
    args = parse_args()
    data_dir = Path(args.data_dir)

    if not data_dir.exists():
        print(f"ERROR: data directory not found: {data_dir}")
        return 1

    parquet_files = sorted(data_dir.glob(f"{args.taxi_type}_tripdata_*.parquet"))

    if not parquet_files:
        print("No trip parquet files found.")
        if args.strict:
            return 1

    zone_path = data_dir / "taxi_zone_lookup.csv"
    if not zone_path.exists():
        print("Missing taxi_zone_lookup.csv")
        if args.strict:
            return 1

    try:
        engine = create_engine(args.database_url)

        replace = True
        total = 0
        for path in parquet_files:
            print(f"Loading {path.name}...")
            rows = load_trip_parquet(engine, path, args.batch_size, replace)
            print(f"[LOADED] {path.name}: {rows:,} rows")
            total += rows
            replace = False

        zone_rows = load_zone_lookup(engine, zone_path)
        print(f"[LOADED] taxi_zone_lookup.csv: {zone_rows:,} rows")
        print(f"Total trip rows loaded: {total:,}")
        print("Load complete.")
        return 0

    except Exception as exc:
        print(f"Load failed: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
