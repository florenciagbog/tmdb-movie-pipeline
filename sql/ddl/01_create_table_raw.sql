-- create the table that will hold API responses
CREATE TABLE IF NOT EXISTS raw.tmdb_api_responses (
    id          SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    endpoint    TEXT NOT NULL,
    payload     JSONB NOT NULL,
    page        INT NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_snapshot_page UNIQUE (snapshot_date, page)
);


-- ALTER TABLE raw.tmdb_trending_raw RENAME TO tmdb_api_responses;
-- ALTER TABLE staging.tmdb_trending_daily RENAME TO tmdb_daily_metrics;
-- ALTER TABLE staging.tmdb_trending_movies_raw RENAME TO tmdb_movie_entries;
-- ALTER TABLE analytics.fact_trending_daily RENAME TO fact_daily_movie;