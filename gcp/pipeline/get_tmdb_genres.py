from pipeline.config import run_query, tmdb_get
from google.cloud import bigquery

UPSERT_SQL = """
MERGE analytics.dim_genre t
USING (
    SELECT genre_id, @names[OFFSET(i)] AS genre_name
    FROM UNNEST(@ids) AS genre_id WITH OFFSET i
) s
ON t.genre_id = s.genre_id
WHEN MATCHED THEN UPDATE SET genre_name = s.genre_name
WHEN NOT MATCHED THEN INSERT (genre_id, genre_name) VALUES (s.genre_id, s.genre_name);
"""


def main() -> None:
    resp = tmdb_get("genre/movie/list")
    resp.raise_for_status()
    genres = resp.json()["genres"]

    run_query(UPSERT_SQL, [
        bigquery.ArrayQueryParameter("ids", "INT64", [g["id"] for g in genres]),
        bigquery.ArrayQueryParameter("names", "STRING", [g["name"] for g in genres]),
    ])
    print(f"{len(genres)} genres loaded into analytics.dim_genre")


if __name__ == "__main__":
    main()
