import json

import requests
from google.cloud import bigquery

from pipeline.config import run_query, tmdb_get

BATCH_SIZE = 100

MISSING_SQL = """
SELECT m.movie_id
FROM analytics.dim_movie m
LEFT JOIN (SELECT DISTINCT movie_id FROM raw.tmdb_movie_videos) r
    ON m.movie_id = r.movie_id
WHERE r.movie_id IS NULL
ORDER BY m.movie_id
"""

INSERT_SQL = """
INSERT INTO raw.tmdb_movie_videos (movie_id, fetched_at, payload)
SELECT
    movie_id,
    CURRENT_TIMESTAMP(),
    PARSE_JSON(@payloads[OFFSET(i)], wide_number_mode => 'round')
FROM UNNEST(@movie_ids) AS movie_id WITH OFFSET i;
"""


def _flush(movie_ids: list[int], payloads: list[str]) -> None:
    if not movie_ids:
        return
    run_query(INSERT_SQL, [
        bigquery.ArrayQueryParameter("movie_ids", "INT64", movie_ids),
        bigquery.ArrayQueryParameter("payloads", "STRING", payloads),
    ])
    print(f"Saved videos for {len(movie_ids)} movies")


def main() -> None:
    missing = [row.movie_id for row in run_query(MISSING_SQL)]
    print(f"{len(missing)} movies without videos")

    movie_ids, payloads = [], []
    with requests.Session() as session:
        for movie_id in missing:
            resp = tmdb_get(f"movie/{movie_id}/videos", session=session)

            if resp.status_code == 404:
                payload = {"id": movie_id, "results": [], "http_status": 404}
                print(f"Movie {movie_id} not found - stored as 404")
            else:
                resp.raise_for_status()
                payload = resp.json()

            movie_ids.append(movie_id)
            payloads.append(json.dumps(payload))

            # Save in batches so a failure late in the loop doesn't lose earlier work
            if len(movie_ids) >= BATCH_SIZE:
                _flush(movie_ids, payloads)
                movie_ids, payloads = [], []

    _flush(movie_ids, payloads)
    print("Movie videos loaded into raw.tmdb_movie_videos")


if __name__ == "__main__":
    main()
