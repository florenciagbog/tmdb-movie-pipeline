from dotenv import load_dotenv
import os

load_dotenv()

import json

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


def main() -> None:
    conn = psycopg2.connect(**DB)

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT m.movie_id
                    FROM analytics.dim_movie m
                    LEFT JOIN raw.tmdb_movie_videos r
                        ON m.movie_id = r.movie_id
                    WHERE r.movie_id IS NULL
                    ORDER BY m.movie_id;    
                    """
                )

                movies = cur.fetchall()

                for (movie_id,) in movies:
                    url = (
                        f"https://api.themoviedb.org/3/"
                        f"movie/{movie_id}/videos"
                    )

                    resp = requests.get(
                        url,
                        params={"api_key": TMDB_API_KEY},
                        timeout=30,
                    )

                    if resp.status_code == 404:
                        payload = {
                            "id": movie_id,
                            "results": [],
                            "http_status": 404,
                        }

                        cur.execute(
                            """
                            INSERT INTO raw.tmdb_movie_videos
                            (movie_id, payload)
                            VALUES (%s, %s::jsonb);
                            """,
                            (movie_id, json.dumps(payload)),
                        )

                        print(f"Movie {movie_id} not found - stored as 404")
                        continue

                    resp.raise_for_status()
                    payload = resp.json()

                    cur.execute(
                        """
                        INSERT INTO raw.tmdb_movie_videos
                        (movie_id, payload)
                        VALUES (%s, %s::jsonb);
                        """,
                        (movie_id, json.dumps(payload)),
                    )

                    print(f"Inserted videos for movie {movie_id}")

        print("Movie videos loaded into raw.tmdb_movie_videos")

    finally:
        conn.close()


if __name__ == "__main__":
    main()