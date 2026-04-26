-- Stores one raw JSONB payload row per movie per day per endpoint, preserving the full API response before transformation.

CREATE TABLE IF NOT EXISTS raw.tmdb_trending_movies_raw (
    snapshot_date  DATE        NOT NULL,
    endpoint       TEXT        NOT NULL,
    page           INTEGER     NOT NULL,
    rank_overall   INTEGER     NOT NULL,
    movie_id       INTEGER     NOT NULL,
    title          TEXT,
    movie_payload  JSONB       NOT NULL,
    inserted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (snapshot_date, endpoint, movie_id)
);