PYTHON ?= python3
DB_NAME ?= nyc_mobility_analytics
DATABASE_URL ?= postgresql+psycopg2://localhost/$(DB_NAME)
PSQL ?= psql

.PHONY: setup download load sql materialize validate exports run

setup:
	$(PYTHON) -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt

download:
	$(PYTHON) scripts/download_tlc_data.py --data-dir data/raw --taxi-type yellow --year 2024 --months 10 --skip-existing

load:
	DATABASE_URL=$(DATABASE_URL) $(PYTHON) scripts/load_tlc.py --data-dir data/raw --taxi-type yellow --strict

sql:
	$(PSQL) -d $(DB_NAME) -f sql/analytics_query_pack.sql

materialize:
	$(PSQL) -d $(DB_NAME) -f sql/materialize_analytics_tables.sql

validate:
	DATABASE_URL=$(DATABASE_URL) $(PYTHON) scripts/validate_data.py

exports:
	$(PSQL) -d $(DB_NAME) -f sql/export_dashboard_csv.sql

run: download load sql materialize validate exports
