from dotenv import load_dotenv
import os

load_dotenv()

import json
from datetime import date

import requests
import psycopg2

TMDB_API_KEY = os.getenv("TMDB_API_KEY")

DB = {
    "host": os.getenv("PG_HOST"),
    "port": int(os.getenv("PG_PORT")),
    "dbname": os.getenv("PG_DB"),
    "user": os.getenv("PG_USER"),
    "password": os.getenv("PG_PASSWORD"),
}

ENDPOINT = "trending/movie/day"


def main() -> None:
    conn = psycopg2.connect(**DB)

    try:
        with conn:
            with conn.cursor() as cur:
                for page in range(1, 6):
                    url = (
                        f"https://api.themoviedb.org/3/{ENDPOINT}"
                        f"?api_key={TMDB_API_KEY}&page={page}"
                    )

                    resp = requests.get(url, timeout=30)
                    resp.raise_for_status()
                    payload = resp.json()

                    cur.execute(
                        """
                        INSERT INTO raw.tmdb_api_responses
                        (snapshot_date, endpoint, payload, page)
                        VALUES (%s, %s, %s::jsonb, %s)
                        ON CONFLICT (snapshot_date, page) DO NOTHING;
                        """,
                        (date.today(), ENDPOINT, json.dumps(payload), page),
                    )

                    print(f"Inserted page {page}")

    finally:
        conn.close()


if __name__ == "__main__":
    main()