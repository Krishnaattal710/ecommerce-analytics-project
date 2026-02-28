PYTHON ?= python3
DB_NAME ?= olist_analytics
DATABASE_URL ?= postgresql+psycopg2://localhost/$(DB_NAME)

.PHONY: setup load sql validate run lint tree

setup:
	$(PYTHON) -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt

load:
	DATABASE_URL=$(DATABASE_URL) $(PYTHON) scripts/load_olist.py --data-dir data/raw --strict

sql:
	psql -d $(DB_NAME) -f sql/analytics_query_pack.sql

validate:
	DATABASE_URL=$(DATABASE_URL) $(PYTHON) scripts/validate_data.py

run: load sql validate

lint:
	$(PYTHON) -m py_compile scripts/load_olist.py scripts/validate_data.py

tree:
	find . -maxdepth 3 -type f | sort
