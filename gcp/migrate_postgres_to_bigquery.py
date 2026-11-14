"""
One-off migration: copy the RAW history from the local Postgres into BigQuery.

Only the two raw tables are copied (trending pages + movie videos). Every staging and
analytics table is rebuilt from them by the first run of the BigQuery pipeline, so the
result is identical to what the SQL transforms produce.

Safe to re-run: rows already in BigQuery are skipped.

Usage (from the repo root, with your existing .env for Postgres):
    gcloud auth application-default login
    pip install -r gcp/requirements-migration.txt
    python gcp/migrate_postgres_to_bigquery.py
"""

import json
import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv
from google.cloud import bigquery

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline.config import BQ_LOCATION, PROJECT_ID, ensure_tables, run_query  # noqa: E402

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

MAX_BATCH_BYTES = 2_000_000  # keep each INSERT request well under BigQuery's limits

INSERT_RESPONSES_SQL = """
INSERT INTO raw.tmdb_api_responses (snapshot_date, endpoint, page, payload, inserted_at)
SELECT
    @dates[OFFSET(i)],
    @endpoints[OFFSET(i)],
    @pages[OFFSET(i)],
    PARSE_JSON(payload, wide_number_mode => 'round'),
    @inserted[OFFSET(i)]
FROM UNNEST(@payloads) AS payload WITH OFFSET i
"""

INSERT_VIDEOS_SQL = """
INSERT INTO raw.tmdb_movie_videos (movie_id, fetched_at, payload)
SELECT
    @movie_ids[OFFSET(i)],
    @fetched[OFFSET(i)],
    PARSE_JSON(payload, wide_number_mode => 'round')
FROM UNNEST(@payloads) AS payload WITH OFFSET i
"""


def pg_connect():
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT")),
        dbname=os.getenv("PG_DB"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )


def batches(rows, payload_index):
    batch, size = [], 0
    for row in rows:
        row_size = len(row[payload_index])
        if batch and size + row_size > MAX_BATCH_BYTES:
            yield batch
            batch, size = [], 0
        batch.append(row)
        size += row_size
    if batch:
        yield batch


def migrate_responses(pg_cur) -> int:
    existing = {
        (r.snapshot_date, r.page)
        for r in run_query("SELECT snapshot_date, page FROM raw.tmdb_api_responses")
    }
    pg_cur.execute("""
        SELECT snapshot_date, endpoint, page, payload::text, inserted_at
        FROM raw.tmdb_api_responses
        ORDER BY snapshot_date, page
    """)
    rows = [r for r in pg_cur.fetchall() if (r[0], r[2]) not in existing]
    print(f"raw.tmdb_api_responses: {len(rows)} rows to copy ({len(existing)} already in BigQuery)")

    for batch in batches(rows, payload_index=3):
        run_query(INSERT_RESPONSES_SQL, [
            bigquery.ArrayQueryParameter("dates", "DATE", [r[0] for r in batch]),
            bigquery.ArrayQueryParameter("endpoints", "STRING", [r[1] for r in batch]),
            bigquery.ArrayQueryParameter("pages", "INT64", [r[2] for r in batch]),
            bigquery.ArrayQueryParameter("payloads", "STRING", [r[3] for r in batch]),
            bigquery.ArrayQueryParameter("inserted", "TIMESTAMP", [r[4] for r in batch]),
        ])
        print(f"  copied {len(batch)} rows")
    return len(rows)


def migrate_videos(pg_cur) -> int:
    # The pipeline only fetches videos for movies with none stored, so skipping by movie_id
    # keeps re-runs safe without duplicating rows.
    existing = {r.movie_id for r in run_query("SELECT DISTINCT movie_id FROM raw.tmdb_movie_videos")}
    # fetched_at is a naive local timestamp in Postgres; interpret it as Europe/Rome
    pg_cur.execute("""
        SELECT movie_id,
               fetched_at AT TIME ZONE 'Europe/Rome' AS fetched_at,
               payload::text
        FROM raw.tmdb_movie_videos
        ORDER BY movie_id, fetched_at
    """)
    rows = [r for r in pg_cur.fetchall() if r[0] not in existing]
    print(f"raw.tmdb_movie_videos: {len(rows)} rows to copy ({len(existing)} movies already in BigQuery)")

    for batch in batches(rows, payload_index=2):
        run_query(INSERT_VIDEOS_SQL, [
            bigquery.ArrayQueryParameter("movie_ids", "INT64", [r[0] for r in batch]),
            bigquery.ArrayQueryParameter("fetched", "TIMESTAMP", [r[1] for r in batch]),
            bigquery.ArrayQueryParameter("payloads", "STRING", [r[2] for r in batch]),
        ])
        print(f"  copied {len(batch)} rows")
    return len(rows)


def compare_counts(pg_cur) -> None:
    print("\nRow counts (Postgres → BigQuery):")
    for table in ("raw.tmdb_api_responses", "raw.tmdb_movie_videos"):
        pg_cur.execute(f"SELECT COUNT(*) FROM {table}")
        pg_count = pg_cur.fetchone()[0]
        bq_count = next(iter(run_query(f"SELECT COUNT(*) AS n FROM {table}"))).n
        flag = "OK" if bq_count >= pg_count else "MISSING ROWS"
        print(f"  {table}: {pg_count} → {bq_count}  [{flag}]")


def main() -> None:
    print(f"Migrating raw history to BigQuery project {PROJECT_ID} ({BQ_LOCATION})")
    ensure_tables()

    conn = pg_connect()
    try:
        with conn.cursor() as cur:
            migrate_responses(cur)
            migrate_videos(cur)
            compare_counts(cur)
    finally:
        conn.close()

    print("\nDone. Now run the pipeline once (Cloud Run job or "
          "`python -m pipeline.run_pipeline` from gcp/) to rebuild staging and analytics.")


if __name__ == "__main__":
    main()
