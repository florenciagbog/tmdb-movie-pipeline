from dotenv import load_dotenv
import os

load_dotenv()


import requests
import psycopg2

API_KEY = os.getenv("TMDB_API_KEY")

DB = {
    "host": os.getenv("PG_HOST"),
    "port": int(os.getenv("PG_PORT")),
    "dbname": os.getenv("PG_DB"),
    "user": os.getenv("PG_USER"),
    "password": os.getenv("PG_PASSWORD"),
}

def main():
    url = f"https://api.themoviedb.org/3/genre/movie/list?api_key={API_KEY}"
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    data = response.json()

    conn = psycopg2.connect(**DB)

    try:
        with conn:
            with conn.cursor() as cur:
                for genre in data["genres"]:
                    cur.execute(
                        """
                        insert into analytics.dim_genre (genre_id, genre_name)
                        values (%s, %s)
                        on conflict (genre_id) do update
                        set genre_name = excluded.genre_name;
                        """,
                        (genre["id"], genre["name"])
                    )

        print("Genres loaded into analytics.dim_genre")

    finally:
        conn.close()

if __name__ == "__main__":
    main()