# run_pipeline.py

import os
import psycopg2
from dotenv import load_dotenv

import get_tmdb_genres
import ingest_tmdb
import get_tmdb_languages
import ingest_tmdb_movie_videos


load_dotenv()


# Connect to the database
conn = psycopg2.connect(
    host=os.getenv("PG_HOST"),
    port=int(os.getenv("PG_PORT")),
    dbname=os.getenv("PG_DB"),
    user=os.getenv("PG_USER"),
    password=os.getenv("PG_PASSWORD"),
)


# Step 1: Fetch genres from TMDB
print("Fetching genres from TMDB...")
get_tmdb_genres.main()


# Step 2: Fetch languages from TMDB
print("Fetching languages from TMDB...")
get_tmdb_languages.main()


# Step 3: Fetch trending movies from TMDB
print("Fetching trending movies from TMDB...")
ingest_tmdb.main()


# Step 4: Load staging tables and dimensions required for video ingestion
sql_files = [
    "sql/transforms/20_load_staging_tables.sql",
    "sql/transforms/21_load_dim_calendar.sql",
    "sql/transforms/22_load_dim_movie.sql",
]


# Open cursor
cur = conn.cursor()


# Run first SQL transformation phase
for file in sql_files:
    print(f"Running {file}...")

    with open(file, "r") as f:
        sql = f.read()

    cur.execute(sql)

    print("Done!")


# Commit new movies so video ingestion can see them
conn.commit()

# Close cursor
cur.close()


# Step 5: Fetch videos for movies missing from raw video data
print("Fetching videos from TMDB...")
ingest_tmdb_movie_videos.main()


# Step 6: Load trailers and remaining analytics tables
sql_files2 = [
    "sql/transforms/26_load_staging_movie_trailers.sql",
    "sql/transforms/22_load_dim_movie.sql",
    "sql/transforms/23_load_bridge_movie_genre.sql",
    "sql/transforms/24_load_fact_table.sql",
    "sql/transforms/25_load_dim_snapshot.sql",
]


# Open new cursor
cur = conn.cursor()


# Run second SQL transformation phase
for file in sql_files2:
    print(f"Running {file}...")

    with open(file, "r") as f:
        sql = f.read()

    cur.execute(sql)

    print("Done!")


# Commit final transformations
conn.commit()


# Close cursor and database connection
cur.close()
conn.close()


print("Pipeline finished")