"""Daily TMDB pipeline (BigQuery version). Run with: python -m pipeline.run_pipeline"""

import time

from pipeline import (
    get_tmdb_genres,
    get_tmdb_languages,
    ingest_tmdb,
    ingest_tmdb_movie_videos,
)
from pipeline.config import BQ_LOCATION, PROJECT_ID, ensure_tables, run_sql_file

PHASE_1 = [
    "transforms/20_load_staging_tables.sql",
    "transforms/21_load_dim_calendar.sql",
    "transforms/22_load_dim_movie.sql",
]

PHASE_2 = [
    "transforms/26_load_staging_movie_trailers.sql",
    "transforms/22_load_dim_movie.sql",
    "transforms/23_load_bridge_movie_genre.sql",
    "transforms/24_load_fact_table.sql",
    "transforms/25_load_dim_snapshot.sql",
]


def step(name, fn, *args):
    print(f"▶ {name}")
    start = time.monotonic()
    fn(*args)
    print(f"  done in {time.monotonic() - start:.1f}s")


def main() -> None:
    print(f"TMDB pipeline → project {PROJECT_ID} ({BQ_LOCATION})")

    step("Ensuring datasets and tables exist", ensure_tables)
    step("Fetching genres from TMDB", get_tmdb_genres.main)
    step("Fetching languages from TMDB", get_tmdb_languages.main)
    step("Fetching trending movies from TMDB", ingest_tmdb.main)

    for sql_file in PHASE_1:
        step(f"Running {sql_file}", run_sql_file, sql_file)

    step("Fetching videos from TMDB", ingest_tmdb_movie_videos.main)

    for sql_file in PHASE_2:
        step(f"Running {sql_file}", run_sql_file, sql_file)

    print("Pipeline finished")


if __name__ == "__main__":
    main()
