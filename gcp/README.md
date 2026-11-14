# TMDB pipeline on Google Cloud (BigQuery + Cloud Run)

BigQuery version of the daily TMDB pipeline, scheduled in the cloud instead of being run by hand.

```
Cloud Scheduler (daily 09:00 Europe/Rome)
        │  HTTP POST (OAuth)
        ▼
Cloud Run Job  tmdb-pipeline  ── reads TMDB_API_KEY from Secret Manager
        │  python -m pipeline.run_pipeline
        ▼
BigQuery  tmdb-data-engineering   raw → staging → analytics
        ▼
Power BI (Google BigQuery connector)
```

Same steps and same tables as the Postgres version; the SQL was translated to GoogleSQL:

| Postgres | BigQuery |
|---|---|
| `JSONB`, `->>`, `jsonb_array_elements … WITH ORDINALITY` | `JSON`, `JSON_VALUE` / `LAX_*`, `UNNEST(JSON_QUERY_ARRAY(…)) WITH OFFSET` |
| `INSERT … ON CONFLICT` | `MERGE` |
| `DISTINCT ON` | `QUALIFY ROW_NUMBER() … = 1` |
| `LEFT JOIN LATERAL … LIMIT 1` | correlated subquery over `UNNEST` |
| `SERIAL`, PK / FK constraints | dropped (BigQuery doesn't enforce them; keys are enforced by the MERGEs) |

## Layout

```
gcp/
├── pipeline/                  # Python steps (BigQuery client instead of psycopg2)
├── sql/ddl/                   # CREATE TABLE IF NOT EXISTS (run at the start of every job)
├── sql/transforms/            # 20–26, same numbering as before
├── Dockerfile                 # image for the Cloud Run job
├── deploy.sh                  # one-shot setup: APIs, service account, secret, job, schedule
└── migrate_postgres_to_bigquery.py   # one-off copy of the raw history from Postgres
```

## Setup

1. **Copy the history** (on the machine with Postgres, from the repo root):
   ```
   gcloud auth application-default login
   pip install -r gcp/requirements-migration.txt
   python gcp/migrate_postgres_to_bigquery.py
   ```
2. **Deploy** (Cloud Shell, after pushing this folder):
   ```
   git clone https://github.com/florenciagbog/tmdb-movie-pipeline.git
   cd tmdb-movie-pipeline/gcp && bash deploy.sh
   gcloud run jobs execute tmdb-pipeline --region europe-west1 --wait
   ```
   The first run rebuilds every staging/analytics table from the raw history.

Override defaults with env vars, e.g. `SCHEDULE="30 7 * * *" BQ_LOCATION=US bash deploy.sh`.

## Operations

- Run now: `gcloud run jobs execute tmdb-pipeline --region europe-west1`
- Logs: Cloud Run → Jobs → tmdb-pipeline → Logs
- Change schedule: re-run `deploy.sh` with `SCHEDULE=...`
- Run locally: `cd gcp && TMDB_API_KEY=... python -m pipeline.run_pipeline`

Cost at this volume is effectively zero (Cloud Run Jobs, Scheduler and BigQuery free tiers).
