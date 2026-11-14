from pipeline.config import run_query, tmdb_get
from google.cloud import bigquery

UPSERT_SQL = """
MERGE analytics.dim_language t
USING (
    SELECT language_code, @names[OFFSET(i)] AS language_name
    FROM UNNEST(@codes) AS language_code WITH OFFSET i
) s
ON t.language_code = s.language_code
WHEN MATCHED THEN UPDATE SET language_name = s.language_name
WHEN NOT MATCHED THEN INSERT (language_code, language_name) VALUES (s.language_code, s.language_name);
"""


def main() -> None:
    resp = tmdb_get("configuration/languages")
    resp.raise_for_status()
    languages = resp.json()

    run_query(UPSERT_SQL, [
        bigquery.ArrayQueryParameter("codes", "STRING", [l["iso_639_1"] for l in languages]),
        bigquery.ArrayQueryParameter("names", "STRING", [l["english_name"] for l in languages]),
    ])
    print(f"{len(languages)} languages loaded into analytics.dim_language")


if __name__ == "__main__":
    main()
