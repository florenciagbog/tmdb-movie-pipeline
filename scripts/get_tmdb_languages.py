# get_tmdb_languages.py
from dotenv import load_dotenv
import os
import requests
import psycopg2

load_dotenv()

API_KEY = os.getenv("TMDB_API_KEY")

DB = {
    "host": os.getenv("PG_HOST"),
    "port": int(os.getenv("PG_PORT")),
    "dbname": os.getenv("PG_DB"),
    "user": os.getenv("PG_USER"),
    "password": os.getenv("PG_PASSWORD"),
}

def main():
    url = f"https://api.themoviedb.org/3/configuration/languages?api_key={API_KEY}"
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    data = response.json()

    conn = psycopg2.connect(**DB)

    try:
        with conn:
            with conn.cursor() as cur:
                for language in data:
                    cur.execute(
                        """
                        INSERT INTO analytics.dim_language (language_code, language_name)
                        VALUES (%s, %s)
                        ON CONFLICT (language_code) DO UPDATE
                        SET language_name = excluded.language_name;
                        """,
                        (language["iso_639_1"], language["english_name"])
                    )

        print("Languages loaded into analytics.dim_language")

    finally:
        conn.close()

if __name__ == "__main__":
    main()