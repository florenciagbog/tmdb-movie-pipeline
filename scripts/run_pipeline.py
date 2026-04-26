# run_pipeline.py
import os
import psycopg2
from dotenv import load_dotenv
import get_tmdb_genres
import ingest_tmdb

load_dotenv()

# Connect to the database
conn = psycopg2.connect(
    host=os.getenv("PG_HOST"),
    port=int(os.getenv("PG_PORT")),
    dbname=os.getenv("PG_DB"),
    user=os.getenv("PG_USER"),
    password=os.getenv("PG_PASSWORD"),
)

# Step 1: fetch genre lookup table from TMDB 
print("Fetching genres from TMDB...")
get_tmdb_genres.main()

# Step 2: fetch trending movies from TMDB API and load into raw table
print("Fetching trending movies from TMDB...")
ingest_tmdb.main()

# Step 3: run each SQL transform in order
sql_files = [
    "sql/20_load_raw_tables.sql",
    "sql/21_load_dim_calendar.sql",
    "sql/22_load_dim_movie.sql",
    "sql/23_load_bridge_movie_genre.sql",
    "sql/24_load_fact_table.sql",
]

# Open a cursor to execute SQL against the database
cur = conn.cursor()

# Run each SQL file in order
for file in sql_files:
    print(f"Running {file}...")
    
    # Open the file and read its contents
    with open(file, "r") as f:
        sql = f.read()
    
    # Execute the SQL
    cur.execute(sql)
    print(f"Done!")

# Commit all changes to the database
conn.commit()

# Close the cursor and connection
cur.close()
conn.close()

print("Pipeline finished")