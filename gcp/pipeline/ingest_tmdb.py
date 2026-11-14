import json

from google.cloud import bigquery

from pipeline.config import run_query, tmdb_get, today

ENDPOINT = "trending/movie/day"
PAGES = range(1, 6)

# Equivalent of ON CONFLICT (snapshot_date, page) DO NOTHING
INSERT_SQL = """
INSERT INTO raw.tmdb_api_responses (snapshot_date, endpoint, page, payload)
SELECT
    @snapshot_date,
    @endpoint,
    page,
    PARSE_JSON(@payloads[OFFSET(i)], wide_number_mode => 'round')
FROM UNNEST(@pages) AS page WITH OFFSET i
WHERE page NOT IN (
    SELECT page FROM raw.tmdb_api_responses WHERE snapshot_date = @snapshot_date
);
"""


def main() -> None:
    snapshot_date = today()
    pages, payloads = [], []

    for page in PAGES:
        resp = tmdb_get(ENDPOINT, page=page)
        resp.raise_for_status()
        pages.append(page)
        payloads.append(json.dumps(resp.json()))
        print(f"Fetched page {page}")

    run_query(INSERT_SQL, [
        bigquery.ScalarQueryParameter("snapshot_date", "DATE", snapshot_date),
        bigquery.ScalarQueryParameter("endpoint", "STRING", ENDPOINT),
        bigquery.ArrayQueryParameter("pages", "INT64", pages),
        bigquery.ArrayQueryParameter("payloads", "STRING", payloads),
    ])
    print(f"Trending pages for {snapshot_date} loaded into raw.tmdb_api_responses")


if __name__ == "__main__":
    main()
