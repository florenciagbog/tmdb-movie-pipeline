import json # converts Python objects ↔ JSON text
from datetime import date # gives today’s date

import requests # makes HTTP calls (API request)
import psycopg2 # connects Python to PostgreSQL

TMDB_API_KEY = "3944bca334751775059e5d70804a76af"


# Database connection info
DB = {
    "host": "localhost",
    "port": 5432,
    "dbname": "movies_project",
    "user": "FlorGonzalez",
    "password": "mypassword123",
}
# API endpoint setup
ENDPOINT = "trending/movie/day"
URL = f"https://api.themoviedb.org/3/{ENDPOINT}?api_key={TMDB_API_KEY}"

# Main function

def main() -> None:
    conn = psycopg2.connect(**DB)

    try:
        with conn:
            with conn.cursor() as cur:

                # loop through pages 1 to 5 (top 100 movies)
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
                        INSERT INTO raw.tmdb_trending_raw
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