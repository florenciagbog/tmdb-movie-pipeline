-- create the table that will hold API responses
CREATE TABLE IF NOT EXISTS raw.tmdb_trending_raw (
    id          SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL,
    endpoint    TEXT NOT NULL,
    payload     JSONB NOT NULL,
    page        INT NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_snapshot_page UNIQUE (snapshot_date, page)
);