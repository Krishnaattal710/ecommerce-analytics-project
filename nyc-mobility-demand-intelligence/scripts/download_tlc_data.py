#!/usr/bin/env python3
"""Download NYC TLC trip parquet files and taxi zone lookup CSV."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


BASE_URL = "https://d37ci6vzurychx.cloudfront.net"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download NYC TLC datasets")
    parser.add_argument("--data-dir", default="data/raw", help="Output data directory")
    parser.add_argument(
        "--taxi-type",
        default="yellow",
        choices=["yellow", "green", "fhv", "fhvhv"],
        help="Taxi dataset type",
    )
    parser.add_argument("--year", type=int, required=True, help="Year, e.g. 2024")
    parser.add_argument(
        "--months",
        type=int,
        nargs="+",
        required=True,
        help="Month numbers, e.g. 10 11 12",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="HTTP timeout seconds",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=5,
        help="Retry count for transient download failures (default: 5)",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip download when target file already exists and is non-empty.",
    )
    return parser.parse_args()


def build_session(retries: int) -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=retries,
        connect=retries,
        read=retries,
        status=retries,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def download_file(session: requests.Session, url: str, output_path: Path, timeout: int) -> None:
    response = session.get(url, stream=True, timeout=timeout)
    response.raise_for_status()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as f:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if chunk:
                f.write(chunk)


def main() -> int:
    args = parse_args()
    data_dir = Path(args.data_dir)
    data_dir.mkdir(parents=True, exist_ok=True)
    session = build_session(args.retries)

    try:
        for month in args.months:
            if not 1 <= month <= 12:
                raise ValueError(f"Invalid month: {month}")

            month_str = f"{month:02d}"
            file_name = f"{args.taxi_type}_tripdata_{args.year}-{month_str}.parquet"
            url = f"{BASE_URL}/trip-data/{file_name}"
            output_path = data_dir / file_name

            if args.skip_existing and output_path.exists() and output_path.stat().st_size > 0:
                print(f"Skipping existing file: {output_path}")
                continue

            print(f"Downloading {file_name}...")
            download_file(session, url, output_path, args.timeout)
            print(f"Saved: {output_path}")

        zone_file = "taxi_zone_lookup.csv"
        zone_url = f"{BASE_URL}/misc/{zone_file}"
        zone_path = data_dir / zone_file
        if args.skip_existing and zone_path.exists() and zone_path.stat().st_size > 0:
            print(f"Skipping existing file: {zone_path}")
            print("Download complete.")
            return 0
        print(f"Downloading {zone_file}...")
        download_file(session, zone_url, zone_path, args.timeout)
        print(f"Saved: {zone_path}")

        print("Download complete.")
        return 0

    except Exception as exc:
        print(f"Download failed: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
