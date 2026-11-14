"""Shared settings and BigQuery helpers for the TMDB pipeline."""

import os
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import requests
from google.cloud import bigquery

PROJECT_ID = os.getenv("GCP_PROJECT_ID", "tmdb-data-engineering")
BQ_LOCATION = os.getenv("BQ_LOCATION", "EU")
PIPELINE_TZ = os.getenv("PIPELINE_TZ", "Europe/Rome")
TMDB_BASE_URL = "https://api.themoviedb.org/3"

SQL_DIR = Path(__file__).resolve().parent.parent / "sql"

_client = None


def tmdb_api_key() -> str:
    key = os.getenv("TMDB_API_KEY")
    if not key:
        raise RuntimeError("TMDB_API_KEY is not set")
    return key.strip()


def tmdb_get(path: str, session: requests.Session | None = None, **params) -> requests.Response:
    """GET an endpoint of the TMDB v3 API. Caller decides how to handle status codes."""
    http = session or requests
    return http.get(
        f"{TMDB_BASE_URL}/{path.lstrip('/')}",
        params={"api_key": tmdb_api_key(), **params},
        timeout=30,
    )


def today() -> date:
    """Snapshot date in the pipeline's time zone (Cloud Run runs in UTC)."""
    return datetime.now(ZoneInfo(PIPELINE_TZ)).date()


def get_client() -> bigquery.Client:
    global _client
    if _client is None:
        _client = bigquery.Client(project=PROJECT_ID, location=BQ_LOCATION)
    return _client


def run_query(sql: str, params: list | None = None):
    """Run a (multi-statement) GoogleSQL script and wait for it to finish."""
    job_config = bigquery.QueryJobConfig(query_parameters=params or [])
    job = get_client().query(sql, job_config=job_config)
    return job.result()


def run_sql_file(relative_path: str) -> None:
    sql = (SQL_DIR / relative_path).read_text(encoding="utf-8")
    run_query(sql)


DATASETS = ("raw", "staging", "analytics")


def ensure_tables() -> None:
    """Create datasets and tables if missing (all DDL is IF NOT EXISTS)."""
    client = get_client()
    for name in DATASETS:
        dataset = bigquery.Dataset(f"{PROJECT_ID}.{name}")
        dataset.location = BQ_LOCATION
        client.create_dataset(dataset, exists_ok=True)
    for path in sorted((SQL_DIR / "ddl").glob("*.sql")):
        run_query(path.read_text(encoding="utf-8"))
