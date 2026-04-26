-- Stores one flattened row per movie per day from the TMDB trending API, capturing ranking and engagement metrics at each daily snapshot.

CREATE TABLE IF NOT EXISTS raw.tmdb_trending_daily (
    snapshot_date  DATE        NOT NULL,
    movie_id       INTEGER     NOT NULL,
    title          TEXT,
    rank_overall   INTEGER,
    popularity     NUMERIC,
    vote_average   NUMERIC,
    vote_count     INTEGER,
    inserted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (snapshot_date, movie_id)
);